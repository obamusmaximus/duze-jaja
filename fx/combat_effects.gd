class_name CombatEffects
extends Node3D
## The combat particle effects: a muzzle flash where a shot leaves, sparks where it lands, and an explosion (fireball,
## debris, smoke) where a unit dies. Listens to simulation signals and plays pooled one-shot particle systems, reusing
## the oldest when a battle asks for more than the pool holds. View side: the simulation never knows it exists.

@export var stats: FxStats

var _flashes: Array[GPUParticles3D] = []
var _sparks: Array[GPUParticles3D] = []
## Each death is a Node3D holding fire, debris and smoke.
var _deaths: Array[Node3D] = []
var _next_flash: int = 0
var _next_spark: int = 0
var _next_death: int = 0


func setup(shots: Shots, registry: UnitRegistry) -> void:
	shots.shot_fired.connect(_on_shot_fired)
	shots.shot_hit.connect(_on_shot_hit)
	registry.unit_added.connect(_watch)
	for unit: Unit in registry.all_units():
		_watch(unit)
	stats.changed.connect(_build_pools)
	_build_pools()


func _watch(unit: Unit) -> void:
	unit.died.connect(_on_died)


## Rebuilds every pool from the stats (at the start, and when a value is edited live).
func _build_pools() -> void:
	for child: Node in get_children():
		child.queue_free()
	_flashes.clear()
	_sparks.clear()
	_deaths.clear()
	for i: int in stats.small_pool:
		_flashes.append(_add(FxBuilder.flash(stats)))
		_sparks.append(_add(FxBuilder.spark(stats)))
	for i: int in stats.death_pool:
		var burst := Node3D.new()
		burst.add_child(FxBuilder.fire(stats))
		burst.add_child(FxBuilder.debris(stats))
		burst.add_child(FxBuilder.smoke(stats))
		add_child(burst)
		_deaths.append(burst)


func _add(system: GPUParticles3D) -> GPUParticles3D:
	add_child(system)
	return system


func _on_shot_fired(from: Vector3, weapon: WeaponStats) -> void:
	_play(_flashes[_next_flash], from, weapon.effect_scale)
	_next_flash = (_next_flash + 1) % _flashes.size()


func _on_shot_hit(at: Vector3, weapon: WeaponStats) -> void:
	_play(_sparks[_next_spark], at, weapon.effect_scale)
	_next_spark = (_next_spark + 1) % _sparks.size()


func _on_died(unit: Unit) -> void:
	var burst: Node3D = _deaths[_next_death]
	_next_death = (_next_death + 1) % _deaths.size()
	burst.global_position = unit.center()
	burst.scale = Vector3.ONE * unit.stats.death_effect_scale
	for system: Node in burst.get_children():
		(system as GPUParticles3D).restart()


func _play(system: GPUParticles3D, point: Vector3, effect_scale: float) -> void:
	system.global_position = point
	system.scale = Vector3.ONE * effect_scale
	system.restart()
