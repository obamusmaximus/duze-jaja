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
## Unit id to Unit.
var _by_id: Dictionary = {}
var _units: Array[Unit] = []
var _hash := UnitSpatialHash.new(HASH_CELL)


## Called by the level once the map is built; registers the units already placed under this node.
func setup(map_grid: MapGrid, path_service: PathService, shot_system: Shots) -> void:
	map = map_grid
	paths = path_service
	shots = shot_system
	process_physics_priority = -100 # Rebuild the hash before anything reads it this tick.
	add_to_group(&"playtest_probe")
	for child: Node in get_children():
		if child is Unit:
			_register(child as Unit)
	_hash.rebuild(_units)


## Puts a new unit (team already set) into the match and returns its id.
func add(unit: Unit) -> int:
	add_child(unit)
	_register(unit)
	return unit.id


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


func _physics_process(_delta: float) -> void:
	_hash.rebuild(_units)


func _register(unit: Unit) -> void:
	unit.setup(_next_id, self)
	_by_id[unit.id] = unit
	_units.append(unit)
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
