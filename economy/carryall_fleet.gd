class_name CarryallFleet
extends Node
## Every carryall of the match, as a list the strategy view and the AI commander read: each with its coordinates and
## its state (`Carryall.State`: delivering, returning, following commands, idle, or loading on its pad). It also hands
## a production line a fresh carryall on a free pad of the team's mothership, free of charge, and cleans up when one
## is lost. Simulation: no view or camera is read here. Group `carryalls`.

## A carryall left a pad (`Production` stops the line that was loading it).
signal took_off(carryall: Carryall)
## A team's carryalls changed (one appeared, left or was lost).
signal changed(team: int)

## Read from outside through `carryall_type()`: a direct read of another script's `static var` breaks the engine's cleanup at exit.
static var _carryall_type: UnitStats = preload("res://tuning/unit_carryall.tres")

var squads: SquadRegistry
var _units: UnitRegistry
var _carryalls: Array[Carryall] = []


static func carryall_type() -> UnitStats:
	return _carryall_type



func setup(unit_registry: UnitRegistry, squad_registry: SquadRegistry) -> void:
	_units = unit_registry
	squads = squad_registry
	add_to_group(&"carryalls")


## A carryall for a production line to load: an empty one waiting on a pad of `team`'s mothership, else a new one on
## a free pad. Null if there is neither (the pads are all taken).
func claim_on_pad(team: int) -> Carryall:
	for carryall: Carryall in of_team(team):
		if carryall.ready_to_load():
			return carryall
	var deck: Airfield = _deck_of(team)
	if deck == null or _units == null or deck.free_pads() == 0:
		return null
	var carryall: Carryall = _spawn(team, deck.global_position)
	carryall.dock(deck)
	changed.emit(team)
	return carryall


## A new empty carryall of `team` hovering over `at` (a level's starting carryalls).
func spawn_hovering(team: int, at: Vector3) -> Carryall:
	var carryall: Carryall = _spawn(team, at)
	changed.emit(team)
	return carryall


func _spawn(team: int, at: Vector3) -> Carryall:
	var body: Unit = _units.spawn(_carryall_type, team, at)
	var carryall: Carryall = body.carryall
	carryall.squads = squads
	carryall.took_off.connect(func() -> void: took_off.emit(carryall))
	_carryalls.append(carryall)
	body.died.connect(_on_died.bind(carryall), CONNECT_ONE_SHOT)
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


## The team's carryall pads, or null (a level without a mothership).
func _deck_of(team: int) -> Airfield:
	for node: Node in get_tree().get_nodes_in_group(&"airfields"):
		var field := node as Airfield
		if field.team == team and field.for_carryalls:
			return field
	return null


## A lost carryall takes whatever it held with it, and so does the squad aboard.
func _on_died(_unit: Unit, carryall: Carryall) -> void:
	_carryalls.erase(carryall)
	for squad: SquadRecord in squads.aboard_of(carryall.unit.team):
		if squad.carryall_id == carryall.unit.id:
			squads.disband(squad)
	changed.emit(carryall.unit.team)
