class_name AbilitiesModule
extends HudModule
## HUD module, placeholder: the commander's abilities along the bottom of the strategy HUD, six slots (satellite
## recon, EMP, airstrike, three open). Each slot is a hatched cell with its name under it; cooldowns and use come
## with the abilities themselves.

const SLOTS: PackedStringArray = ["RECON", "EMP", "AIRSTRIKE", "", "", ""]

var _cells: Array[Button] = []


func _title() -> String:
	return "COMMANDER"


func _build() -> void:
	set_note("SOON")
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.UNIT)
	for slot_name: String in SLOTS:
		var column := VBoxContainer.new()
		column.add_theme_constant_override(&"separation", 0)
		var cell := Button.new()
		cell.theme_type_variation = &"CommandCell"
		cell.text = "+"
		cell.disabled = true
		cell.focus_mode = Control.FOCUS_NONE
		column.add_child(cell)
		_cells.append(cell)
		var caption := label(slot_name if slot_name != "" else "OPEN", &"LabelMuted")
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(caption)
		row.add_child(column)
	content.add_child(row)


func _apply() -> void:
	for cell: Button in _cells:
		cell.custom_minimum_size = Vector2.ONE * UiTokens.px(context.stats.ability_slot_units)
