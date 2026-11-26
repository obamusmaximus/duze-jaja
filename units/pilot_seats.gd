class_name PilotSeats
extends RefCounted
## Which unit each team's player inhabits (one each; a team has one player for now). Taking a seat swaps the unit's
## brain for a `PilotBrain`, drops its orders, puts it on the flight model and runs it at the full rate; leaving gives it back to its orders, so
## it idles where it is (a fixed wing circles). A seat ends by itself when its unit dies or leaves the world.
## A seated player can hand the unit to the autopilot (to land at an airfield): it flies by its orders again while
## the seat stays theirs, and takes the controls back on `release_autopilot` once it is clear of any pad.
## Changed only through the `CommandIssuer`, which owns it. Simulation.

## Why a seat ended.
enum Release { LEFT, DIED, REMOVED }

## A team took over a unit.
signal inhabited(team: int, unit: Unit)
## A seat ended. `unit` is still valid during the signal (views read where it was), even when it died.
signal released(team: int, unit: Unit, reason: Release)
## The autopilot took over a seated unit (`on`), or handed its controls back.
signal autopilot_changed(team: int, unit: Unit, on: bool)

## Team to the PilotBrain flying its unit.
var _brains: Dictionary = {}
## Team to the inhabited Unit.
var _units: Dictionary = {}
## Teams whose seated unit is on the autopilot.
var _auto: Dictionary = {}


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


## Whether a unit can be flown by a player: any flyer, but not an Explorer that is deploying, deployed or packing up;
## and a jetpack type (the commando), on foot. Other ground units get their own controls later.
func can_inhabit(unit: Unit) -> bool:
	if unit == null or not unit.alive:
		return false
	if unit.jetpack != null:
		return true
	return unit.is_flying() and (unit.explorer == null or not unit.explorer.anchored())


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
	unit.full_rate = true
	unit.died.connect(_on_unit_died)
	if unit.explorer != null:
		unit.explorer.flying_again.connect(_on_explorer_flying)
	inhabited.emit(team, unit)
	# On or coming down to a pad it can't be flown from where it is: the autopilot takes off first.
	if unit.landing != null and unit.landing.holds_craft():
		engage_autopilot(team)
		release_autopilot(team)
	elif unit.landing != null:
		unit.landing.cancel()
	if _auto.get(team) != true:
		_take_controls(team)
	return true


## Whether the unit `team` inhabits is flying on the autopilot.
func is_on_autopilot(team: int) -> bool:
	return _auto.has(team)


## The autopilot takes over the unit `team` inhabits: it follows its orders until `release_autopilot`.
func engage_autopilot(team: int) -> void:
	if not _units.has(team):
		return
	var unit: Unit = _units[team]
	if _auto.has(team):
		if unit.landing != null:
			unit.landing.cancel_handback()
		return
	_auto[team] = true
	unit.movement.end_flight()
	unit.set_brain(unit.brain)
	unit.navigator.stop()
	unit.weapon.target = null
	autopilot_changed.emit(team, unit, true)


## Gives the controls back: at once, or for a craft on or over a pad once it has taken off and picked up speed. (An
## Explorer has them back by itself once it has packed up and climbed.)
func release_autopilot(team: int) -> void:
	if not _auto.has(team) or (_units[team] as Unit).landing == null:
		return
	var unit: Unit = _units[team]
	unit.orders.clear()
	unit.landing.hand_back(_resume.bind(team, unit.id))


func _resume(team: int, unit_id: int) -> void:
	if unit_id_of(team) != unit_id or not _auto.has(team):
		return
	var unit: Unit = _units[team]
	_auto.erase(team)
	unit.orders.clear()
	unit.navigator.stop()
	unit.weapon.target = null
	if unit.movement.autopilot != null:
		unit.movement.autopilot.end_orbit()
	_take_controls(team)
	autopilot_changed.emit(team, unit, false)


## The player's brain and the flight model, from the autopilot's present state.
func _take_controls(team: int) -> void:
	var unit: Unit = _units[team]
	var brain: PilotBrain = _brains[team]
	if unit.carryall != null:
		unit.carryall.take_controls()
	unit.set_brain(brain)
	unit.movement.start_flight(brain.input)


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
	var held: PilotInput = (_brains[input.team] as PilotBrain).input
	var pressed: bool = input.ability and not held.ability
	held.copy_controls(input)
	if pressed:
		_use_ability(input.team)
	return true


## The pilot's ability key was pressed (flying or on the autopilot). A targeted ability needs a click on the map,
## which the cockpit has no way to make yet.
func _use_ability(team: int) -> void:
	var unit: Unit = _units[team]
	var ability: UnitAbility = unit.ability
	if ability == null or ability.stats.targeting() != AbilityStats.Targeting.NONE or not ability.is_ready():
		return
	if ability.stats.needs_autopilot():
		engage_autopilot(team)
	ability.use()


func _on_explorer_flying(unit: Unit) -> void:
	if is_inhabited(unit) and _auto.has(unit.team):
		_resume(unit.team, unit.id)


func _release(team: int, reason: Release) -> void:
	var unit: Unit = _units[team]
	var brain: PilotBrain = _brains[team]
	_units.erase(team)
	_brains.erase(team)
	if _auto.erase(team) and unit.landing != null:
		unit.landing.cancel_handback() # It carries on with its orders (or stays on its pad).
	if unit.explorer != null:
		unit.explorer.flying_again.disconnect(_on_explorer_flying)
	unit.died.disconnect(_on_unit_died)
	unit.full_rate = false
	unit.movement.end_flight()
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
