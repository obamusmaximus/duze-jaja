class_name PilotSeats
extends RefCounted
## Which unit each team's player inhabits (one each; a team has one player for now). Taking a seat swaps the unit's
## brain for a `PilotBrain`, drops its orders and runs it at the full rate; leaving gives it back to its orders, so
## it idles where it is (a fixed wing circles). A seat ends by itself when its unit dies or leaves the world.
## Changed only through the `CommandIssuer`, which owns it. Simulation.

## Why a seat ended.
enum Release { LEFT, DIED, REMOVED }

## A team took over a unit.
signal inhabited(team: int, unit: Unit)
## A seat ended. `unit` is still valid during the signal (views read where it was), even when it died.
signal released(team: int, unit: Unit, reason: Release)

## Team to the PilotBrain flying its unit.
var _brains: Dictionary = {}
## Team to the inhabited Unit.
var _units: Dictionary = {}


func _init(registry: UnitRegistry) -> void:
	registry.unit_removed.connect(_on_unit_removed)


## The id of the unit `team` inhabits, or 0.
func unit_id_of(team: int) -> int:
	return (_units[team] as Unit).id if _units.has(team) else 0


## The controls of the unit `team` inhabits (to read, not to write), or null.
func input_of(team: int) -> PilotInput:
	return (_brains[team] as PilotBrain).input if _brains.has(team) else null


func is_inhabited(unit: Unit) -> bool:
	return _units.get(unit.team) == unit


## Whether a unit of this kind can be flown by a player. Only jets and VTOLs for now: ground units and carryalls get
## their own controls later.
func can_inhabit(unit: Unit) -> bool:
	return unit != null and unit.alive and unit.is_flying() and unit.carryall == null


## `team` takes over `unit`. False for another team's unit, one that can't be inhabited, or a team already seated.
func enter(team: int, unit: Unit) -> bool:
	if not can_inhabit(unit) or unit.team != team or _units.has(team):
		return false
	var brain := PilotBrain.new()
	brain.name = "PilotBrain"
	unit.add_child(brain)
	brain.setup(unit)
	_brains[team] = brain
	_units[team] = unit
	unit.orders.clear()
	unit.navigator.stop()
	unit.weapon.target = null # No shooting on its own while a player flies it.
	if unit.movement.autopilot != null:
		unit.movement.autopilot.end_orbit()
	unit.set_brain(brain)
	unit.full_rate = true
	unit.died.connect(_on_unit_died)
	inhabited.emit(team, unit)
	return true


## `team` leaves its unit. False if it inhabits none.
func leave(team: int) -> bool:
	if not _units.has(team):
		return false
	_release(team, Release.LEFT)
	return true


## Hands the controls to the unit `input` names. False unless that team inhabits that unit.
func steer(input: PilotInput) -> bool:
	if input == null or input.unit_id == 0 or unit_id_of(input.team) != input.unit_id:
		return false
	(_brains[input.team] as PilotBrain).input.copy_controls(input)
	return true


func _release(team: int, reason: Release) -> void:
	var unit: Unit = _units[team]
	var brain: PilotBrain = _brains[team]
	_units.erase(team)
	_brains.erase(team)
	unit.died.disconnect(_on_unit_died)
	unit.full_rate = false
	unit.set_brain(unit.brain)
	brain.queue_free()
	released.emit(team, unit, reason)


func _on_unit_died(unit: Unit) -> void:
	if is_inhabited(unit):
		_release(unit.team, Release.DIED)


## A unit can leave the world alive, as data (into a carryall's hold, later).
func _on_unit_removed(unit: Unit) -> void:
	if is_inhabited(unit):
		_release(unit.team, Release.REMOVED)
