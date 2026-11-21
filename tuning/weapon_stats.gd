class_name WeaponStats
extends Resource
## Tunable numbers for a weapon (combat/). A unit type points at one from its UnitStats `weapon`; weapon variants
## are more .tres files (tuning/weapon_default.tres).

@export_group("Shot")
## Reach, in metres from the unit's edge to the target's edge.
@export_range(0.5, 200.0, 0.5) var max_range: float = 12.0
## Seconds between shots.
@export_range(0.05, 20.0, 0.05) var cooldown: float = 1.0
## Damage per shot.
@export_range(0.0, 2000.0, 1.0) var damage: float = 10.0
## Fire only at targets within this angle of where the unit faces, in degrees either side (180 fires all round).
## Units turn to face what they fight when standing; moving units fire only at what is ahead.
@export_range(1.0, 180.0, 1.0) var fire_arc_deg: float = 30.0

@export_group("Projectile")
## On: the shot flies to its target and hits on arrival (homing). Off: the shot hits at once (a tracer shows it).
@export var projectile: bool = true
## Flight speed of the projectile, in metres per second.
@export_range(1.0, 300.0, 1.0) var projectile_speed: float = 40.0
