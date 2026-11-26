class_name Unit
extends CharacterBody3D
## A unit in the match. It only holds its parts (look, movement, navigator, order queue and brain, targeting,
## weapon, health) and its identity: a stable `id` (unique per match, given by the UnitRegistry), the owning `team`,
## and its type (`stats`). Simulation: the registry runs it on the fixed tick (no `_physics_process` here)
## and never reads views. Groups: `units`, `team_<n>`.
## Units don't collide with each other (layer 2, masks 1 and 3): they keep apart by separation steering.

## The unit died (it leaves the match at the end of the frame; `alive` is already false).
signal died(unit: Unit)
## The local player selected or deselected it (shows the ring).
signal selected_changed(selected: bool)

@export var stats: UnitStats
## Owning team. Set in the level, or by a spawner before the unit is added to the registry.
@export var team: int = 0

## Unique per match; 0 until the registry adds the unit.
var id: int = 0
var registry: UnitRegistry
## Thinks every physics tick instead of every other one (the unit a player inhabits; `docs/performance.md`).
var full_rate: bool = false
var alive: bool = true
var selected: bool = false
## Id of the unit that dealt the killing blow (0 if none).
var killed_by: int = 0
## What it crashed into (`FlightCrash.Cause`); NONE if it didn't.
var crash_cause: FlightCrash.Cause = FlightCrash.Cause.NONE
## Flyers and jetpack types: height above the ground or sea under it, kept by the autopilot or the jetpack; 0 on the
## ground.
var hover_height: float = 0.0
## The squad this unit belongs to (`SquadRegistry`); 0 for none.
var squad_id: int = 0
## The type's ability and its charges (`stats.ability`); null for a type without one.
var ability: UnitAbility
## Set by a running ability (1: none): the flight model's thrust, and the autopilot's top speed and acceleration.
var thrust_boost: float = 1.0
var speed_boost: float = 1.0
## The hold, for a type with `stats.cargo` (a carryall); null otherwise.
var cargo: Cargo
## The carryall behaviour (pad, delivery, side gunners), for a type with `stats.carryall`; null otherwise.
var carryall: Carryall
## The Explorer behaviour (deploy, bubble, base area), for a type with `stats.explorer`; null otherwise.
var explorer: Explorer
## Using pads (landing, repair, takeoff), for any flyer but an Explorer; null otherwise. An Explorer built on the
## mothership has one only until it is clear of its pad (`ExplorerYard`).
var landing: Landing
## The jetpack (hover, surge, afterburner) under the RTS, for a type with `stats.jetpack`; null otherwise.
var jetpack: Jetpack
## View side (`FogView`), which the simulation never reads: how much of the unit the local player's view draws (0
## hidden, 1 whole), and whether that view knows of it (so it can be picked).
var view_level: float = 1.0
var in_view: bool = true

@onready var movement: UnitMovement = $Movement
@onready var navigator: UnitNavigator = $Navigator
@onready var orders: OrderQueue = $Orders
@onready var brain: OrderBrain = $Brain
@onready var targeting: UnitTargeting = $Targeting
@onready var weapon: Weapon = $Weapon
@onready var health: Health = $Health
@onready var _shape: CollisionShape3D = $Shape
@onready var _look: UnitLook = $Look


## Called once by the UnitRegistry as the unit joins the match.
func setup(new_id: int, unit_registry: UnitRegistry) -> void:
	id = new_id
	registry = unit_registry
	add_to_group(&"units")
	add_to_group(StringName("team_%d" % team))
	health.setup(stats)
	if stats.cargo != null:
		cargo = Cargo.new(stats.cargo)
	if stats.carryall != null and cargo != null:
		carryall = Carryall.new(self, stats.carryall)
	if stats.explorer != null:
		explorer = Explorer.new(self, stats.explorer)
	if stats.flying and explorer == null:
		landing = Landing.new(self)
	if stats.ability != null:
		ability = UnitAbility.new(self, stats.ability)
	if stats.jetpack != null:
		jetpack = Jetpack.new(self, stats.jetpack)
	if stats.flying:
		collision_mask = 0 # Flyers pass over walls and buildings; they only share the air with other flyers.
	weapon.setup(self, stats.weapon, unit_registry.shots)
	targeting.setup(self, unit_registry, weapon)
	navigator.setup(self, stats, unit_registry)
	brain.setup(self, orders, navigator, targeting, weapon, unit_registry)
	movement.setup(self, stats, brain, unit_registry)
	if registry.map:
		_look.air = registry.map.air
	_look.setup(stats, team)
	if explorer != null:
		_look.add_explorer(explorer)
	if jetpack != null:
		set_hover(jetpack.hover_height())
	_apply_size()
	stats.changed.connect(_apply_size)
	health.damaged.connect(targeting.note_attacker)
	health.died.connect(die)


## One decision, run by the registry at the unit's rate: targeting, what movement wants, the weapon.
func think(delta: float) -> void:
	if carryall != null:
		carryall.step(delta)
	if explorer != null:
		explorer.step(delta)
	if landing != null:
		landing.step(delta)
		if explorer != null and landing.phase == Landing.Phase.NONE:
			landing = null # Clear of the pad it was built on: an Explorer uses no pads after that.
	if ability != null:
		ability.step(delta)
	targeting.step(delta)
	movement.decide(delta)
	if jetpack != null and movement.flight == null:
		jetpack.step(delta, movement.flat_velocity())
		if jetpack.afterburning():
			weapon.cool(delta) # No firing under the afterburner.
			return
	weapon.step(delta)


## Hands movement to another brain (direct control); `set_brain(brain)` gives it back to the orders.
func set_brain(new_brain: UnitBrain) -> void:
	movement.brain = new_brain


func set_selected(on: bool) -> void:
	if selected == on:
		return
	selected = on
	_look.show_selected(on)
	selected_changed.emit(on)


## View side (`FogView`): draws this much of the unit.
func show_in_view(level: float, known: bool) -> void:
	view_level = level
	in_view = known
	_look.set_view_level(level)


## Whether any of it is in view: its effects and sounds play.
func is_drawn() -> bool:
	return view_level > 0.0


## The middle of the body, for screen projection and aiming.
func center() -> Vector3:
	return global_position + Vector3.UP * stats.height * 0.5


func is_enemy_of(other_team: int) -> bool:
	return team != other_team


## Awareness (`vision.md`): whether this unit knows of the enemy `other` (it, its squad or its base detects it).
## What it reacts to. Costs a sight line when nobody linked to it saw `other` last: call it on a search, not every tick.
func knows(other: Unit) -> bool:
	return registry.vision == null or registry.vision.unit_knows(self, other)


## Whether this unit's team knows of `other` (the commander's view; cheap).
func team_knows(other: Unit) -> bool:
	return registry.vision == null or registry.vision.of_team(team).knows(other.id)


func is_flying() -> bool:
	return stats.flying


## Flyers and jetpack types: the body hovers above its ground point (a jetpack type is still a ground unit).
func hovers() -> bool:
	return stats.flying or stats.jetpack != null


## Whether this unit may target `other` at all: an enemy, and in the air only if this unit is anti-air.
func can_attack(other: Unit) -> bool:
	return other != null and other.team != team and (not other.is_flying() or stats.anti_air)


## The spot on the ground (or sea) under the unit; for a ground unit its position. A flyer's plate and ring sit here.
func ground_point() -> Vector3:
	return global_position - Vector3.UP * hover_height


## Flyers: how far the body hovers above the ground under it (`ground_point`, and the look's plate and ring).
func set_hover(height: float) -> void:
	hover_height = height
	_look.set_hover(height)


## Where an inhabiting player's eyes are (a view's mount point on the airframe).
func cockpit_mount() -> Node3D:
	return _look.cockpit_mount()


## A first-person view sits in the cockpit (look only): the airframe isn't drawn.
func set_cockpit_occupied(occupied: bool) -> void:
	_look.set_cockpit_occupied(occupied)


## Flyers: pitch and bank of the airframe, for the look (the node itself only turns about the vertical).
func set_attitude(pitch: float, bank: float) -> void:
	_look.set_attitude(pitch, bank)


## The flight while a player flies this unit, for views to read (speed, stall, controls); else null.
func pilot_flight() -> PilotFlight:
	return movement.flight


## Destroyed by flying into something.
func crash(cause: FlightCrash.Cause) -> void:
	if alive:
		crash_cause = cause
		die()


func die(killer_id: int = 0) -> void:
	if not alive:
		return
	alive = false
	killed_by = killer_id
	collision_layer = 0
	died.emit(self)
	queue_free()


## Flyers under the flight model: the airframe's whole orientation within the node's yaw (look and cockpit mount).
func set_airframe(basis_in_node: Basis) -> void:
	_look.set_airframe(basis_in_node)


func _apply_size() -> void:
	var shape := _shape.shape as CylinderShape3D
	shape.radius = stats.radius
	shape.height = stats.height
	_shape.position.y = stats.height * 0.5
