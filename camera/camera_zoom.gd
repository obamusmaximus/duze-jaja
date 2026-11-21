class_name CameraZoom
extends Node
## Zooms the camera (its distance from the focus point) and gives the pitch that goes with the distance. Owns the
## target and current distance.

## The distance the camera is heading for, in metres.
var target: float
## The distance now, easing toward `target`.
var distance: float

var _stats: CameraStats


func setup(stats: CameraStats) -> void:
	_stats = stats
	target = _clamp(stats.default_distance)
	distance = target


## Zooms by mouse-wheel notches: positive out, negative in. Each notch is the same fraction of the distance.
func add_notches(notches: float) -> void:
	target = _clamp(target * pow(1.0 + _stats.zoom_step, notches))


func reset() -> void:
	target = _clamp(_stats.default_distance)


func step(delta: float) -> void:
	target = _clamp(target) # The limits can change live in the tuning panel.
	distance = lerpf(distance, target, CameraEase.weight(_stats.zoom_smoothing, delta))


## Degrees down from the horizon for the current distance: `pitch_near` at the closest zoom to `pitch_far` at the
## farthest, shaped by `pitch_curve`.
func pitch() -> float:
	var span: float = _stats.max_distance - _stats.min_distance
	if span <= 0.0:
		return _stats.pitch_far
	var blend: float = clampf((distance - _stats.min_distance) / span, 0.0, 1.0)
	return lerpf(_stats.pitch_near, _stats.pitch_far, pow(blend, _stats.pitch_curve))


func _clamp(value: float) -> float:
	return clampf(value, _stats.min_distance, maxf(_stats.max_distance, _stats.min_distance))
