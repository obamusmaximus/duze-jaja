class_name LastKnown
extends RefCounted
## Where a team last saw an enemy unit it has lost. It stays if the unit dies or is carried off unseen: the team
## doesn't know. For commander views only; units never act on it. It ends after `memory_time`
## (`ghost_time` for a ghost), when the unit is known again, or when the team watches its spot again and the unit
## isn't there (`Vision`). Simulation.

var unit_id: int
var type: UnitStats
## The unit's team.
var team: int
var position: Vector3
var yaw: float
## `Vision.time` at which the contact was lost.
var time: float
## Whether the team has stopped watching the spot since (only then can watching it again clear the record: a unit lost
## at the edge of sight leaves from a spot that is still watched).
var hidden: bool = false
## Whether it shows as a ghost (a big unit) rather than heat.
var ghost: bool


func _init(id: int, contact: VisionContact, lost_at: float) -> void:
	unit_id = id
	type = contact.type
	team = contact.team
	position = contact.position
	yaw = contact.yaw
	time = lost_at
	ghost = type != null and type.leaves_ghost
