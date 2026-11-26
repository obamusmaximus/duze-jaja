class_name CargoEntry
extends RefCounted
## One carried unit as data: its id (kept when it is unloaded; 0 for a unit built aboard, which gets one when it
## lands), its type, its health and its squad. A controller joins with first-person play.

var unit_id: int
var unit_type: UnitStats
var health: float
## The squad it belongs to (`SquadRegistry`), 0 for none.
var squad_id: int = 0


func _init(id: int, type: UnitStats, current_health: float = -1.0) -> void:
	unit_id = id
	unit_type = type
	health = type.max_health if current_health < 0.0 else current_health


## Puts the unit back on the map at `at` for `team` (same id if it had one, its health kept); returns it.
func land(registry: UnitRegistry, team: int, at: Vector3) -> Unit:
	var landed: Unit = registry.spawn(unit_type, team, at, unit_id)
	landed.health.current = health
	return landed
