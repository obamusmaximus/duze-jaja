class_name CameraPan
extends Node
## Moves the rig's focus point over the ground (keys, screen edge, drag, jumps) and keeps it inside the map bounds.
## Owns the target and current focus on the ground plane (x, z); the height is CameraGroundFollow's job.

## Where the focus point is heading (x, z).
var target: Vector2
## Where the focus point is now (x, z), easing toward `target`.
var current: Vector2

var _stats: CameraStats
var _bounds: Rect2
var _has_bounds: bool = false


func setup(stats: CameraStats, start: Vector2) -> void:
	_stats = stats
	target = start
	current = start


## Keeps the focus point inside `bounds` (x, z) from now on.
func set_bounds(bounds: Rect2) -> void:
	_bounds = bounds
	_has_bounds = true
	target = _clamp(target)
	current = _clamp(current)


## Pans by `direction` (x right, y forward on screen, length up to 1) for `delta` seconds.
func move(direction: Vector2, yaw_deg: float, distance: float, delta: float) -> void:
	if direction == Vector2.ZERO:
		return
	target = _clamp(target + _to_ground(direction, yaw_deg) * _stats.pan_speed * _zoom_scale(distance) * delta)


## Pans by a mouse drag of `pixels`. By default the ground follows the mouse (grab); inverted, the camera does.
func drag(pixels: Vector2, yaw_deg: float, distance: float) -> void:
	var screen := Vector2(-pixels.x, pixels.y)
	if _stats.drag_pan_inverted:
		screen = -screen
	target = _clamp(target + _to_ground(screen, yaw_deg) * _stats.drag_pan_per_px * _zoom_scale(distance))


## Flies by a fly-drag `pull` (pixels, x right, y down): speed grows with the pull.
func fly(pull: Vector2, yaw_deg: float, distance: float, delta: float) -> void:
	if pull == Vector2.ZERO:
		return
	var screen := Vector2(pull.x, -pull.y)
	target = _clamp(target + _to_ground(screen, yaw_deg) * _stats.fly_speed_per_px * _zoom_scale(distance) * delta)


## Heads straight for `point` (x, z).
func jump_to(point: Vector2) -> void:
	target = _clamp(point)


func step(delta: float) -> void:
	current = current.lerp(target, CameraEase.weight(_stats.pan_smoothing, delta))


## Screen directions to the ground (x, z) for the camera's yaw: forward at yaw 0 is -z.
func _to_ground(screen: Vector2, yaw_deg: float) -> Vector2:
	var yaw: float = deg_to_rad(yaw_deg)
	var right := Vector2(cos(yaw), -sin(yaw))
	var forward := Vector2(-sin(yaw), -cos(yaw))
	return right * screen.x + forward * screen.y


func _zoom_scale(distance: float) -> float:
	if not _stats.pan_scales_with_zoom:
		return 1.0
	return distance / maxf(_stats.min_distance, 0.01)


func _clamp(point: Vector2) -> Vector2:
	if not _has_bounds:
		return point
	return point.clamp(_bounds.position, _bounds.end)
