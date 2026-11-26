class_name BirdsEyeClouds
extends Node3D
## Visual only: the bird's-eye view's clouds and cloud shadows (`docs/mechanics/birds_eye.md`). Two big flat layers
## between the camera and the ground, one shared seamless noise texture, drifting on real time. The layers follow the
## camera's focus but take their pattern from world x, z, so panning shows parallax between them. The same noise, as
## global shader uniforms, darkens the sea and (through a multiply overlay on the chunks) the land, so shadows lie
## under their clouds. Everything is off (hidden, not processed, shadows at strength 0) below `SHOW_ABOVE` of the
## flight, so the RTS view pays nothing.

## The visual layer (mask bit) of the cloud quads: only the bird's-eye and flight cameras render it.
const LAYER: int = 1 << 21
const SHADER: Shader = preload("res://views/birds_eye/cloud.gdshader")
const SHADOW_SHADER: Shader = preload("res://views/birds_eye/cloud_shadow.gdshader")
const SHOW_ABOVE: float = 0.01
const NOISE_SIZE: int = 256
const SNAP: float = 256.0

var _stats: BirdsEyeStats
var _rig: CameraRig
var _chunks: TerrainChunks
var _sun_dir: Vector2 = Vector2.ZERO
## Horizontal metres a shadow lies from its cloud, per metre of cloud height.
var _lean: Vector2 = Vector2.ZERO
var _materials: Array[ShaderMaterial] = []
var _layers: Array[MeshInstance3D] = []
var _shadow_material: ShaderMaterial
var _blend: float = 0.0
## The level's light preset: night cloud colours and weaker shadows.
var _light: LightStats


## `rig` is the bird's-eye rig (the clouds follow its focus), `chunks` the terrain that takes the shadows, `sun` the
## level's sun (the shadows and the fake lighting lean away from it).
func setup(stats: BirdsEyeStats, rig: CameraRig, chunks: TerrainChunks, sun: DirectionalLight3D) -> void:
	_stats = stats
	_rig = rig
	_chunks = chunks
	_read_sun(sun)
	RenderingServer.global_shader_parameter_set(&"cloud_noise", _make_noise())
	RenderingServer.global_shader_parameter_set(&"cloud_shadow_strength", 0.0)
	_shadow_material = ShaderMaterial.new()
	_shadow_material.shader = SHADOW_SHADER
	for i: int in 2:
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.render_priority = 1 # After the post pass (priority 0), so the clouds stay crisp over its blur.
		_materials.append(material)
		var plane := PlaneMesh.new()
		plane.size = Vector2(32000.0, 32000.0)
		var layer := MeshInstance3D.new()
		layer.mesh = plane
		layer.material_override = material
		layer.layers = LAYER
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layer.extra_cull_margin = 16384.0
		add_child(layer)
		_layers.append(layer)
	top_level = true
	stats.changed.connect(_apply_stats)
	_apply_stats()
	_show(0.0)


## The light changed: the shadows and the fake lighting lean away from the sun again, and the colours and shadow
## strength follow the preset.
func set_light(sun: DirectionalLight3D, light: LightStats) -> void:
	_light = light
	_read_sun(sun)
	_apply_stats()


func _read_sun(sun: DirectionalLight3D) -> void:
	var away: Vector3 = sun.global_transform.basis.z # The sun shines along -z; this points toward it.
	_sun_dir = Vector2(away.x, away.z)
	_lean = _sun_dir / maxf(away.y, 0.05)


## Lets `camera` render the clouds.
func attach(camera: Camera3D) -> void:
	camera.cull_mask |= LAYER


## `blend` is 0 in the RTS view and 1 in the bird's-eye view.
func apply_blend(blend: float) -> void:
	_blend = blend
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter(&"strength", blend)
	RenderingServer.global_shader_parameter_set(&"cloud_shadow_strength", _shadow_strength() * blend)
	_show(blend)


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001 # Real time, unaffected by slow time and pause.
	var wind: Vector2 = Vector2.from_angle(deg_to_rad(_stats.wind_direction)) * _stats.wind_speed
	RenderingServer.global_shader_parameter_set(&"cloud_offset", wind * t / _stats.cloud_size)
	var focus: Vector3 = _rig.focus_point()
	var snapped_xz := Vector2(snappedf(focus.x, SNAP), snappedf(focus.z, SNAP))
	for i: int in _layers.size():
		_layers[i].global_position = Vector3(snapped_xz.x, _height(i), snapped_xz.y)


func _height(layer: int) -> float:
	return _stats.cloud_height_low if layer == 0 else _stats.cloud_height_high


func _show(blend: float) -> void:
	var on: bool = _stats.clouds_enabled and blend > SHOW_ABOVE
	_layers[0].visible = on
	_layers[1].visible = on and _stats.second_layer
	set_process(on)
	# The land takes the shadow overlay only while it can be seen.
	_chunks.set_base_overlay(_shadow_material if on and _shadow_strength() > 0.0 else null)
	if not on:
		RenderingServer.global_shader_parameter_set(&"cloud_shadow_strength", 0.0)


func _apply_stats() -> void:
	RenderingServer.global_shader_parameter_set(&"cloud_scale", 1.0 / _stats.cloud_size)
	RenderingServer.global_shader_parameter_set(&"cloud_coverage", _stats.coverage)
	RenderingServer.global_shader_parameter_set(&"cloud_softness", _stats.softness)
	# The cloud that shades a ground point lies toward the sun, by its height times the sun's horizontal lean.
	RenderingServer.global_shader_parameter_set(&"cloud_shadow_shift", _lean * _stats.cloud_height_low)
	var night: bool = _light != null and _light.night
	# The shader takes these as linear values (a Vector3 is not converted), so the palette colours are converted here.
	var lit: Color = UiTokens.WORLD_NIGHT_CLOUD.srgb_to_linear() if night else _stats.cloud_color
	var shade: Color = UiTokens.WORLD_NIGHT_CLOUD_SHADE.srgb_to_linear() if night else _stats.cloud_shade_color
	var sun_uv: Vector2 = _sun_dir.normalized() * _stats.light_reach if _sun_dir.length() > 0.001 else Vector2.ZERO
	for i: int in _materials.size():
		var m: ShaderMaterial = _materials[i]
		m.set_shader_parameter(&"scale_mul", 1.0 if i == 0 else 1.7)
		m.set_shader_parameter(&"offset_mul", Vector2.ONE if i == 0 else Vector2(1.6, 1.3))
		m.set_shader_parameter(&"lit_color", Vector3(lit.r, lit.g, lit.b))
		m.set_shader_parameter(&"shade_color", Vector3(shade.r, shade.g, shade.b))
		m.set_shader_parameter(&"sun_uv", sun_uv)
		m.set_shader_parameter(&"light_gain", _stats.light_gain)
		m.set_shader_parameter(&"opacity", _stats.cloud_opacity * (1.0 if i == 0 else 0.8))
		m.set_shader_parameter(&"edge_bias", _stats.edge_bias)
		m.set_shader_parameter(&"edge_start", _stats.edge_start)
		m.set_shader_parameter(&"fade_near", _stats.fade_near)
		m.set_shader_parameter(&"fade_range", _stats.fade_range)
	RenderingServer.global_shader_parameter_set(&"cloud_shadow_strength", _shadow_strength() * _blend if _layers[0].visible else 0.0)
	_show(_blend)


func _shadow_strength() -> float:
	return _stats.shadow_strength * (_light.cloud_shadow_scale if _light != null else 1.0)


## One seamless tiling noise, made once at load and shared by everything that draws or shades clouds.
func _make_noise() -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.frequency = 0.012
	noise.seed = 7
	var image: Image = noise.get_seamless_image(NOISE_SIZE, NOISE_SIZE, false, false, 0.1, true)
	image.convert(Image.FORMAT_L8)
	return ImageTexture.create_from_image(image)
