class_name UnitCatalog
extends RefCounted
## The unit types a squad can be built from, with a stable string id each (the type's file name without `unit_`), so a
## `SquadSpec` is plain data that can cross the network and live in saves. Simulation data only.

const TYPES: Array[UnitStats] = [
	preload("res://tuning/unit_trooper.tres"), preload("res://tuning/unit_rover.tres"),
	preload("res://tuning/unit_ifv.tres"), preload("res://tuning/unit_tank.tres")]


static func id_of(type: UnitStats) -> StringName:
	return StringName(type.resource_path.get_file().get_basename().trim_prefix("unit_"))


## The type with `id`, or null.
static func by_id(id: StringName) -> UnitStats:
	for type: UnitStats in TYPES:
		if id_of(type) == id:
			return type
	return null
