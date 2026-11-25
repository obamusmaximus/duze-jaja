class_name HeightBands
extends Node
## Debug: `debug_height_bands` (9) draws the ground in height colours with a contour line every `contour_interval`
## metres and a line at the waterline, over the heightmap chunks (`TerrainChunks.set_overlay`), so slopes and the
## shore read while painting. Colours come from `UiTokens`; the interval and top height from `HeightmapStats`.

const SHADER: Shader = preload("res://debug/heightmap_io/height_bands.gdshader")

var _chunks: TerrainChunks
var _stats: HeightmapStats
var _material := ShaderMaterial.new()
var _shown: bool = false


func setup(chunks: TerrainChunks, stats: HeightmapStats) -> void:
	_chunks = chunks
	_stats = stats
	_material.shader = SHADER
	_material.set_shader_parameter(&"sea_color", UiTokens.CYAN)
	_material.set_shader_parameter(&"low_color", UiTokens.GREEN)
	_material.set_shader_parameter(&"mid_color", UiTokens.BONE)
	_material.set_shader_parameter(&"high_color", UiTokens.OFF_WHITE)
	_material.set_shader_parameter(&"line_color", UiTokens.BLACK)
	_material.set_shader_parameter(&"shore_color", UiTokens.ORANGE)
	_stats.changed.connect(_apply)
	_apply()


func _apply() -> void:
	_material.set_shader_parameter(&"interval", _stats.contour_interval)
	_material.set_shader_parameter(&"band_top", _stats.band_top)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_height_bands"):
		get_viewport().set_input_as_handled()
		_shown = not _shown
		_chunks.set_overlay(_material if _shown else null)
