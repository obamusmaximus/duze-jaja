class_name PilotWeapon
extends RefCounted
## The weapon of an inhabited unit, fired by hand from the pilot's controls: a beam along where the weapon points (the
## boresight, or for a turret type the pilot's view), bent onto the locked target when that is close enough to it. The
## lock key takes the enemy nearest the pilot's crosshair. Nothing blocks the lock or the beam but ground, buildings and
## (an unlocked beam only) other units; own units stop it unharmed. Uses the unit's `Weapon` for the cooldown. Held by
## `PilotFlight` and run every tick. Simulation.

## The World and Building layers.
const SOLID_MASK: int = (1 << 0) | (1 << 2)
const UNIT_MASK: int = 1 << 1
## A sight line stops this far short of its end, so the ground under a target doesn't hide it, metres.
const SIGHT_SLACK: float = 0.5

## The locked unit's id, or 0.
var locked_id: int = 0

var _unit: Unit
## The lock key as of the last tick: a lock is a press, not the key held.
var _lock_held: bool = false
var _near: Array[Unit] = []


func _init(unit: Unit) -> void:
	_unit = unit


## Whether the unit has a weapon a pilot can fire.
func armed() -> bool:
	return _unit.weapon.has_weapon() and _unit.weapon.stats.pilot_fire


## The locked unit, or null.
func target() -> Unit:
	return _unit.registry.get_unit(locked_id) if locked_id != 0 else null


## Whether the beam would bend onto the locked target if fired now, along the weapon's `axis` from `eye`.
func in_envelope(eye: Vector3, axis: Vector3) -> bool:
	var locked: Unit = target()
	if locked == null:
		return false
	var stats: WeaponStats = _unit.weapon.stats
	var to: Vector3 = locked.center() - eye
	return to.length() <= stats.pilot_range and axis.angle_to(to) <= deg_to_rad(stats.lock_fire_deg)


## Where the weapon points: the boresight, or for a turret the pilot's view.
func axis(input: PilotInput, nose: Vector3) -> Vector3:
	if _unit.stats.pilot_turret and input.view.length_squared() > 0.0001:
		return input.view
	return nose


## The pilot's eyes, which both the crosshair and the beam are sighted from.
func eye(model: PilotModel) -> Vector3:
	return model.position + model.basis * (_unit.stats.cockpit_offset - Vector3.UP * _unit.stats.height * 0.5)


## One tick.
func step(input: PilotInput, model: PilotModel) -> void:
	if not armed():
		return
	var from: Vector3 = eye(model)
	var nose: Vector3 = -model.basis.z
	var locked: Unit = target()
	if locked_id != 0 and (locked == null or from.distance_to(locked.center()) > _unit.weapon.stats.lock_range
			or not _unit.team_knows(locked)):
		locked_id = 0
	if input.lock and not _lock_held:
		var look: Vector3 = input.view if input.view.length_squared() > 0.0001 else nose
		locked_id = _pick(from, look)
	_lock_held = input.lock
	if input.fire and _unit.weapon.is_ready():
		_fire(from, axis(input, nose), model)


## The id of the visible enemy the unit knows of nearest `look` within the pick angle and lock range, or 0 (which unlocks).
func _pick(from: Vector3, look: Vector3) -> int:
	var stats: WeaponStats = _unit.weapon.stats
	_unit.registry.units_near(from, stats.lock_range, _near)
	var best: int = 0
	var best_angle: float = deg_to_rad(stats.lock_pick_deg)
	for other: Unit in _near:
		if not other.alive or not other.is_enemy_of(_unit.team):
			continue
		var to: Vector3 = other.center() - from
		var angle: float = look.angle_to(to)
		if angle > best_angle or to.length() > stats.lock_range or not _unit.knows(other) \
				or not _blocker(from, other.center()).is_empty():
			continue
		best = other.id
		best_angle = angle
	return best


func _fire(from: Vector3, along: Vector3, model: PilotModel) -> void:
	var stats: WeaponStats = _unit.weapon.stats
	_unit.weapon.reload()
	var muzzle: Vector3 = model.position - model.basis.z * _unit.stats.radius
	if in_envelope(from, along):
		var locked: Unit = target()
		var wall: Dictionary = _blocker(from, locked.center())
		var at: Vector3 = locked.center() if wall.is_empty() else wall["position"]
		_unit.registry.shots.fire_beam(_unit, muzzle, at, locked if wall.is_empty() else null, true, stats)
		return
	var to: Vector3 = from + along.normalized() * stats.pilot_range
	# The sea has no collision: the beam ends at its surface.
	var struck_sea: bool = to.y < MapGrid.SEA_LEVEL and from.y > MapGrid.SEA_LEVEL
	if struck_sea:
		to = from.lerp(to, (from.y - MapGrid.SEA_LEVEL) / (from.y - to.y))
	var hit: Dictionary = _ray(from, to, SOLID_MASK | UNIT_MASK)
	if hit.is_empty():
		_unit.registry.shots.fire_beam(_unit, muzzle, to, null, struck_sea, stats)
		return
	var other := hit["collider"] as Unit
	if other != null and (not other.alive or not other.is_enemy_of(_unit.team)):
		other = null
	_unit.registry.shots.fire_beam(_unit, muzzle, hit["position"], other, true, stats)


## What ground or building stands between `from` and `to`; empty if the way is clear.
func _blocker(from: Vector3, to: Vector3) -> Dictionary:
	var length: float = from.distance_to(to)
	if length <= SIGHT_SLACK:
		return {}
	return _ray(from, from.lerp(to, 1.0 - SIGHT_SLACK / length), SOLID_MASK)


func _ray(from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask, [_unit.get_rid()])
	return _unit.get_world_3d().direct_space_state.intersect_ray(query)
