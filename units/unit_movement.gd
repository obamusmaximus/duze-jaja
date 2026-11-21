class_name UnitMovement
extends Node
## Moves the unit on the fixed tick: turns toward the velocity its brain wants (or the facing it wants while
## standing) at `turn_rate`, moves faster the more it already faces that way (turning on the spot first), adds
## separation from nearby units (soft collision: units push apart instead of blocking each other, so crowds never
## lock up), and falls under gravity. Walls and buildings block it hard (move_and_slide).

## Neighbours are searched within the unit's radius plus this (metres): covers other units up to about this radius.
const NEIGHBOUR_MARGIN: float = 1.5

## Where the wanted velocity comes from. Swappable (order brain now, direct control later).
var brain: UnitBrain

var _body: Unit
var _stats: UnitStats
var _registry: UnitRegistry
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
var _neighbours: Array[Unit] = []
## Ticks spent standing still; physics runs only every REST_CHECK_TICKS of them (to notice ground going away).
var _rest_ticks: int = 0

## A standing unit re-checks its ground this often (ticks).
const REST_CHECK_TICKS: int = 30


func setup(body: Unit, stats: UnitStats, start_brain: UnitBrain, registry: UnitRegistry) -> void:
	_body = body
	_stats = stats
	brain = start_brain
	_registry = registry


## One physics tick.
func step(delta: float) -> void:
	var wanted := Vector3.ZERO
	var facing := Vector3.ZERO
	if brain:
		wanted = brain.wanted_velocity(delta)
		facing = brain.wanted_facing()
	wanted.y = 0.0
	facing.y = 0.0
	if wanted.length_squared() > 0.0001:
		facing = wanted
	var flat := Vector3.ZERO
	if facing.length_squared() > 0.0001:
		var target_yaw: float = atan2(-facing.x, -facing.z)
		_body.rotation.y = rotate_toward(_body.rotation.y, target_yaw, deg_to_rad(_stats.turn_rate) * delta)
	if wanted.length_squared() > 0.0001:
		var forward: Vector3 = -_body.global_basis.z
		flat = wanted.limit_length(_stats.speed) * clampf(forward.dot(wanted.normalized()), 0.0, 1.0)
	flat = (flat + _separation() * _stats.speed).limit_length(_stats.speed)
	var on_floor: bool = _body.is_on_floor()
	if on_floor and flat.length_squared() < 0.0001:
		_body.velocity = Vector3.ZERO
		_rest_ticks += 1
		if _rest_ticks % REST_CHECK_TICKS != 0:
			return # Standing still on the ground: nothing for physics to do (most of an army, most of the time).
	else:
		_rest_ticks = 0
	var velocity: Vector3 = _body.velocity
	velocity.x = flat.x
	velocity.z = flat.z
	velocity.y = 0.0 if on_floor else velocity.y - _gravity * delta
	_body.velocity = velocity
	_body.move_and_slide()


## Push away from overlapping units, stronger the deeper the overlap.
func _separation() -> Vector3:
	if _registry == null or _stats.separation_strength <= 0.0:
		return Vector3.ZERO
	var position: Vector3 = _body.global_position
	_registry.units_near(position, _stats.radius + NEIGHBOUR_MARGIN, _neighbours)
	var push := Vector3.ZERO
	for other: Unit in _neighbours:
		if other == _body:
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
