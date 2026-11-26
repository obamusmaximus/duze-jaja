class_name MatchLevel
extends Node3D
## The base of a playable level: wires the match (map grid, paths, units, shots, command issuer) and the local
## player's RTS view (camera rig, selection, controls, shot view). `AtollLevel` builds on it.

## The team the local player commands.
const PLAYER_TEAM: int = 0
const VISION_STATS: VisionStats = preload("res://tuning/vision_default.tres")

## The part of the ground (x, z) the camera's focus point may move over.
@export var camera_bounds: Rect2 = Rect2(-95.0, -95.0, 190.0, 190.0)
## The map grid's area (x, z): the whole ground.
@export var map_area: Rect2 = Rect2(-100.0, -100.0, 200.0, 200.0)
## The camera's home yaw (degrees; reset returns to it). 0 looks toward -Z, which suits a level laid out north-south.
@export_range(-180.0, 180.0, 1.0) var camera_yaw: float = 0.0
## Looping ambient sound cue for the level (a `SfxCue` id), or none.
@export var ambient_cue: StringName = &""

## Detection: what each team knows of its enemies. Made once the map is built.
var vision: Vision
## What of the enemy the local player's views draw. Made with `vision`.
var fog: FogView
## The ground the local player's team watches (null on a level without heightmap terrain).
var coverage: CoverageMap

@onready var _camera_rig: CameraRig = $CameraRig
@onready var _map: MapGrid = $MapGrid
@onready var _paths: PathService = $PathService
@onready var _shots: Shots = $Shots
@onready var _shot_view: ShotView = $ShotView
@onready var _units: UnitRegistry = $Units
@onready var _issuer: CommandIssuer = $CommandIssuer
@onready var _selection: Selection = $Selection
@onready var _player: RtsPlayer = $RtsPlayer
@onready var _hud: Hud = $Hud
## Optional view nodes: levels without them are silent and have no particle effects.
@onready var _game_sound: GameSound = get_node_or_null("GameSound")
@onready var _combat_effects: CombatEffects = get_node_or_null("CombatEffects")


func _ready() -> void:
	_camera_rig.setup(camera_bounds, camera_yaw)
	_map.air.bounds = map_area
	_issuer.setup(_units)
	_player.setup(PLAYER_TEAM, _selection, _issuer, _camera_rig)
	_shot_view.setup(_shots)
	_hud.setup(_selection, PLAYER_TEAM, map_area, _camera_rig)
	_player.bind_hud(_hud.commands)
	# The ground's collision is only queryable once the physics server has stepped.
	await get_tree().physics_frame
	_build_map()
	_paths.setup(_map)
	_shots.setup(_units)
	_units.setup(_map, _paths, _shots)
	vision = Vision.new()
	vision.name = "Vision"
	add_child(vision)
	vision.setup(_units, _map.terrain, VISION_STATS)
	_units.vision = vision
	fog = FogView.new()
	fog.name = "FogView"
	add_child(fog)
	fog.setup(_units, vision, _issuer.seats, PLAYER_TEAM)
	fog.unit_lost.connect(_selection.end_inspection_of)
	if _map.terrain != null:
		_build_coverage()
	if _game_sound:
		_game_sound.setup(_shots, _units, _issuer, _selection, PLAYER_TEAM)
	if _combat_effects:
		_combat_effects.setup(_shots, _units)
	Sfx.attach_listener(_camera_rig)
	if ambient_cue != &"":
		Sfx.start_ambient(ambient_cue)
		tree_exiting.connect(Sfx.stop_ambient)


## The player's team's coverage over the heightmap and its drawing on the ground, and its last-known marks. Needs `TerrainChunks`, whose chunk
## grid it shares.
func _build_coverage() -> void:
	var chunks: TerrainChunks = get_node_or_null("TerrainChunks")
	if chunks == null:
		return
	coverage = CoverageMap.new()
	coverage.name = "CoverageMap"
	add_child(coverage)
	coverage.setup(vision, _units, _map.terrain, chunks.stats.chunk_cells, VISION_STATS, PLAYER_TEAM)
	var coverage_view := CoverageView.new()
	coverage_view.name = "CoverageView"
	add_child(coverage_view)
	coverage_view.setup(coverage, _issuer.seats, PLAYER_TEAM, VISION_STATS)
	var heat := LastKnownHeat.new()
	heat.name = "LastKnownHeat"
	add_child(heat)
	heat.setup(vision, _issuer.seats, _map.terrain, PLAYER_TEAM, VISION_STATS)
	var ghosts := LastKnownGhosts.new()
	ghosts.name = "LastKnownGhosts"
	add_child(ghosts)
	ghosts.setup(vision, _issuer.seats, _map.terrain, PLAYER_TEAM, VISION_STATS)


## Builds the map grid, on the first physics tick. Levels that computed it earlier publish it here instead.
func _build_map() -> void:
	_map.build(_grid_area())


## The part of the ground (x, z) the map grid covers. Levels whose land is smaller than the map override it.
func _grid_area() -> Rect2:
	return map_area
