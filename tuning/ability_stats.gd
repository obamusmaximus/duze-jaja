class_name AbilityStats
extends Resource
## Base of a unit ability's tunable numbers and of what it does. A unit type names one in `UnitStats.ability`; the
## unit runs it as a `UnitAbility`, which keeps the charges and timers. A new ability is one script extending this
## (its own numbers, `start` and `end`) and a .tres of it. The resource is shared by every unit of the type, so it
## keeps no state: that is on the unit.

## What the ability is aimed at: nothing (it fires on F), a ground point, or a unit (F arms it and the next left
## click aims it). Part of what the ability does, so a script says it (`targeting`); it isn't a tunable.
enum Targeting { NONE, POINT, UNIT }

@export_group("Ability")
## The ability's name, for the HUD.
@export var display_name: String = "Ability"
## Uses it can hold. Each use takes one; they come back one at a time.
@export_range(1, 10, 1) var charges: int = 1
## Seconds to get one charge back. The count waits while the ability is running.
@export_range(0.0, 300.0, 0.5) var cooldown: float = 12.0
## Seconds it runs for; 0 for an instant one. It can't be used again while it runs.
@export_range(0.0, 60.0, 0.1) var duration: float = 0.0


func targeting() -> Targeting:
	return Targeting.NONE


## Whether `target` is something a `Targeting.UNIT` ability of `unit` can be aimed at.
func accepts_target(unit: Unit, target: Unit) -> bool:
	return target.is_enemy_of(unit.team) and unit.team_knows(target)


## Whether `unit` may use it now, beyond charges and cooldown (an Explorer halfway through deploying can't).
func can_use(_unit: Unit) -> bool:
	return true


## Whether a pilot using it hands the unit to the autopilot, which carries it out (`PilotSeats`).
func needs_autopilot() -> bool:
	return false


## Takes effect on `unit`. `point` and `target_id` are what a targeted ability was aimed at (zero and 0 if nothing).
func start(_unit: Unit, _point: Vector3, _target_id: int) -> void:
	pass


## The effect is over (at once for an instant ability).
func end(_unit: Unit) -> void:
	pass
