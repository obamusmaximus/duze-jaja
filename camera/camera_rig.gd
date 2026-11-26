class_name CameraRig
extends Node3D
## The RTS view's camera (GAME_DESIGN.md, "Camera"): this node sits at the focus point on the ground and turns with
## the yaw; the Camera3D child sits `distance` away along the pitched arm. Each job is a child part (input, pan,
## rotate, zoom, ground follow) owning its own target and current values; this node wires them and places the camera.
##
## A view only: it owns its camera and input and nothing else, and the simulation never reads it. It runs on real
## time, so it keeps full speed while `Engine.time_scale` slows the game. The level calls `setup(bounds, home_yaw)`.


@export var stats: CameraStats

@onready var _camera: Camera3D = $Camera
@onready var _input: CameraInput = $CameraInput
@onready var _pan: CameraPan = $Pan
@onready var _rotate: CameraRotate = $Rotate
@onready var _zoom: CameraZoom = $Zoom
@onready var _ground: CameraGroundFollow = $GroundFollow

## Off for a rig that floats over no ground (the bird's-eye one): the focus keeps the height the rig was placed at.
var follow_ground: bool = true
var _base_far: float = 0.0


func _ready() -> void:
	add_to_group(&"playtest_probe")
	_input.setup(stats)
	_pan.setup(stats, Vector2(global_position.x, global_position.z))
	_rotate.setup(stats)
	_zoom.setup(stats)
	_ground.setup(stats, global_position.y)
	_input.drag_moved.connect(_on_drag_moved)
	_input.rotate_moved.connect(_rotate.turn_by_pixels)
	_input.zoom_notches.connect(_on_zoom_notches)
	_input.reset_pressed.connect(reset)
	_base_far = _camera.far
	if stats.drag_mode == CameraStats.DragMode.FLY:
		var layer := CanvasLayer.new()
		layer.layer = 7 # Over the world, under the HUD.
		add_child(layer)
		var arrow := CameraFlyArrow.new()
		layer.add_child(arrow)
		arrow.setup(_input)
	_camera.make_current()
	_place()


## Keeps the focus point inside `bounds` (x, z on the ground), and sets the yaw that reset returns to (degrees; 0
## looks toward -Z, so a level laid out along X starts at -90 or 90).
func setup(bounds: Rect2, home_yaw: float) -> void:
	_pan.set_bounds(bounds)
	_rotate.set_home(home_yaw)


## Moves the camera to look at `point` (control-group jumps, minimap clicks, alerts); `instant` skips the easing.
func focus_on(point: Vector3, instant: bool = false) -> void:
	_pan.jump_to(Vector2(point.x, point.z))
	if instant:
		_pan.current = _pan.target


## The focus point's x and z (with the ground height the rig stands at).
func focus_point() -> Vector3:
	return Vector3(_pan.current.x, global_position.y, _pan.current.y)


## The camera's distance from the focus point now.
func distance() -> float:
	return _zoom.distance


## The yaw now, degrees.
func yaw() -> float:
	return _rotate.yaw


## Sets the yaw (degrees) without easing.
func set_yaw(degrees: float) -> void:
	_rotate.target = degrees
	_rotate.yaw = degrees


## Places the camera now (a rig that is off isn't processed, so a view that flies to it calls this first).
func refresh() -> void:
	_place()


## Sets the zoom (clamped to the limits) without easing.
func set_distance(value: float) -> void:
	_zoom.target = value
	_zoom.step(0.0)
	_zoom.distance = _zoom.target


## Turns the view on or off: an off rig ignores input and does not move; the camera of the one that is on is current.
func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if active:
		_camera.make_current()


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
	_pan.fly(_input.fly_pull(), _rotate.yaw, _zoom.distance, real_delta)
	_rotate.step(real_delta)
	_zoom.step(real_delta)
	_pan.step(real_delta)
	_ground.step(real_delta)
	_place()


func _physics_process(_delta: float) -> void:
	if follow_ground:
		_ground.sample(get_world_3d().direct_space_state, _pan.current)


## Zooms; where `zoom_to_cursor` is on, the focus moves so the ground point under the cursor stays under it.
func _on_zoom_notches(notches: float) -> void:
	if not stats.zoom_to_cursor:
		_zoom.add_notches(notches)
		return
	var before: float = _zoom.target
	var point: Vector2 = _pan.target + _cursor_offset(before)
	_zoom.add_notches(notches)
	var shift: Vector2 = _cursor_offset(_zoom.target)
	if point.is_finite() and shift.is_finite():
		_pan.jump_to(point - shift)


## Where the ground under the cursor lies relative to the focus (x, z, world axes) with the camera `at_distance` out
## and the current yaw, on the plane through the focus; INF if the cursor ray misses it.
func _cursor_offset(at_distance: float) -> Vector2:
	var view: Rect2 = _camera.get_viewport().get_visible_rect()
	var mouse: Vector2 = _camera.get_viewport().get_mouse_position()
	var ndc := Vector2((mouse.x - view.position.x) / view.size.x * 2.0 - 1.0,
			1.0 - (mouse.y - view.position.y) / view.size.y * 2.0)
	var tan_half: float = tan(deg_to_rad(stats.fov) * 0.5)
	var ray := Vector3(ndc.x * tan_half * view.size.x / view.size.y, ndc.y * tan_half, -1.0)
	var pitch: float = deg_to_rad(_zoom.pitch_at(at_distance))
	var dir := Vector3(ray.x, ray.y * cos(pitch) + ray.z * sin(pitch), -ray.y * sin(pitch) + ray.z * cos(pitch))
	if dir.y >= -0.001:
		return Vector2.INF
	var cam := Vector3(0.0, sin(pitch), cos(pitch)) * at_distance
	var hit: Vector3 = cam + dir * (-cam.y / dir.y)
	var yaw: float = deg_to_rad(_rotate.yaw)
	return Vector2(hit.x * cos(yaw) + hit.z * sin(yaw), -hit.x * sin(yaw) + hit.z * cos(yaw))


func _on_drag_moved(pixels: Vector2) -> void:
	_pan.drag(pixels, _rotate.yaw, _zoom.distance)


func _place() -> void:
	global_position = Vector3(_pan.current.x, _ground.height, _pan.current.y)
	rotation = Vector3(0.0, deg_to_rad(_rotate.yaw), 0.0)
	var pitch: float = deg_to_rad(_zoom.pitch())
	_camera.position = Vector3(0.0, sin(pitch), cos(pitch)) * _zoom.distance
	_camera.rotation = Vector3(-pitch, 0.0, 0.0)
	_camera.fov = stats.fov
	_camera.far = maxf(_base_far, _zoom.distance * stats.far_per_distance)
	_camera.near = maxf(0.1, _zoom.distance * stats.near_per_distance)


## `delta` with the game's time scale taken out, so slowed time doesn't slow the camera.
func _real_delta(delta: float) -> float:
	if Engine.time_scale <= 0.0:
		return delta
	return delta / Engine.time_scale


func playtest_snapshot() -> Dictionary:
	return {
		"focus": global_position, "yaw": _rotate.yaw, "distance": _zoom.distance, "pitch": _zoom.pitch(),
	}
