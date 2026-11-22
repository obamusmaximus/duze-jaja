class_name Shots
extends Node
## Every shot in the match. Instant shots hit at once; projectiles are plain data (packed arrays, no nodes or physics
## bodies) moved on the fixed tick, homing on their target and hitting on arrival, or vanishing where the target was if
## it died first. The ShotView draws them. Simulation. A playtest probe (event `attack` when a unit opens fire on a
## new target).

## A shot was fired: `instant` ones only, for tracers (projectiles are drawn from `positions()`).
signal fired(from: Vector3, to: Vector3)
## Any shot was fired (instant or projectile), from the muzzle; for sound and flashes.
signal shot_fired(from: Vector3, weapon: WeaponStats)
## A shot landed on a unit, at its centre; for sound and sparks.
signal shot_hit(at: Vector3, weapon: WeaponStats)
signal playtest_event(event: StringName, data: Dictionary)

## Projectiles closer than this (metres) to their aim point hit.
const HIT_DISTANCE: float = 0.3

var _registry: UnitRegistry
var _positions := PackedVector3Array()
var _aims := PackedVector3Array()
var _targets := PackedInt32Array()
var _sources := PackedInt32Array()
var _damages := PackedFloat32Array()
var _speeds := PackedFloat32Array()
## The weapon each shot came from (for its hit effects).
var _weapons: Array[WeaponStats] = []
## Source unit id to the id of the target it last fired at.
var _last_target: Dictionary = {}


func setup(registry: UnitRegistry) -> void:
	_registry = registry
	add_to_group(&"playtest_probe")


func fire(source: Unit, target: Unit, weapon: WeaponStats) -> void:
	if _last_target.get(source.id, 0) != target.id:
		_last_target[source.id] = target.id
		playtest_event.emit(&"attack", {"unit": source.id, "target": target.id})
	var muzzle: Vector3 = source.center() - source.global_basis.z * source.stats.radius
	shot_fired.emit(muzzle, weapon)
	if not weapon.projectile:
		fired.emit(muzzle, target.center())
		shot_hit.emit(target.center(), weapon)
		target.health.damage(weapon.damage, source.id)
		return
	_positions.append(muzzle)
	_aims.append(target.center())
	_targets.append(target.id)
	_sources.append(source.id)
	_damages.append(weapon.damage)
	_speeds.append(weapon.projectile_speed)
	_weapons.append(weapon)
	target.health.incoming += weapon.damage


## Projectiles in flight, for the view.
func positions() -> PackedVector3Array:
	return _positions


func count() -> int:
	return _positions.size()


func _physics_process(delta: float) -> void:
	var i: int = 0
	while i < _positions.size():
		var target: Unit = _registry.get_unit(_targets[i])
		if target:
			_aims[i] = target.center()
		var to_aim: Vector3 = _aims[i] - _positions[i]
		var step: float = _speeds[i] * delta
		if to_aim.length() <= step + HIT_DISTANCE:
			if target:
				target.health.incoming = maxf(target.health.incoming - _damages[i], 0.0)
				shot_hit.emit(target.center(), _weapons[i])
				target.health.damage(_damages[i], _sources[i])
			_remove(i)
			continue
		_positions[i] += to_aim / to_aim.length() * step
		i += 1


## Swap-remove: order doesn't matter, and it keeps removal O(1).
func _remove(i: int) -> void:
	var last: int = _positions.size() - 1
	_positions[i] = _positions[last]
	_aims[i] = _aims[last]
	_targets[i] = _targets[last]
	_sources[i] = _sources[last]
	_damages[i] = _damages[last]
	_speeds[i] = _speeds[last]
	_weapons[i] = _weapons[last]
	_positions.resize(last)
	_aims.resize(last)
	_targets.resize(last)
	_sources.resize(last)
	_damages.resize(last)
	_speeds.resize(last)
	_weapons.resize(last)
