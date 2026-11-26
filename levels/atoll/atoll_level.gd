class_name AtollLevel
extends SandboxLevel
## The battlefield level and the main scene: a full-size sea, the sculpted atoll (a heightmap PNG, `docs/plans/
## battlefield.md` step 5), a hovering mothership per team, capture point markers and 100 units on the big island.
## The terrain is `TerrainChunks` over `levels/atoll/heightmap.png` (written once from `AtollBlockout`, then edited in
## Krita and auto-reloaded, `heightmap.md`); `BattlefieldStats` sizes the map, motherships and readout, and only shapes
## the first draft of the land.

const UNIT_SCENE: PackedScene = preload("res://units/unit.tscn")
const UNIT_TYPES: Array[UnitStats] = [
	preload("res://tuning/unit_trooper.tres"), preload("res://tuning/unit_rover.tres"),
	preload("res://tuning/unit_ifv.tres"), preload("res://tuning/unit_tank.tres")]
const FIGHTER_TYPE: UnitStats = preload("res://tuning/unit_fighter.tres")
const VTOL_TYPE: UnitStats = preload("res://tuning/unit_vtol.tres")
const EXPLORER_TYPE: UnitStats = preload("res://tuning/unit_explorer.tres")
## What each test Explorer carries: 20 troopers, 4 IFVs, a tank and a VTOL (40 of its 40).
const EXPLORER_DEMO_HOLD: Array[Array] = [[preload("res://tuning/unit_trooper.tres"), 20],
	[preload("res://tuning/unit_ifv.tres"), 4], [preload("res://tuning/unit_tank.tres"), 1], [VTOL_TYPE, 1]]
## Where each team's first test Explorer starts (x, z): low ground near its block (team 0's side is mountainous).
const EXPLORER_SPOTS: Array[Vector2] = [Vector2(-140.0, 95.0), Vector2(100.0, 70.0)]
## Spacing of further test Explorers, metres (toward the island's middle).
const EXPLORER_SPACING: float = 90.0
## Spacing of the test flyers in their row, metres.
const FLYER_SPACING: float = 14.0
const TABLE_STATS: WarTableStats = preload("res://tuning/war_table_default.tres")
const BIRDS_EYE_STATS: BirdsEyeStats = preload("res://tuning/birds_eye_default.tres")
const ECONOMY_STATS: EconomyStats = preload("res://tuning/economy_default.tres")
## Spacing of the test units in their blocks, metres.
const UNIT_SPACING: float = 9.0
const UNITS_PER_ROW: int = 10
## Gap between the two teams' blocks on the big island, metres. Each block grows outward from its side of the gap.
const TEAM_GAP: float = 60.0
## Margin round the dry land that the map grid covers, metres.
const LAND_MARGIN: float = 24.0

@export var battlefield: BattlefieldStats
@export var heightmap: HeightmapStats

@onready var _chunks: TerrainChunks = $TerrainChunks
@onready var _water: WaterBody = $Water
@onready var _readout: BattlefieldReadout = $BattlefieldReadout

var economy: Economy
var production: Production
var fleet: CarryallFleet
var map_markers: MapMarkers
var strategy_control: StrategyControl
var squads: SquadRegistry
var heights: TerrainHeights
var war_table: WarTable
var birds_eye: BirdsEye
var views: ViewSwitcher
var cockpit: CockpitView
var shore: ShoreField
var _dirty: bool = false
var _grid_started_usec: int = 0
## How long computing the grid took during the load, microseconds.
var _grid_usec: int = 0


func _ready() -> void:
	battlefield.changed.connect(func() -> void: _dirty = true)
	_water.stats.changed.connect(_cover_seabed)
	_apply_size() # Sizes the sea first, so the chunks it covers are never built.
	heights = _load_heights()
	_chunks.set_sun($WorldLight.sun())
	var grid: MapGrid = _map_node()
	grid.terrain = heights
	shore = ShoreField.new()
	shore.name = "ShoreField"
	add_child(shore)
	var build := LevelBuild.new()
	build.run(heights, _chunks, shore, _water.stats, grid, _grid_area, battlefield.threaded_load)
	_grid_usec = build.grid_usec
	_chunks.changed_area.connect(grid.resample)
	grid.cells_changed.connect(_on_grid_built)
	_water.set_shore_field(shore)
	_chunks.changed_area.connect(shore.mark_changed)
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
	_place_capture_markers()
	_build_economy()
	await super()
	_spawn_units()
	_spawn_flyers()
	_spawn_explorers()
	_build_war_table()


func _physics_process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		_apply_size()


## The banks, the squad registry, the carryall fleet and the production lines (a line per bay of each team's mothership). Made before the
## HUD binds so its modules find them by group; orders reach them through the issuer.
func _build_economy() -> void:
	var teams: Array[int] = []
	var line_counts: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group(&"motherships"):
		var ship: Mothership = node as Mothership
		teams.append(ship.team)
		line_counts[ship.team] = ship.stats.production_bays
	economy = Economy.new()
	economy.name = "Economy"
	economy.stats = ECONOMY_STATS
	add_child(economy)
	economy.setup(teams)
	squads = SquadRegistry.new()
	squads.name = "Squads"
	add_child(squads)
	fleet = CarryallFleet.new()
	fleet.name = "Carryalls"
	add_child(fleet)
	fleet.setup(_units, squads)
	production = Production.new()
	production.name = "Production"
	add_child(production)
	production.setup(economy, squads, fleet, line_counts)
	_issuer.production = production
	map_markers = MapMarkers.new()
	map_markers.name = "MapMarkers"
	map_markers.max_per_team = _issuer.stats.max_markers
	add_child(map_markers)
	_issuer.markers = map_markers


## The strategy views: the table model of the map and the bird's-eye rig, each with its own camera rig, and the switcher between them and the RTS view.
func _build_war_table() -> void:
	war_table = WarTable.new()
	war_table.name = "WarTable"
	war_table.stats = TABLE_STATS
	add_child(war_table)
	war_table.setup(heights, camera_bounds, camera_yaw, _units, PLAYER_TEAM)
	_chunks.changed_area.connect(war_table.mark_changed)
	birds_eye = BirdsEye.new()
	birds_eye.name = "BirdsEye"
	birds_eye.stats = BIRDS_EYE_STATS
	add_child(birds_eye)
	birds_eye.setup(camera_bounds, camera_yaw, _water, $WorldLight, _chunks)
	views = ViewSwitcher.new()
	views.name = "ViewSwitcher"
	add_child(views)
	views.setup(TABLE_STATS, BIRDS_EYE_STATS, _camera_rig, war_table, birds_eye, $WorldLight, _player)
	views.view_changed.connect(func(view: ViewSwitcher.View) -> void:
		_hud.show_mode(Hud.Mode.RTS if view == ViewSwitcher.View.RTS else Hud.Mode.STRATEGY))
	cockpit = CockpitView.new()
	cockpit.name = "CockpitView"
	add_child(cockpit)
	cockpit.setup(PLAYER_TEAM, _selection, _issuer, views, _camera_rig, $WorldLight)
	cockpit.entering.connect(_hud.show_mode.bind(Hud.Mode.FLIGHT))
	cockpit.leaving.connect(_hud.show_mode.bind(Hud.Mode.RTS))
	strategy_control = StrategyControl.new()
	strategy_control.name = "StrategyControl"
	add_child(strategy_control)
	strategy_control.setup(PLAYER_TEAM, _selection, _issuer, map_markers, _hud.tools, views, war_table, heights)


## The map from the source PNG; the first run writes a generated draft there to open in Krita.
func _load_heights() -> TerrainHeights:
	if not FileAccess.file_exists(heightmap.source_path):
		HeightmapImport.save_file(AtollBlockout.make(battlefield, heightmap), heightmap.source_path)
	var loaded: TerrainHeights = HeightmapImport.load_file(heightmap.source_path, heightmap)
	return loaded if loaded != null else AtollBlockout.make(battlefield, heightmap)


## The grid is land only, so it covers the dry samples' bounding box (plus a margin) and nothing more.
func _grid_area() -> Rect2:
	var first: Vector2i = heights.samples
	var last := Vector2i(-1, -1)
	for iz: int in heights.samples.y:
		for ix: int in heights.samples.x:
			if heights.sample_height(ix, iz) > MapGrid.SEA_LEVEL:
				first = first.min(Vector2i(ix, iz))
				last = last.max(Vector2i(ix, iz))
	if last.x < 0:
		return heights.bounds()
	var land := Rect2(heights.origin + Vector2(first) * heights.spacing, Vector2(last - first) * heights.spacing)
	return land.grow(LAND_MARGIN).intersection(heights.bounds())


## The grid was computed with the rest of the level (`LevelBuild`). The readout's time is that plus publishing.
func _build_map() -> void:
	_grid_started_usec = Time.get_ticks_usec() - _grid_usec
	_map_node().publish()


func _map_node() -> MapGrid:
	return $MapGrid


func _place_capture_markers() -> void:
	for point: Vector2 in AtollBlockout.capture_points(battlefield):
		var marker := CaptureMarker.new()
		marker.position = Vector3(point.x, maxf(heights.height_at(point.x, point.y), 0.0), point.y)
		add_child(marker)


## The map, the camera bounds, the sea, the shore and the motherships follow the stats.
func _apply_size() -> void:
	var extent: Vector2 = battlefield.map_extent
	map_area = Rect2(-extent * 0.5, extent)
	camera_bounds = map_area.grow(-50.0)
	_map_node().air.bounds = map_area
	_water.set_size(extent + Vector2(400.0, 400.0))
	_cover_seabed()
	var camera: Camera3D = $CameraRig/Camera
	camera.far = maxf(1000.0, extent.length() * 1.5)
	_place_motherships()
	_readout.grid_cells = 0


## Tells the terrain where the sea hides it, so it draws no seabed there.
func _cover_seabed() -> void:
	var centre := Vector2(_water.global_position.x, _water.global_position.z)
	_chunks.set_water_cover(Rect2(centre - _water.size * 0.5, _water.size),
		_water.global_position.y - _water.max_trough())


## Each mothership hovers at its side of the map (team 0 west, 1 east), its long side to the atoll: the bow points
## to -z for both, so the west one shows its starboard side to the atoll and the east one its port side.
func _place_motherships() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"motherships"):
		var ship: Mothership = node as Mothership
		var side: float = -1.0 if ship.team == 0 else 1.0
		ship.place(Vector3(side * battlefield.mothership_standoff, battlefield.mothership_altitude, 0.0))


func _on_grid_built(area: Rect2, _opened: bool) -> void:
	_readout.grid_cells = int(area.size.x * area.size.y / pow(_map_node().stats.cell_size, 2.0))
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
			var x: float = side * (TEAM_GAP * 0.5 + column)
			var z: float = float(per_team / UNITS_PER_ROW) * UNIT_SPACING * 0.5 + row
			unit.position = Vector3(x, heights.height_at(x, z) + 0.3, z)
			_units.add(unit)


## The test flyers: a row per team behind the gap, VTOLs hovering and fighters circling.
func _spawn_flyers() -> void:
	for team: int in 2:
		var side: float = -1.0 if team == 0 else 1.0
		var types: Array[UnitStats] = []
		for i: int in battlefield.test_fighters:
			types.append(FIGHTER_TYPE)
		for i: int in battlefield.test_vtols:
			types.append(VTOL_TYPE)
		for i: int in types.size():
			var at := Vector3(side * (TEAM_GAP * 0.5 + i * FLYER_SPACING), 0.0, -FLYER_SPACING * 2.0)
			_units.spawn(types[i], team, at)


## The test Explorers: a row per team near its block, each with the demo hold aboard.
func _spawn_explorers() -> void:
	for team: int in 2:
		for i: int in battlefield.test_explorers:
			var spot: Vector2 = EXPLORER_SPOTS[team] - Vector2(0.0, i * EXPLORER_SPACING)
			var at := Vector3(spot.x, 0.0, spot.y)
			var explorer: Unit = _units.spawn(EXPLORER_TYPE, team, at)
			explorer.explorer.squads = squads
			for row: Array in EXPLORER_DEMO_HOLD:
				for n: int in row[1]:
					explorer.cargo.load_entry(CargoEntry.new(0, row[0]))
