class_name UnitMovement
extends Node
## Moves the unit. Two halves, both driven by the UnitRegistry (units have no `_physics_process`, `docs/performance.md`):
## - `decide(delta)` runs at the unit's own rate (half the physics rate, so `delta` is two ticks): asks the brain for
##   a velocity and facing, adds separation from nearby units (soft collision: units push apart instead of blocking
##   each other, so crowds never lock up) and works out the wanted turn and flat velocity.
## - `integrate(delta)` runs every physics tick (so physics interpolation shows smooth motion): turns at `turn_rate`
##   and moves the body.
## Ground units move kinematically: height from the map model (`MapGrid.surface_height`), walls and buildings from its
## cells (a blocked cell stops a move, which then slides along it); the physics engine solves nothing. Flyers are
## flown by their `autopilot` (`FlightAutopilot`). `physical` brings back `move_and_slide` (gravity, collision) for direct control.

## Neighbours are searched within the unit's radius plus this (metres): covers other units up to about this radius.
const NEIGHBOUR_MARGIN: float = 1.5
## A standing unit re-checks its ground this often (decisions).
const REST_CHECK_TICKS: int = 15

## Where the wanted velocity comes from. Swappable (order brain now, direct control later).
var brain: UnitBrain
## Moves with `move_and_slide` instead of kinematically (direct control; the unit then runs every tick).
var physical: bool = false
## Flyers: a height above sea level to hold instead of the usual altitude over the ground (a carryall on its pad or
## landed); NAN for none.
var altitude_override: float = NAN
## Flies a flyer (null on a ground unit, and before the unit joins a match with a map).
var autopilot: FlightAutopilot

var _body: Unit
var _stats: UnitStats
var _registry: UnitRegistry
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
var _neighbours: Array[Unit] = []
## Decisions spent standing still.
var _rest_ticks: int = 0
## The flat velocity decided last (metres per second), and the yaw the unit wants to turn to (NAN: none).
var _flat := Vector3.ZERO
var _target_yaw: float = NAN


func setup(body: Unit, stats: UnitStats, start_brain: UnitBrain, registry: UnitRegistry) -> void:
	_body = body
	_stats = stats
	brain = start_brain
	_registry = registry
	if stats.flying and registry.map:
		autopilot = FlightAutopilot.new(body, stats, registry.map.air)
		autopilot.snap_to_altitude(altitude_override)
	if not stats.flying and registry.map and registry.map.is_built():
		_body.global_position.y = registry.map.surface_height(_body.global_position)


## One decision (the unit's own tick; `delta` is the time since its last one).
func decide(delta: float) -> void:
	var wanted := Vector3.ZERO
	var facing := Vector3.ZERO
	if brain:
		wanted = brain.wanted_velocity(delta)
		facing = brain.wanted_facing()
	wanted.y = 0.0
	facing.y = 0.0
	if autopilot:
		autopilot.command(wanted, facing, _separation() * _stats.speed)
		return
	if wanted.length_squared() > 0.0001:
		facing = wanted
	_target_yaw = atan2(-facing.x, -facing.z) if facing.length_squared() > 0.0001 else NAN
	var flat := Vector3.ZERO
	if wanted.length_squared() > 0.0001:
		var forward: Vector3 = -_body.global_basis.z
		flat = wanted.limit_length(_stats.speed) * clampf(forward.dot(wanted.normalized()), 0.0, 1.0)
	_flat = (flat + _separation() * _stats.speed).limit_length(_stats.speed)
	if _flat.length_squared() < 0.0001:
		_rest_ticks += 1
		if _rest_ticks % REST_CHECK_TICKS == 0:
			_settle()
	else:
		_rest_ticks = 0


## Every physics tick: turn and move by what was decided.
func integrate(delta: float) -> void:
	if autopilot:
		autopilot.step(delta, altitude_override)
		return
	if not is_nan(_target_yaw):
		_body.rotation.y = rotate_toward(_body.rotation.y, _target_yaw, deg_to_rad(_stats.turn_rate) * delta)
	if physical:
		_move_physical(delta)
	elif _flat.length_squared() > 0.0001:
		_walk(delta)


## The usual height above sea level over ground at `ground` (`FlightAutopilot.altitude_for`). Flyers only.
func altitude_for(ground: float) -> float:
	return autopilot.altitude_for(ground)


## Kinematic walk: slide along blocked cells, follow the ground height.
func _walk(delta: float) -> void:
	var map: MapGrid = _registry.map
	var position: Vector3 = _body.global_position
	if map == null or not map.is_built():
		return
	var step := Vector3(_flat.x, 0.0, _flat.z) * delta
	var inside_wall: bool = map.is_blocked(map.cell_of(position))
	var moved: Vector3 = position + step
	if not inside_wall and map.is_blocked(map.cell_of(moved)):
		var along_x := Vector3(position.x + step.x, position.y, position.z)
		var along_z := Vector3(position.x, position.y, position.z + step.z)
		if not map.is_blocked(map.cell_of(along_x)):
			moved = along_x
		elif not map.is_blocked(map.cell_of(along_z)):
			moved = along_z
		else:
			return
	moved.y = map.surface_height(moved)
	_body.global_position = moved


## Standing: take the ground's height again, and step out of a cell that became blocked under the unit.
func _settle() -> void:
	var map: MapGrid = _registry.map
	if _stats.flying or map == null or not map.is_built():
		return
	var position: Vector3 = _body.global_position
	var cell: Vector2i = map.cell_of(position)
	if map.is_blocked(cell):
		var out: Vector2i = map.nearest_walkable(cell)
		position = map.cell_center(out)
	position.y = map.surface_height(position)
	_body.global_position = position


## Direct control: the physics body moves and falls (`_flat` is the wanted velocity).
func _move_physical(delta: float) -> void:
	var velocity: Vector3 = _body.velocity
	velocity.x = _flat.x
	velocity.z = _flat.z
	velocity.y = 0.0 if _body.is_on_floor() else velocity.y - _gravity * delta
	_body.velocity = velocity
	_body.move_and_slide()


## Push away from overlapping units, stronger the deeper the overlap. Flyers only push other flyers, and ground units
## only the ground ones: the air and the ground don't block each other. Flyers more than `flight_separation_height`
## apart in height pass over each other.
func _separation() -> Vector3:
	if _registry == null or _stats.separation_strength <= 0.0:
		return Vector3.ZERO
	var position: Vector3 = _body.global_position
	_registry.units_near(position, _stats.radius + NEIGHBOUR_MARGIN, _neighbours)
	var push := Vector3.ZERO
	for other: Unit in _neighbours:
		if other == _body or other.is_flying() != _body.is_flying():
			continue
		if _stats.flying and absf(position.y - other.global_position.y) > _stats.flight_separation_height:
			continue
		var away := Vector3(position.x - other.global_position.x, 0.0, position.z - other.global_position.z)
		var distance: float = away.length()
		var keep: float = _stats.radius + other.stats.radius + _stats.separation_padding
		if distance >= keep:
			continue
		if distance < 0.001: # Exactly stacked: split them apart by id, the same way every time.
			var angle: float = float(_body.id) * 2.399963
			away = Vector3(cos(angle), 0.0, sin(angle))
			distance = 0.001
		push += away / distance * (1.0 - distance / keep)
	return push * _stats.separation_strength
