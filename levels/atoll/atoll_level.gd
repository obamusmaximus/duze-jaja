class_name AtollLevel
extends SandboxLevel
## The scale reference level (`docs/plans/battlefield.md`, step 1) and the main scene: a full-size sea with a
## primitive atoll, a hovering mothership box per team and 100 units on the big island, to measure what a battlefield
## costs and to pick the map size. Everything sizes from `BattlefieldStats`; edits in the tuning panel rebuild the land,
## the sea, the motherships and the map grid (debounced to one rebuild per physics tick).

const UNIT_SCENE: PackedScene = preload("res://units/unit.tscn")
const UNIT_TYPES: Array[UnitStats] = [
	preload("res://tuning/unit_trooper.tres"), preload("res://tuning/unit_rover.tres")]
## Spacing of the test units in their blocks, metres.
const UNIT_SPACING: float = 3.0
const UNITS_PER_ROW: int = 10
## Gap between the two teams' blocks on the big island, metres.
const TEAM_GAP: float = 60.0

@export var battlefield: BattlefieldStats

@onready var _land: AtollLand = $Land
@onready var _water: WaterBody = $Water
@onready var _readout: BattlefieldReadout = $BattlefieldReadout

var _dirty: bool = false
## Physics ticks to wait (so the new land's shapes exist) before the grid is rebuilt; -1 for none pending.
var _regrid_in: int = -1
var _grid_started_usec: int = 0


func _ready() -> void:
	battlefield.changed.connect(func() -> void: _dirty = true)
	_apply_size()
	_map_node().cells_changed.connect(_on_grid_built)
	await super()
	_spawn_units()


func _physics_process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		_land.rebuild()
		_apply_size()
		_regrid_in = 2
	elif _regrid_in > 0:
		_regrid_in -= 1
		if _regrid_in == 0:
			_regrid_in = -1
			_map_node().build(_grid_area())


## The grid covers the atoll only: the sea has no ground to put in it.
func _grid_area() -> Rect2:
	_grid_started_usec = Time.get_ticks_usec()
	return Rect2(-battlefield.grid_size * 0.5, battlefield.grid_size)


func _map_node() -> MapGrid:
	return $MapGrid


## The map, the camera bounds, the sea, the shore and the motherships follow the stats.
func _apply_size() -> void:
	var extent: Vector2 = battlefield.map_extent
	map_area = Rect2(-extent * 0.5, extent)
	camera_bounds = map_area.grow(-50.0)
	_water.set_size(extent + Vector2(400.0, 400.0))
	_water.set_shore(_land.rects())
	var camera: Camera3D = $CameraRig/Camera
	camera.far = maxf(1000.0, extent.length() * 1.5)
	for box: Node in get_tree().get_nodes_in_group(&"mothership_boxes"):
		(box as MothershipBox).refresh()
	var cells := Vector2i(ceili(battlefield.grid_size.x / _map_node_cell()), ceili(battlefield.grid_size.y / _map_node_cell()))
	_readout.grid_cells = cells.x * cells.y


func _map_node_cell() -> float:
	return _map_node().stats.cell_size


func _on_grid_built(_area: Rect2, _opened: bool) -> void:
	_readout.grid_build_ms = float(Time.get_ticks_usec() - _grid_started_usec) / 1000.0


## Puts `unit_count` units on the big island, half for each team in a block of their own.
func _spawn_units() -> void:
	var per_team: int = battlefield.unit_count / 2
	for team: int in 2:
		for i: int in per_team:
			var unit: Unit = UNIT_SCENE.instantiate()
			unit.stats = UNIT_TYPES[i % UNIT_TYPES.size()]
			unit.team = team
			var column: float = float(i % UNITS_PER_ROW) * UNIT_SPACING
			var row: float = float(i / UNITS_PER_ROW) * UNIT_SPACING
			var side: float = -1.0 if team == 0 else 1.0
			unit.position = Vector3(side * TEAM_GAP * 0.5 - column * side, battlefield.island_height + 0.3,
				-float(per_team / UNITS_PER_ROW) * UNIT_SPACING * 0.5 + row)
			_units.add(unit)
