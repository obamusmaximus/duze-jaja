class_name UnitNavigator
extends Node
## Gets the unit to a point: asks the PathService for a path, follows its waypoints, and decides arrival.
## - Arrival: within the reach of the goal; or, near the goal, touching an already-arrived unit that stands between
##   it and the goal (so a group settles instead of jostling for one spot); or the path's end when the goal is cut off.
## - Stuck: no progress toward the next waypoint for `stuck_seconds` re-paths, at most MAX_STUCK_REPATHS times, then
##   gives up and counts as arrived (no endless re-path loops).
## - Map changes: re-paths when a change touches the rest of its path, or when the map opened up and it is on a
##   detour that may now be shorter.
## Simulation.

const MAX_STUCK_REPATHS: int = 2
## Progress smaller than this (metres) doesn't count.
const PROGRESS_EPSILON: float = 0.15
## A path this much longer than the straight line is a detour worth re-checking when the map opens up.
const DETOUR_RATIO: float = 1.3
## Chasing: re-path at most this often (seconds), and only when the target moved this far (metres) from the goal.
const FOLLOW_REPATH_SECONDS: float = 0.5
const FOLLOW_MOVE_DISTANCE: float = 2.0
## Seconds over which the unit brakes into its final point.
const BRAKE_SECONDS: float = 0.25
## Hover flyers plan their braking with this share of their acceleration, and creep no slower than this (m/s).
const BRAKE_MARGIN: float = 0.7
const MIN_APPROACH_SPEED: float = 0.5

## Where it is heading.
var goal: Vector3
## Moving (or waiting for a path) toward `goal`.
var active: bool = false
## Reached `goal` (or settled as near as it could). Cleared by the next `go_to`.
var arrived: bool = false

var _unit: Unit
var _stats: UnitStats
var _registry: UnitRegistry
var _path := PackedVector3Array()
var _next: int = 0
var _request: PathService.Request
var _reach: float = 0.0
var _best: float = INF
var _stuck: float = 0.0
var _repaths: int = 0
var _since_repath: float = 0.0
var _neighbours: Array[Unit] = []


func setup(unit: Unit, stats: UnitStats, registry: UnitRegistry) -> void:
	_unit = unit
	_stats = stats
	_registry = registry
	if registry.map:
		registry.map.cells_changed.connect(_on_cells_changed)


## Heads for `point`; arrives within `reach` metres of it.
func go_to(point: Vector3, reach: float) -> void:
	if active and point.distance_squared_to(goal) < 0.0001 and is_equal_approx(reach, _reach):
		return
	goal = point
	_reach = reach
	active = true
	arrived = false
	_repaths = 0
	_repath(&"")


## Chases a moving point: keeps the path while the point stays near the goal, re-paths at most every
## FOLLOW_REPATH_SECONDS.
func follow(point: Vector3, reach: float) -> void:
	_reach = reach
	if active and point.distance_to(goal) < FOLLOW_MOVE_DISTANCE:
		return
	if (active or arrived) and _since_repath < FOLLOW_REPATH_SECONDS:
		return
	goal = point
	active = true
	arrived = false
	_repath(&"")


func stop() -> void:
	active = false
	arrived = false
	_cancel()
	_path.clear()


## The velocity toward the goal this tick (flat, metres per second). Advances waypoints and decides arrival.
func wanted_velocity(delta: float) -> Vector3:
	_since_repath += delta
	if not active:
		return Vector3.ZERO
	var position: Vector3 = _unit.global_position
	var to_goal: Vector3 = _flat(goal - position)
	var distance: float = to_goal.length()
	var wing: FlightAutopilot = _unit.movement.autopilot
	if wing != null and wing.is_fixed_wing():
		return _fly_over(wing, distance)
	if distance <= _reach:
		_arrive()
		return Vector3.ZERO
	if _request != null:
		return Vector3.ZERO # Waiting a tick or two for the path.
	if _path.is_empty():
		_arrive() # No way there at all.
		return Vector3.ZERO
	var last: int = _path.size() - 1
	while _next < last and _flat(_path[_next] - position).length() < _waypoint_reach():
		_next += 1
		_best = INF
	var to_waypoint: Vector3 = _flat(_path[_next] - position)
	var waypoint_distance: float = to_waypoint.length()
	if _next == last and waypoint_distance <= maxf(_reach, _stats.arrive_distance):
		_arrive() # The end of a path that stops short of a cut-off goal.
		return Vector3.ZERO
	if distance <= _reach + _stats.crowd_arrive_distance and _blocked_by_arrived(to_goal):
		_arrive()
		return Vector3.ZERO
	if not _progressing(waypoint_distance, distance, delta):
		return Vector3.ZERO
	var speed: float = _stats.speed
	if _next == last:
		if _stats.flying: # Brake early enough for the autopilot's acceleration.
			var braking: float = sqrt(2.0 * _stats.flight_acceleration * BRAKE_MARGIN * maxf(distance - _reach, 0.0))
			speed = minf(speed, maxf(braking, MIN_APPROACH_SPEED))
		else:
			speed = minf(speed, maxf((distance - _reach) / BRAKE_SECONDS, _stats.speed * 0.2))
	return to_waypoint / maxf(waypoint_distance, 0.0001) * speed


## Fixed wings can't stop or be stuck: they arrive by passing within `flight_arrive_radius`, then orbit the goal.
func _fly_over(wing: FlightAutopilot, distance: float) -> Vector3:
	if distance <= maxf(_reach, _stats.flight_arrive_radius):
		wing.orbit(goal)
		_arrive()
		return Vector3.ZERO
	return wing.approach(goal)


## Remaining path points, for debug views.
func remaining_path() -> PackedVector3Array:
	return _path.slice(_next)


func _arrive() -> void:
	active = false
	arrived = true
	_cancel()
	_path.clear()


## Tracks progress toward the current waypoint; re-paths or gives up when stuck. False when it stopped moving.
func _progressing(waypoint_distance: float, goal_distance: float, delta: float) -> bool:
	if waypoint_distance < _best - PROGRESS_EPSILON:
		_best = waypoint_distance
		_stuck = 0.0
		return true
	_stuck += delta
	if _stuck < _stats.stuck_seconds:
		return true
	if _repaths >= MAX_STUCK_REPATHS or goal_distance <= _reach + _stats.crowd_arrive_distance:
		_arrive()
		return false
	_repaths += 1
	_repath(&"stuck")
	return false


## Touching a unit that has stopped (arrived or idle) and stands roughly between this unit and the goal.
func _blocked_by_arrived(to_goal: Vector3) -> bool:
	_registry.units_near(_unit.global_position, _stats.radius * 2.0 + 1.5, _neighbours)
	for other: Unit in _neighbours:
		if other == _unit or other.team != _unit.team or other.navigator.active or other.is_flying() != _unit.is_flying():
			continue
		var wing: FlightAutopilot = other.movement.autopilot
		if wing != null and (wing.is_fixed_wing() or absf(other.global_position.y - _unit.global_position.y) > _stats.flight_separation_height):
			continue # A circling plane hasn't stopped, and a flyer well above or below isn't in the way.
		var between: Vector3 = _flat(other.global_position - _unit.global_position)
		var touch: float = _stats.radius + other.stats.radius + _stats.separation_padding + 0.25
		if between.length() <= touch and between.dot(to_goal) > 0.0:
			return true
	return false


func _repath(reason: StringName) -> void:
	_cancel()
	_path.clear()
	_next = 0
	_best = INF
	_stuck = 0.0
	_since_repath = 0.0
	if _stats.flying or _registry.paths == null: # Flyers fly straight: the ground grid doesn't apply to them.
		_path = PackedVector3Array([goal])
		return
	if reason != &"":
		_registry.paths.note_repath(_unit.id, reason)
	_request = _registry.paths.request(_unit.global_position, goal, _on_path)


func _on_path(path: PackedVector3Array) -> void:
	_request = null
	_path = path
	_next = 0
	_best = INF
	_stuck = 0.0


func _cancel() -> void:
	if _request:
		_request.cancelled = true
		_request = null


func _on_cells_changed(area: Rect2, opened: bool) -> void:
	if not active or _request != null or _path.is_empty() or _stats.flying:
		return
	var margin: float = _stats.radius + _registry.map.cell_size
	if _path_touches(area.grow(margin)):
		_repath(&"map_change")
	elif opened and _path_length() > DETOUR_RATIO * _flat(goal - _unit.global_position).length() + 1.0:
		_repath(&"map_opened")


func _path_touches(area: Rect2) -> bool:
	var from := Vector2(_unit.global_position.x, _unit.global_position.z)
	for i: int in range(_next, _path.size()):
		var to := Vector2(_path[i].x, _path[i].z)
		if MapGrid.segment_hits_rect(from, to, area):
			return true
		from = to
	return false


func _path_length() -> float:
	var length: float = 0.0
	var from: Vector3 = _unit.global_position
	for i: int in range(_next, _path.size()):
		length += _flat(_path[i] - from).length()
		from = _path[i]
	return length


func _waypoint_reach() -> float:
	return maxf(_stats.radius, 0.5)


func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
