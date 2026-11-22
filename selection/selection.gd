class_name Selection
extends Node
## The local player's selection: a list of their own units, held as unit ids (an id survives a unit leaving the world,
## `docs/performance.md`). `units` resolves them through the registry. Shows and hides the units' rings as they come
## and go, and drops units that leave the match. View state: the simulation never reads it.

signal changed

var _ids := PackedInt32Array()
var _registry: UnitRegistry

## The selected units that are alive (resolved from the ids on each read).
var units: Array[Unit]:
	get:
		var found: Array[Unit] = []
		var registry: UnitRegistry = _find_registry()
		if registry == null:
			return found
		for id: int in _ids:
			var unit: Unit = registry.get_unit(id)
			if unit:
				found.append(unit)
		return found


func set_units(new_units: Array[Unit]) -> void:
	var registry: UnitRegistry = _find_registry()
	var new_ids := PackedInt32Array()
	for unit: Unit in new_units:
		if is_instance_valid(unit) and unit.id != 0 and not new_ids.has(unit.id):
			new_ids.append(unit.id)
	if registry:
		for id: int in _ids:
			if not new_ids.has(id):
				var old: Unit = registry.get_unit(id)
				if old:
					old.set_selected(false)
		for id: int in new_ids:
			var unit: Unit = registry.get_unit(id)
			if unit:
				unit.set_selected(true)
	_ids = new_ids
	changed.emit()


func add(more: Array[Unit]) -> void:
	var all: Array[Unit] = units
	all.append_array(more)
	set_units(all)


func remove(unit: Unit) -> void:
	var rest: Array[Unit] = units
	rest.erase(unit)
	set_units(rest)


func toggle(unit: Unit) -> void:
	if has(unit):
		remove(unit)
	else:
		var one: Array[Unit] = [unit]
		add(one)


func clear() -> void:
	var none: Array[Unit] = []
	set_units(none)


func has(unit: Unit) -> bool:
	return _ids.has(unit.id)


func is_empty() -> bool:
	return _ids.is_empty()


func ids() -> PackedInt32Array:
	return _ids.duplicate()


## The middle of the selected units on the ground.
func center() -> Vector3:
	var sum := Vector3.ZERO
	var all: Array[Unit] = units
	for unit: Unit in all:
		sum += unit.global_position
	return sum / maxf(all.size(), 1)


func _find_registry() -> UnitRegistry:
	if _registry == null:
		_registry = get_tree().get_first_node_in_group(&"unit_registry") as UnitRegistry
		if _registry:
			_registry.unit_removed.connect(_on_unit_removed)
	return _registry


func _on_unit_removed(unit: Unit) -> void:
	var at: int = _ids.find(unit.id)
	if at >= 0:
		_ids.remove_at(at)
		changed.emit()
