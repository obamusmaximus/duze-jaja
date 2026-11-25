class_name SelectionCard
extends PanelContainer
## One bone card in the selection panel's grid. A type card: team stripe, type name, count and the type's combined
## health. A unit card: the type's icon and that unit's health. An overflow card: "+N". The main type's card is ringed
## orange (`PanelLightMain`). Reports clicks upward; it changes nothing itself.

signal clicked
signal double_clicked

var type: UnitStats
var units: Array[Unit] = []
var _bar := StatBar.new()


## `per_unit`: a card for the single unit in `of_units`. `type` null: an overflow card for `of_units.size()` more.
func _init(of_type: UnitStats, of_units: Array[Unit], team: int, side: int, per_unit: bool) -> void:
	type = of_type
	units = of_units
	theme_type_variation = &"PanelLight"
	custom_minimum_size = Vector2(side, side)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL # Cards share the row's width evenly.
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	if type == null:
		var more := HudModule.label("+%d" % units.size(), &"LabelNumberDark")
		more.size_flags_vertical = Control.SIZE_EXPAND_FILL
		more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		more.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		column.add_child(more)
		return
	column.add_child(_stripe(UiTokens.team_color(team)))
	if per_unit:
		var icon := UnitIcon.new(type, UiTokens.BLACK)
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(icon)
	else:
		var name_label := HudModule.label(type.display_name.to_upper(), &"LabelCaptionDark")
		name_label.clip_text = true
		column.add_child(name_label)
		var count := HudModule.label("×%d" % units.size(), &"LabelHeadingDark")
		count.size_flags_vertical = Control.SIZE_EXPAND_FILL
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		column.add_child(count)
	_bar.fill_color = UiTokens.BLACK
	_bar.custom_minimum_size = Vector2(0, UiTokens.UNIT * 0.5)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_bar)
	refresh()


func set_main(on: bool) -> void:
	theme_type_variation = &"PanelLightMain" if on else &"PanelLight"


## Re-reads the units' health.
func refresh() -> void:
	if type == null:
		return
	var alive: float = 0.0
	var total: float = 0.0
	for unit: Unit in units:
		total += type.max_health
		if is_instance_valid(unit) and unit.alive:
			alive += unit.health.current
	_bar.fraction = alive / maxf(total, 1.0)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if button.double_click:
		double_clicked.emit()
	else:
		clicked.emit()


static func _stripe(color: Color) -> ColorRect:
	var stripe := ColorRect.new()
	stripe.color = color
	stripe.custom_minimum_size = Vector2(0, UiTokens.UNIT * 0.5)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stripe
