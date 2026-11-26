class_name WaterBody
extends MeshInstance3D
## A sheet of faceted sea (water.gdshader, ported from the sibling project `first`): a subdivided plane the shader
## lifts into waves, with foam and calm water along the shore. Visual only, no collision: the MapGrid reads no ground
## under it, so ground units can't enter it and picking passes through. `setup` takes the shore as rectangles (x, z),
## one per island part or carrier; every `WaterStats` value is applied live. The plane is centred on this node and
## lies at its height. Group: `water`.
##
## At battlefield size the sea is two parts (`WaterStats.near_size` above 0): a dense patch of `quad_size` quads that
## follows where the camera looks, snapped to the quad grid so the facets hold still, and this node's own coarse flat
## sheet under it for the rest. Waves fade out at the patch's edge, so the two meet without a step.
## `set_shore_field` takes a baked `ShoreField` (a heightmap level) instead of rectangles.

## The water's footprint (m), centred on the node.
@export var size: Vector2 = Vector2(600.0, 1200.0)
@export var stats: WaterStats

## The shader's limit on shore rectangles.
const MAX_RECTS: int = 48
## How far ahead of a low camera the dense patch's centre may lie, as a share of its side.
const LOW_REACH: float = 0.25
## Metres that limit grows per metre the camera rises above that height.
const HIGH_OPENING: float = 4.0

var _plane := PlaneMesh.new()
## The dense patch's material (the node's own is the far sheet's, `_far_material`).
var _material := ShaderMaterial.new()
var _far_material := ShaderMaterial.new()
var _near: MeshInstance3D
var _near_plane := PlaneMesh.new()
var _shore: Array[Rect2] = []
var _field: ShoreField
var _near_centre := Vector2(INF, INF)
## The level's light preset, for the sea's night look; null keeps the day look.
var _light: LightStats


func _ready() -> void:
	add_to_group(&"water")
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := load("res://water/water.gdshader") as Shader
	_material.shader = shader
	_far_material.shader = shader
	_plane.size = size
	mesh = _plane
	material_override = _far_material
	_near = MeshInstance3D.new()
	_near.name = "NearPatch"
	_near.top_level = true
	_near.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_near.mesh = _near_plane
	_near.material_override = _material
	add_child(_near)
	stats.changed.connect(_apply)
	_apply()


## Resizes the sheet (metres, x and z) and re-cuts its quads.
func set_size(new_size: Vector2) -> void:
	size = new_size
	_plane.size = size
	_apply_mesh()


## Sets the shore (world x, z rectangles): the foam, the calm and the waves' damping measure from these.
func set_shore(rects: Array[Rect2]) -> void:
	_shore = rects.slice(0, MAX_RECTS)
	_apply_shore()


## Reads the shore from a baked field (distance, depth) instead of rectangles. Re-bake the field in place on a map
## change; the texture updates itself.
func set_shore_field(field: ShoreField) -> void:
	_field = field
	_apply_shore()


## The sea's colours, glow and glitter follow the level's light preset. Call again when the preset changes.
func set_light(light: LightStats) -> void:
	_light = light
	_apply_light()


func _apply_light() -> void:
	var night: bool = _light != null and _light.night
	var values: Dictionary = {
		"deep_color": UiTokens.WORLD_NIGHT_SEA_DEEP if night else UiTokens.WORLD_SEA_DEEP,
		"shallow_color": UiTokens.WORLD_NIGHT_SEA_SHALLOW if night else UiTokens.WORLD_SEA_SHALLOW,
		"foam_color": UiTokens.WORLD_NIGHT_FOAM if night else UiTokens.WORLD_FOAM,
		"glitter_color": UiTokens.WORLD_NIGHT_MOON if night else UiTokens.WORLD_SUN,
		"body_glow": _light.sea_glow if _light != null else 1.0,
		"foam_glow": stats.foam_glow * (_light.foam_glow_scale if _light != null else 1.0),
		"sun_glitter": _light.glitter_scale if _light != null else 1.0,
	}
	for key: String in values:
		_material.set_shader_parameter(key, values[key])
		_far_material.set_shader_parameter(key, values[key])


func _apply_shore() -> void:
	var packed := PackedVector4Array()
	packed.resize(MAX_RECTS)
	for i: int in _shore.size():
		packed[i] = Vector4(_shore[i].position.x, _shore[i].position.y, _shore[i].end.x, _shore[i].end.y)
	for material: ShaderMaterial in [_material, _far_material]:
		material.set_shader_parameter("shore_rects", packed)
		material.set_shader_parameter("shore_rect_count", _shore.size())
		material.set_shader_parameter("use_field", _field != null)
		if _field != null:
			material.set_shader_parameter("shore_field", _field.texture)
			material.set_shader_parameter("field_origin", _field.origin)
			material.set_shader_parameter("field_texel", _field.texel)


## Whether the sea is a dense patch over a flat sheet.
func _patched() -> bool:
	return stats.near_size > 0.0


func _process(_delta: float) -> void:
	if _patched():
		_follow_camera()


## Centres the dense patch on the ground the camera looks at, snapped to whole quads. A low camera (a cockpit
## looking near the horizon) keeps the patch round itself instead: never farther ahead than `LOW_REACH` of its side,
## a limit that opens up with height. Continuous from looking down to level, so the patch never jumps.
func _follow_camera() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin: Vector3 = camera.global_position
	var forward: Vector3 = -camera.global_basis.z
	var along: float = stats.near_size * 4.0
	if forward.y < -0.01:
		along = minf((global_position.y - origin.y) / forward.y, along)
	var low: float = stats.near_size * LOW_REACH
	var limit: float = low + maxf(origin.y - global_position.y - low, 0.0) * HIGH_OPENING
	var offset: Vector2 = (Vector2(forward.x, forward.z) * along).limit_length(limit)
	var focus := Vector2(origin.x, origin.z) + offset
	var quad: float = maxf(stats.quad_size, 0.5)
	var snapped_focus: Vector2 = (focus / quad).round() * quad
	if snapped_focus == _near_centre:
		return
	_near_centre = snapped_focus
	_near.global_position = Vector3(snapped_focus.x, global_position.y, snapped_focus.y)
	_material.set_shader_parameter("patch_center", snapped_focus)


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
		"ramp_steps": stats.ramp_steps,
		"ramp_contrast": stats.ramp_contrast,
		"crest_tint": stats.crest_tint,
		"light_strength": stats.light_strength,
		"facet_amount": stats.facet_amount,
		"foam_width": stats.foam_width,
		"foam_raggedness": stats.foam_raggedness,
		"foam_noise_scale": stats.foam_noise_scale,
		"foam_speed": stats.foam_speed,
		"band_spacing": stats.band_spacing,
		"band_speed": stats.band_speed,
		"band_width": stats.band_width,
		"band_reach": stats.band_reach,
		"band_breakup": stats.band_breakup,
		"glitter_strength": stats.glitter_strength,
		"glitter_threshold": stats.glitter_threshold,
		"lamp_glitter": stats.lamp_glitter,
	}
	values["field_texel"] = _field.texel if _field != null else 4.0
	values["reef_depth"] = stats.reef_depth
	values["reef_strength"] = stats.reef_strength
	var patched: bool = _patched()
	_near.visible = patched
	_material.set_shader_parameter("patch_half", stats.near_size * 0.5 if patched else 0.0)
	_far_material.set_shader_parameter("wave_gain", 0.0 if patched else 1.0)
	_far_material.set_shader_parameter("vertex_drop", max_trough() if patched else 0.0)
	_near_centre = Vector2(INF, INF)
	for key: String in values:
		_material.set_shader_parameter(key, values[key])
		_far_material.set_shader_parameter(key, values[key])
	_apply_light()


## The deepest trough the waves can make (m): the sum of the wave heights as they fall off.
func max_trough() -> float:
	return stats.wave_height / maxf(1.0 - stats.height_falloff, 0.05)


## Subdivides the plane into quads of about `quad_size` and grows the cull box by the highest crest, since the shader
## lifts the vertices above the flat mesh.
func _apply_mesh() -> void:
	var quad: float = maxf(stats.quad_size, 0.5)
	var sheet: float = maxf(stats.far_quad_size, quad) if _patched() else quad
	var width: int = maxi(0, ceili(size.x / sheet) - 1)
	var depth: int = maxi(0, ceili(size.y / sheet) - 1)
	if _plane.subdivide_width != width:
		_plane.subdivide_width = width
	if _plane.subdivide_depth != depth:
		_plane.subdivide_depth = depth
	_near_plane.size = Vector2.ONE * stats.near_size
	var near_cells: int = maxi(0, ceili(stats.near_size / quad) - 1)
	_near_plane.subdivide_width = near_cells
	_near_plane.subdivide_depth = near_cells
	extra_cull_margin = max_trough() + 1.0
	_near.extra_cull_margin = extra_cull_margin
