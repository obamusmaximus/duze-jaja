class_name OrderBrain
extends UnitBrain
## Drives the unit by its orders (OrderQueue), using its navigator, targeting and weapon. Behaviour by order:
## - Move: goes there; fires at enemies in range that happen to be ahead (in the fire arc), never turns or stops for
##   them.
## - Attack: chases its target until in range, faces it and fires; done when the target is gone.
## - Attack-move: goes there, but fights anything it meets on the way (enemies within `sight_range`), chasing at most
##   `leash_distance` from where it met them, so it can't be kited away; then carries on.
## - Idle (no orders): holds its ground, faces and fires at enemies in range, the one that hit it last first.
## Stop clears the queue, which makes the unit idle. Simulation.

var _unit: Unit
var _queue: OrderQueue
var _nav: UnitNavigator
var _targeting: UnitTargeting
var _weapon: Weapon
var _registry: UnitRegistry
var _active: Order
var _facing := Vector3.ZERO
## Attack-move: the enemy being fought, where the fight began, and an enemy given up on (leash).
var _engaged: Unit
var _engaged_from := Vector3.ZERO
var _given_up_id: int = 0


func setup(unit: Unit, queue: OrderQueue, navigator: UnitNavigator, targeting: UnitTargeting, weapon: Weapon,
		registry: UnitRegistry) -> void:
	_unit = unit
	_queue = queue
	_nav = navigator
	_targeting = targeting
	_weapon = weapon
	_registry = registry


func wanted_facing() -> Vector3:
	return _facing


func wanted_velocity(delta: float) -> Vector3:
	_facing = Vector3.ZERO
	var order: Order = _queue.current()
	while order and order.kind == Order.Kind.STOP:
		_queue.finish()
		order = _queue.current()
	if order != _active:
		_start(order)
	if order == null:
		return _hold_ground()
	match order.kind:
		Order.Kind.MOVE:
			return _move(delta)
		Order.Kind.ATTACK:
			var target: Unit = _registry.get_unit(order.target_unit_id)
			if target == null:
				return _finish()
			return _fight(target, delta)
		Order.Kind.ATTACK_MOVE:
			return _attack_move(order, delta)
	return _finish()


func _start(order: Order) -> void:
	_active = order
	_engaged = null
	_given_up_id = 0
	_weapon.target = null
	if order == null:
		_nav.stop()
	elif order.kind == Order.Kind.MOVE or order.kind == Order.Kind.ATTACK_MOVE:
		_nav.go_to(order.target_position, _unit.stats.arrive_distance)
	else:
		_nav.stop()


func _move(delta: float) -> Vector3:
	_weapon.target = _targeting.in_range # Fires only if it happens to be ahead.
	var velocity: Vector3 = _nav.wanted_velocity(delta)
	if _nav.arrived:
		return _finish()
	return velocity


func _attack_move(order: Order, delta: float) -> Vector3:
	if _engaged and (not _engaged.alive or _engaged_from.distance_to(_unit.global_position) > _unit.stats.leash_distance):
		if _engaged.alive and not _weapon.in_range(_engaged):
			_given_up_id = _engaged.id # Leash: don't chase this one again unless it comes into range.
		_engaged = null
		_nav.go_to(order.target_position, _unit.stats.arrive_distance)
	if _engaged == null:
		var found: Unit = _targeting.in_range
		if found == null and _targeting.in_sight and _targeting.in_sight.id != _given_up_id:
			found = _targeting.in_sight
		if found and _weapon.has_weapon():
			_engaged = found
			_engaged_from = _unit.global_position
	if _engaged:
		return _fight(_engaged, delta)
	return _move(delta)


## Chase `target` into range, then stand, face it and let the weapon fire.
func _fight(target: Unit, delta: float) -> Vector3:
	_weapon.target = target
	var to_target: Vector3 = target.global_position - _unit.global_position
	if not _weapon.has_weapon():
		_nav.follow(target.global_position, _unit.stats.radius + target.stats.radius + 1.0)
		return _nav.wanted_velocity(delta)
	if _weapon.in_range(target):
		_nav.stop()
		_facing = to_target
		return Vector3.ZERO
	_nav.follow(target.global_position, _weapon.reach_to(target) * 0.9)
	return _nav.wanted_velocity(delta)


func _hold_ground() -> Vector3:
	var target: Unit = _targeting.in_range
	_weapon.target = target
	if target:
		_facing = target.global_position - _unit.global_position
	return Vector3.ZERO


func _finish() -> Vector3:
	_queue.finish()
	return Vector3.ZERO
