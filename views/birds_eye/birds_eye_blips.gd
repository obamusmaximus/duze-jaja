class_name BirdsEyeBlips
extends Control
## Visual only: the unit blips of the bird's-eye view, drawn on screen over the blur and the clouds (units are
## specks from up there; the blips carry them). A figure per squad (square with its member count), unit (small
## square), carryall (triangle) and mothership (hollow square), in the team colour with a black edge, at a fixed
## pixel size. Figures (`StrategyFigures`) are re-read `blip_hz` times a second and re-projected through the current
## camera every frame. Hidden and not processing below `blip_show_blend` of the flight.

const EDGE: float = 2.0

var _stats: BirdsEyeStats
var _units: UnitRegistry
var _figures := StrategyFigures.new()
var _clock: float = INF
var _font: Font
## The edge round each mark: black on the day's pale map, light by night, when a black edge is lost in the dark.
var _edge: Color = UiTokens.BLACK


func setup(stats: BirdsEyeStats) -> void:
	_stats = stats
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_font(&"font", &"LabelNumberDark")
	apply_blend(0.0)


func set_night(night: bool) -> void:
	_edge = UiTokens.OFF_WHITE if night else UiTokens.BLACK


## Fades in over the top of the flight; off (no processing) below `blip_show_blend`.
func apply_blend(blend: float) -> void:
	var shown: float = smoothstep(_stats.blip_show_blend, 1.0, blend)
	visible = shown > 0.0
	modulate.a = shown
	process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	_clock += delta
	if _clock >= 1.0 / _stats.blip_hz:
		_clock = 0.0
		if _units == null:
			_units = get_tree().get_first_node_in_group(&"unit_registry") as UnitRegistry
		_figures.collect(_units, get_tree())
	queue_redraw()


func _draw() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var screen := Rect2(Vector2.ZERO, size)
	var base: float = _stats.blip_size
	for i: int in _figures.size():
		var world: Vector3 = _figures.positions[i]
		if camera.is_position_behind(world):
			continue
		var at: Vector2 = camera.unproject_position(world)
		if not screen.grow(base * 4.0).has_point(at):
			continue
		var color: Color = UiTokens.team_color(_figures.teams[i])
		var level: float = _figures.levels[i]
		color.a = level
		match _figures.kinds[i]:
			StrategyFigures.Kind.UNIT:
				_square(at, base, color)
			StrategyFigures.Kind.SQUAD:
				_square(at, base * _stats.squad_blip_scale, color)
				if _figures.counts[i] > 1:
					_count(at, base * _stats.squad_blip_scale, _figures.counts[i], level)
			StrategyFigures.Kind.CARRYALL:
				_triangle(at, base * _stats.carryall_blip_scale, color)
			StrategyFigures.Kind.MOTHERSHIP:
				var side: float = base * _stats.ship_blip_scale
				var rect := Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side)
				draw_rect(rect.grow(EDGE), _edge, false, EDGE * 2.0)
				draw_rect(rect, color, false, EDGE * 1.5)


func _square(at: Vector2, side: float, color: Color) -> void:
	var rect := Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	draw_rect(rect.grow(EDGE), Color(_edge, color.a))
	draw_rect(rect, color)


func _triangle(at: Vector2, side: float, color: Color) -> void:
	var half: float = side * 0.5
	var edge := PackedVector2Array([at + Vector2(0, -half - EDGE * 2.0), at + Vector2(half + EDGE * 2.0, half + EDGE),
			at + Vector2(-half - EDGE * 2.0, half + EDGE)])
	draw_colored_polygon(edge, Color(_edge, color.a))
	draw_colored_polygon(PackedVector2Array([at + Vector2(0, -half), at + Vector2(half, half), at + Vector2(-half, half)]), color)


## The squad's member count beside its square.
func _count(at: Vector2, side: float, members: int, level: float) -> void:
	var font_size: int = UiTokens.TEXT_SMALL / 2
	var origin := at + Vector2(side * 0.5 + EDGE * 2.0, font_size * 0.35)
	draw_string_outline(_font, origin, str(members), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(UiTokens.BLACK, level))
	draw_string(_font, origin, str(members), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(UiTokens.OFF_WHITE, level))
