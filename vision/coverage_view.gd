class_name CoverageView
extends Node
## Visual only: shows a team's coverage (`CoverageMap`) on the ground in the commander views. Unwatched ground darkens
## under a fine, faint wireframe (hairlines, corner crosses, a contour at the edge of watched ground); in first person
## (the team has a pilot) it is off. It sets parameters on the ground material (`WorldMaterials.ground`) and reads the
## simulation, never changes it.

const LINE_COLOR: Color = UiTokens.HUD_LINE

var _map: CoverageMap
var _seats: PilotSeats
var _team: int = 0
var _stats: VisionStats
## The last two published sweeps; the ground fades from `_from` to `_to` over `_fade_time`.
var _from: ImageTexture
var _to: ImageTexture
## Seconds since `_to` arrived, and the fade's length.
var _age: float = 0.0
var _fade_time: float = 0.0
## Whether the grid shows now (1.0) or not (0.0); -1 before the first frame.
var _shown: float = -1.0


func setup(map: CoverageMap, seats: PilotSeats, team: int, stats: VisionStats) -> void:
	_map = map
	_seats = seats
	_team = team
	_stats = stats
	_map.changed.connect(_on_map_changed)
	_stats.changed.connect(_apply)
	_on_map_changed()


func _process(delta: float) -> void:
	var fading: bool = _age < _fade_time
	_age += delta
	if fading:
		_set_blend()
	var show: float = 0.0 if _seats.unit_id_of(_team) != 0 else 1.0
	if show != _shown:
		_shown = show
		_apply()


## A new sweep (or a new grid): fade to it from the one before, over the time it took to arrive, so the edge of
## watched ground slides without stopping and the fade is done by about the next sweep.
func _on_map_changed() -> void:
	_from = _to if _to != null and _map.texture != null else _map.texture
	_to = _map.texture
	_fade_time = minf(_age, _stats.coverage_fade)
	_age = 0.0
	_apply()


func _set_blend() -> void:
	var blend: float = 1.0 if _fade_time <= 0.0 else clampf(_age / _fade_time, 0.0, 1.0)
	for role: WorldMaterials.Role in WorldMaterials.Role.values():
		WorldMaterials.ground(role).set_shader_parameter(&"coverage_blend", blend)


## Sets the ground materials' coverage parameters from the map and the settings.
func _apply() -> void:
	var area := Vector4(_map.origin.x, _map.origin.y, _map.cells.x * _map.cell, _map.cells.y * _map.cell)
	for role: WorldMaterials.Role in WorldMaterials.Role.values():
		var material: ShaderMaterial = WorldMaterials.ground(role)
		material.set_shader_parameter(&"coverage_map", _to)
		material.set_shader_parameter(&"coverage_map_from", _from)
		material.set_shader_parameter(&"coverage_area", area)
		material.set_shader_parameter(&"coverage_cell", _map.block)
		material.set_shader_parameter(&"coverage_show", maxf(_shown, 0.0))
		material.set_shader_parameter(&"coverage_dim", _stats.coverage_dim)
		material.set_shader_parameter(&"coverage_divisions", float(_stats.coverage_divisions))
		material.set_shader_parameter(&"coverage_line", _stats.coverage_line)
		material.set_shader_parameter(&"coverage_tick", _stats.coverage_tick)
		material.set_shader_parameter(&"coverage_edge", _stats.coverage_edge)
		material.set_shader_parameter(&"coverage_line_color", LINE_COLOR)
	_set_blend()
