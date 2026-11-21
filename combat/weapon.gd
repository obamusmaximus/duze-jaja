class_name Weapon
extends Node
## Fires at `target` (set by the brain each tick) whenever the target is in range, inside the fire arc and the
## cooldown is ready; the shot itself is the Shots system's job. A unit without WeaponStats has an idle weapon.
## Simulation.

## What the brain wants shot at, or null.
var target: Unit
var stats: WeaponStats

var _unit: Unit
var _shots: Shots
var _cooldown: float = 0.0


func setup(unit: Unit, weapon_stats: WeaponStats, shots: Shots) -> void:
	_unit = unit
	stats = weapon_stats
	_shots = shots


func has_weapon() -> bool:
	return stats != null


## Edge to edge on the ground, within `max_range`.
func in_range(other: Unit) -> bool:
	return stats != null and _flat_distance(other) <= reach_to(other)


## The centre-to-centre distance at which `other` is in range.
func reach_to(other: Unit) -> float:
	var weapon_range: float = stats.max_range if stats else 0.0
	return weapon_range + _unit.stats.radius + other.stats.radius


## Whether `other` is within the fire arc of where the unit faces.
func in_arc(other: Unit) -> bool:
	if stats == null:
		return false
	if stats.fire_arc_deg >= 180.0:
		return true
	var to_other := Vector3(other.global_position.x - _unit.global_position.x, 0.0,
		other.global_position.z - _unit.global_position.z)
	if to_other.length_squared() < 0.0001:
		return true
	var forward: Vector3 = -_unit.global_basis.z
	return forward.angle_to(to_other) <= deg_to_rad(stats.fire_arc_deg)


func step(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if stats == null or target == null or not target.alive or _cooldown > 0.0:
		return
	if not in_range(target) or not in_arc(target):
		return
	_cooldown = stats.cooldown
	_shots.fire(_unit, target, stats)


func _flat_distance(other: Unit) -> float:
	return Vector2(other.global_position.x - _unit.global_position.x,
		other.global_position.z - _unit.global_position.z).length()
