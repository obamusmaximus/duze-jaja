class_name UnitRegistry
extends Node3D
## The match's units: the parent of every unit, gives each a stable id (unique per match, never reused), finds units
## by id and by place (a spatial hash rebuilt first thing every physics tick), and hands units the match services
## they use (`map`, `paths`, `shots`). Units placed as its children in the level join at `setup()`, in child order.
## Simulation. A playtest probe (event `death`).

signal unit_added(unit: Unit)
signal unit_removed(unit: Unit)
signal playtest_event(event: StringName, data: Dictionary)

## Side of a spatial hash bucket, in metres: about twice the separation search, so that hot query touches few
## buckets; target searches are wider but run a few times a second, not every tick.
const HASH_CELL: float = 4.0

var map: MapGrid
var paths: PathService
var shots: Shots

var _next_id: int = 1
var _tick: int = 0
## Total microseconds spent in the unit loop since the match began (the benchmark reads it).
var step_usec: int = 0
## Unit id to Unit.
var _by_id: Dictionary = {}
var _units: Array[Unit] = []
var _hash := UnitSpatialHash.new(HASH_CELL)


## Called by the level once the map is built; registers the units already placed under this node.
func setup(map_grid: MapGrid, path_service: PathService, shot_system: Shots) -> void:
	map = map_grid
	paths = path_service
	shots = shot_system
	process_physics_priority = -100 # Rebuild the hash and step the units before views and shots read them.
	add_to_group(&"playtest_probe")
	add_to_group(&"unit_registry")
	for child: Node in get_children():
		if child is Unit:
			_register(child as Unit)
	_hash.rebuild(_units)


## Puts a new unit (team already set) into the match and returns its id. `keep_id` (a unit that left the match as
## data) gives it that id back; ids are never reused, so it is free.
func add(unit: Unit, keep_id: int = 0) -> int:
	add_child(unit)
	_register(unit, keep_id)
	return unit.id


## Makes a unit of `type` for `team` at `at` and puts it into the match.
func spawn(type: UnitStats, team: int, at: Vector3, keep_id: int = 0) -> Unit:
	var unit: Unit = load("res://units/unit.tscn").instantiate()
	unit.stats = type
	unit.team = team
	unit.position = at
	add(unit, keep_id)
	return unit


## The living unit with `id`, or null.
func get_unit(id: int) -> Unit:
	var unit: Object = _by_id.get(id)
	if is_instance_valid(unit) and (unit as Unit).alive:
		return unit as Unit
	return null


func all_units() -> Array[Unit]:
	return _units.duplicate()


func count() -> int:
	return _units.size()


## Fills `out` with the living units whose centre is within `radius` (x, z) of `point`.
func units_near(point: Vector3, radius: float, out: Array[Unit]) -> void:
	_hash.query(point, radius, out)


## The one loop over the units. Half of them think each tick (by id parity, so the load is even), with twice the delta;
## every unit moves every tick (the decided velocity, so physics interpolation stays smooth); `full_rate` units think
## every tick.
func _physics_process(delta: float) -> void:
	var started: int = Time.get_ticks_usec()
	_hash.rebuild(_units)
	_tick += 1
	var parity: int = _tick & 1
	for unit: Unit in _units:
		if not unit.alive:
			continue
		if unit.full_rate:
			unit.think(delta)
		elif (unit.id & 1) == parity:
			unit.think(delta * 2.0)
		unit.movement.integrate(delta)
	step_usec += Time.get_ticks_usec() - started


func _register(unit: Unit, keep_id: int = 0) -> void:
	var new_id: int = keep_id if keep_id != 0 and not _by_id.has(keep_id) else _next_id
	unit.setup(new_id, self)
	_by_id[unit.id] = unit
	_units.append(unit)
	if new_id == _next_id:
		_next_id += 1
	unit.died.connect(_on_died)
	unit.tree_exiting.connect(_forget.bind(unit), CONNECT_ONE_SHOT)
	unit_added.emit(unit)


func _on_died(unit: Unit) -> void:
	playtest_event.emit(&"death", {"unit": unit.id, "team": unit.team, "killer": unit.killed_by})


func _forget(unit: Unit) -> void:
	_by_id.erase(unit.id)
	_units.erase(unit)
	unit_removed.emit(unit)
