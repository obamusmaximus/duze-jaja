class_name GameSound
extends Node
## Turns what happens in the match into sounds: shots fired and landing, deaths, the local player's orders and
## selection. It only listens to simulation signals and calls `Sfx`; the simulation never knows it exists. View side.
## Cue names come from the stats (`WeaponStats`, `UnitStats`), the order acknowledgements are fixed here.

## Order kind to the cue played when the local player gives it.
const ORDER_CUES: Dictionary = {
	Order.Kind.MOVE: &"order_move",
	Order.Kind.ATTACK: &"order_attack",
	Order.Kind.ATTACK_MOVE: &"order_attack_move",
	Order.Kind.STOP: &"order_stop",
}

var _team: int = 0
## Unit ids in the selection the last time it changed (a sound plays only when a new unit joins).
var _selected_ids: Dictionary = {}


func setup(shots: Shots, registry: UnitRegistry, issuer: CommandIssuer, selection: Selection, local_team: int) -> void:
	_team = local_team
	shots.shot_fired.connect(_on_shot_fired)
	shots.shot_hit.connect(_on_shot_hit)
	registry.unit_added.connect(_watch)
	for unit: Unit in registry.all_units():
		_watch(unit)
	issuer.issued.connect(_on_order)
	selection.changed.connect(_on_selection_changed.bind(selection))


func _watch(unit: Unit) -> void:
	unit.died.connect(_on_died)


func _on_shot_fired(from: Vector3, weapon: WeaponStats) -> void:
	Sfx.play_at(weapon.fire_cue, from)


func _on_shot_hit(at: Vector3, weapon: WeaponStats) -> void:
	Sfx.play_at(weapon.hit_cue, at)


func _on_died(unit: Unit) -> void:
	Sfx.play_at(unit.stats.death_cue, unit.global_position)


func _on_order(order: Order) -> void:
	if order.team == _team:
		Sfx.play_ui(ORDER_CUES.get(order.kind, &""))


func _on_selection_changed(selection: Selection) -> void:
	var now: Dictionary = {}
	var newcomer: Unit = null
	for unit: Unit in selection.units:
		now[unit.id] = true
		if newcomer == null and not _selected_ids.has(unit.id):
			newcomer = unit
	_selected_ids = now
	if newcomer:
		Sfx.play_ui(newcomer.stats.select_cue)
