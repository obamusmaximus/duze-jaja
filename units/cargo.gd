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


## Fills below this much of a slot still count as fitting (sizes are in halves, sums stay exact; this is only a guard).
const EPSILON: float = 0.001


## Room `unit_type` takes in a hold (in infantry), 0 if it can't be carried.
static func size_of(unit_type: UnitStats) -> float:
	return unit_type.cargo_size if unit_type.cargo_class != UnitStats.CargoClass.NONE else 0.0


## The hold's whole volume.
func capacity() -> float:
	return stats.volume


## Room taken by the units aboard.
func used() -> float:
	var total: float = 0.0
	for entry: CargoEntry in entries:
		total += size_of(entry.unit_type)
	return total


func free_room() -> float:
	return capacity() - used()


## Whether `unit_type` fits in the room left.
func can_load(unit_type: UnitStats) -> bool:
	var size: float = size_of(unit_type)
	return size > 0.0 and size <= free_room() + EPSILON


## Stores `entry` if it fits; returns whether it did.
func load_entry(entry: CargoEntry) -> bool:
	if not can_load(entry.unit_type):
		return false
	entries.append(entry)
	changed.emit()
	return true


## Whether a whole list of unit types fits together (a squad against an empty hold of this size).
func fits_all(unit_types: Array[UnitStats]) -> bool:
	var total: float = 0.0
	for unit_type: UnitStats in unit_types:
		var size: float = size_of(unit_type)
		if size <= 0.0:
			return false
		total += size
	return total <= capacity() + EPSILON


## How many of each type are aboard, in the order each type first came aboard: `[{type, count}]` (views).
func type_counts() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: CargoEntry in entries:
		var found: bool = false
		for row: Dictionary in out:
			if row.type == entry.unit_type:
				row.count += 1
				found = true
				break
		if not found:
			out.append({type = entry.unit_type, count = 1})
	return out


## Removes and returns the entry for `unit_id` (null if aboard none).
func unload(unit_id: int) -> CargoEntry:
	for i: int in entries.size():
		if entries[i].unit_id == unit_id:
			var entry: CargoEntry = entries[i]
			entries.remove_at(i)
			changed.emit()
			return entry
	return null


## Removes `entry` (one picked by the carrier itself, ids may be 0 for units built aboard).
func remove_entry(entry: CargoEntry) -> void:
	var at: int = entries.find(entry)
	if at >= 0:
		entries.remove_at(at)
		changed.emit()


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
