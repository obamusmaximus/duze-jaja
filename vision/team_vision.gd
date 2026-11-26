class_name TeamVision
extends RefCounted
## One team's picture of its enemies. Simulation.

var team: int
## Enemy unit id to VisionContact: those detected now or still being lost.
var contacts: Dictionary = {}
## Enemy unit id to LastKnown: those lost and not seen since.
var memory: Dictionary = {}
## Whether `memory` changed this tick (`Vision` emits `memory_changed` once for it).
var memory_dirty: bool = false


func _init(owner_team: int) -> void:
	team = owner_team


## Whether the team knows of the enemy unit now.
func knows(unit_id: int) -> bool:
	var contact: VisionContact = contacts.get(unit_id)
	return contact != null and contact.known


## How firmly the team has the enemy unit, 0 to 1.
func level(unit_id: int) -> float:
	var contact: VisionContact = contacts.get(unit_id)
	return contact.level if contact != null else 0.0
