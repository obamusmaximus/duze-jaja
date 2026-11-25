class_name Cargo
extends RefCounted
## A carrier's hold, as data (`docs/mechanics/cargo.md`): what it can take and which units are aboard. Carried units
## are `CargoEntry` records, not nodes. Simulation only: views read it and listen to `changed`.

signal changed

var stats: CargoStats
## The units aboard, in the order they were loaded.
var entries: Array[CargoEntry] = []


func _init(hold: CargoStats) -> void:
	stats = hold


## Slots of its class that `unit_type` takes, 0 if it can't be carried.
static func slots_of(unit_type: UnitStats) -> int:
	return unit_type.cargo_slots if unit_type.cargo_class != UnitStats.CargoClass.NONE else 0


func capacity(cargo_class: UnitStats.CargoClass) -> int:
	return stats.capacity(cargo_class)


func used(cargo_class: UnitStats.CargoClass) -> int:
	var total: int = 0
	for entry: CargoEntry in entries:
		if entry.unit_type.cargo_class == cargo_class:
			total += slots_of(entry.unit_type)
	return total


func free_slots(cargo_class: UnitStats.CargoClass) -> int:
	return capacity(cargo_class) - used(cargo_class)


## Whether `unit_type` fits in the slots left.
func can_load(unit_type: UnitStats) -> bool:
	var slots: int = slots_of(unit_type)
	return slots > 0 and slots <= free_slots(unit_type.cargo_class)


## Stores `entry` if it fits; returns whether it did.
func load_entry(entry: CargoEntry) -> bool:
	if not can_load(entry.unit_type):
		return false
	entries.append(entry)
	changed.emit()
	return true


## Whether a whole list of unit types fits together (a squad against an empty hold of this size).
func fits_all(unit_types: Array[UnitStats]) -> bool:
	var left: Dictionary = {}
	for cargo_class: UnitStats.CargoClass in [UnitStats.CargoClass.INFANTRY, UnitStats.CargoClass.MACHINERY]:
		left[cargo_class] = capacity(cargo_class)
	for unit_type: UnitStats in unit_types:
		var slots: int = slots_of(unit_type)
		if slots == 0:
			return false
		left[unit_type.cargo_class] -= slots
		if left[unit_type.cargo_class] < 0:
			return false
	return true


## Removes and returns the entry for `unit_id` (null if aboard none).
func unload(unit_id: int) -> CargoEntry:
	for i: int in entries.size():
		if entries[i].unit_id == unit_id:
			var entry: CargoEntry = entries[i]
			entries.remove_at(i)
			changed.emit()
			return entry
	return null


## Empties the hold (the units aboard are scrapped).
func clear() -> void:
	if not entries.is_empty():
		entries.clear()
		changed.emit()


## Removes and returns the first entry aboard (null if empty).
func take_first() -> CargoEntry:
	if entries.is_empty():
		return null
	var entry: CargoEntry = entries.pop_front()
	changed.emit()
	return entry
