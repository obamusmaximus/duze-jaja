class_name SelectionModule
extends HudModule
## HUD module: what the local player has selected. None: a hatched empty slot. One unit: its model turning in a
## hatched well (`UnitPortrait`), its name in the wide face with a team mark, health with a bar, and chips for
## speed, range, damage and rate of fire. Several: a grid of bone
## cards, one per unit type (team stripe, name, count, the type's health), above the group's total health. View
## only: it reads the `Selection` and the units' health and changes nothing.

var _units: Array[Unit] = []
var _health_row: StatRow
## Unit type to [card health bar, its units].
var _cards: Dictionary = {}
var _since_refresh: float = INF


func _title() -> String:
	return "SELECTION"


func _build() -> void:
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	context.selection.changed.connect(_rebuild)


func _apply() -> void:
	custom_minimum_size.x = UiTokens.px(context.stats.selection_width_units)
	_rebuild()


func _process(delta: float) -> void:
	_since_refresh += delta
	if _health_row == null or (_units.size() > 1 and _since_refresh < 1.0 / context.stats.readout_rate):
		return
	_since_refresh = 0.0
	var current: float = 0.0
	var most: float = 0.0
	for unit: Unit in _units:
		if is_instance_valid(unit) and unit.alive:
			current += unit.health.current
		most += unit.stats.max_health if is_instance_valid(unit) else 0.0
	_health_row.set_value("%d / %d" % [ceili(current), roundi(most)], current / maxf(most, 1.0), UiTokens.team_color(context.team))
	for stats: UnitStats in _cards:
		var bar: StatBar = _cards[stats][0]
		var alive: float = 0.0
		var total: float = 0.0
		for unit: Unit in _cards[stats][1]:
			total += stats.max_health
			if is_instance_valid(unit) and unit.alive:
				alive += unit.health.current
		bar.fraction = alive / maxf(total, 1.0)


func _rebuild() -> void:
	if context == null:
		return
	_units = context.selection.units.duplicate()
	_health_row = null
	_cards.clear()
	_since_refresh = INF
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	set_active(not _units.is_empty())
	if _units.is_empty():
		set_note("NONE")
		_empty()
	elif _units.size() == 1:
		set_note("UNIT %d" % _units[0].id)
		_single(_units[0])
	else:
		set_note("%d UNITS" % _units.size())
		_group()


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
	title.add_child(_swatch(UiTokens.team_color(unit.team), Vector2(UiTokens.px(1), UiTokens.px(4))))
	title.add_child(HudModule.label(unit.stats.display_name.to_upper(), &"LabelHeading"))
	sheet.add_child(title)
	_health_row = StatRow.new("Health")
	sheet.add_child(_health_row)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override(&"separation", UiTokens.UNIT)
	chips.add_child(_chip("Speed", "%.1f" % unit.stats.speed, "M/S"))
	var weapon: WeaponStats = unit.stats.weapon
	if weapon != null:
		chips.add_child(_chip("Range", "%d" % roundi(weapon.max_range), "M"))
		chips.add_child(_chip("Damage", "%d" % roundi(weapon.damage), ""))
		chips.add_child(_chip("Rate", "%.1f" % (1.0 / weapon.cooldown), "/S"))
	sheet.add_child(chips)
	row.add_child(sheet)
	content.add_child(row)


## A small inset block: a caption over a figure and its unit.
func _chip(caption: String, figure: String, unit_text: String) -> Control:
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"PanelInset"
	chip.custom_minimum_size.x = UiTokens.px(12)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	column.add_child(HudModule.label(caption.to_upper(), &"LabelCaption"))
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", UiTokens.UNIT / 2)
	line.add_child(HudModule.label(figure, &"LabelNumber"))
	if unit_text != "":
		var unit_label := HudModule.label(unit_text, &"LabelCaption")
		unit_label.size_flags_vertical = Control.SIZE_SHRINK_END
		line.add_child(unit_label)
	column.add_child(line)
	chip.add_child(column)
	return chip


func _group() -> void:
	var by_type: Dictionary = {}
	for unit: Unit in _units:
		if not by_type.has(unit.stats):
			by_type[unit.stats] = []
		(by_type[unit.stats] as Array).append(unit)
	var card_side: int = UiTokens.px(context.stats.selection_card_units)
	var gap: int = UiTokens.UNIT
	var grid := GridContainer.new()
	var inner_width: int = maxi(UiTokens.px(context.stats.selection_width_units), int(size.x)) - UiTokens.px(4)
	grid.columns = maxi(1, (inner_width + gap) / (card_side + gap))
	grid.add_theme_constant_override(&"h_separation", gap)
	grid.add_theme_constant_override(&"v_separation", gap)
	for stats: UnitStats in by_type:
		grid.add_child(_card(stats, by_type[stats], card_side))
	content.add_child(grid)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(spacer)
	_health_row = StatRow.new("Health")
	content.add_child(_health_row)


## A bone card: team stripe, type name, count, and the type's health.
func _card(stats: UnitStats, units: Array, side: int) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = &"PanelLight"
	card.custom_minimum_size = Vector2(side, side)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	column.add_child(_swatch(UiTokens.team_color(context.team), Vector2(0, UiTokens.UNIT * 0.5)))
	var name_label := HudModule.label(stats.display_name.to_upper(), &"LabelCaptionDark")
	name_label.clip_text = true
	column.add_child(name_label)
	var count := HudModule.label("×%d" % units.size(), &"LabelHeadingDark")
	count.size_flags_vertical = Control.SIZE_EXPAND_FILL
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	column.add_child(count)
	var bar := StatBar.new()
	bar.fill_color = UiTokens.BLACK
	bar.custom_minimum_size = Vector2(0, UiTokens.UNIT * 0.5)
	column.add_child(bar)
	card.add_child(column)
	_cards[stats] = [bar, units]
	return card


func _swatch(color: Color, min_size: Vector2) -> ColorRect:
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = min_size
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return swatch
