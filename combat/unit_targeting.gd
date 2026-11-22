class_name UnitTargeting
extends Node
## Finds enemies for the unit's brain. A full search runs every `scan_interval` seconds, staggered by unit id so the
## units don't all search on one tick; between searches the found targets are only checked cheaply, and dropped (with
## a search on the next tick) when they die or leave range. Simulation.
## - `in_range`: the best enemy in weapon range: the last attacker first (return fire), then enemies not already
##   doomed by shots in flight (no overkill), nearest first.
## - `in_sight`: the nearest enemy within `sight_range`.

var in_range: Unit
var in_sight: Unit

var _unit: Unit
var _registry: UnitRegistry
var _weapon: Weapon
var _timer: float = 0.0
var _last_attacker_id: int = 0
var _found: Array[Unit] = []


func setup(unit: Unit, registry: UnitRegistry, weapon: Weapon) -> void:
	_unit = unit
	_registry = registry
	_weapon = weapon
	_timer = fposmod(float(unit.id) * 0.618034, 1.0) * unit.stats.scan_interval


## Health.damaged: remember who hit us, and look again at once if it isn't the current target.
func note_attacker(_amount: float, source_id: int) -> void:
	_last_attacker_id = source_id
	if in_range == null or in_range.id != source_id:
		_timer = 0.0


func step(delta: float) -> void:
	_timer -= delta
	if in_range and not (in_range.alive and _weapon.in_range(in_range)):
		in_range = null
		_timer = 0.0
	if in_sight and not (in_sight.alive and _within(in_sight, _unit.stats.sight_range)):
		in_sight = null
	if _timer > 0.0:
		return
	_timer = _unit.stats.scan_interval
	_scan()


func _scan() -> void:
	in_range = null
	in_sight = null
	var search: float = _unit.stats.sight_range
	if _weapon.has_weapon():
		search = maxf(search, _weapon.stats.max_range + _unit.stats.radius + 2.0)
	_registry.units_near(_unit.global_position, search, _found)
	var best_score: float = INF
	var nearest: float = INF
	for other: Unit in _found:
		if not other.alive or not _unit.can_attack(other):
			continue
		var distance: float = _unit.global_position.distance_to(other.global_position)
		if distance < nearest and distance <= _unit.stats.sight_range:
			nearest = distance
			in_sight = other
		if _weapon.in_range(other):
			var score: float = distance
			if other.health.is_doomed():
				score += 10000.0
			if other.id == _last_attacker_id:
				score -= 100000.0
			if score < best_score:
				best_score = score
				in_range = other


func _within(other: Unit, distance: float) -> bool:
	return _unit.global_position.distance_squared_to(other.global_position) <= distance * distance
