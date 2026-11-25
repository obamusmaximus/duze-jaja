class_name SquadRegistry
extends Node
## The match's squads: gives each an id (unique, never reused), keeps them by team and finds the squad a unit belongs
## to (`Unit.squad_id`). Members stay selectable one by one: a squad is bookkeeping, not a selection group.
## Simulation. Group `squads`.

signal squad_added(squad: SquadRecord)
signal squad_removed(squad: SquadRecord)

var _next_id: int = 1
var _by_id: Dictionary = {}


func _ready() -> void:
	add_to_group(&"squads")


## Registers a squad (aboard, no units yet: the production line adds each one as it is built) and returns it.
func create(team: int, spec: SquadSpec) -> SquadRecord:
	var squad := SquadRecord.new()
	squad.id = _next_id
	_next_id += 1
	squad.team = team
	squad.display_name = spec.display_name
	squad.job = spec.job
	_by_id[squad.id] = squad
	squad_added.emit(squad)
	return squad


func get_squad(id: int) -> SquadRecord:
	return _by_id.get(id)


func aboard_of(team: int) -> Array[SquadRecord]:
	var out: Array[SquadRecord] = []
	for squad: SquadRecord in _by_id.values():
		if squad.team == team and squad.aboard:
			out.append(squad)
	return out


## Drops a squad that has nothing left (its carryall was lost, or it was scrapped).
func disband(squad: SquadRecord) -> void:
	if _by_id.erase(squad.id):
		squad_removed.emit(squad)


## A deployed squad's unit joins it (carryalls call this as they unload).
func attach(squad_id: int, unit: Unit) -> void:
	var squad: SquadRecord = get_squad(squad_id)
	if squad == null or unit.team != squad.team:
		return
	unit.squad_id = squad_id
	squad.unit_ids.append(unit.id)
	unit.died.connect(_on_member_died.bind(squad), CONNECT_ONE_SHOT)


## The whole squad is off its carryall.
func mark_deployed(squad_id: int) -> void:
	var squad: SquadRecord = get_squad(squad_id)
	if squad == null:
		return
	squad.aboard = false
	squad.carryall_id = 0
	if squad.unit_ids.is_empty():
		disband(squad)


func _on_member_died(unit: Unit, squad: SquadRecord) -> void:
	var at: int = squad.unit_ids.find(unit.id)
	if at >= 0:
		squad.unit_ids.remove_at(at)
	if squad.unit_ids.is_empty() and not squad.aboard:
		disband(squad)
