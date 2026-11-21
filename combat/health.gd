class_name Health
extends Node
## A unit's hit points. `incoming` is damage already on its way (projectiles in flight), so targeting can skip
## targets that are already as good as dead instead of wasting shots on them (overkill). Simulation.

## Took damage from the unit with id `source_id` (0 if unknown).
signal damaged(amount: float, source_id: int)
## Hit points reached zero; `killer_id` dealt the last hit.
signal died(killer_id: int)

var current: float = 1.0
## Damage from shots in flight toward this unit.
var incoming: float = 0.0

var _stats: UnitStats


func setup(stats: UnitStats) -> void:
	_stats = stats
	current = stats.max_health


func damage(amount: float, source_id: int) -> void:
	if current <= 0.0 or amount <= 0.0:
		return
	current = maxf(current - amount, 0.0)
	damaged.emit(amount, source_id)
	if current <= 0.0:
		died.emit(source_id)


## Full is 1.
func fraction() -> float:
	return clampf(current / maxf(_stats.max_health, 0.001), 0.0, 1.0)


func is_damaged() -> bool:
	return current < _stats.max_health


## Shots in flight will kill it.
func is_doomed() -> bool:
	return incoming >= current
