class_name Carryall
extends RefCounted
## What makes a flying unit with a hold a carryall (`docs/mechanics/carryall.md`): it sits on a mothership pad while its
## squad is built into the hold, delivers by landing and unloading round itself (a delivery order, or its deploy
## ability where it is), then flies back to land on a mothership pad (`Landing`, as any flyer does). Its side gunners
## (infantry aboard) shoot ground enemies. Simulation: the `Unit` steps it from `think`, and the `OrderBrain` asks it
## for the velocity of a delivery. On the autopilot a carryall only moves in x and z at its cruise height
## (`UnitMovement` altitude); a player flies it freely with the hover controls (`HoverModel`).

## The carryall left a pad (a production line loading it stops, `Production`).
signal took_off

## What the strategy view and the commander read: where a carryall stands in its work.
enum State { IDLE, LOADING, DELIVERING, RETURNING, FOLLOWING }
enum Phase { FLY, DESCEND, UNLOAD, LIFT }

var unit: Unit
var stats: CarryallStats
var squads: SquadRegistry
## It sat on a pad at its last tick.
var docked: bool = false
## A production line is still adding units to its hold.
var building: bool = false
## The current delivery is done (the brain finishes the order).
var delivery_finished: bool = false

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


## Sits the carryall on a free pad of `field` (the fleet calls this right after spawning it). False if none is free.
func dock(field: Airfield) -> bool:
	var pad: Pad = field.request_pad(unit.id)
	if pad == null:
		field.release(unit.id)
		return false
	unit.landing.dock(field, pad)
	docked = true
	return true


## On a pad, empty, with nothing to do: a production line may build a new squad into it.
func ready_to_load() -> bool:
	return not building and unit.landing.is_down() and unit.orders.is_idle() and unit.cargo.entries.is_empty()


func state() -> State:
	if building:
		return State.LOADING
	var order: Order = unit.orders.current()
	if order == null:
		return State.IDLE
	if order.kind == Order.Kind.DELIVER:
		return State.DELIVERING
	return State.RETURNING if order.returning else State.FOLLOWING


## The carryall's own tick, before its movement decision: notes leaving a pad, and fires the guns.
func step(delta: float) -> void:
	if unit.landing.is_down():
		docked = true
	elif docked:
		docked = false
		building = false
		took_off.emit()
	_fire_gunners(delta)


## A player has the controls: any delivery is dropped.
func take_controls() -> void:
	delivery_finished = false
	_phase = Phase.FLY
	unit.movement.altitude_override = NAN
	_deploy_squads()


## Whether the deploy ability does anything now: something aboard, in the air, not delivering already, and ground it
## can set down on under it.
func can_deploy() -> bool:
	if building or unit.cargo.entries.is_empty() or unit.landing.holds_craft():
		return false
	var order: Order = unit.orders.current()
	if order != null and order.kind == Order.Kind.DELIVER:
		return false
	var map: MapGrid = unit.registry.map
	if map == null or not map.is_built():
		return true
	var rings: int = ceili(stats.deploy_reach / map.stats.cell_size)
	return map.nearest_walkable(map.cell_of(unit.global_position), rings).x >= 0


## The deploy ability: lands here, unloads and returns to a mothership pad, dropping its other orders.
func deploy() -> void:
	unit.orders.replace(Order.deliver(unit.team, PackedInt32Array([unit.id]), unit.global_position))


## The brain started `order` (null: it went idle): a flight height held for landing is let go.
func order_started(order: Order) -> void:
	if not unit.landing.holds_craft():
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


## The way back: a land order for the nearest mothership pad with room, flagged so the state reads `RETURNING`. Queued
## waypoints are flown first.
func _go_home() -> void:
	var field: Airfield = Airfield.nearest_for(unit)
	if field == null:
		return
	var order: Order = Order.land(unit.team, PackedInt32Array([unit.id]), field.airfield_id)
	order.target_position = field.global_position
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
	var landed: Unit = entry.land(unit.registry, unit.team, at)
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
	if unit.landing.holds_craft() or stats.side_gunners <= 0 or unit.registry == null or unit.registry.shots == null:
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


## The nearest living enemy on the ground within `reach` (flat, edge to edge) that the carryall knows of, or null.
## Flyers are never chosen.
func _ground_enemy_within(reach: float) -> Unit:
	unit.registry.units_near(unit.global_position, reach + 8.0, _near)
	var best: Unit = null
	var best_distance: float = INF
	for other: Unit in _near:
		if not other.alive or other.team == unit.team or other.is_flying():
			continue
		var distance: float = Vector2(other.global_position.x - unit.global_position.x,
			other.global_position.z - unit.global_position.z).length()
		if distance <= reach + other.stats.radius and distance < best_distance and unit.knows(other):
			best = other
			best_distance = distance
	return best
