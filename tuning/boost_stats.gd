class_name BoostStats
extends AbilityStats
## A short burst of speed for a flyer: more thrust while a player flies it, a higher top speed on the autopilot
## (tuning/ability_boost_fighter.tres, the test ability).

@export_group("Boost")
## The flight model's thrust while it runs, as a multiple of the type's own.
@export_range(1.0, 6.0, 0.05) var thrust_scale: float = 2.2
## The autopilot's top speed and acceleration while it runs, as a multiple of the type's own.
@export_range(1.0, 3.0, 0.05) var speed_scale: float = 1.4


func start(unit: Unit, _point: Vector3, _target_id: int) -> void:
	unit.thrust_boost = thrust_scale
	unit.speed_boost = speed_scale


func end(unit: Unit) -> void:
	unit.thrust_boost = 1.0
	unit.speed_boost = 1.0
