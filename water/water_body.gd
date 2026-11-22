class_name WaterBody
extends MeshInstance3D
## A sheet of faceted sea (water.gdshader, ported from the sibling project `first`): a subdivided plane the shader
## lifts into waves, with foam and calm water along the shore. Visual only, no collision: the MapGrid reads no ground
## under it, so ground units can't enter it and picking passes through. `setup` takes the shore as rectangles (x, z),
## one per island part or carrier; every `WaterStats` value is applied live. The plane is centred on this node and
## lies at its height. Group: `water`.

## The water's footprint (m), centred on the node.
@export var size: Vector2 = Vector2(600.0, 1200.0)
@export var stats: WaterStats

## The shader's limit on shore rectangles.
const MAX_RECTS: int = 48

var _plane := PlaneMesh.new()
var _material := ShaderMaterial.new()
var _shore: Array[Rect2] = []


func _ready() -> void:
	add_to_group(&"water")
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material.shader = load("res://water/water.gdshader") as Shader
	_plane.size = size
	mesh = _plane
	material_override = _material
	stats.changed.connect(_apply)
	_apply()


## Sets the shore (world x, z rectangles): the foam, the calm and the waves' damping measure from these.
func set_shore(rects: Array[Rect2]) -> void:
	_shore = rects.slice(0, MAX_RECTS)
	_apply_shore()


func _apply_shore() -> void:
	var packed := PackedVector4Array()
	packed.resize(MAX_RECTS)
	for i: int in _shore.size():
		packed[i] = Vector4(_shore[i].position.x, _shore[i].position.y, _shore[i].end.x, _shore[i].end.y)
	_material.set_shader_parameter("shore_rects", packed)
	_material.set_shader_parameter("shore_rect_count", _shore.size())


func _apply() -> void:
	_apply_mesh()
	_apply_shore()
	var values: Dictionary = {
		"wave_count": stats.wave_count,
		"wave_height": stats.wave_height,
		"wavelength": stats.wavelength,
		"wavelength_falloff": stats.wavelength_falloff,
		"height_falloff": stats.height_falloff,
		"wave_direction": deg_to_rad(stats.wave_direction),
		"direction_spread": deg_to_rad(stats.direction_spread),
		"wave_speed": stats.wave_speed,
		"calm_begin": stats.calm_begin,
		"calm_end": stats.calm_end,
		"shore_calm_reach": stats.shore_calm_reach,
		"shore_calm_level": stats.shore_calm_level,
		"deep_color": UiTokens.WORLD_SEA_DEEP,
		"shallow_color": UiTokens.WORLD_SEA_SHALLOW,
		"ramp_steps": stats.ramp_steps,
		"ramp_contrast": stats.ramp_contrast,
		"crest_tint": stats.crest_tint,
		"light_strength": stats.light_strength,
		"facet_amount": stats.facet_amount,
		"foam_color": UiTokens.WORLD_FOAM,
		"foam_width": stats.foam_width,
		"foam_raggedness": stats.foam_raggedness,
		"foam_noise_scale": stats.foam_noise_scale,
		"foam_speed": stats.foam_speed,
		"foam_glow": stats.foam_glow,
		"band_spacing": stats.band_spacing,
		"band_speed": stats.band_speed,
		"band_width": stats.band_width,
		"band_reach": stats.band_reach,
		"band_breakup": stats.band_breakup,
		"glitter_color": UiTokens.WORLD_SUN,
		"glitter_strength": stats.glitter_strength,
		"glitter_threshold": stats.glitter_threshold,
		"lamp_glitter": stats.lamp_glitter,
	}
	for key: String in values:
		_material.set_shader_parameter(key, values[key])


## Subdivides the plane into quads of about `quad_size` and grows the cull box by the highest crest, since the shader
## lifts the vertices above the flat mesh.
func _apply_mesh() -> void:
	var quad: float = maxf(stats.quad_size, 0.5)
	var width: int = maxi(0, ceili(size.x / quad) - 1)
	var depth: int = maxi(0, ceili(size.y / quad) - 1)
	if _plane.subdivide_width != width:
		_plane.subdivide_width = width
	if _plane.subdivide_depth != depth:
		_plane.subdivide_depth = depth
	extra_cull_margin = stats.wave_height / maxf(1.0 - stats.height_falloff, 0.05) + 1.0
