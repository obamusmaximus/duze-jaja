class_name AbilityButton
extends HBoxContainer
## The selection panel's ability row: a command cell with the key (press it like F), the ability's name, its state
## (`AbilityStatus`) and a bar that fills as it cools down. The cell is hatched while no unit can use it and stays
## down while a targeted ability waits for its click. It only reports the press; `refresh` re-reads the units.

signal pressed

var _cell := Button.new()
var _name := HudModule.label("", &"LabelNumber")
var _state := HudModule.label("", &"LabelCaption")
var _bar := StatBar.new()


func _init(cell_units: int) -> void:
	add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
	_cell.theme_type_variation = &"CommandCell"
	_cell.custom_minimum_size = Vector2.ONE * UiTokens.px(cell_units)
	_cell.focus_mode = Control.FOCUS_NONE
	_cell.toggle_mode = true
	_cell.text = "F"
	# Pressed state is set from `refresh`, not by the click.
	_cell.pressed.connect(func() -> void:
		_cell.set_pressed_no_signal(not _cell.button_pressed)
		pressed.emit())
	add_child(_cell)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override(&"separation", UiTokens.UNIT / 2)
	_state.clip_text = true
	column.add_child(_name)
	column.add_child(_state)
	_bar.warn_when_low = false
	_bar.fill_color = UiTokens.GREEN
	column.add_child(_bar)
	add_child(column)


## Shows the ability of `units` (hidden if they have none). `armed`: it is waiting for its target click.
func refresh(units: Array[Unit], armed: bool) -> void:
	var status: AbilityStatus = AbilityStatus.of(units)
	visible = status != null
	if status == null:
		return
	_name.text = status.stats.display_name.to_upper()
	var words: String = status.text()
	if armed:
		words = "PICK A TARGET" if status.stats.targeting() == AbilityStats.Targeting.UNIT else "PICK A POINT"
	_state.text = words
	_bar.fraction = status.fraction
	var disabled: bool = status.state != AbilityStatus.State.READY
	if _cell.disabled != disabled:
		_cell.disabled = disabled
	_cell.set_pressed_no_signal(armed)
