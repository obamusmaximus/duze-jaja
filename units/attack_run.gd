class_name AttackRun
extends RefCounted
## A fixed wing's attack passes on one target (it can't stand and fire). It runs in toward the target, the weapon
## firing whenever the target is in range and arc; close in, or once past, it breaks off, flies straight out to
## `flight_pass_distance`, then comes round for the next run. Held by the unit's OrderBrain. Simulation.

## How many turn radii of room it keeps ahead while flying out.
const EDGE_ROOM: float = 1.5

## Whether it is flying out after a pass (otherwise running in).
var extending: bool = false

var _target_id: int = 0
## The flat direction held while flying out.
var _out := Vector3.ZERO


## The velocity `wing` (flying `unit`) wants this decision to attack `target`.
func velocity(wing: FlightAutopilot, unit: Unit, target: Unit) -> Vector3:
	var to := Vector3(target.global_position.x - unit.global_position.x, 0.0,
			target.global_position.z - unit.global_position.z)
	var forward: Vector3 = -unit.global_basis.z
	if target.id != _target_id:
		_target_id = target.id
		extending = false
	var distance: float = to.length()
	if extending:
		if distance >= unit.stats.flight_pass_distance:
			extending = false
	# Broken off close in, or right past it. A target merely behind and far off is not a pass: it just turns back.
	elif distance <= unit.stats.flight_pass_break_distance \
			or (distance <= unit.weapon.reach_to(target) and forward.dot(to) < 0.0):
		extending = true
		_out = Vector3(forward.x, 0.0, forward.z).normalized()
	if not extending:
		return wing.approach(target.global_position)
	_turn_from_edge(wing, unit)
	return _out * unit.stats.speed


## Flying out toward the map edge with no room left to turn: swing the way out back into the map.
func _turn_from_edge(wing: FlightAutopilot, unit: Unit) -> void:
	var ahead: Vector3 = unit.global_position + _out * wing.turn_radius(unit.stats.speed) * EDGE_ROOM
	var inside: Vector3 = unit.registry.map.air.clamp_point(ahead)
	if not is_equal_approx(inside.x, ahead.x):
		_out.x = absf(_out.x) * signf(inside.x - ahead.x)
	if not is_equal_approx(inside.z, ahead.z):
		_out.z = absf(_out.z) * signf(inside.z - ahead.z)
