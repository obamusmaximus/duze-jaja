class_name AtollLevel
extends MatchLevel
## The battlefield level and the main scene: a full-size sea, the sculpted atoll (a heightmap PNG, `docs/plans/
## battlefield.md` step 5), a hovering mothership per team, capture point markers and units on each team's island.
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
const COMMANDO_TYPE: UnitStats = preload("res://tuning/unit_commando.tres")
## The test commandos stand this far (metres, along x) inland of their airfield's deck.
const COMMANDO_OFFSET: float = 24.0
## How far (cells) a test commando's spot looks for walkable ground.
const COMMANDO_SEARCH_CELLS: int = 64
## What each test Explorer carries: 20 troopers, 4 IFVs, a tank and a VTOL (40 of its 40).
const EXPLORER_DEMO_HOLD: Array[Array] = [[preload("res://tuning/unit_trooper.tres"), 20],
	[preload("res://tuning/unit_ifv.tres"), 4], [preload("res://tuning/unit_tank.tres"), 1], [VTOL_TYPE, 1]]
## Spacing of further starting carryalls and test Explorers, metres (along z).
const CARRYALL_SPACING: float = 45.0
const EXPLORER_SPACING: float = 90.0
## Spacing of the test flyers in their row, metres.
const FLYER_SPACING: float = 14.0
const BIRDS_EYE_STATS: BirdsEyeStats = preload("res://tuning/birds_eye_default.tres")
const AIRFIELD_STATS: AirfieldStats = preload("res://tuning/airfield_default.tres")
const ECONOMY_STATS: EconomyStats = preload("res://tuning/economy_default.tres")
## Test units' spawn candidates: a grid this fine (metres), at least this high above the sea, with the ground's slope
## measured over this reach, and this far clear of an airfield's deck.
const SPAWN_STEP: float = 8.0
const SPAWN_MIN_HEIGHT: float = 1.0
const SPAWN_SLOPE_REACH: float = 4.0
const SPAWN_AIRFIELD_CLEARANCE: float = 8.0
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
var explorer_yard: ExplorerYard
var map_markers: MapMarkers
var strategy_control: StrategyControl
var squads: SquadRegistry
var heights: TerrainHeights
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
	var lamps := LampField.new()
	lamps.name = "LampField"
	add_child(lamps)
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
	$WorldLight.applied.connect(func() -> void: _chunks.set_sun($WorldLight.sun()))
	var day_night := DayNightToggle.new()
	add_child(day_night)
	day_night.setup($WorldLight)
	_water.set_shore_field(shore)
	_water.set_light($WorldLight.stats)
	$WorldLight.applied.connect(func() -> void: _water.set_light($WorldLight.stats))
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
	_spawn_units() # Before the airfields block their ground, while the land regions are whole.
	_build_airfields()
	_build_deck_pads()
	_add_base_sensors()
	_spawn_carryalls()
	_spawn_flyers()
	_spawn_commandos()
	_spawn_explorers()
	_build_views()
	_camera_rig.focus_on(_ground_spot(battlefield.airfield_west), true)


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
	explorer_yard = ExplorerYard.new()
	explorer_yard.name = "ExplorerYard"
	add_child(explorer_yard)
	explorer_yard.setup(economy, squads, _units) # Its pads come once the motherships' decks do.
	_issuer.explorers = explorer_yard
	map_markers = MapMarkers.new()
	map_markers.name = "MapMarkers"
	map_markers.max_per_team = _issuer.stats.max_markers
	add_child(map_markers)
	_issuer.markers = map_markers


## The bird's-eye view with its own camera rig, the switcher between it and the RTS view, the cockpit and the
## strategist's controls.
func _build_views() -> void:
	birds_eye = BirdsEye.new()
	birds_eye.name = "BirdsEye"
	birds_eye.stats = BIRDS_EYE_STATS
	add_child(birds_eye)
	birds_eye.setup(camera_bounds, camera_yaw, _water, $WorldLight, _chunks)
	views = ViewSwitcher.new()
	views.name = "ViewSwitcher"
	add_child(views)
	views.setup(BIRDS_EYE_STATS, _camera_rig, birds_eye, $WorldLight, _player)
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
	strategy_control.setup(PLAYER_TEAM, _selection, _issuer, map_markers, _hud.tools, views, heights)


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


## Spreads `unit_count` units, half for each team, over each team's island.
func _spawn_units() -> void:
	var per_team: int = battlefield.unit_count / 2
	for team: int in 2:
		var spots: PackedVector3Array = _spread_spots(_airfield_spots()[team], per_team)
		for i: int in spots.size():
			var unit: Unit = UNIT_SCENE.instantiate()
			unit.stats = UNIT_TYPES[i % UNIT_TYPES.size()]
			unit.team = team
			unit.position = spots[i] + Vector3.UP * 0.3
			_units.add(unit)


## `count` spots on the land mass of `home` (x, z), on gentle ground and as far apart as they fit: candidates in a
## fixed shuffled order, each kept if it is clear of those kept, with the gap shrunk until enough are.
func _spread_spots(home: Vector2, count: int) -> PackedVector3Array:
	var grid: MapGrid = _map_node()
	var region: int = grid.region_at_point(Vector3(home.x, 0.0, home.y), 48)
	var deck: Rect2 = Airfield.footprint(AIRFIELD_STATS, home).grow(SPAWN_AIRFIELD_CLEARANCE)
	var candidates: Array[Vector3] = []
	var land: Rect2 = _grid_area()
	var max_rise: float = SPAWN_SLOPE_REACH * tan(deg_to_rad(battlefield.spawn_max_slope_deg))
	var x: float = land.position.x
	while x < land.end.x:
		var z: float = land.position.y
		while z < land.end.y:
			var at := Vector3(x, heights.height_at(x, z), z)
			if at.y >= SPAWN_MIN_HEIGHT and not deck.has_point(Vector2(x, z)) and _gentle(at, max_rise) \
					and grid.region_at_point(at, 0) == region:
				candidates.append(at)
			z += SPAWN_STEP
		x += SPAWN_STEP
	var random := RandomNumberGenerator.new()
	random.seed = 1
	for i: int in range(candidates.size() - 1, 0, -1):
		var j: int = random.randi_range(0, i)
		var swap: Vector3 = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = swap
	var out := PackedVector3Array()
	var gap: float = sqrt(float(candidates.size()) * SPAWN_STEP * SPAWN_STEP / float(maxi(count, 1)))
	while out.size() < mini(count, candidates.size()):
		out.clear()
		for at: Vector3 in candidates:
			var clear: bool = true
			for other: Vector3 in out:
				if other.distance_squared_to(at) < gap * gap:
					clear = false
					break
			if clear:
				out.append(at)
				if out.size() == count:
					break
		gap *= 0.85
	return out


func _gentle(at: Vector3, max_rise: float) -> bool:
	for offset: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
		var near: Vector2 = Vector2(at.x, at.z) + offset * SPAWN_SLOPE_REACH
		if absf(heights.height_at(near.x, near.y) - at.y) > max_rise:
			return false
	return true


func _ground_spot(at: Vector2) -> Vector3:
	return Vector3(at.x, maxf(heights.height_at(at.x, at.y), 0.0), at.y)


func _airfield_spots() -> Array[Vector2]:
	return [battlefield.airfield_west, battlefield.airfield_east]


## One airfield per team, where the stats put it.
func _build_airfields() -> void:
	var spots: Array[Vector2] = _airfield_spots()
	for team: int in spots.size():
		var field := Airfield.new()
		field.name = "Airfield%d" % team
		field.team = team
		field.airfield_id = team + 1
		field.stats = AIRFIELD_STATS
		add_child(field)
		field.setup(spots[team], _map_node(), _units)


## Each mothership's pads, as airfields: its carryall pads and its helipads. After the ground airfields, whose ids come
## first.
func _build_deck_pads() -> void:
	var next_id: int = _airfield_spots().size() + 1
	for node: Node in get_tree().get_nodes_in_group(&"motherships"):
		var ship: Mothership = node as Mothership
		# Carryalls sit along the hull; the helipads' craft face out toward the atoll.
		var out: Vector3 = ship.side_direction()
		var layouts: Array[Array] = [["CarryallPad", ship.stats.carryall_pads, ship.stats.carryall_pad, 0.0],
				["HeliPad", ship.stats.helipads, ship.stats.helipad, atan2(-out.x, -out.z)]]
		for i: int in layouts.size():
			var deck := DeckAirfield.new()
			deck.name = "%sPads%d" % [layouts[i][0], ship.team]
			deck.stats = AIRFIELD_STATS
			deck.for_carryalls = i == 0
			deck.airfield_id = next_id
			next_id += 1
			add_child(deck)
			deck.setup_on_deck(ship, layouts[i][0], layouts[i][1], layouts[i][2], layouts[i][3], _units)
		var explorer_deck := DeckAirfield.new() # Lies along the ship. Not listed: nothing lands there.
		explorer_deck.name = "ExplorerPad%d" % ship.team
		explorer_deck.stats = AIRFIELD_STATS
		add_child(explorer_deck)
		explorer_deck.setup_on_deck(ship, "ExplorerPad", 1, ship.stats.explorer_pad, 0.0, _units, false)
		explorer_yard.add_pad(ship.team, explorer_deck)


## What sees besides units: each ground airfield and each mothership.
func _add_base_sensors() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"airfields"):
		var field := node as Airfield
		if field is DeckAirfield:
			continue # The mothership's own sensor covers its decks.
		vision.add_sensor(VisionSensor.new(field.team, field, func() -> float: return field.stats.sensor_range,
				func() -> float: return field.stats.sensor_height))
	for node: Node in get_tree().get_nodes_in_group(&"motherships"):
		var ship := node as Mothership
		vision.add_sensor(VisionSensor.new(ship.team, ship, func() -> float: return ship.stats.sensor_range,
				func() -> float: return 0.0))


## The starting carryalls, hovering over their team's island, their holds full of troopers.
func _spawn_carryalls() -> void:
	var spots: Array[Vector2] = [battlefield.carryalls_west, battlefield.carryalls_east]
	for team: int in spots.size():
		for i: int in battlefield.test_carryalls:
			var carryall: Carryall = fleet.spawn_hovering(team, _ground_spot(spots[team] + Vector2(0.0, i * CARRYALL_SPACING)))
			while carryall.unit.cargo.load_entry(CargoEntry.new(0, UNIT_TYPES[0])):
				pass


## The test flyers: a row per team clear of high ground, VTOLs hovering and fighters circling.
func _spawn_flyers() -> void:
	var spots: Array[Vector2] = [battlefield.flyers_west, battlefield.flyers_east]
	for team: int in 2:
		var types: Array[UnitStats] = []
		for i: int in battlefield.test_fighters:
			types.append(FIGHTER_TYPE)
		for i: int in battlefield.test_vtols:
			types.append(VTOL_TYPE)
		for i: int in types.size():
			var at := Vector2(spots[team].x, spots[team].y + (i - (types.size() - 1) * 0.5) * FLYER_SPACING)
			_units.spawn(types[i], team, _ground_spot(at))


## The test commandos, in a row just inland of their team's airfield, each on the nearest walkable ground.
func _spawn_commandos() -> void:
	var grid: MapGrid = _map_node()
	for team: int in 2:
		var home: Vector2 = _airfield_spots()[team]
		var deck: Rect2 = Airfield.footprint(AIRFIELD_STATS, home)
		var inland: float = deck.end.x + COMMANDO_OFFSET if home.x < 0.0 else deck.position.x - COMMANDO_OFFSET
		for i: int in battlefield.test_commandos:
			var at := Vector2(inland, home.y + (i - (battlefield.test_commandos - 1) * 0.5) * FLYER_SPACING * 0.5)
			var cell: Vector2i = grid.nearest_walkable(grid.cell_of(Vector3(at.x, 0.0, at.y)), COMMANDO_SEARCH_CELLS)
			if cell.x >= 0:
				var centre: Vector3 = grid.cell_center(cell)
				at = Vector2(centre.x, centre.z)
			_units.spawn(COMMANDO_TYPE, team, _ground_spot(at))


## The test Explorers on their team's island, each with the demo hold aboard.
func _spawn_explorers() -> void:
	var spots: Array[Vector2] = [battlefield.explorer_west, battlefield.explorer_east]
	for team: int in 2:
		for i: int in battlefield.test_explorers:
			var at: Vector3 = _ground_spot(spots[team] + Vector2(0.0, i * EXPLORER_SPACING))
			var explorer: Unit = _units.spawn(EXPLORER_TYPE, team, at)
			explorer.explorer.squads = squads
			for row: Array in EXPLORER_DEMO_HOLD:
				for n: int in row[1]:
					explorer.cargo.load_entry(CargoEntry.new(0, row[0]))
