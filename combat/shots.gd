class_name Shots
extends Node
## Every shot in the match. Instant shots hit at once; projectiles are plain data (packed arrays, no nodes or physics
## bodies) moved on the fixed tick, homing on their target and hitting on arrival, or vanishing where the target was if
## it died first. The ShotView draws them. Simulation. A playtest probe (event `attack` when a unit opens fire on a
## new target).

## An instant shot was fired, for tracers and beams (projectiles are drawn from `positions()`).
signal fired(from: Vector3, to: Vector3, source: Unit, weapon: WeaponStats)
## Any shot was fired (instant or projectile), from the muzzle; for sound and flashes.
signal shot_fired(from: Vector3, weapon: WeaponStats, source: Unit)
## A shot landed; for sound and sparks. `target` is the unit it hit (null: ground or a wall), `source` who fired it
## (null once gone).
signal shot_hit(at: Vector3, weapon: WeaponStats, source: Unit, target: Unit)
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
	_note_target(source, target)
	var muzzle: Vector3 = source.center() - source.global_basis.z * source.stats.radius
	shot_fired.emit(muzzle, weapon, source)
	if not weapon.projectile:
		fired.emit(muzzle, target.center(), source, weapon)
		_hit(target, target.center(), damage_of(weapon, target), source.id, weapon)
		return
	_positions.append(muzzle)
	_aims.append(target.center())
	_targets.append(target.id)
	_sources.append(source.id)
	var damage: float = damage_of(weapon, target)
	_damages.append(damage)
	_speeds.append(weapon.projectile_speed)
	_weapons.append(weapon)
	target.health.incoming += damage


## An instant shot aimed by hand, from `from` to `to`, where it stops. `target` is the unit it hits there, or null
## (ground, a wall, a friend or nothing at all). `struck`: something is there, so it sparks.
func fire_beam(source: Unit, from: Vector3, to: Vector3, target: Unit, struck: bool, weapon: WeaponStats) -> void:
	shot_fired.emit(from, weapon, source)
	fired.emit(from, to, source, weapon)
	if target != null:
		_note_target(source, target)
		_hit(target, to, damage_of(weapon, target), source.id, weapon)
	elif struck:
		shot_hit.emit(to, weapon, source, null)


## A hit delivered by something that flies on its own (a seeker pellet): `target` takes `weapon`'s damage at `at`.
func strike(source: Unit, target: Unit, at: Vector3, weapon: WeaponStats) -> void:
	_note_target(source, target)
	_hit(target, at, damage_of(weapon, target), source.id, weapon)


## What one hit of `weapon` does to `target`'s armor.
static func damage_of(weapon: WeaponStats, target: Unit) -> float:
	if weapon.damage_profile == null:
		return DamageProfile.FALLBACK
	return weapon.damage_profile.against(target.stats.armor)


func _note_target(source: Unit, target: Unit) -> void:
	if _last_target.get(source.id, 0) != target.id:
		_last_target[source.id] = target.id
		playtest_event.emit(&"attack", {"unit": source.id, "target": target.id})


func _hit(target: Unit, at: Vector3, damage: float, source_id: int, weapon: WeaponStats) -> void:
	shot_hit.emit(at, weapon, _registry.get_unit(source_id), target)
	target.health.damage(damage, source_id)


## Projectiles in flight, for the view.
func positions() -> PackedVector3Array:
	return _positions


## The id of who fired projectile `i` (an index into `positions()`), and that unit (null once gone).
func source_id_of(i: int) -> int:
	return _sources[i]


func source_of(i: int) -> Unit:
	return _registry.get_unit(_sources[i])


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
				shot_hit.emit(target.center(), _weapons[i], _registry.get_unit(_sources[i]), target)
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
