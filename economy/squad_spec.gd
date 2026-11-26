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
	var used: float = 0.0
	for id: String in type_ids:
		var type: UnitStats = UnitCatalog.by_id(StringName(id))
		if type == null:
			return "unknown type"
		if Cargo.size_of(type) <= 0.0:
			return "%s can't be carried" % type.display_name
		used += Cargo.size_of(type)
	if used > stats.squad_hold.volume * stats.squad_carryalls + Cargo.EPSILON:
		return "too big for the hold"
	return ""


func to_dict() -> Dictionary:
	return {"name": display_name, "job": Job.keys()[job], "types": Array(type_ids)}
