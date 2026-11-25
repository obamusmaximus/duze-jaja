class_name SquadSpec
extends RefCounted
## A squad as plain data: a name, a job and the unit type ids in it. What `produce` orders carry and what a preset
## (`SquadStats`) turns into. Cost and build time are the sum over its units.

enum Job { SCOUT, PATROL, GUARD, COVERT, ASSAULT }

var display_name: String = "Squad"
var job: Job = Job.ASSAULT
var type_ids: PackedStringArray = PackedStringArray()


static func from_types(squad_name: String, squad_job: Job, types: Array[UnitStats]) -> SquadSpec:
	var spec := SquadSpec.new()
	spec.display_name = squad_name
	spec.job = squad_job
	for type: UnitStats in types:
		spec.type_ids.append(UnitCatalog.id_of(type))
	return spec


## The unit types in order; unknown ids are skipped (`validate` refuses a spec that has them).
func types() -> Array[UnitStats]:
	var out: Array[UnitStats] = []
	for id: String in type_ids:
		var type: UnitStats = UnitCatalog.by_id(StringName(id))
		if type != null:
			out.append(type)
	return out


func cost() -> int:
	var total: int = 0
	for type: UnitStats in types():
		total += type.cost
	return total


## Seconds a production line needs.
func build_seconds(scale: float) -> float:
	var total: float = 0.0
	for type: UnitStats in types():
		total += type.build_time
	return total * scale


## "" if the squad may be built, else why not: empty, an unknown or uncarriable type, or more than the hold allows.
func validate(stats: EconomyStats) -> String:
	if type_ids.is_empty():
		return "empty squad"
	var used: Dictionary = {}
	for id: String in type_ids:
		var type: UnitStats = UnitCatalog.by_id(StringName(id))
		if type == null:
			return "unknown type"
		if type.cargo_class == UnitStats.CargoClass.NONE:
			return "%s can't be carried" % type.display_name
		used[type.cargo_class] = int(used.get(type.cargo_class, 0)) + type.cargo_slots
	for cargo_class: int in used:
		if int(used[cargo_class]) > stats.squad_hold.capacity(cargo_class as UnitStats.CargoClass) * stats.squad_carryalls:
			return "too big for the hold"
	return ""


func to_dict() -> Dictionary:
	return {"name": display_name, "job": Job.keys()[job], "types": Array(type_ids)}
