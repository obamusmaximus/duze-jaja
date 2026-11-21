class_name SelectionControl
extends Node
## Changes the player's selection from clicks and boxes. Only own units are selected: a box takes only own units,
## and clicking an enemy shows its info (later, in the HUD) without selecting it. Holding `select_add` (Shift) adds
## to or removes from the selection. A box projects unit positions to the screen; it doesn't use physics.
## A playtest probe: the selected unit ids, and the events `select`, `box_select`, `inspect`.

signal playtest_event(event: StringName, data: Dictionary)

var _team: int
var _selection: Selection


func setup(team: int, selection: Selection) -> void:
	_team = team
	_selection = selection
	add_to_group(&"playtest_probe")


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


## A click on a unit that can't be selected (an enemy). The HUD will show its info.
func inspect(unit: Unit) -> void:
	playtest_event.emit(&"inspect", {"unit": unit.id, "team": unit.team})


## Own units whose middle projects into `rect` (viewport coordinates).
func _own_units_in(rect: Rect2) -> Array[Unit]:
	var found: Array[Unit] = []
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return found
	for node: Node in get_tree().get_nodes_in_group(StringName("team_%d" % _team)):
		var unit := node as Unit
		if unit == null or camera.is_position_behind(unit.center()):
			continue
		if rect.has_point(camera.unproject_position(unit.center())):
			found.append(unit)
	return found


func _adding() -> bool:
	return Input.is_action_pressed(&"select_add")


func playtest_snapshot() -> Dictionary:
	return {"selected": _selection.ids()}
