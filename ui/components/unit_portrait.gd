class_name UnitPortrait
extends SubViewportContainer
## A unit type's model turning slowly (linear, no easing) in its own small 3D world, seen from above at the RTS
## angle with a flat neutral light, over a transparent background so the panel behind (hatching) shows. View only.

## Turn speed in radians per second.
const TURN_SPEED: float = 0.5
## Camera pitch below the horizontal, in degrees.
const PITCH_DEG: float = 35.0

var _viewport := SubViewport.new()
var _pivot := Node3D.new()
var _camera := Camera3D.new()


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = UiTokens.OFF_WHITE
	environment.ambient_light_energy = 0.6
	var world := WorldEnvironment.new()
	world.environment = environment
	_viewport.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	sun.light_energy = 0.9
	_viewport.add_child(sun)
	_viewport.add_child(_pivot)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_viewport.add_child(_camera)


## Shows `stats`'s model (nothing if it has none) in `team`'s livery, framed by the unit's body size.
func show_unit(stats: UnitStats, team: int = -1) -> void:
	for child: Node in _pivot.get_children():
		child.queue_free()
	if stats.model != null:
		_pivot.add_child(ModelFit.instance(stats.model, stats.model_scale, stats.model_yaw_deg, team))
	var reach: float = maxf(stats.radius * 3.0, stats.height * 2.0)
	_camera.size = reach
	var pitch: float = deg_to_rad(PITCH_DEG)
	var target := Vector3(0.0, stats.height * 0.4, 0.0)
	_camera.position = target + Vector3(0.0, sin(pitch), cos(pitch)) * reach * 4.0
	_camera.rotation = Vector3(-pitch, 0.0, 0.0)


func _process(delta: float) -> void:
	_pivot.rotate_y(TURN_SPEED * delta)
