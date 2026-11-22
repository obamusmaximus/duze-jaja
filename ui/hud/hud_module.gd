class_name HudModule
extends PanelContainer
## Base of every HUD module: a card with a header strip (title on the left, a short note on the right) above a
## body. Modules are placed by a `HudLayout`, so they must work in any section: they size themselves from `UiStats`
## and never assume where they are. Subclasses override `_title`, `_build` (add children to `content`) and
## optionally `_apply` (re-read stats; runs on bind and whenever the stats change).

var context: HudContext
## Where subclasses put their children.
var content := VBoxContainer.new()
var body := PanelContainer.new()
var _header := PanelContainer.new()
var _title_label := Label.new()
var _note_label := Label.new()


func bind(new_context: HudContext) -> void:
	context = new_context
	theme_type_variation = &"ModuleFrame"
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	add_child(column)
	_header.theme_type_variation = _header_style()
	var row := HBoxContainer.new()
	_title_label.theme_type_variation = &"LabelCaptionDark"
	_title_label.text = _title()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note_label.theme_type_variation = &"LabelCaptionDark"
	row.add_child(_title_label)
	row.add_child(_note_label)
	_header.add_child(row)
	_header.visible = _title() != ""
	column.add_child(_header)
	body.theme_type_variation = _body_style()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override(&"separation", UiTokens.UNIT)
	body.add_child(content)
	column.add_child(body)
	_build()
	context.stats.changed.connect(_apply)
	_apply()


## The short text at the right of the header strip (a count, a state).
func set_note(text: String) -> void:
	_note_label.text = text.to_upper()


## Marks the module active (its header strip turns acid green) or back to normal.
func set_active(on: bool) -> void:
	_header.theme_type_variation = &"ModuleHeaderAccent" if on else _header_style()


## Header text, upper case. Empty hides the header.
func _title() -> String:
	return ""


func _header_style() -> StringName:
	return &"ModuleHeader"


func _body_style() -> StringName:
	return &"ModuleBody"


func _build() -> void:
	pass


func _apply() -> void:
	pass


static func label(text: String, variation: StringName = &"") -> Label:
	var new_label := Label.new()
	new_label.text = text
	new_label.theme_type_variation = variation
	return new_label
