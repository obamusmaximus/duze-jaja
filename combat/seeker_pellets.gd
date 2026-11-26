class_name SeekerPellets
extends RefCounted
## The seeker shotgun's pellets in flight, as plain data (`docs/mechanics/commando.md`). Each flies straight for
## `homing_delay`, then turns toward its enemy at up to `turn_rate`. Once its enemy is inside its turning circle (out
## of reach) it gives up and flies straight on; with `brake_into_turns` it slows into the turn instead, then speeds
## back up. One whose enemy is gone flies straight on too. A pellet stops on the ground, the sea, a building or a unit;
## an enemy it touches takes the weapon's damage (`Shots.strike`); `lifetime` ends it. Stepped by `SeekerShotgun`.
## Simulation; `PelletTracers` draws them.

## The World, Unit and Building layers.
const HIT_MASK: int = (1 << 0) | (1 << 1) | (1 << 2)


class Pellet:
	var position: Vector3
	var velocity: Vector3
	## The unit it homes on (an id), or 0.
	var target_id: int = 0
	var age: float = 0.0


var stats: SeekerShotgunStats
## Pellets in flight.
var flying: Array[Pellet] = []

var _unit: Unit
var _shape := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()


func _init(unit: Unit, shotgun_stats: SeekerShotgunStats) -> void:
	_unit = unit
	stats = shotgun_stats
	_query.shape = _shape
	_query.collision_mask = HIT_MASK
	_query.exclude = [unit.get_rid()]


func spawn(from: Vector3, velocity: Vector3, target_id: int) -> void:
	var pellet := Pellet.new()
	pellet.position = from
	pellet.velocity = velocity
	pellet.target_id = target_id
	flying.append(pellet)


func clear() -> void:
	flying.clear()


func step(delta: float) -> void:
	if flying.is_empty():
		return
	_shape.radius = stats.pellet_radius
	var space: PhysicsDirectSpaceState3D = _unit.get_world_3d().direct_space_state
	var kept: Array[Pellet] = []
	for pellet: Pellet in flying:
		if _fly(pellet, delta, space):
			kept.append(pellet)
	flying = kept


## Moves one pellet; false once it stopped.
func _fly(pellet: Pellet, delta: float, space: PhysicsDirectSpaceState3D) -> bool:
	pellet.age += delta
	var speed: float = minf(pellet.velocity.length() + stats.speed_recovery * delta, stats.speed)
	var direction: Vector3 = pellet.velocity.normalized()
	var target: Unit = _unit.registry.get_unit(pellet.target_id) if pellet.target_id != 0 else null
	if pellet.age >= stats.homing_delay and target != null:
		var to_target: Vector3 = target.center() - pellet.position
		direction = _steer(pellet, direction, to_target, speed, delta)
		if stats.brake_into_turns:
			speed = clampf(minf(speed, _arc_speed(direction, to_target)), stats.speed * stats.min_speed_share,
				stats.speed)
	pellet.velocity = direction * speed
	var motion: Vector3 = pellet.velocity * delta
	_query.transform = Transform3D(Basis.IDENTITY, pellet.position)
	_query.motion = motion
	var fractions: PackedFloat32Array = space.cast_motion(_query)
	if fractions[1] < 1.0:
		pellet.position += motion * fractions[1]
		_hit(pellet, space)
		return false
	pellet.position += motion
	# The sea has no collision.
	if pellet.position.y <= MapGrid.SEA_LEVEL:
		_unit.registry.shots.shot_hit.emit(pellet.position, stats.weapon, _unit, null)
		return false
	return pellet.age < stats.lifetime


## Turns `direction` toward the enemy at up to `turn_rate`. Without `brake_into_turns`, a pellet that can no longer
## reach its enemy at its speed (`_arc_speed`) gives up: it drops the enemy and flies straight on.
func _steer(pellet: Pellet, direction: Vector3, to_target: Vector3, speed: float, delta: float) -> Vector3:
	if not stats.brake_into_turns and _arc_speed(direction, to_target) < speed:
		pellet.target_id = 0
		return direction
	var angle: float = direction.angle_to(to_target)
	var axis: Vector3 = direction.cross(to_target)
	if angle < 0.0001 or axis.is_zero_approx():
		return direction
	return direction.rotated(axis.normalized(), minf(angle, deg_to_rad(stats.turn_rate) * delta))


## The fastest a pellet heading along `direction` can fly and still turn onto a point `to_target` away. The arc that
## reaches a point `d` away and `angle` off the nose has radius d / (2 sin angle), flown at `turn_rate`. Past 90
## degrees the point needs the tightest turn, so it counts as 90. Faster than this, it would circle the point.
func _arc_speed(direction: Vector3, to_target: Vector3) -> float:
	var distance: float = to_target.length()
	var angle: float = direction.angle_to(to_target)
	if distance < 0.0001 or angle < 0.0001:
		return INF
	var bend: float = sin(angle) if angle < PI * 0.5 else 1.0
	return deg_to_rad(stats.turn_rate) * distance / (2.0 * bend)


func _hit(pellet: Pellet, space: PhysicsDirectSpaceState3D) -> void:
	_query.transform = Transform3D(Basis.IDENTITY, pellet.position)
	_query.motion = Vector3.ZERO
	var info: Dictionary = space.get_rest_info(_query)
	var other: Unit = instance_from_id(info["collider_id"]) as Unit if not info.is_empty() else null
	var shots: Shots = _unit.registry.shots
	if other != null and other.alive and other.is_enemy_of(_unit.team):
		shots.strike(_unit, other, pellet.position, stats.weapon)
	else:
		shots.shot_hit.emit(pellet.position, stats.weapon, _unit, null)
