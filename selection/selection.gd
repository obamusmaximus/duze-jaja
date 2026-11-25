class_name Selection
extends Node
## The local player's selection: a list of their own units, held as unit ids (an id survives a unit leaving the world,
## `docs/performance.md`). `units` resolves them through the registry. Shows and hides the units' rings as they come
## and go, and drops units that leave the match. View state: the simulation never reads it.
## With several types selected, one is the **main type** (RA3 style): the HUD shows it, and type abilities (F) will
## apply to its units only. It stays while it is in the selection, otherwise it becomes the most numerous type.

signal changed
## The main type changed without the selection changing.
signal main_changed

## The selected type the HUD features and type abilities apply to; null with nothing selected.
var main_type: UnitStats

var _ids := PackedInt32Array()
## An enemy unit being inspected (shown in the HUD, never selected: orders ignore it); 0 for none. Any change of the
## own selection ends the inspection.
var _inspected_id: int = 0
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
	_replace(new_units, 0)


## Shows `unit` (an enemy) in the HUD in place of the selection, which it empties.
func inspect(unit: Unit) -> void:
	var none: Array[Unit] = []
	_replace(none, unit.id)


## The unit being inspected, or null.
func inspected() -> Unit:
	var registry: UnitRegistry = _find_registry()
	return registry.get_unit(_inspected_id) if registry != null and _inspected_id != 0 else null


func _replace(new_units: Array[Unit], inspected_id: int) -> void:
	_inspected_id = inspected_id
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
	_pick_main()
	changed.emit()


## Makes `type` the main type, if any selected unit is of it.
func set_main_type(type: UnitStats) -> void:
	if type == main_type or not types().has(type):
		return
	main_type = type
	main_changed.emit()


## The selected unit types, most numerous first (ties keep selection order), with their units.
func types() -> Dictionary:
	var by_type: Dictionary = {}
	for unit: Unit in units:
		if not by_type.has(unit.stats):
			by_type[unit.stats] = []
		(by_type[unit.stats] as Array).append(unit)
	var order: Array = by_type.keys()
	var first_seen: Array = order.duplicate()
	order.sort_custom(func(a: UnitStats, b: UnitStats) -> bool:
		var count_a: int = (by_type[a] as Array).size()
		var count_b: int = (by_type[b] as Array).size()
		return count_a > count_b or (count_a == count_b and first_seen.find(a) < first_seen.find(b)))
	var sorted: Dictionary = {}
	for type: UnitStats in order:
		sorted[type] = by_type[type]
	return sorted


## The selected units of the main type.
func main_units() -> Array[Unit]:
	var found: Array[Unit] = []
	for unit: Unit in units:
		if unit.stats == main_type:
			found.append(unit)
	return found


func _pick_main() -> void:
	var by_type: Dictionary = types()
	if not by_type.has(main_type):
		main_type = by_type.keys()[0] if not by_type.is_empty() else null


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
	if unit.id == _inspected_id:
		_inspected_id = 0
		changed.emit()
	var at: int = _ids.find(unit.id)
	if at >= 0:
		_ids.remove_at(at)
		_pick_main()
		changed.emit()
