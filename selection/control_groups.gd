class_name ControlGroups
extends Node
## Control groups: `control_group_set` (Ctrl or Cmd) with a number stores the selection under it; the number
## selects the group; the same number twice within `group_double_tap_seconds` also centres the camera on it.
## A playtest probe (events `group_set`, `group_recall`).

signal playtest_event(event: StringName, data: Dictionary)

const GROUP_COUNT: int = 10

var _stats: PlayerControlStats
var _selection: Selection
var _camera_rig: CameraRig
## Group number to its unit ids; ids of units that left the match are dropped when the group is used.
var _groups: Array[PackedInt32Array] = []
var _registry: UnitRegistry
var _last_group: int = -1
var _last_press_time: float = -INF


func setup(stats: PlayerControlStats, selection: Selection, camera_rig: CameraRig) -> void:
	_stats = stats
	_selection = selection
	_camera_rig = camera_rig
	add_to_group(&"playtest_probe")
	for i: int in GROUP_COUNT:
		_groups.append(PackedInt32Array())


func _unhandled_input(event: InputEvent) -> void:
	for number: int in GROUP_COUNT:
		if event.is_action_pressed(StringName("control_group_%d" % number)):
			get_viewport().set_input_as_handled()
			if Input.is_action_pressed(&"control_group_set"):
				store(number)
			else:
				recall(number)
			return


func store(number: int) -> void:
	_groups[number] = _selection.ids()
	playtest_event.emit(&"group_set", {"group": number, "ids": _selection.ids()})


func recall(number: int) -> void:
	if _registry == null:
		_registry = get_tree().get_first_node_in_group(&"unit_registry") as UnitRegistry
	var alive: Array[Unit] = []
	var kept := PackedInt32Array()
	for id: int in _groups[number]:
		var unit: Unit = _registry.get_unit(id) if _registry else null
		if unit:
			alive.append(unit)
			kept.append(id)
	_groups[number] = kept
	if alive.is_empty():
		return
	var now: float = Time.get_ticks_msec() / 1000.0 # Real time: unaffected by slow time.
	var jump: bool = number == _last_group and now - _last_press_time <= _stats.group_double_tap_seconds
	_last_group = number
	_last_press_time = now
	_selection.set_units(alive)
	if jump:
		_camera_rig.focus_on(_selection.center())
	playtest_event.emit(&"group_recall", {"group": number, "ids": _selection.ids(), "jump": jump})
