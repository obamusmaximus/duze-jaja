class_name CarryallFleet
extends Node
## Every carryall of the match, as a list the strategy view and the AI commander read: each with its coordinates and
## its state (`Carryall.State`: delivering, returning, following commands, idle, or loading on its pad). It also hands
## a production line a fresh carryall on a free pad of the team's mothership, free of charge, and cleans up when one
## is lost. Simulation: no view or camera is read here. Group `carryalls`.

## A carryall left its pad (`Production` stops the line that was loading it).
signal took_off(carryall: Carryall)
## A team's carryalls changed (one appeared, left or was lost).
signal changed(team: int)

const CARRYALL_TYPE: UnitStats = preload("res://tuning/unit_carryall.tres")

var squads: SquadRegistry
var _units: UnitRegistry
var _carryalls: Array[Carryall] = []


func setup(unit_registry: UnitRegistry, squad_registry: SquadRegistry) -> void:
	_units = unit_registry
	squads = squad_registry
	add_to_group(&"carryalls")


## Puts a new empty carryall on a free pad of `team`'s mothership; null if there is none free (or no mothership).
func spawn_on_pad(team: int) -> Carryall:
	var ship: Mothership = _mothership_of(team)
	if ship == null or _units == null:
		return null
	var index: int = _free_pad(team, ship.stats.carryall_pads)
	if index < 0:
		return null
	var body: Unit = _units.spawn(CARRYALL_TYPE, team, ship.pad_position(index))
	var carryall: Carryall = body.carryall
	carryall.squads = squads
	carryall.dock(ship, index)
	carryall.took_off.connect(func() -> void: took_off.emit(carryall))
	_carryalls.append(carryall)
	body.died.connect(_on_died.bind(carryall), CONNECT_ONE_SHOT)
	changed.emit(team)
	return carryall


## Every carryall of `team`.
func of_team(team: int) -> Array[Carryall]:
	var out: Array[Carryall] = []
	for carryall: Carryall in _carryalls:
		if carryall.unit.team == team:
			out.append(carryall)
	return out


## The list as plain data: `{id, position, state}` per carryall of `team`. For the strategy view and the commander;
## players don't see the coordinates.
func snapshot(team: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for carryall: Carryall in of_team(team):
		if not carryall.unit.is_inside_tree(): # Leaving the match (its removal is being announced).
			continue
		out.append({"id": carryall.unit.id, "position": carryall.unit.global_position, "state": carryall.state()})
	return out


## The idle carryall of `team` closest to `point` (flat), or null. Meant for an exfil: it must have an empty hold,
## unless `empty_only` is off.
func closest_idle(team: int, point: Vector3, empty_only: bool = true) -> Carryall:
	var best: Carryall = null
	var best_distance: float = INF
	for carryall: Carryall in of_team(team):
		if carryall.state() != Carryall.State.IDLE or (empty_only and not carryall.unit.cargo.entries.is_empty()):
			continue
		var distance: float = Vector2(carryall.unit.global_position.x - point.x, carryall.unit.global_position.z - point.z).length()
		if distance < best_distance:
			best = carryall
			best_distance = distance
	return best


func _free_pad(team: int, pad_count: int) -> int:
	for index: int in pad_count:
		var taken: bool = false
		for carryall: Carryall in of_team(team):
			if carryall.pad == index:
				taken = true
				break
		if not taken:
			return index
	return -1


func _mothership_of(team: int) -> Mothership:
	for node: Node in get_tree().get_nodes_in_group(&"motherships"):
		if (node as Mothership).team == team:
			return node as Mothership
	return null


## A lost carryall takes whatever it held with it, and so does the squad aboard.
func _on_died(_unit: Unit, carryall: Carryall) -> void:
	_carryalls.erase(carryall)
	for squad: SquadRecord in squads.aboard_of(carryall.unit.team):
		if squad.carryall_id == carryall.unit.id:
			squads.disband(squad)
	changed.emit(carryall.unit.team)
