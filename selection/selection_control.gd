class_name SelectionControl
extends Node
## Changes the player's selection from clicks and boxes. Only own units are selected: a box takes only own units,
## and clicking one enemy shows its info in the HUD without selecting it (box and Shift never take enemies). Holding `select_add` (Shift) adds
## to or removes from the selection. A box projects unit positions to the screen; it doesn't use physics. A flyer
## is boxed by its body or by its ground point.
## A playtest probe: the selected unit ids, and the events `select`, `box_select`, `inspect`.

signal playtest_event(event: StringName, data: Dictionary)

var _team: int
var _selection: Selection


func setup(team: int, selection: Selection) -> void:
	_team = team
	_selection = selection
	add_to_group(&"playtest_probe")


func _unhandled_input(event: InputEvent) -> void:
	if _selection != null and event.is_action_pressed(&"cycle_main_type"):
		cycle_main_type()
		get_viewport().set_input_as_handled()


## Makes the next selected type the main one (the types run most numerous first, and wrap round).
func cycle_main_type() -> void:
	var types: Array = _selection.types().keys()
	if types.size() > 1:
		_selection.set_main_type(types[(types.find(_selection.main_type) + 1) % types.size()])


## A click on one of the player's units. A double-click selects every own unit of its type on screen.
func click_unit(unit: Unit, double_click: bool) -> void:
	if double_click:
		var same: Array[Unit] = []
		for other: Unit in _own_units_in(get_viewport().get_visible_rect()):
			if other.stats == unit.stats:
				same.append(other)
		if _adding():
			_selection.add(same)
		else:
			_selection.set_units(same)
	elif _adding():
		_selection.toggle(unit)
	else:
		var one: Array[Unit] = [unit]
		_selection.set_units(one)
	playtest_event.emit(&"select", {"unit": unit.id, "double": double_click, "ids": _selection.ids()})


func select_box(rect: Rect2) -> void:
	var inside: Array[Unit] = _own_units_in(rect)
	if _adding():
		_selection.add(inside)
	else:
		_selection.set_units(inside)
	playtest_event.emit(&"box_select", {"rect": [rect.position, rect.end], "ids": _selection.ids()})


func clear() -> void:
	_selection.clear()


## A click on a unit that can't be selected (an enemy): the HUD shows its info in place of the selection.
func inspect(unit: Unit) -> void:
	_selection.inspect(unit)
	playtest_event.emit(&"inspect", {"unit": unit.id, "team": unit.team})


## Own units that `rect` (viewport coordinates) takes (`FlyerPick.in_box`).
func _own_units_in(rect: Rect2) -> Array[Unit]:
	var found: Array[Unit] = []
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return found
	for node: Node in get_tree().get_nodes_in_group(StringName("team_%d" % _team)):
		var unit := node as Unit
		if unit != null and unit.alive and FlyerPick.in_box(camera, unit, rect):
			found.append(unit)
	return found


func _adding() -> bool:
	return Input.is_action_pressed(&"select_add")


func playtest_snapshot() -> Dictionary:
	return {"selected": _selection.ids()}
