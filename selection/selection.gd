class_name Selection
extends Node
## The local player's selection: a list of their own units. Owned by the level. Shows and hides the units' rings as
## they come and go, and drops units that leave the match. View state: the simulation never reads it.

signal changed

var units: Array[Unit] = []
## Units whose leaving the match is already watched.
var _watched: Dictionary = {}


func set_units(new_units: Array[Unit]) -> void:
	for unit: Unit in units:
		if not new_units.has(unit):
			_drop(unit)
	var kept: Array[Unit] = []
	for unit: Unit in new_units:
		if is_instance_valid(unit) and not kept.has(unit):
			kept.append(unit)
			_take(unit)
	units = kept
	changed.emit()


func add(more: Array[Unit]) -> void:
	var all: Array[Unit] = units.duplicate()
	all.append_array(more)
	set_units(all)


func remove(unit: Unit) -> void:
	var rest: Array[Unit] = units.duplicate()
	rest.erase(unit)
	set_units(rest)


func toggle(unit: Unit) -> void:
	if units.has(unit):
		remove(unit)
	else:
		var one: Array[Unit] = [unit]
		add(one)


func clear() -> void:
	var none: Array[Unit] = []
	set_units(none)


func has(unit: Unit) -> bool:
	return units.has(unit)


func is_empty() -> bool:
	return units.is_empty()


func ids() -> PackedInt32Array:
	var result := PackedInt32Array()
	for unit: Unit in units:
		result.append(unit.id)
	return result


## The middle of the selected units on the ground.
func center() -> Vector3:
	var sum := Vector3.ZERO
	for unit: Unit in units:
		sum += unit.global_position
	return sum / maxf(units.size(), 1)


func _take(unit: Unit) -> void:
	unit.set_selected(true)
	if not _watched.has(unit):
		_watched[unit] = true
		unit.tree_exiting.connect(_on_unit_leaving.bind(unit), CONNECT_ONE_SHOT)


func _drop(unit: Unit) -> void:
	if is_instance_valid(unit):
		unit.set_selected(false)


func _on_unit_leaving(unit: Unit) -> void:
	_watched.erase(unit)
	if units.has(unit):
		remove(unit)
