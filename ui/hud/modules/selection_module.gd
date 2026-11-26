class_name SelectionModule
extends HudModule
## HUD module: what the local player has selected. None: a hatched empty slot. One unit: its model turning in a
## hatched well (`UnitPortrait`), its name in the wide face with a team mark, health with a bar, and stat chips.
## Several: `SelectionGroup` (the main type on top, a grid of type or unit cards below, RA3 style). It changes only
## the `Selection` (view state): card clicks pick the main type or narrow the selection. Under own units sits the main
## type's ability (`AbilityButton`); its press goes to the RTS controls through `HudCommands`.

var _units: Array[Unit] = []
var _health_row: StatRow
var _group: SelectionGroup
var _ability: AbilityButton
var _since_refresh: float = INF


func _title() -> String:
	return "SELECTION"


func _build() -> void:
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	context.selection.changed.connect(_rebuild)
	context.selection.main_changed.connect(_refresh_ability)
	context.commands.armed_changed.connect(_refresh_ability)


func _apply() -> void:
	custom_minimum_size.x = UiTokens.px(context.stats.selection_width_units)
	_rebuild()


func _process(delta: float) -> void:
	_since_refresh += delta
	if _since_refresh < 1.0 / context.stats.readout_rate:
		return
	_since_refresh = 0.0
	_refresh_ability()
	if _group != null:
		_group.refresh()
	elif _health_row != null and not _units.is_empty() and is_instance_valid(_units[0]):
		var unit: Unit = _units[0]
		var current: float = unit.health.current if unit.alive else 0.0
		_health_row.set_value("%d / %d" % [ceili(current), roundi(unit.stats.max_health)],
				current / maxf(unit.stats.max_health, 1.0), UiTokens.team_color(unit.team))


func _rebuild() -> void:
	if context == null:
		return
	_units = context.selection.units.duplicate()
	var inspected: Unit = context.selection.inspected()
	if _units.is_empty() and inspected != null:
		_units = [inspected] # An enemy being inspected: the same sheet, without its hold.
	_health_row = null
	_group = null
	_ability = null
	_since_refresh = INF
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	set_active(not _units.is_empty())
	if _units.is_empty():
		set_note("NONE")
		_empty()
	elif _units.size() == 1:
		set_note(("UNIT %d" if _units[0].team == context.team else "ENEMY %d") % _units[0].id)
		_single(_units[0])
	else:
		set_note("%d UNITS" % _units.size())
		_group = SelectionGroup.new()
		content.add_child(_group)
		_group.setup(context.selection, context.stats, context.team)
	if not context.selection.is_empty():
		_ability = AbilityButton.new(context.stats.ability_button_units)
		_ability.pressed.connect(context.commands.ability_pressed.emit)
		content.add_child(_ability)
		_refresh_ability()


func _refresh_ability() -> void:
	if _ability != null:
		_ability.refresh(context.selection.main_units(), context.commands.ability_armed)


func _empty() -> void:
	var slot := PanelContainer.new()
	slot.theme_type_variation = &"PanelHatch"
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hint := HudModule.label("NO UNITS SELECTED", &"LabelCaption")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(hint)
	content.add_child(slot)


func _single(unit: Unit) -> void:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
	var well := PanelContainer.new()
	well.theme_type_variation = &"PanelHatch"
	well.custom_minimum_size = Vector2.ONE * UiTokens.px(context.stats.portrait_units)
	well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var portrait := UnitPortrait.new()
	well.add_child(portrait)
	portrait.show_unit(unit.stats, unit.team)
	row.add_child(well)
	var sheet := VBoxContainer.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.add_theme_constant_override(&"separation", UiTokens.UNIT)
	var title := HBoxContainer.new()
	title.add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
	var swatch := ColorRect.new()
	swatch.color = UiTokens.team_color(unit.team)
	swatch.custom_minimum_size = Vector2(UiTokens.px(1), UiTokens.px(4))
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_child(swatch)
	title.add_child(HudModule.label(unit.stats.display_name.to_upper(), &"LabelHeading"))
	sheet.add_child(title)
	_health_row = StatRow.new("Health")
	sheet.add_child(_health_row)
	sheet.add_child(StatChip.row_for(unit.stats))
	if unit.cargo != null and unit.team == context.team: # Enemy holds stay hidden.
		sheet.add_child(CargoView.new(unit.cargo, UiTokens.px(context.stats.cargo_slot_units)))
	row.add_child(sheet)
	content.add_child(row)
