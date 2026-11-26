class_name Explorer
extends RefCounted
## What makes a flying unit with a hold an Explorer, the flying forward base (`docs/mechanics/explorer.md`). On its
## ability (F, `DeployStats`) it deploys: it sinks to a low hover over where it stands, raises a beam from its back
## and unfurls an energy bubble from the beam's top, sets the units in its hold down over the ground inside, and the
## bubble's ground becomes a base area. F again (or any order that moves it) packs up: the bubble folds, it climbs
## back to cruise height and flies on. Simulation: the `Unit` steps it from `think`; the `OrderBrain` holds it still
## while `anchored`. Views read `state`, `beam`, `bubble` and `bubble_center`.

## The base area opened (deployed, `true`) or closed (packing up, `false`).
signal base_changed(open: bool)

## Back at cruise height after packing up (or giving up a deploy): it flies again.
signal flying_again(unit: Unit)

enum State { FLYING, DESCENDING, RAISING, UNLOADING, DEPLOYED, PACKING, CLIMBING }

## Group of the units whose base area is open (`base_at`).
const BASE_GROUP: StringName = &"base_areas"
## Sinking is over once it moves slower than this (metres per second) and is this close to its height (metres).
const REST_SPEED: float = 0.1
const REST_SLACK: float = 0.25

var unit: Unit
var stats: ExplorerStats
var state: State = State.FLYING
## How far the beam has shot up, 0 to 1 (view).
var beam: float = 0.0
## How far the bubble has unfurled from the top, 0 to 1 (view).
var bubble: float = 0.0
## The squad registry units joined on landing (set by the level; null: none).
var squads: SquadRegistry

## Seconds into the current step.
var _time: float = 0.0
var _from_height: float = 0.0
var _to_height: float = 0.0
## Where it deployed: the ground under it (follows it until it has come to rest).
var _ground := Vector3.ZERO
var _unloaded: int = 0
var _unload_total: int = 0
var _timer: float = 0.0


func _init(body: Unit, explorer_stats: ExplorerStats) -> void:
	unit = body
	stats = explorer_stats


## True while it isn't free to fly (from the start of a deploy to the end of the climb back).
func anchored() -> bool:
	return state != State.FLYING


## Whether F does anything now: deploy while flying, pack up once the bubble is raising or up.
func can_toggle() -> bool:
	if unit.landing != null:
		return false # Still on (or leaving) the mothership's pad.
	return state in [State.FLYING, State.RAISING, State.UNLOADING, State.DEPLOYED]


## Deploys while flying, packs up while deployed. Returns whether it did either.
func toggle() -> bool:
	if not can_toggle():
		return false
	if state == State.FLYING:
		_deploy()
		return true
	if state in [State.RAISING, State.UNLOADING, State.DEPLOYED]:
		_pack()
		return true
	return false


## True while the bubble's ground is a base area.
func is_base() -> bool:
	return state == State.UNLOADING or state == State.DEPLOYED


## The middle of the bubble, in the world.
func bubble_center() -> Vector3:
	return _ground + Vector3.UP * stats.bubble_lift


## Where it deployed (the ground at the base area's middle).
func base_center() -> Vector3:
	return _ground


func base_radius() -> float:
	return stats.base_radius()


## Whether `point` lies in the base area (flat distance); false when it isn't deployed.
func covers(point: Vector3) -> bool:
	if not is_base():
		return false
	return Vector2(point.x - _ground.x, point.z - _ground.z).length() <= base_radius()


## The open base area of `team` that covers `point`: its Explorer, or null.
static func base_at(tree: SceneTree, team: int, point: Vector3) -> Explorer:
	for node: Node in tree.get_nodes_in_group(BASE_GROUP):
		var body := node as Unit
		if body != null and body.alive and body.team == team and body.explorer.covers(point):
			return body.explorer
	return null


## The Explorer's own tick, before its movement decision.
func step(delta: float) -> void:
	_time += delta
	match state:
		State.DESCENDING:
			if not unit.orders.is_idle():
				_climb() # An order to move: give up the deploy and go.
				return
			# It may still be coasting, or high above (just left by a pilot): the spot is wherever it comes to rest.
			_settle_over(unit.global_position)
			var t: float = clampf(_time / stats.descent_time, 0.0, 1.0)
			unit.movement.altitude_override = lerpf(_from_height, _to_height, smoothstep(0.0, 1.0, t))
			if t >= 1.0 and _at_rest():
				_enter(State.RAISING)
				base_changed.emit(true)
				unit.add_to_group(BASE_GROUP)
		State.RAISING:
			beam = clampf(_time / stats.beam_time, 0.0, 1.0)
			bubble = clampf((_time - stats.beam_time) / stats.bubble_time, 0.0, 1.0)
			if bubble >= 1.0:
				_enter(State.UNLOADING)
				_unloaded = 0
				_unload_total = unit.cargo.entries.size() if unit.cargo != null else 0
				_timer = 0.0
			elif not unit.orders.is_idle():
				_pack()
		State.UNLOADING:
			if not unit.orders.is_idle():
				_pack()
				return
			_timer -= delta
			if _timer <= 0.0:
				_timer = stats.unload_interval
				if not _unload_one():
					_enter(State.DEPLOYED)
		State.DEPLOYED:
			if not unit.orders.is_idle():
				_pack()
		State.PACKING:
			var t: float = clampf(_time / stats.pack_time, 0.0, 1.0)
			bubble = 1.0 - clampf(t / 0.75, 0.0, 1.0)
			beam = 1.0 - clampf((t - 0.75) / 0.25, 0.0, 1.0)
			if t >= 1.0:
				_climb()
		State.CLIMBING:
			var t: float = clampf(_time / stats.climb_time, 0.0, 1.0)
			_to_height = unit.movement.altitude_for(_ground_height(unit.global_position))
			unit.movement.altitude_override = lerpf(_from_height, _to_height, smoothstep(0.0, 1.0, t))
			if t >= 1.0:
				unit.movement.altitude_override = NAN
				_enter(State.FLYING)
				flying_again.emit(unit)


func _deploy() -> void:
	unit.orders.clear()
	_from_height = unit.global_position.y
	_settle_over(unit.global_position)
	_enter(State.DESCENDING)


## Takes `at` as the spot to deploy over: the ground there, and the hover height above it.
func _settle_over(at: Vector3) -> void:
	_ground = Vector3(at.x, _ground_height(at), at.z)
	_to_height = _ground.y + unit.stats.flight_height * stats.hover_fraction


## Stopped, and down at the hover height. It sinks no faster than its climb rate, so from high up this takes longer
## than `descent_time`.
func _at_rest() -> bool:
	var pilot: FlightAutopilot = unit.movement.autopilot
	return pilot == null or (pilot.velocity.length() < REST_SPEED
			and absf(unit.global_position.y - _to_height) < REST_SLACK)


func _pack() -> void:
	if is_base():
		base_changed.emit(false)
	unit.remove_from_group(BASE_GROUP)
	_enter(State.PACKING)


func _climb() -> void:
	beam = 0.0
	bubble = 0.0
	unit.remove_from_group(BASE_GROUP)
	_from_height = unit.global_position.y
	unit.movement.altitude_override = _from_height
	_enter(State.CLIMBING)


func _enter(next: State) -> void:
	state = next
	_time = 0.0


## Sets the next unit in the hold down over the base area (sunflower spread, so any count covers it evenly).
## Returns false when the hold has nothing left that can land. A ground unit with no walkable ground near its spot
## stays aboard.
func _unload_one() -> bool:
	if unit.cargo == null:
		return false
	var map: MapGrid = unit.registry.map
	for entry: CargoEntry in unit.cargo.entries:
		var at: Vector3 = _drop_point(_unloaded)
		var flyer: bool = entry.unit_type.flying
		if flyer:
			at = Vector3(at.x, unit.global_position.y, at.z) # Flyers leave at the hull's height and climb away.
		elif map != null and map.is_built():
			var cell: Vector2i = map.nearest_walkable(map.cell_of(at))
			if cell.x < 0:
				continue
			at = map.cell_center(cell)
			at.y = map.surface_height(at)
		unit.cargo.remove_entry(entry)
		_unloaded += 1
		var landed: Unit = entry.land(unit.registry, unit.team, at)
		if squads != null and entry.squad_id != 0:
			squads.attach(entry.squad_id, landed)
		return true
	return false


## The `index`th point of a sunflower spiral over the base area's middle, `unload_spread` of its radius out.
func _drop_point(index: int) -> Vector3:
	var count: float = float(maxi(_unload_total, 1))
	var golden: float = PI * (3.0 - sqrt(5.0))
	var reach: float = base_radius() * stats.unload_spread * sqrt((float(index) + 0.5) / count)
	var angle: float = float(index) * golden
	return _ground + Vector3(cos(angle), 0.0, sin(angle)) * reach


func _ground_height(point: Vector3) -> float:
	var map: MapGrid = unit.registry.map if unit.registry != null else null
	return maxf(map.ground_height(point), MapGrid.SEA_LEVEL) if map != null else 0.0
