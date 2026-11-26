class_name OrderBrain
extends UnitBrain
## Drives the unit by its orders (OrderQueue), using its navigator, targeting and weapon. Behaviour by order:
## - Move: goes there; fires at enemies in range that happen to be ahead (in the fire arc), never turns or stops for
##   them.
## - Attack: chases its target until in range, faces it and fires; done when the target is gone or its team loses it.
## - Attack-move: goes there, but fights anything it meets on the way (enemies within `sight_range`), chasing at most
##   `leash_distance` from where it met them, so it can't be kited away; then carries on.
## - An Explorer that is deploying, deployed or packing up holds still (`Explorer`).
## - Land (fighters, VTOLs, carryalls): flies to a pad and lands to repair (`Landing`); done once repaired. A craft on
##   a pad stays there, orders or none, until another order, which waits for it to take off.
## - Deliver (carryalls): the carryall flies, lands, unloads and lifts off (`Carryall.deliver`).
## - Fixed wings can't stand: whenever one of the above has it fight, it makes attack passes (`AttackRun`).
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
var _engaged_id: int = 0
var _engaged: Unit:
	get:
		return _registry.get_unit(_engaged_id) if _engaged_id != 0 else null
	set(value):
		_engaged_id = value.id if value else 0
var _engaged_from := Vector3.ZERO
var _given_up_id: int = 0
## A fixed wing's passes over what it fights.
var _attack_run := AttackRun.new()


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
	if _unit.explorer != null and _unit.explorer.anchored():
		_nav.stop()
		_active = null # Orders given meanwhile start afresh once it flies again.
		return Vector3.ZERO # Deploying, deployed or packing up: it holds still (an order packs it up first).
	var order: Order = _queue.current()
	while order and order.kind == Order.Kind.STOP:
		_queue.finish()
		order = _queue.current()
	var landing: Landing = _unit.landing
	if landing != null and landing.must_leave(order):
		_weapon.target = null
		_nav.stop()
		_active = null # The order starts afresh once it is off the pad.
		return Vector3.ZERO
	if order != _active:
		_start(order)
	if order == null:
		if landing != null and landing.is_down():
			_weapon.target = null
			_facing = landing.pad_facing()
			return Vector3.ZERO
		return _hold_ground()
	match order.kind:
		Order.Kind.MOVE:
			return _move(delta)
		Order.Kind.ATTACK:
			var target: Unit = _registry.get_unit(order.target_unit_id)
			if target == null or not _unit.can_attack(target) or not _unit.team_knows(target):
				return _finish() # Gone, or the team lost it: the commander's order ends with the contact.
			return _fight(target, delta)
		Order.Kind.ATTACK_MOVE:
			return _attack_move(order, delta)
		Order.Kind.LAND:
			return _land(delta)
		Order.Kind.DELIVER:
			var carryall: Carryall = _unit.carryall
			if carryall == null:
				return _finish()
			var velocity: Vector3 = carryall.deliver(_nav, delta)
			return _finish() if carryall.delivery_finished else velocity
	return _finish()


func _start(order: Order) -> void:
	_active = order
	_engaged = null
	_given_up_id = 0
	_weapon.target = null
	if _unit.carryall != null:
		_unit.carryall.order_started(order)
	if order == null:
		_nav.stop()
	elif order.kind == Order.Kind.DELIVER:
		_nav.go_to(_unit.carryall.landing_point(), _unit.carryall.stats.land_arrive_radius)
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


## Heading for a pad it fires at what happens to be ahead, as on a move; over the pad it doesn't fire.
func _land(delta: float) -> Vector3:
	var landing: Landing = _unit.landing
	if landing == null:
		return _finish()
	var velocity: Vector3 = landing.fly(_active, _nav, delta)
	if landing.finished:
		return _finish()
	_weapon.target = _targeting.in_range if landing.is_flying_in() else null
	_facing = landing.pad_facing()
	return velocity


func _attack_move(order: Order, delta: float) -> Vector3:
	var engaged: Unit = _engaged
	if _engaged_id != 0 and (engaged == null or _leashed(engaged) or not _unit.team_knows(engaged)):
		if engaged and not _weapon.in_range(engaged):
			_given_up_id = _engaged_id # Leash: don't chase this one again unless it comes into range.
		_engaged_id = 0
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


## Whether the fight has gone too far from where it began. A fixed wing's passes swing wide, so for it the enemy's
## distance counts, not its own.
func _leashed(engaged: Unit) -> bool:
	var wing: FlightAutopilot = _unit.movement.autopilot
	var at: Vector3 = engaged.global_position if wing != null and wing.is_fixed_wing() else _unit.global_position
	var from_start := Vector2(at.x - _engaged_from.x, at.z - _engaged_from.z)
	return from_start.length() > _unit.stats.leash_distance


## Chase `target` into range, then stand, face it and let the weapon fire.
func _fight(target: Unit, delta: float) -> Vector3:
	_weapon.target = target
	var to_target: Vector3 = target.global_position - _unit.global_position
	if not _weapon.has_weapon():
		_nav.follow(target.global_position, _unit.stats.radius + target.stats.radius + 1.0)
		return _nav.wanted_velocity(delta)
	var wing: FlightAutopilot = _unit.movement.autopilot
	if wing != null and wing.is_fixed_wing():
		_nav.stop() # It can't stand and fire: it makes attack passes.
		return _attack_run.velocity(wing, _unit, target)
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
