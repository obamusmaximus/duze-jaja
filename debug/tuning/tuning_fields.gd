class_name TuningFields
extends RefCounted
## Debug: builds editing controls for a tuning Resource (PlayerStats, DroneStats, ...) by reflecting on its
## exported properties. Each `@export_group` becomes a foldable sub-label; each property a row with a
## slider and number box (floats, ints), a checkbox, a colour button, or a box per element (float arrays).
## Edits write straight into the resource and call `emit_changed()`, so parts that listen can refresh.
## No resource needs to be registered: add an `@export` to a stats script and it shows up here.
## Hovering a row, or focusing its editor, calls `on_hover(resource, prop, description)` (the panel's preview).

## Row columns share the row by stretch ratio, so a long label never pushes the slider. Widths are minimums only.
const LABEL_RATIO: float = 4.0
const EDITOR_RATIO: float = 6.0
const SLIDER_RATIO: float = 2.0
const NUMBER_RATIO: float = 1.0
const NUMBER_MIN_WIDTH: float = 112.0
const SLIDER_MIN_WIDTH: float = 96.0
const ARRAY_BOX_MIN_WIDTH: float = 88.0
## The row that is showing in the preview, so it can be marked. One per built column.
const ACTIVE_ROW_VARIATION: StringName = &"TuningRowActive"
const ROW_VARIATION: StringName = &"TuningRow"


## A VBoxContainer holding one foldable section per `@export_group` of `resource`.
static func build(resource: Resource, on_hover: Callable = Callable()) -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.theme_type_variation = &"TuningTightV"
	var active: Array[Control] = []
	var tooltips: Dictionary = _read_tooltips(resource.get_script() as Script)
	var group_title: String = "General"
	var body: VBoxContainer = null
	for info: Dictionary in get_editable_properties(resource, true):
		if int(info["usage"]) & PROPERTY_USAGE_GROUP:
			group_title = str(info["name"])
			body = null  # The section is only made once a row needs it, so empty groups don't show.
			continue
		var row: Control = _make_row(resource, info, tooltips, on_hover, active)
		if row == null:
			continue
		if body == null:
			var section := FoldableContainer.new()
			section.title = group_title.to_upper()
			body = VBoxContainer.new()
			section.add_child(body)
			column.add_child(section)
		body.add_child(row)
	return column


## The script-defined properties of `resource` in declaration order. With `with_groups` the
## `@export_group` markers are included, as entries whose usage has PROPERTY_USAGE_GROUP.
static func get_editable_properties(resource: Resource, with_groups: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for info: Dictionary in resource.get_property_list():
		var usage: int = info["usage"]
		if with_groups and usage & PROPERTY_USAGE_GROUP:
			result.append(info)
		elif usage & PROPERTY_USAGE_EDITOR and usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result.append(info)
	return result


## Copies every editable value from `source` into `target` (used to reset to what is saved on disk).
static func copy_values(source: Resource, target: Resource) -> void:
	for info: Dictionary in get_editable_properties(target):
		var prop: String = info["name"]
		var value: Variant = source.get(prop)
		if value is Array or value is PackedFloat32Array:
			value = value.duplicate()
		target.set(prop, value)
	target.emit_changed()


static func _make_row(resource: Resource, info: Dictionary, tooltips: Dictionary, on_hover: Callable, active: Array[Control]) -> Control:
	var prop: String = info["name"]
	var value: Variant = resource.get(prop)
	var editor: Control
	match typeof(value):
		TYPE_FLOAT, TYPE_INT:
			editor = _number_editor(resource, prop, info, value)
		TYPE_BOOL:
			var check := CheckBox.new()
			check.button_pressed = value
			check.toggled.connect(func(on: bool) -> void: _apply(resource, prop, on))
			editor = check
		TYPE_COLOR:
			var picker := ColorPickerButton.new()
			picker.custom_minimum_size = Vector2(70.0, 24.0)
			picker.color = value
			picker.color_changed.connect(func(color: Color) -> void: _apply(resource, prop, color))
			editor = picker
		TYPE_PACKED_FLOAT32_ARRAY:
			editor = _array_editor(resource, prop, value)
		_:
			return null
	var row := PanelContainer.new()
	row.theme_type_variation = ROW_VARIATION
	row.custom_minimum_size.y = UiTokens.px(UiTokens.TOOL_ROW_UNITS)
	var cells := HBoxContainer.new()
	cells.theme_type_variation = &"TuningGapH"
	row.add_child(cells)
	var label := Label.new()
	label.text = prop.capitalize()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	label.size_flags_stretch_ratio = LABEL_RATIO
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.tooltip_text = str(tooltips.get(prop, ""))
	row.tooltip_text = label.tooltip_text
	cells.add_child(label)
	var editor_cell: Control = editor
	if editor is Button: # A checkbox or colour swatch keeps its own size at the left of the editor column.
		editor_cell = HBoxContainer.new()
		editor_cell.add_child(editor)
		editor.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	editor_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_cell.size_flags_stretch_ratio = EDITOR_RATIO
	cells.add_child(editor_cell)
	if on_hover.is_valid():
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		var show: Callable = func() -> void:
			_mark_active(row, active)
			on_hover.call(resource, prop, label.tooltip_text)
		row.mouse_entered.connect(show)
		_connect_focus(editor, show)
	return row


## Marks `row` as the one in the preview and clears the mark on the previous one.
static func _mark_active(row: Control, active: Array[Control]) -> void:
	if not active.is_empty() and is_instance_valid(active[0]):
		active[0].theme_type_variation = ROW_VARIATION
	active.clear()
	active.append(row)
	row.theme_type_variation = ACTIVE_ROW_VARIATION


## Calls `show` when `control` or any control inside it takes focus.
static func _connect_focus(control: Control, show: Callable) -> void:
	if control.focus_mode != Control.FOCUS_NONE:
		control.focus_entered.connect(show)
	for child: Node in control.get_children(true):
		if child is Control:
			_connect_focus(child as Control, show)


static func _number_editor(resource: Resource, prop: String, info: Dictionary, value: float) -> Control:
	var is_int: bool = typeof(value) == TYPE_INT
	var bounds: Vector3 = _slider_range(prop, info, value, is_int)
	var slider := HSlider.new()
	slider.min_value = bounds.x
	slider.max_value = bounds.y
	slider.step = bounds.z
	slider.allow_greater = true
	slider.allow_lesser = true
	slider.custom_minimum_size.x = SLIDER_MIN_WIDTH
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_stretch_ratio = SLIDER_RATIO
	slider.value = value

	var spin := SpinBox.new()
	spin.allow_greater = true
	spin.allow_lesser = true
	spin.min_value = -1.0e9
	spin.max_value = 1.0e9
	spin.step = 1.0 if is_int else maxf(bounds.z * 0.1, 0.00001)
	spin.custom_arrow_step = bounds.z
	spin.custom_minimum_size.x = NUMBER_MIN_WIDTH
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	spin.size_flags_stretch_ratio = NUMBER_RATIO
	spin.get_line_edit().alignment = HORIZONTAL_ALIGNMENT_RIGHT
	spin.value = value

	slider.value_changed.connect(func(v: float) -> void:
		spin.set_value_no_signal(v)
		_apply(resource, prop, int(roundf(v)) if is_int else v))
	spin.value_changed.connect(func(v: float) -> void:
		slider.set_value_no_signal(v)
		_apply(resource, prop, int(roundf(v)) if is_int else v))

	var box := HBoxContainer.new()
	box.theme_type_variation = &"TuningGapH"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(slider)
	box.add_child(spin)
	return box


static func _array_editor(resource: Resource, prop: String, value: PackedFloat32Array) -> Control:
	var box := HBoxContainer.new()
	box.theme_type_variation = &"TuningTightH"
	for i: int in value.size():
		var spin := SpinBox.new()
		spin.allow_greater = true
		spin.allow_lesser = true
		spin.min_value = -1.0e9
		spin.max_value = 1.0e9
		spin.step = 0.1
		spin.custom_minimum_size.x = ARRAY_BOX_MIN_WIDTH
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		spin.get_line_edit().alignment = HORIZONTAL_ALIGNMENT_RIGHT
		spin.value = value[i]
		spin.value_changed.connect(func(v: float) -> void:
			var items := PackedFloat32Array(resource.get(prop))
			items[i] = v
			_apply(resource, prop, items))
		box.add_child(spin)
	return box


## Slider (min, max, step). A range hint wins; otherwise it spans from 0 to three times the current value.
static func _slider_range(prop: String, info: Dictionary, value: float, is_int: bool) -> Vector3:
	if int(info["hint"]) == PROPERTY_HINT_RANGE:
		var parts: PackedStringArray = str(info["hint_string"]).split(",")
		if parts.size() >= 2:
			var step: float = float(parts[2]) if parts.size() >= 3 and parts[2].is_valid_float() else (1.0 if is_int else 0.001)
			return Vector3(float(parts[0]), float(parts[1]), step)
	if prop.ends_with("_db"):
		return Vector3(-60.0, 12.0, 0.5)
	var high: float = maxf(absf(value) * 3.0, 10.0 if is_int else 1.0)
	var low: float = 0.0 if value >= 0.0 else -high
	if value < 0.0:
		high = 0.0
	if is_int:
		return Vector3(low, high, 1.0)
	var step: float = pow(10.0, floorf(log(high) / log(10.0)) - 2.0)
	return Vector3(low, high, step)


static func _apply(resource: Resource, prop: String, value: Variant) -> void:
	if value is float:
		value = snappedf(value, 0.000001) # Sliders work in 32-bit steps; keep the stored value clean.
	resource.set(prop, value)
	resource.emit_changed()


## Maps property name to its `##` doc comment, read from the script's source, to use as a tooltip.
static func _read_tooltips(script: Script) -> Dictionary:
	var result: Dictionary = {}
	# Walk up the base scripts too, so a stats class that extends another shows the base's tooltips.
	var current: Script = script
	while current != null:
		var source: String = (current as GDScript).source_code if current is GDScript else ""
		var pending: PackedStringArray = PackedStringArray()
		for raw: String in source.split("\n"):
			var line: String = raw.strip_edges()
			if line.begins_with("##"):
				pending.append(line.trim_prefix("##").strip_edges())
			elif line.begins_with("@export") and " var " in line:
				var prop: String = line.split(" var ")[1].split(":")[0].strip_edges()
				if not pending.is_empty() and not result.has(prop):
					result[prop] = " ".join(pending)
				pending.clear()
			else:
				pending.clear()
		current = current.get_base_script()
	return result
