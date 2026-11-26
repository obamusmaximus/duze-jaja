class_name UnitAbility
extends RefCounted
## A unit's ability as it stands: its charges, cooldown and running time. What it does and its numbers are the
## type's `AbilityStats`. Made by the unit; used by an ability order (`CommandIssuer`) or the pilot's key
## (`PilotFlight`), and stepped with the unit's decisions. Simulation.

var stats: AbilityStats
## Uses ready now.
var charges: int = 0
## Seconds until the next charge is back; 0 when full.
var cooldown_left: float = 0.0
## Seconds the running effect still lasts; 0 when not running.
var active_left: float = 0.0

var _unit: Unit


func _init(unit: Unit, ability_stats: AbilityStats) -> void:
	_unit = unit
	stats = ability_stats
	charges = stats.charges


func is_active() -> bool:
	return active_left > 0.0


func is_ready() -> bool:
	return _unit.alive and charges > 0 and not is_active() and stats.can_use(_unit)


## Spends a charge and starts the effect. False (and nothing changes) when not ready, or when a unit-targeted
## ability isn't aimed at a unit it accepts.
func use(point: Vector3 = Vector3.ZERO, target_id: int = 0) -> bool:
	if not is_ready():
		return false
	if stats.targeting() == AbilityStats.Targeting.UNIT:
		var target: Unit = _unit.registry.get_unit(target_id)
		if target == null or not target.alive or not stats.accepts_target(_unit, target):
			return false
	if charges >= stats.charges:
		cooldown_left = stats.cooldown
	charges -= 1
	stats.start(_unit, point, target_id)
	active_left = stats.duration
	if not is_active():
		stats.end(_unit)
	return true


func step(delta: float) -> void:
	charges = mini(charges, stats.charges) # The number may be tuned down mid-match.
	if is_active():
		active_left = maxf(active_left - delta, 0.0)
		if not is_active():
			stats.end(_unit)
		return
	if charges >= stats.charges:
		cooldown_left = 0.0
		return
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if cooldown_left <= 0.0:
		charges += 1
		cooldown_left = stats.cooldown if charges < stats.charges else 0.0
