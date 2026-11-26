class_name CommandIssuer
extends Node
## The only way into the game: players' views, the AI and (later) the network send `Order`s to `issue()`. It refuses
## units that aren't the issuing team's, spreads group moves into a loose block (Formation), and gives each unit its
## own order (replacing its queue, or appended when queued). A player also takes over a unit here (`inhabit`, `leave`,
## held in `seats`) and streams its controls to `pilot()`; an inhabited unit takes no other orders.
## Simulation side. A playtest probe (event `order`).

signal playtest_event(event: StringName, data: Dictionary)
## An order was accepted and handed to its units.
signal issued(order: Order)

@export var stats: OrderStats

## Set by a level that has an economy; produce and cancel orders are refused without it.
var production: Production
## Set by a level with map markers; marker orders are refused without it.
var markers: MapMarkers
## Who inhabits which unit; made in `setup`. Views read it and follow its signals.
var seats: PilotSeats

var _registry: UnitRegistry


func setup(registry: UnitRegistry) -> void:
	_registry = registry
	seats = PilotSeats.new(registry)
	add_to_group(&"playtest_probe")
	add_to_group(&"command_issuer")


## Carries out `order`. False if it was refused (no units of the issuing team, or no valid target).
func issue(order: Order) -> bool:
	if order.kind == Order.Kind.PRODUCE or order.kind == Order.Kind.CANCEL:
		return _issue_production(order)
	if order.kind == Order.Kind.MARKER or order.kind == Order.Kind.CLEAR_MARKER:
		return _issue_marker(order)
	if order.kind == Order.Kind.INHABIT or order.kind == Order.Kind.LEAVE:
		return _issue_seat(order)
	var units: Array[Unit] = _own_units(order)
	if units.is_empty():
		return false
	match order.kind:
		Order.Kind.ABILITY:
			units = _use_abilities(units, order)
			if units.is_empty():
				return false # None of them has an ability ready.
		Order.Kind.STOP:
			for unit: Unit in units:
				unit.orders.clear()
		Order.Kind.ATTACK:
			var target: Unit = _registry.get_unit(order.target_unit_id)
			if target == null or not target.is_enemy_of(order.team):
				return false
			var able: int = 0
			for unit: Unit in units:
				if not unit.can_attack(target):
					continue # Ground units can't attack a flyer; the rest of the selection still goes.
				_give(unit, order.for_unit(unit.id, target.global_position))
				able += 1
			if able == 0:
				return false
		Order.Kind.DELIVER:
			units = _loaded_carryalls(units)
			if units.is_empty() or not _lands_on_land(order.target_position):
				return false
			var slots: PackedVector3Array = Formation.slots(_positions(units), order.target_position, _spacing(units))
			for i: int in units.size():
				_give(units[i], order.for_unit(units[i].id, slots[i]))
		Order.Kind.MOVE, Order.Kind.ATTACK_MOVE:
			units = _reachable(units, order.target_position)
			if units.is_empty():
				return false # Every unit is on another land mass: no search would find a way across the sea.
			# Flyers and ground units form up apart: each layer spaces itself by its own sizes.
			_move_group(units.filter(func(unit: Unit) -> bool: return not unit.is_flying()), order)
			_move_group(units.filter(func(unit: Unit) -> bool: return unit.is_flying()), order)
	playtest_event.emit(&"order", {
		"kind": order.kind_name(), "target": order.target_position, "target_unit": order.target_unit_id,
		"units": units.size(), "queued": order.queued,
	})
	issued.emit(order)
	return true


## The control channel: this tick's controls for the unit the input's team inhabits. False (and nothing changes) for
## any other unit.
func pilot(input: PilotInput) -> bool:
	return seats.steer(input)


## Taking over a unit, or leaving it.
func _issue_seat(order: Order) -> bool:
	var unit_id: int = 0
	var done: bool = false
	if order.kind == Order.Kind.LEAVE:
		unit_id = seats.unit_id_of(order.team)
		done = seats.leave(order.team)
	elif order.unit_ids.size() == 1:
		unit_id = order.unit_ids[0]
		done = seats.enter(order.team, _registry.get_unit(unit_id))
	if done:
		playtest_event.emit(&"order", {"kind": order.kind_name(), "unit": unit_id})
		issued.emit(order)
	return done


## A block of destinations round the order's point, one per unit. A flyer's is kept far enough inside the map.
func _move_group(units: Array[Unit], order: Order) -> void:
	if units.is_empty():
		return
	var slots: PackedVector3Array = Formation.slots(_positions(units), order.target_position, _spacing(units))
	for i: int in units.size():
		var point: Vector3 = slots[i]
		var autopilot: FlightAutopilot = units[i].movement.autopilot
		if autopilot != null:
			point = _registry.map.air.clamp_point(point, autopilot.edge_margin())
		_give(units[i], order.for_unit(units[i].id, point))


## Squad production: no units involved. The team's own bank pays, the team's own lines build.
func _issue_production(order: Order) -> bool:
	if production == null:
		return false
	var done: bool
	if order.kind == Order.Kind.PRODUCE:
		done = production.queue(order.team, order.squad_spec, order.line) != 0
	else:
		done = production.cancel(order.team, order.ticket)
	if done:
		issued.emit(order)
	return done


## Map markers: data on the team's board, no units involved.
func _issue_marker(order: Order) -> bool:
	if markers == null:
		return false
	var done: bool = true
	if order.kind == Order.Kind.MARKER:
		done = markers.place(order.team, order.marker_kind, order.target_position) != 0
	else:
		done = markers.remove(order.team, order.marker_id)
	if done:
		playtest_event.emit(&"order", {"kind": order.kind_name(), "target": order.target_position, "marker": order.marker_kind})
		issued.emit(order)
	return done


func _own_units(order: Order) -> Array[Unit]:
	var units: Array[Unit] = []
	for id: int in order.unit_ids:
		var unit: Unit = _registry.get_unit(id)
		if unit and unit.team == order.team and not seats.is_inhabited(unit):
			units.append(unit)
	return units


## The units that can walk to `target`: those of its land region, flyers, amphibious units and any unit not on mapped
## ground. Nothing is filtered where the grid is not built or the target is off the land.
func _reachable(units: Array[Unit], target: Vector3) -> Array[Unit]:
	var grid := get_tree().get_first_node_in_group(&"map_grid") as MapGrid
	if grid == null or not grid.is_built():
		return units
	var want: int = grid.region_at_point(target, 24)
	if want == 0:
		return units
	var able: Array[Unit] = []
	for unit: Unit in units:
		var has: int = 0 if unit.is_flying() or unit.stats.amphibious else grid.region_at_point(unit.global_position)
		if has == 0 or has == want:
			able.append(unit)
	return able


## The units among `units` whose ability was ready and is now used.
func _use_abilities(units: Array[Unit], order: Order) -> Array[Unit]:
	var out: Array[Unit] = []
	for unit: Unit in units:
		if unit.ability != null and unit.ability.use(order.target_position, order.target_unit_id):
			out.append(unit)
	return out


## The carryalls among `units` that have something aboard to deliver.
func _loaded_carryalls(units: Array[Unit]) -> Array[Unit]:
	var out: Array[Unit] = []
	for unit: Unit in units:
		if unit.carryall != null and not unit.cargo.entries.is_empty():
			out.append(unit)
	return out


## Whether a carryall can set down at `point`: walkable ground of some land mass is near it (any point if the map
## isn't built).
func _lands_on_land(point: Vector3) -> bool:
	var grid := get_tree().get_first_node_in_group(&"map_grid") as MapGrid
	return grid == null or not grid.is_built() or grid.region_at_point(point, 24) != 0


func _give(unit: Unit, order: Order) -> void:
	if order.queued:
		unit.orders.append(order)
	else:
		unit.orders.replace(order)


func _positions(units: Array[Unit]) -> PackedVector3Array:
	var points := PackedVector3Array()
	for unit: Unit in units:
		points.append(unit.global_position)
	return points


func _spacing(units: Array[Unit]) -> float:
	var radius: float = 0.0
	for unit: Unit in units:
		radius = maxf(radius, unit.stats.radius)
	return radius * 2.0 * stats.formation_spacing
