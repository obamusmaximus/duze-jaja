class_name PathService
extends Node
## Finds paths on the MapGrid. Requests are answered on later physics ticks, as many per tick as fit in
## `path_budget_ms`, so an order to 100 units spreads over a few ticks instead of stalling one. A path is the grid's
## jump-point A* path smoothed by dropping every corner a straight line can skip, ending at the asked-for point, or at
## the nearest reachable one when that point is blocked or cut off. Requests that start and end near a recent path's
## ends (`path_share_size`) reuse its middle, so a group order mostly costs one search; map changes clear the
## shared paths. Simulation. A playtest probe (event `repath`).

signal playtest_event(event: StringName, data: Dictionary)


## One waiting path request. Cancel it to drop the answer (the unit asked again or stopped).
class Request:
	extends RefCounted
	var from: Vector3
	var to: Vector3
	var callback: Callable
	var cancelled: bool = false


## Shared paths kept at most; the oldest half goes when full.
const MAX_SHARED: int = 256

@export var stats: MapStats

var searches: int = 0
var shared_hits: int = 0

var _map: MapGrid
var _queue: Array[Request] = []
var _head: int = 0
## Vector4i(start area, goal area) to the smoothed path found between them (end point included).
var _shared: Dictionary = {}


func setup(map: MapGrid) -> void:
	_map = map
	process_physics_priority = -50 # Before the units, so answers are used the same tick.
	add_to_group(&"playtest_probe")
	map.cells_changed.connect(func(_area: Rect2, _opened: bool) -> void: _shared.clear())


## Asks for a path; `callback` gets a PackedVector3Array (empty when there is no way at all).
func request(from: Vector3, to: Vector3, callback: Callable) -> Request:
	var entry := Request.new()
	entry.from = from
	entry.to = to
	entry.callback = callback
	_queue.append(entry)
	return entry


func pending() -> int:
	return _queue.size() - _head


## Logs why a unit asked again (map change, stuck); the first request for an order isn't logged.
func note_repath(unit_id: int, reason: StringName) -> void:
	playtest_event.emit(&"repath", {"unit": unit_id, "reason": reason})


func _physics_process(_delta: float) -> void:
	if _head >= _queue.size():
		return
	var start: int = Time.get_ticks_usec()
	var budget: float = stats.path_budget_ms * 1000.0
	while _head < _queue.size():
		var next: Request = _queue[_head]
		_head += 1
		if not next.cancelled:
			next.callback.call(find_path(next.from, next.to))
		if Time.get_ticks_usec() - start >= budget:
			break
	if _head >= _queue.size():
		_queue.clear()
		_head = 0


## The path from `from` to `to`, at once (requests use this).
func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if _map == null or not _map.is_built():
		return PackedVector3Array([to])
	var start: Vector2i = _map.nearest_walkable(_map.cell_of(from))
	var goal_cell: Vector2i = _map.cell_of(to)
	var goal: Vector2i = _map.nearest_walkable(goal_cell)
	if start.x < 0 or goal.x < 0:
		return PackedVector3Array()
	var end_point: Vector3 = to if goal == goal_cell else _map.cell_center(goal)
	if start == goal or _map.line_walkable(from, end_point):
		return PackedVector3Array([end_point])
	var key: Vector4i = _share_key(from, end_point)
	var reused: PackedVector3Array = _reuse(key, from, end_point)
	if not reused.is_empty():
		shared_hits += 1
		return reused
	searches += 1
	var cells: Array[Vector2i] = _map.astar.get_id_path(start, goal, true)
	if cells.is_empty():
		return PackedVector3Array()
	if cells[-1] != goal:
		end_point = _map.cell_center(cells[-1]) # Cut off: go as near as the map allows.
	var corners := PackedVector3Array()
	for i: int in range(1, cells.size() - 1): # Only where the path turns.
		if (cells[i] - cells[i - 1]).sign() != (cells[i + 1] - cells[i]).sign():
			corners.append(_map.cell_center(cells[i]))
	corners.append(end_point)
	var path: PackedVector3Array = _smooth(from, corners)
	if stats.path_share_size > 0.0:
		if _shared.size() >= MAX_SHARED:
			_shared.clear()
		_shared[key] = path
	return path


## A recent path between the same areas, with this request's own ends, if the ends connect straight.
func _reuse(key: Vector4i, from: Vector3, end_point: Vector3) -> PackedVector3Array:
	if stats.path_share_size <= 0.0 or not _shared.has(key):
		return PackedVector3Array()
	var shared: PackedVector3Array = _shared[key]
	if shared.size() < 2:
		return PackedVector3Array()
	var middle: PackedVector3Array = shared.slice(0, shared.size() - 1)
	if not _map.line_walkable(from, middle[0]) or not _map.line_walkable(middle[-1], end_point):
		return PackedVector3Array()
	middle.append(end_point)
	return _smooth(from, middle)


func _share_key(from: Vector3, to: Vector3) -> Vector4i:
	var area: float = maxf(stats.path_share_size, 0.01)
	return Vector4i(floori(from.x / area), floori(from.z / area), floori(to.x / area), floori(to.z / area))


## Drops every corner a straight line from the last kept point can skip.
func _smooth(from: Vector3, corners: PackedVector3Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	var anchor: Vector3 = from
	var i: int = 0
	while i < corners.size():
		var reach: int = i
		while reach + 1 < corners.size() and _map.line_walkable(anchor, corners[reach + 1]):
			reach += 1
		result.append(corners[reach])
		anchor = corners[reach]
		i = reach + 1
	return result
