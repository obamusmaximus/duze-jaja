class_name FogView
extends Node
## Visual only: what of the enemy the local player's views draw (`docs/mechanics/vision.md`, "What is drawn"). Each
## frame it gives every unit how much of it to draw (`Unit.show_in_view`); every view, pick, effect and sound reads
## that from the unit. A commander's view (RTS, bird's-eye) follows the team's contacts and fades by their level. A
## first-person view follows what the inhabited unit knows, plus what it has locked or is tracking. Own units are always
## drawn. Reads the simulation, never changes it.

## An enemy the view knew of is no longer known to it.
signal unit_lost(unit: Unit)

## Debug tools only: draw every unit whole.
var reveal_all: bool = false

var _registry: UnitRegistry
var _vision: Vision
var _seats: PilotSeats
var _team: int = 0
var _clock: float = 0.0
## The inhabited unit's id as of the last frame (0: a commander's view).
var _pilot_id: int = 0
## First person only: enemy id to whether the inhabited unit knows it, and to when to ask again (`_clock`).
var _aware: Dictionary = {}
var _due: Dictionary = {}


func setup(registry: UnitRegistry, vision: Vision, seats: PilotSeats, team: int) -> void:
	_registry = registry
	_vision = vision
	_seats = seats
	_team = team
	process_priority = -100 # Before the views draw.
	registry.unit_added.connect(_on_unit_added)
	for unit: Unit in registry.all_units():
		_on_unit_added(unit)


func _on_unit_added(unit: Unit) -> void:
	# A new enemy is hidden until detected: never one frame in view.
	if unit.team != _team and not reveal_all:
		unit.show_in_view(0.0, false)


func _process(delta: float) -> void:
	_clock += delta
	var pilot_id: int = _seats.unit_id_of(_team)
	var pilot: Unit = _registry.get_unit(pilot_id) if pilot_id != 0 else null
	if pilot_id != _pilot_id:
		_pilot_id = pilot_id
		_aware.clear()
		_due.clear()
	var picture: TeamVision = _vision.of_team(_team)
	for unit: Unit in _registry.all_units():
		if not unit.alive:
			continue # It keeps what it had, for its death effect and sound.
		if unit.team == _team or reveal_all:
			unit.show_in_view(1.0, true)
			continue
		var known: bool = picture.knows(unit.id)
		var level: float = picture.level(unit.id)
		if pilot != null:
			known = _pilot_has(pilot, unit, known)
			# A unit's knowledge switches at once: fade toward it at the contact's own rates.
			var target: float = 1.0 if known else 0.0
			var seconds: float = _vision.stats.gain_time if known else _vision.stats.lose_time
			level = move_toward(unit.view_level, target, delta / seconds)
		var was_known: bool = unit.in_view
		unit.show_in_view(level, known)
		if was_known and not known:
			unit_lost.emit(unit)


## Whether the inhabited unit's view knows of `enemy`: its awareness (asked every `check_interval`, as it costs sight
## lines), or its own lock or track on it.
func _pilot_has(pilot: Unit, enemy: Unit, team_knows: bool) -> bool:
	var flight: PilotFlight = pilot.pilot_flight()
	if flight != null:
		if flight.weapon != null and flight.weapon.locked_id == enemy.id:
			return true
		if flight.tracking != null and flight.tracking.time_left(enemy.id) > 0.0:
			return true
	if not team_knows:
		_aware.erase(enemy.id)
		_due.erase(enemy.id)
		return false
	if _clock >= float(_due.get(enemy.id, 0.0)):
		_due[enemy.id] = _clock + _vision.stats.check_interval
		_aware[enemy.id] = _vision.unit_has(pilot, enemy)
	return _aware[enemy.id]
