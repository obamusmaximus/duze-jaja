class_name CockpitFeel
extends RefCounted
## What the flight does to the pilot's view: the field of view widens with speed, and the camera shakes at high speed
## and buffets as the wing nears and passes its stall. Reads the flight, writes `fov_gain` and `shake` for the
## cockpit camera. View side.

## Degrees to add to the cockpit's field of view.
var fov_gain: float = 0.0
## A small turn to put on the camera.
var shake := Basis.IDENTITY

var _stats: CockpitStats
var _noise := FastNoiseLite.new()
var _amount: float = 0.0
var _time: float = 0.0


func setup(stats: CockpitStats) -> void:
	_stats = stats
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0


## A new flight starts at its own speed, not by zooming there.
func start(flight: PilotFlight) -> void:
	_amount = 0.0
	shake = Basis.IDENTITY
	fov_gain = _fov_target(flight.model) if flight != null else 0.0


func step(delta: float, flight: PilotFlight) -> void:
	if flight == null:
		return
	var model: PilotModel = flight.model
	fov_gain = lerpf(fov_gain, _fov_target(model), 1.0 - exp(-_stats.speed_fov_response * delta))
	_amount = lerpf(_amount, _shake_target(model), 1.0 - exp(-_stats.shake_response * delta))
	_time += delta * _stats.shake_frequency
	var size: float = deg_to_rad(_amount)
	# Three far-apart rows of the same noise, so the axes move on their own. Roll shows most, so it gets less.
	shake = Basis.from_euler(Vector3(_noise.get_noise_2d(_time, 0.0), _noise.get_noise_2d(_time, 31.7),
			_noise.get_noise_2d(_time, 73.1) * 0.5) * size)


func _fov_target(model: PilotModel) -> float:
	return _stats.speed_fov_gain * _ramp(_pace(model), _stats.speed_fov_from, _stats.speed_fov_to)


## Degrees of shake: speed and buffet together.
func _shake_target(model: PilotModel) -> float:
	var buffet: float = 1.0 if model.stalled else _ramp(model.stall_load(), _stats.shake_stall_from, 1.0)
	return _stats.shake_speed * _ramp(_pace(model), _stats.shake_speed_from, _stats.shake_speed_to) \
		+ _stats.shake_stall * buffet


## Speed as a share of the type's level top speed.
func _pace(model: PilotModel) -> float:
	return model.velocity.length() / model.top_speed()


## 0 at `from` and below, 1 at `to` and above (also when a tuned `to` isn't above `from`).
func _ramp(value: float, from: float, to: float) -> float:
	return smoothstep(from, maxf(to, from + 0.001), value)
