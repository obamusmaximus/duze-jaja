class_name ViewTransition
extends Node
## View side: the flight between two views' cameras (`docs/mechanics/birds_eye.md`). It owns a transition `Camera3D`
## that sits between a `from` camera (blend 0) and a `to` camera (blend 1), easing its position, rotation, field of
## view and clip planes; the cameras it blends are held still while it flies. `blend` moves toward its goal at a
## constant rate on real time, and the pose is an eased function of it, so reversing mid-flight turns round from the
## current pose with no snap. Off (no processing) when it isn't flying.

## `blend` changed; the flight is over once `finished` fires.
signal blend_changed(blend: float)
signal finished(reached_end: bool)

## Seconds for a full flight.
var duration: float = 1.6
## 0 at the `from` camera, 1 at the `to` camera.
var blend: float = 0.0

var camera: Camera3D
var _from: Camera3D
var _to: Camera3D
var _goal: float = 0.0
var _environment := Environment.new()
var _from_environment: Environment
var _to_environment: Environment


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "FlightCamera"
	camera.top_level = true
	add_child(camera)
	camera.environment = _environment
	set_process(false)


## Whether a flight is under way.
func flying() -> bool:
	return is_processing()


## Sets the two cameras to blend between (their environments are blended too).
func set_ends(from: Camera3D, to: Camera3D, from_environment: Environment, to_environment: Environment) -> void:
	_from = from
	_to = to
	_from_environment = from_environment
	_to_environment = to_environment
	camera.cull_mask = from.cull_mask
	camera.keep_aspect = from.keep_aspect


## Starts flying toward `goal` (0 or 1) from the current `blend`; flying already, it simply turns round.
func fly_to(goal: float) -> void:
	_goal = goal
	camera.make_current()
	set_process(true)
	_apply()


## Jumps to `value` at once and stops.
func settle(value: float) -> void:
	blend = value
	_goal = value
	set_process(false)
	_apply()


func _process(delta: float) -> void:
	var real_delta: float = delta if Engine.time_scale <= 0.0 else delta / Engine.time_scale
	blend = move_toward(blend, _goal, real_delta / maxf(duration, 0.01))
	_apply()
	blend_changed.emit(blend)
	if is_equal_approx(blend, _goal):
		blend = _goal
		set_process(false)
		finished.emit(is_equal_approx(_goal, 1.0))


func _apply() -> void:
	var t: float = smoothstep(0.0, 1.0, blend)
	var a: Transform3D = _from.global_transform
	var b: Transform3D = _to.global_transform
	camera.global_transform = Transform3D(a.basis.get_rotation_quaternion().slerp(b.basis.get_rotation_quaternion(), t), a.origin.lerp(b.origin, t))
	camera.fov = lerpf(_from.fov, _to.fov, t)
	# Clip planes blend in log space, so the near plane never jumps through the scene.
	camera.near = exp(lerpf(log(_from.near), log(_to.near), t))
	camera.far = exp(lerpf(log(_from.far), log(_to.far), t))
	_blend_environment(t)


func _blend_environment(t: float) -> void:
	var from: Environment = _from_environment
	var to: Environment = _to_environment
	if from == null or to == null:
		return
	_environment.background_mode = from.background_mode if t < 0.5 else to.background_mode
	_environment.sky = from.sky
	_environment.background_color = from.background_color
	_environment.tonemap_mode = from.tonemap_mode
	_environment.tonemap_exposure = from.tonemap_exposure
	_environment.tonemap_white = from.tonemap_white
	_environment.ambient_light_source = from.ambient_light_source
	_environment.ambient_light_color = from.ambient_light_color
	_environment.ambient_light_energy = from.ambient_light_energy
	_environment.fog_enabled = from.fog_enabled or to.fog_enabled
	_environment.fog_mode = from.fog_mode
	_environment.fog_light_color = from.fog_light_color
	_environment.fog_sky_affect = from.fog_sky_affect
	_environment.fog_density = lerpf(from.fog_density, to.fog_density, t)
	_environment.adjustment_enabled = true
	_environment.adjustment_contrast = lerpf(1.0 if not from.adjustment_enabled else from.adjustment_contrast, to.adjustment_contrast, t)
	_environment.adjustment_saturation = lerpf(1.0 if not from.adjustment_enabled else from.adjustment_saturation, to.adjustment_saturation, t)
	_environment.adjustment_brightness = lerpf(1.0 if not from.adjustment_enabled else from.adjustment_brightness, to.adjustment_brightness, t)
	_environment.glow_enabled = to.glow_enabled and t > 0.5
