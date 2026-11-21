class_name OrderMarker
extends MeshInstance3D
## Visual only: a ring that shrinks away where an order landed. Runs on real time, like the camera.

const RADIUS: float = 1.0

var _seconds: float = 0.5
var _age: float = 0.0


func setup(color: Color, seconds: float) -> void:
	_seconds = maxf(seconds, 0.01)
	var ring := TorusMesh.new()
	ring.inner_radius = RADIUS * 0.8
	ring.outer_radius = RADIUS
	mesh = ring
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	_age += delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
	var left: float = 1.0 - _age / _seconds
	if left <= 0.0:
		queue_free()
		return
	scale = Vector3.ONE * maxf(left, 0.05)
