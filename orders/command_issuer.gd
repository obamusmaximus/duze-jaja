class_name CommandIssuer
extends Node
## The only way into the game: players' views, the AI and (later) the network send `Order`s to `issue()`. It refuses
## units that aren't the issuing team's, spreads group moves into a loose block (Formation), and gives each unit its
## own order (replacing its queue, or appended when queued). Simulation side. A playtest probe (event `order`).

signal playtest_event(event: StringName, data: Dictionary)
## An order was accepted and handed to its units.
signal issued(order: Order)

@export var stats: OrderStats

var _registry: UnitRegistry


func setup(registry: UnitRegistry) -> void:
	_registry = registry
	add_to_group(&"playtest_probe")


## Carries out `order`. False if it was refused (no units of the issuing team, or no valid target).
func issue(order: Order) -> bool:
	var units: Array[Unit] = _own_units(order)
	if units.is_empty():
		return false
	match order.kind:
		Order.Kind.STOP:
			for unit: Unit in units:
				unit.orders.clear()
		Order.Kind.ATTACK:
			var target: Unit = _registry.get_unit(order.target_unit_id)
			if target == null or not target.is_enemy_of(order.team):
				return false
			for unit: Unit in units:
				_give(unit, order.for_unit(unit.id, target.global_position))
		Order.Kind.MOVE, Order.Kind.ATTACK_MOVE:
			var slots: PackedVector3Array = Formation.slots(_positions(units), order.target_position, _spacing(units))
			for i: int in units.size():
				_give(units[i], order.for_unit(units[i].id, slots[i]))
	playtest_event.emit(&"order", {
		"kind": order.kind_name(), "target": order.target_position, "target_unit": order.target_unit_id,
		"units": units.size(), "queued": order.queued,
	})
	issued.emit(order)
	return true


func _own_units(order: Order) -> Array[Unit]:
	var units: Array[Unit] = []
	for id: int in order.unit_ids:
		var unit: Unit = _registry.get_unit(id)
		if unit and unit.team == order.team:
			units.append(unit)
	return units


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
