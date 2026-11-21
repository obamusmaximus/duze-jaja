extends Node3D
## The sandbox level (the space demo level uses this script too): flat ground with a ramp up to a plateau, a debug
## wall (F3) and a few units of two teams, for testing the groundwork. Wires the match (map grid, paths, units, shots, command issuer) and the local player's RTS
## view (camera rig, selection, controls, shot view).

## The part of the ground (x, z) the camera's focus point may move over.
const CAMERA_BOUNDS: Rect2 = Rect2(-95.0, -95.0, 190.0, 190.0)
## The map grid's area (x, z): the whole ground.
const MAP_AREA: Rect2 = Rect2(-100.0, -100.0, 200.0, 200.0)
## The team the local player commands.
const PLAYER_TEAM: int = 0

@onready var _camera_rig: CameraRig = $CameraRig
@onready var _map: MapGrid = $MapGrid
@onready var _paths: PathService = $PathService
@onready var _shots: Shots = $Shots
@onready var _shot_view: ShotView = $ShotView
@onready var _units: UnitRegistry = $Units
@onready var _issuer: CommandIssuer = $CommandIssuer
@onready var _selection: Selection = $Selection
@onready var _player: RtsPlayer = $RtsPlayer


func _ready() -> void:
	_camera_rig.setup(CAMERA_BOUNDS)
	_issuer.setup(_units)
	_player.setup(PLAYER_TEAM, _selection, _issuer, _camera_rig)
	_shot_view.setup(_shots)
	# The ground's collision is only queryable once the physics server has stepped.
	await get_tree().physics_frame
	_map.build(MAP_AREA)
	get_tree().call_group(&"props", "block_in", _map)
	_paths.setup(_map)
	_shots.setup(_units)
	_units.setup(_map, _paths, _shots)
