class_name HeightmapTestLevel
extends SandboxLevel
## Test level for the heightmap terrain (`docs/plans/battlefield.md`, step 2): a generated island on a sea floor, drawn
## by `TerrainChunks`, with the map grid reading the same data and a few units to order around. Not a maintained level;
## the atoll takes the heightmap over in step 5.

const UNIT_SCENE: PackedScene = preload("res://units/unit.tscn")
const UNIT_TYPE: UnitStats = preload("res://tuning/unit_trooper.tres")
const EXTENT: Vector2 = Vector2(640.0, 640.0)
const UNITS_PER_TEAM: int = 8

@export var heightmap: HeightmapStats

@onready var _chunks: TerrainChunks = $TerrainChunks

var heights: TerrainHeights
var shore: ShoreField


func _ready() -> void:
	heights = _load_heights()
	map_area = heights.bounds()
	camera_bounds = map_area.grow(-30.0)
	_chunks.setup(heights)
	var water: WaterBody = $Water
	water.set_size(map_area.size + Vector2(400.0, 400.0))
	# The shore (foam, calm, reef) comes from the heights, baked once and re-baked where the ground changes.
	shore = ShoreField.new()
	shore.name = "ShoreField"
	add_child(shore)
	shore.bake(heights, water.stats.field_texel, water.stats.field_reach, water.stats.field_settle)
	water.set_shore_field(shore)
	_chunks.changed_area.connect(shore.mark_changed)
	var grid: MapGrid = $MapGrid
	grid.terrain = heights
	_chunks.changed_area.connect(grid.resample)
	var reloader := HeightmapReloader.new()
	reloader.name = "HeightmapReloader"
	add_child(reloader)
	reloader.setup(heights, _chunks, heightmap)
	var brush := HeightmapBrush.new()
	add_child(brush)
	brush.setup(heights, _chunks, heightmap)
	var bands := HeightBands.new()
	add_child(bands)
	bands.setup(_chunks, heightmap)
	await super()
	_spawn_units()


## The map from the source PNG; the first time, a starter atoll is saved there to open in Krita.
func _load_heights() -> TerrainHeights:
	if not FileAccess.file_exists(heightmap.source_path):
		HeightmapImport.save_file(TerrainTestMap.make_atoll(EXTENT, heightmap), heightmap.source_path)
	var loaded: TerrainHeights = HeightmapImport.load_file(heightmap.source_path, heightmap)
	return loaded if loaded != null else TerrainTestMap.make(EXTENT, heightmap)


## Two small teams on the dry ground near the middle.
func _spawn_units() -> void:
	for team: int in 2:
		for i: int in UNITS_PER_TEAM:
			var unit: Unit = UNIT_SCENE.instantiate()
			unit.stats = UNIT_TYPE
			unit.team = team
			var x: float = (-20.0 if team == 0 else 20.0) + float(i % 4) * 3.0
			var z: float = float(i / 4) * 3.0
			unit.position = Vector3(x, heights.height_at(x, z) + 0.3, z)
			$Units.add(unit)
