class_name BirdsEyePost
extends Node
## Visual only: the bird's-eye view's post pass (`docs/mechanics/birds_eye.md`): a full-screen quad that tilt-shift
## blurs, sharpens and grades the 3D frame (`birds_eye_post.gdshader`). One quad rides each camera that shows the view
## (the bird's-eye camera and the flight camera) on its own visual layer, which no other camera renders. Both are
## hidden, and so cost nothing, while the flight is under `SHOW_ABOVE` of the way up.

## The visual layer (mask bit) of the quads. Cameras that never show the view drop it from their cull mask.
const LAYER: int = 1 << 20
const SHADER: Shader = preload("res://views/birds_eye/birds_eye_post.gdshader")
const SHOW_ABOVE: float = 0.01

var _stats: BirdsEyeStats
var _material: ShaderMaterial
var _quads: Array[MeshInstance3D] = []
var _blend: float = 0.0


func setup(stats: BirdsEyeStats) -> void:
	_stats = stats
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_stats.changed.connect(_apply_stats)
	_apply_stats()


## Puts a quad on `camera` (the bird's-eye camera, then the flight camera) and lets it render the layer.
func attach(camera: Camera3D) -> void:
	camera.cull_mask |= LAYER
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2.0, 2.0)
	quad.mesh = mesh
	quad.material_override = _material
	quad.layers = LAYER
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.extra_cull_margin = 16384.0
	camera.add_child(quad)
	_quads.append(quad)
	_show(_blend)


## `blend` is 0 in the RTS view and 1 in the bird's-eye view; the effect fades in with it.
func apply_blend(blend: float) -> void:
	_blend = blend
	_material.set_shader_parameter(&"strength", blend)
	_show(blend)


func _show(blend: float) -> void:
	for quad: MeshInstance3D in _quads:
		quad.visible = _stats.post_enabled and blend > SHOW_ABOVE


func _apply_stats() -> void:
	var m: ShaderMaterial = _material
	m.set_shader_parameter(&"band_center", _stats.band_center)
	m.set_shader_parameter(&"band_half", _stats.band_width * 0.5)
	m.set_shader_parameter(&"band_falloff", _stats.band_falloff)
	m.set_shader_parameter(&"far_blur", _stats.far_blur)
	m.set_shader_parameter(&"near_blur", _stats.near_blur)
	m.set_shader_parameter(&"edge_blur", _stats.edge_blur)
	m.set_shader_parameter(&"max_lod", _stats.max_blur_lod)
	m.set_shader_parameter(&"clarity", _stats.clarity)
	m.set_shader_parameter(&"focus_saturation", _stats.focus_saturation)
	m.set_shader_parameter(&"focus_contrast", _stats.focus_contrast)
	m.set_shader_parameter(&"haze_color", Vector3(_stats.haze_color.r, _stats.haze_color.g, _stats.haze_color.b))
	m.set_shader_parameter(&"edge_haze", _stats.edge_haze)
	m.set_shader_parameter(&"edge_desat", _stats.edge_desaturation)
	m.set_shader_parameter(&"vignette", _stats.vignette)
	_show(_blend)
