class_name SelectionGroup
extends VBoxContainer
## The selection panel with several units selected (RA3 style). On top, the main type: its model turning in a
## hatched well, its name, how many of it are selected and its stats. Below, a grid of cards (`SelectionCard`,
## `UiStats` columns x rows). Several types: a card per type with count and combined health, the main one ringed;
## click makes a type main, double click selects only that type. One type: a card per unit with its health; double
## click selects only that unit. More cards than fit: the last shows "+N". Changes the game only through the
## `Selection` (a view-state list).

var _selection: Selection
var _stats: UiStats
var _team: int
var _portrait := UnitPortrait.new()
var _name := HudModule.label("", &"LabelHeading")
var _count := HudModule.label("", &"LabelCaption")
var _chips := VBoxContainer.new()
var _grid := GridContainer.new()
var _cards: Array[SelectionCard] = []


func setup(selection: Selection, stats: UiStats, team: int) -> void:
	_selection = selection
	_stats = stats
	_team = team
	add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
	var well := PanelContainer.new()
	well.theme_type_variation = &"PanelHatch"
	well.custom_minimum_size = Vector2.ONE * UiTokens.px(stats.portrait_units)
	well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	well.add_child(_portrait)
	row.add_child(well)
	var sheet := VBoxContainer.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.add_theme_constant_override(&"separation", UiTokens.UNIT)
	sheet.add_child(_name)
	sheet.add_child(_count)
	sheet.add_child(_chips)
	row.add_child(sheet)
	add_child(row)
	_grid.columns = stats.selection_columns
	_grid.add_theme_constant_override(&"h_separation", UiTokens.UNIT)
	_grid.add_theme_constant_override(&"v_separation", UiTokens.UNIT)
	add_child(_grid)
	_build_cards()
	_show_main()
	_selection.main_changed.connect(_show_main)


func refresh() -> void:
	for card: SelectionCard in _cards:
		card.refresh()


func _build_cards() -> void:
	var by_type: Dictionary = _selection.types()
	var side: int = UiTokens.px(_stats.selection_card_units)
	var room: int = _stats.selection_columns * _stats.selection_rows
	var entries: Array = [] # [type, units, per_unit]
	if by_type.size() == 1:
		for unit: Unit in by_type.values()[0]:
			var one: Array[Unit] = [unit]
			entries.append([unit.stats, one, true])
	else:
		for type: UnitStats in by_type:
			var of_type: Array[Unit] = []
			of_type.assign(by_type[type])
			entries.append([type, of_type, false])
	for i: int in entries.size():
		if i == room - 1 and entries.size() > room:
			var rest: Array[Unit] = []
			for entry: Array in entries.slice(i):
				rest.append_array(entry[1])
			_grid.add_child(SelectionCard.new(null, rest, _team, side, false))
			break
		var card := SelectionCard.new(entries[i][0], entries[i][1], _team, side, entries[i][2])
		if entries[i][2]:
			card.double_clicked.connect(_selection.set_units.bind(card.units))
		else:
			card.clicked.connect(_selection.set_main_type.bind(card.type))
			card.double_clicked.connect(_selection.set_units.bind(card.units))
		_grid.add_child(card)
		_cards.append(card)


func _show_main() -> void:
	var main: UnitStats = _selection.main_type
	if main == null:
		return
	_portrait.show_unit(main, _team)
	_name.text = main.display_name.to_upper()
	var count: int = _selection.main_units().size()
	var total: int = _selection.ids().size()
	_count.text = ("%d SELECTED" % count) if count == total else ("%d OF %d SELECTED  ·  MAIN TYPE" % [count, total])
	for child: Node in _chips.get_children():
		child.queue_free()
	_chips.add_child(StatChip.row_for(main))
	var several_types: bool = _selection.types().size() > 1
	for card: SelectionCard in _cards:
		card.set_main(several_types and card.type == main)
