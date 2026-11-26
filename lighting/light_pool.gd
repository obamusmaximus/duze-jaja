class_name LightPool
extends MeshInstance3D
## Visual only: a pool of light as a flat additive shape (`light_pool.gdshader`), for the ground under pads and bases.
## It lights nothing: real lights are kept for searchlights. It lies in its own x, z plane, so put it just over a
## flat surface. The light preset sets how bright the pools are (`LightStats.pool_brightness`).

const SHADER: Shader = preload("res://lighting/light_pool.gdshader")

var _material := ShaderMaterial.new()


func _init() -> void:
	_material.shader = SHADER
	_material.render_priority = 1 # After the bird's-eye post pass, like the lamps.
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## `size` is the pool's width and depth (m). `roundness` 1 is an ellipse, near 0 a soft-edged rectangle.
func setup(size: Vector2, color: Color, strength: float, roundness: float = 1.0) -> void:
	var plane := PlaneMesh.new()
	plane.size = size
	mesh = plane
	_material.set_shader_parameter(&"tint", color)
	_material.set_shader_parameter(&"strength", strength)
	_material.set_shader_parameter(&"roundness", roundness)
