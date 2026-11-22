class_name SandboxLevel
extends Node3D
## The sandbox level (the space demo level uses this script too): flat ground with a ramp up to a plateau, a debug
## wall (F3) and a few units of two teams, for testing the groundwork. Wires the match (map grid, paths, units, shots, command issuer) and the local player's RTS
## view (camera rig, selection, controls, shot view).

## The team the local player commands.
const PLAYER_TEAM: int = 0

## The part of the ground (x, z) the camera's focus point may move over.
@export var camera_bounds: Rect2 = Rect2(-95.0, -95.0, 190.0, 190.0)
## The map grid's area (x, z): the whole ground.
@export var map_area: Rect2 = Rect2(-100.0, -100.0, 200.0, 200.0)
## The camera's home yaw (degrees; reset returns to it). 0 looks toward -Z, which suits a level laid out north-south.
@export_range(-180.0, 180.0, 1.0) var camera_yaw: float = 0.0
## Looping ambient sound cue for the level (a `SfxCue` id), or none.
@export var ambient_cue: StringName = &""

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
@onready var _terrain: TerrainMap = get_node_or_null("Terrain")
@onready var _terrain_editor: TerrainEditor = get_node_or_null("TerrainEditor")


func _ready() -> void:
	_camera_rig.setup(camera_bounds, camera_yaw)
	_issuer.setup(_units)
	_player.setup(PLAYER_TEAM, _selection, _issuer, _camera_rig)
	_shot_view.setup(_shots)
	_hud.setup(_selection, PLAYER_TEAM, map_area, _camera_rig)
	# The ground's collision is only queryable once the physics server has stepped.
	await get_tree().physics_frame
	_map.build(_grid_area())
	get_tree().call_group(&"props", "block_in", _map)
	_paths.setup(_map)
	_shots.setup(_units)
	_units.setup(_map, _paths, _shots)
	if _game_sound:
		_game_sound.setup(_shots, _units, _issuer, _selection, PLAYER_TEAM)
	if _combat_effects:
		_combat_effects.setup(_shots, _units)
	Sfx.attach_listener(_camera_rig)
	if ambient_cue != &"":
		Sfx.start_ambient(ambient_cue)
		tree_exiting.connect(Sfx.stop_ambient)
	if _terrain:
		_terrain.changed_area.connect(_on_terrain_changed)
		if _terrain_editor:
			_terrain_editor.setup(_terrain)


## The part of the ground (x, z) the map grid covers. Levels whose land is smaller than the map override it.
func _grid_area() -> Rect2:
	return map_area


## The terrain was edited: once physics has the new shapes, the map grid re-reads the ground there.
func _on_terrain_changed(area: Rect2) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_map.resample(area)
