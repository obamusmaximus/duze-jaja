class_name Awareness
extends RefCounted
## What a single unit knows of (`docs/mechanics/vision.md`, "Awareness"): an enemy its team knows of, detected by the
## unit itself, a member of its squad, or the deployed Explorer whose base area it stands in. While a contact fades,
## the units linked to whoever saw it last still know it. Units react only to this; the commander sees the team's
## contacts. Owned by `Vision` (`Vision.unit_knows`, `Unit.knows`). Simulation.

var _vision: Vision
var _registry: UnitRegistry
var _near: Array[Unit] = []


func _init(vision: Vision, registry: UnitRegistry) -> void:
	_vision = vision
	_registry = registry


## `record`: remember whoever sees it as the contact's observer (the simulation's questions only).
func knows(unit: Unit, target: Unit, record: bool = true) -> bool:
	var contact: VisionContact = _vision.of_team(unit.team).contacts.get(target.id)
	if contact == null or not contact.known:
		return false
	var base: Unit = _base_of(unit)
	if contact.sensor == null and _linked(unit, base, _registry.get_unit(contact.observer_id)):
		return true
	if not contact.seen:
		return false # Fading, and whoever saw it last isn't linked to this unit.
	var seer: Unit = _linked_seer(unit, base, target)
	if seer == null:
		return false
	if record:
		# The next check and the next question start with this observer.
		contact.sensor = null
		contact.observer_id = seer.id
	return true


## The deployed Explorer of the unit's team whose base area holds the unit, or null.
func _base_of(unit: Unit) -> Unit:
	for base: Unit in _vision.bases_of(unit.team):
		if base.explorer.covers(unit.global_position):
			return base
	return null


func _linked(unit: Unit, base: Unit, observer: Unit) -> bool:
	if observer == null or not observer.alive:
		return false
	return observer == unit or observer == base or (unit.squad_id != 0 and observer.squad_id == unit.squad_id)


## The unit, its base or a squad member that detects `target` now, or null.
func _linked_seer(unit: Unit, base: Unit, target: Unit) -> Unit:
	if _vision.detects(unit, target):
		return unit
	if base != null and _vision.detects(base, target):
		return base
	if unit.squad_id == 0:
		return null
	_vision.observers_near(unit.team, target, _near)
	for mate: Unit in _near:
		if mate != unit and mate.squad_id == unit.squad_id and _vision.detects(mate, target):
			return mate
	return null
