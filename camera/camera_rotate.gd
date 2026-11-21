class_name CameraRotate
extends Node
## Turns the camera around the focus point (yaw, degrees). Owns the target and current yaw; both are unwrapped, so
## easing never spins the long way round.

## The yaw the camera is heading for, in degrees. 0 looks toward -Z (north).
var target: float
## The yaw now, easing toward `target`.
var yaw: float

var _stats: CameraStats


func setup(stats: CameraStats) -> void:
	_stats = stats
	target = stats.default_yaw
	yaw = target


## Turns by a mouse movement of `pixels` while the rotate button is held: moving right swings the camera right.
func turn_by_pixels(pixels: Vector2) -> void:
	target += pixels.x * _stats.rotate_per_px


## Turns from the keys: `direction` -1 left, 1 right, for `delta` seconds.
func turn(direction: float, delta: float) -> void:
	target += direction * _stats.rotate_key_speed * delta


## Heads back to `default_yaw` the short way round.
func reset() -> void:
	target += wrapf(_stats.default_yaw - target, -180.0, 180.0)


func step(delta: float) -> void:
	yaw = lerpf(yaw, target, CameraEase.weight(_stats.rotate_smoothing, delta))
