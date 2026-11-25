class_name Carryall
extends RefCounted
## What makes a flying unit with a hold a carryall (`docs/mechanics/carryall.md`): it sits on a mothership pad while its
## squad is built into the hold, leaves the pad sideways at deck level and then drops to cruise height, delivers by
## landing and unloading round itself, then hovers back beside its mothership (never onto a pad). Its side gunners
## (infantry aboard) shoot ground enemies. Simulation: the `Unit` steps it from `think`, and the `OrderBrain` asks it
## for the velocity of a delivery. In the air a carryall only moves in x and z at its cruise height (`UnitMovement`
## altitude); flying it freely in 3D comes with first-person piloting, as a brain swap.

## The carryall left its pad (the production line it was loading from stops, `Production`).
signal took_off

## What the strategy view and the commander read: where a carryall stands in its work.
enum State { IDLE, LOADING, DELIVERING, RETURNING, FOLLOWING }
enum Phase { FLY, DESCEND, UNLOAD, LIFT }

var unit: Unit
var stats: CarryallStats
## The mothership it belongs to and returns to; set by the `CarryallFleet`.
var mothership: Mothership
var squads: SquadRegistry
## The pad it sits on, -1 in the air.
var pad: int = -1
## A production line is still adding units to its hold.
var building: bool = false
## The current delivery is done (the brain finishes the order).
var delivery_finished: bool = false

var _exiting: bool = false
var _exit_point: Vector3 = Vector3.ZERO
var _phase: Phase = Phase.FLY
var _land_point: Vector3 = Vector3.ZERO
var _timer: float = 0.0
var _unloaded: int = 0
var _unload_total: int = 0
var _deployed_squads: Dictionary = {}
## Gunner entry to seconds until it fires again.
var _cooldowns: Dictionary = {}
var _near: Array[Unit] = []


func _init(body: Unit, carryall_stats: CarryallStats) -> void:
	unit = body
	stats = carryall_stats


## Sits the carryall on pad `index` of `ship` (the fleet calls this right after spawning it).
func dock(ship: Mothership, index: int) -> void:
	mothership = ship
	pad = index
	var at: Vector3 = ship.pad_position(index)
	unit.global_position = at + Vector3.UP * stats.deck_clearance
	unit.movement.altitude_override = at.y + stats.deck_clearance


func state() -> State:
	if building:
		return State.LOADING
	var order: Order = unit.orders.current()
	if order == null:
		return State.IDLE
	if order.kind == Order.Kind.DELIVER:
		return State.DELIVERING
	return State.RETURNING if order.returning else State.FOLLOWING


## The carryall's own tick, before its movement decision: leaves the pad when it is given an order, and fires the guns.
func step(delta: float) -> void:
	if pad >= 0 and not _exiting and not unit.orders.is_idle():
		_take_off()
	_fire_gunners(delta)


## True while the carryall flies level off its pad; the brain then asks `leave_velocity` instead of following orders.
func leaving() -> bool:
	return _exiting


## Heads for the point beyond the hull's side at deck level; at it the carryall is free to drop to cruise height.
func leave_velocity() -> Vector3:
	var to: Vector3 = _exit_point - unit.global_position
	to.y = 0.0
	if to.length() <= stats.land_arrive_radius:
		_exiting = false
		unit.movement.altitude_override = NAN
		return Vector3.ZERO
	return to.normalized() * unit.stats.speed


## The brain started `order` (null: it went idle): a flight height held for landing is let go.
func order_started(order: Order) -> void:
	if not _exiting and pad < 0:
		unit.movement.altitude_override = NAN
	delivery_finished = false
	_phase = Phase.FLY
	if order != null and order.kind == Order.Kind.DELIVER:
		_land_point = _landing_point(order.target_position)


## Where a delivery to `order` sets down: its target, moved onto walkable ground.
func landing_point() -> Vector3:
	return _land_point


## One decision of a delivery: fly to the landing point, descend, unload one unit at a time, lift off. Returns the
## flat velocity wanted; `delivery_finished` says when the order is done, and the way home is queued by then.
func deliver(nav: UnitNavigator, delta: float) -> Vector3:
	match _phase:
		Phase.FLY:
			if nav.arrived:
				_phase = Phase.DESCEND
				unit.movement.altitude_override = _ground_at(_land_point) + stats.landed_clearance
				return Vector3.ZERO
			return nav.wanted_velocity(delta)
		Phase.DESCEND:
			if absf(unit.global_position.y - unit.movement.altitude_override) < 0.5:
				_phase = Phase.UNLOAD
				_timer = 0.0
				_unloaded = 0
				_unload_total = unit.cargo.entries.size()
		Phase.UNLOAD:
			_timer -= delta
			if _timer <= 0.0:
				if unit.cargo.entries.is_empty():
					_phase = Phase.LIFT
					_timer = stats.liftoff_delay
					_deploy_squads()
				else:
					_unload_one()
					_timer = stats.unload_interval
		Phase.LIFT:
			if not is_nan(unit.movement.altitude_override):
				_timer -= delta
				if _timer <= 0.0:
					unit.movement.altitude_override = NAN
			elif unit.global_position.y >= unit.movement.altitude_for(_ground_at(unit.global_position)) - 1.0:
				_go_home()
				delivery_finished = true
	return Vector3.ZERO


func _take_off() -> void:
	var from: Vector3 = unit.global_position
	_exit_point = mothership.side_point(from.z, stats.exit_margin, from.y)
	_exiting = true
	pad = -1
	building = false
	took_off.emit()


## The way back: a hover point beside the mothership at cruise height, flagged so the state reads `RETURNING`.
func _go_home() -> void:
	if mothership == null:
		return
	var order: Order = Order.move(unit.team, PackedInt32Array([unit.id]),
		mothership.side_point(mothership.global_position.z, stats.home_margin, 0.0))
	order.returning = true
	unit.orders.append(order)


func _unload_one() -> void:
	var entry: CargoEntry = unit.cargo.take_first()
	var map: MapGrid = unit.registry.map
	var angle: float = unit.global_rotation.y + TAU * (float(_unloaded) + 0.5) / float(maxi(_unload_total, 1))
	_unloaded += 1
	var reach: float = unit.stats.radius + entry.unit_type.radius + stats.unload_gap
	var at: Vector3 = unit.global_position + Vector3(sin(angle), 0.0, cos(angle)) * reach
	if map != null and map.is_built():
		var cell: Vector2i = map.nearest_walkable(map.cell_of(at))
		if cell.x >= 0:
			at = map.cell_center(cell)
		at.y = map.surface_height(at)
	var landed: Unit = unit.registry.spawn(entry.unit_type, unit.team, at, entry.unit_id)
	landed.health.current = entry.health
	if squads != null and entry.squad_id != 0:
		squads.attach(entry.squad_id, landed)
		_deployed_squads[entry.squad_id] = true


func _deploy_squads() -> void:
	if squads != null:
		for squad_id: int in _deployed_squads:
			squads.mark_deployed(squad_id)
	_deployed_squads.clear()


func _landing_point(point: Vector3) -> Vector3:
	var map: MapGrid = unit.registry.map
	if map == null or not map.is_built():
		return point
	var cell: Vector2i = map.nearest_walkable(map.cell_of(point), 48)
	return map.cell_center(cell) if cell.x >= 0 else point


func _ground_at(point: Vector3) -> float:
	var map: MapGrid = unit.registry.map
	return map.ground_height(point) if map != null else 0.0


## Side gunners: the first `side_gunners` infantry aboard with a weapon each shoot the nearest ground enemy in range.
## A hold without them (an empty carryall) has no guns. Nothing fires on the pad.
func _fire_gunners(delta: float) -> void:
	if pad >= 0 or stats.side_gunners <= 0 or unit.registry == null or unit.registry.shots == null:
		return
	var manned: int = 0
	for entry: CargoEntry in unit.cargo.entries:
		var weapon: WeaponStats = entry.unit_type.weapon
		if entry.unit_type.cargo_class != UnitStats.CargoClass.INFANTRY or weapon == null:
			continue
		manned += 1
		if manned > stats.side_gunners:
			break
		var wait: float = maxf(float(_cooldowns.get(entry, 0.0)) - delta, 0.0)
		if wait <= 0.0:
			var target: Unit = _ground_enemy_within(weapon.max_range)
			if target != null:
				unit.registry.shots.fire(unit, target, weapon)
				wait = weapon.cooldown
		_cooldowns[entry] = wait
	if manned == 0:
		_cooldowns.clear()


## The nearest living enemy on the ground within `reach` (flat, edge to edge), or null. Flyers are never chosen.
func _ground_enemy_within(reach: float) -> Unit:
	unit.registry.units_near(unit.global_position, reach + 8.0, _near)
	var best: Unit = null
	var best_distance: float = INF
	for other: Unit in _near:
		if not other.alive or other.team == unit.team or other.is_flying():
			continue
		var distance: float = Vector2(other.global_position.x - unit.global_position.x,
			other.global_position.z - unit.global_position.z).length()
		if distance <= reach + other.stats.radius and distance < best_distance:
			best = other
			best_distance = distance
	return best
