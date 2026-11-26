class_name WorldLight
extends Node3D
## Visual only: a level's light and air, built from a shared `LightStats` preset (style guide, prototyping rule 9):
## the sun (or moon), the sky or void behind the map, the ambient light, the haze that distance fades into, and the filmic
## exposure. Colours come from the palette (`UiTokens.WORLD_*`). Every level instances this scene once instead of
## its own WorldEnvironment and sun; edits to the preset apply live.

## The preset was applied again (another one, or a live edit): copies of the environment and anything that follows the
## sun's direction should refresh.
signal applied

const NIGHT_SKY: Shader = preload("res://lighting/night_sky.gdshader")

@export var stats: LightStats

var _environment := Environment.new()
var _sky_material := ProceduralSkyMaterial.new()
var _sky := Sky.new()
## The night sky: the same gradient, with stars.
var _night_sky := ShaderMaterial.new()
var _sun := DirectionalLight3D.new()


func _ready() -> void:
	_night_sky.shader = NIGHT_SKY
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	_sky_material.sun_angle_max = 0.0
	var world := WorldEnvironment.new()
	world.environment = _environment
	add_child(world)
	_sun.name = "Sun"
	_sun.shadow_enabled = true
	add_child(_sun)
	stats.changed.connect(_apply)
	_apply()


## Swaps the whole preset.
func use_preset(preset: LightStats) -> void:
	if preset == stats:
		return
	stats.changed.disconnect(_apply)
	stats = preset
	stats.changed.connect(_apply)
	_apply()


## The level's environment, for a view that wants its own copy (the bird's-eye camera).
func environment() -> Environment:
	return _environment


## The sun, for effects that lean away from it (the bird's-eye clouds).
func sun() -> DirectionalLight3D:
	return _sun


## Turns the sun's shadows on or off (the bird's-eye view sees kilometres, beyond the shadow map).
func set_shadows(enabled: bool) -> void:
	_sun.shadow_enabled = enabled


func _apply() -> void:
	var sky: Color = UiTokens.WORLD_NIGHT_SKY if stats.night else UiTokens.WORLD_SKY
	var haze: Color = UiTokens.WORLD_NIGHT_HAZE if stats.night else UiTokens.WORLD_HAZE
	_sky_material.sky_top_color = sky
	_sky_material.sky_horizon_color = haze
	_sky_material.ground_horizon_color = haze
	_sky_material.ground_bottom_color = sky
	if stats.night:
		_apply_night_sky(sky, haze)
	_sky.sky_material = _night_sky if stats.night else _sky_material
	_environment.ambient_light_color = UiTokens.WORLD_NIGHT_AMBIENT if stats.night else UiTokens.WORLD_HAZE
	_sun.light_color = UiTokens.WORLD_NIGHT_MOON if stats.night else UiTokens.WORLD_SUN
	RenderingServer.global_shader_parameter_set(&"terrain_shadow_strength", stats.terrain_shadow)
	RenderingServer.global_shader_parameter_set(&"terrain_shadow_sea", stats.terrain_shadow_sea)
	RenderingServer.global_shader_parameter_set(&"lamp_brightness", stats.lamp_brightness)
	RenderingServer.global_shader_parameter_set(&"pool_brightness", stats.pool_brightness)
	_sun.rotation_degrees = Vector3(-stats.sun_elevation, stats.sun_direction, 0.0)
	_sun.light_energy = stats.sun_energy
	_sun.shadow_blur = stats.shadow_blur
	# Without a sky the environment holds none: the Compatibility renderer would still tint the haze with it.
	_environment.sky = _sky if stats.sky else null
	if stats.sky:
		_environment.background_mode = Environment.BG_SKY
	else:
		_environment.background_mode = Environment.BG_COLOR
		_environment.background_color = UiTokens.WORLD_VOID
	_environment.ambient_light_energy = stats.ambient_energy
	_environment.fog_enabled = stats.haze_density > 0.0
	_environment.fog_density = stats.haze_density
	_environment.fog_sky_affect = stats.haze_sky_affect
	# With no sky, distance fades into the void, not a haze that isn't there.
	_environment.fog_light_color = haze if stats.sky else UiTokens.WORLD_VOID
	_environment.tonemap_exposure = stats.exposure
	_environment.tonemap_white = stats.white
	applied.emit()


func _apply_night_sky(top: Color, horizon: Color) -> void:
	_night_sky.set_shader_parameter(&"top_color", top)
	_night_sky.set_shader_parameter(&"horizon_color", horizon)
	_night_sky.set_shader_parameter(&"top_curve", _sky_material.sky_curve)
	_night_sky.set_shader_parameter(&"bottom_curve", _sky_material.ground_curve)
	_night_sky.set_shader_parameter(&"star_color", UiTokens.WORLD_NIGHT_STAR)
	_night_sky.set_shader_parameter(&"star_density", stats.star_density)
	_night_sky.set_shader_parameter(&"star_brightness", stats.star_brightness)
	_night_sky.set_shader_parameter(&"star_size", stats.star_size)
