class_name CameraRig
extends Node3D
## The RTS view's camera (GAME_DESIGN.md, "Camera"): this node sits at the focus point on the ground and turns with
## the yaw; the Camera3D child sits `distance` away along the pitched arm. Each job is a child part (input, pan,
## rotate, zoom, ground follow) owning its own target and current values; this node wires them and places the camera.
##
## A view only: it owns its camera and input and nothing else, and the simulation never reads it. It runs on real
## time, so it keeps full speed while `Engine.time_scale` slows the game. The level calls `setup(bounds)`.

@export var stats: CameraStats

@onready var _camera: Camera3D = $Camera
@onready var _input: CameraInput = $CameraInput
@onready var _pan: CameraPan = $Pan
@onready var _rotate: CameraRotate = $Rotate
@onready var _zoom: CameraZoom = $Zoom
@onready var _ground: CameraGroundFollow = $GroundFollow


func _ready() -> void:
	add_to_group(&"playtest_probe")
	_input.setup(stats)
	_pan.setup(stats, Vector2(global_position.x, global_position.z))
	_rotate.setup(stats)
	_zoom.setup(stats)
	_ground.setup(stats, global_position.y)
	_input.drag_moved.connect(_on_drag_moved)
	_input.rotate_moved.connect(_rotate.turn_by_pixels)
	_input.zoom_notches.connect(_zoom.add_notches)
	_input.reset_pressed.connect(reset)
	_camera.make_current()
	_place()


## Keeps the focus point inside `bounds` (x, z on the ground).
func setup(bounds: Rect2) -> void:
	_pan.set_bounds(bounds)


## Moves the camera to look at `point` (control-group jumps, minimap clicks, alerts).
func focus_on(point: Vector3) -> void:
	_pan.jump_to(Vector2(point.x, point.z))


## Back to the default yaw and zoom; the focus point stays.
func reset() -> void:
	_rotate.reset()
	_zoom.reset()


func get_camera() -> Camera3D:
	return _camera


func _process(delta: float) -> void:
	var real_delta: float = _real_delta(delta)
	_rotate.turn(_input.rotate_direction(), real_delta)
	_pan.move(_input.pan_direction(), _rotate.yaw, _zoom.distance, real_delta)
	_rotate.step(real_delta)
	_zoom.step(real_delta)
	_pan.step(real_delta)
	_ground.step(real_delta)
	_place()


func _physics_process(_delta: float) -> void:
	_ground.sample(get_world_3d().direct_space_state, _pan.current)


func _on_drag_moved(pixels: Vector2) -> void:
	_pan.drag(pixels, _rotate.yaw, _zoom.distance)


func _place() -> void:
	global_position = Vector3(_pan.current.x, _ground.height, _pan.current.y)
	rotation = Vector3(0.0, deg_to_rad(_rotate.yaw), 0.0)
	var pitch: float = deg_to_rad(_zoom.pitch())
	_camera.position = Vector3(0.0, sin(pitch), cos(pitch)) * _zoom.distance
	_camera.rotation = Vector3(-pitch, 0.0, 0.0)
	_camera.fov = stats.fov


## `delta` with the game's time scale taken out, so slowed time doesn't slow the camera.
func _real_delta(delta: float) -> float:
	if Engine.time_scale <= 0.0:
		return delta
	return delta / Engine.time_scale


func playtest_snapshot() -> Dictionary:
	return {
		"focus": global_position, "yaw": _rotate.yaw, "distance": _zoom.distance, "pitch": _zoom.pitch(),
	}
