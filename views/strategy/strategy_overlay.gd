class_name StrategyOverlay
extends Control
## Visual only: what the strategy views (bird's-eye, war table) draw on screen above the world and below the HUD:
## the team's map markers, the outlines ("strategy outline") of the selected and the hovered figure, and a ghost of
## the armed marker under the cursor. Figures (`StrategyFigures`) are re-read by `StrategyControl`; positions are
## re-projected every frame through the `StrategyProjector`, so everything sticks to the map while the camera moves.

const EDGE: float = 2.0

var figures := StrategyFigures.new()
## The figure under the cursor (an index into `figures`), or -1.
var hover_index: int = -1

var _stats: StrategyControlStats
var _projector: StrategyProjector
var _selection: Selection
var _markers: MapMarkers
var _tools: StrategyTools
var _team: int = 0
var _units: UnitRegistry
var _font: Font


func setup(stats: StrategyControlStats, projector: StrategyProjector, selection: Selection, markers: MapMarkers,
		tools: StrategyTools, team: int) -> void:
	_stats = stats
	_projector = projector
	_selection = selection
	_markers = markers
	_tools = tools
	_team = team
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_font(&"font", &"LabelNumberDark")


## Re-reads the figures from the unit registry.
func refresh() -> void:
	if _units == null:
		_units = get_tree().get_first_node_in_group(&"unit_registry") as UnitRegistry
	figures.collect(_units, get_tree())


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	for marker: MapMarker in _markers.of_team(_team):
		var at: Vector2 = _projector.to_screen(get_viewport(), marker.position)
		if at.is_finite():
			_glyph(marker.kind, at, 1.0)
	var chosen: PackedInt32Array = _selection.ids()
	for i: int in figures.size():
		var selected: bool = false
		for id: int in figures.members[i]:
			if chosen.has(id):
				selected = true
				break
		if selected or i == hover_index:
			_outline(i, UiTokens.ORANGE if selected else UiTokens.OFF_WHITE)
	if _tools.armed != -1 and get_viewport().gui_get_hovered_control() == null:
		_glyph(_tools.armed as MapMarker.Kind, get_viewport().get_mouse_position(), 0.55)


## Corner brackets round a figure: a squad's bounds are its members' bounds, anything else a fixed-size box.
func _outline(index: int, color: Color) -> void:
	var at: Vector2 = _projector.to_screen(get_viewport(), figures.positions[index])
	if not at.is_finite():
		return
	var min_side: float = _stats.outline_min_px
	if figures.kinds[index] == StrategyFigures.Kind.MOTHERSHIP:
		min_side *= 1.8
	var rect := Rect2(at - Vector2.ONE * min_side * 0.5, Vector2.ONE * min_side)
	if figures.kinds[index] == StrategyFigures.Kind.SQUAD and _units != null:
		var bounds := Rect2(at, Vector2.ZERO)
		for id: int in figures.members[index]:
			var unit: Unit = _units.get_unit(id)
			var point: Vector2 = _projector.to_screen(get_viewport(), unit.global_position) if unit else Vector2.INF
			if point.is_finite():
				bounds = bounds.expand(point)
		rect = rect.merge(bounds.grow(_stats.outline_pad_px))
	var arm: float = minf(rect.size.x, rect.size.y) * _stats.bracket_share
	for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var sx: float = 1.0 if corner.x == rect.position.x else -1.0
		var sy: float = 1.0 if corner.y == rect.position.y else -1.0
		var line := PackedVector2Array([corner + Vector2(sx * arm, 0.0), corner, corner + Vector2(0.0, sy * arm)])
		draw_polyline(line, UiTokens.BLACK, _stats.outline_width + EDGE * 2.0)
		draw_polyline(line, color, _stats.outline_width)


func marker_color(kind: MapMarker.Kind) -> Color:
	match kind:
		MapMarker.Kind.ATTACK:
			return UiTokens.ORANGE
		MapMarker.Kind.GUARD:
			return UiTokens.CYAN
		MapMarker.Kind.GATHER:
			return UiTokens.GREEN
		MapMarker.Kind.SCOUT:
			return UiTokens.VIOLET
	return UiTokens.OFF_WHITE


## A marker's glyph: attack a crosshair, guard a diamond, gather a ring with ticks, scout a triangle, LZ a square.
func _glyph(kind: MapMarker.Kind, at: Vector2, alpha: float) -> void:
	var r: float = _stats.marker_radius_px
	var color: Color = marker_color(kind)
	color.a = alpha
	var shape := PackedVector2Array()
	var ticks: Array[PackedVector2Array] = []
	match kind:
		MapMarker.Kind.ATTACK:
			shape = _circle(at, r)
			ticks = [PackedVector2Array([at + Vector2(-r * 1.4, 0), at + Vector2(-r * 0.4, 0)]), PackedVector2Array([at + Vector2(r * 0.4, 0), at + Vector2(r * 1.4, 0)]),
				PackedVector2Array([at + Vector2(0, -r * 1.4), at + Vector2(0, -r * 0.4)]), PackedVector2Array([at + Vector2(0, r * 0.4), at + Vector2(0, r * 1.4)])]
		MapMarker.Kind.GUARD:
			shape = PackedVector2Array([at + Vector2(0, -r * 1.2), at + Vector2(r, 0), at + Vector2(0, r * 1.2), at + Vector2(-r, 0), at + Vector2(0, -r * 1.2)])
		MapMarker.Kind.GATHER:
			shape = _circle(at, r)
			ticks = [PackedVector2Array([at + Vector2(-r * 1.5, 0), at + Vector2(-r * 0.6, 0)]), PackedVector2Array([at + Vector2(r * 1.5, 0), at + Vector2(r * 0.6, 0)]),
				PackedVector2Array([at + Vector2(0, -r * 1.5), at + Vector2(0, -r * 0.6)]), PackedVector2Array([at + Vector2(0, r * 1.5), at + Vector2(0, r * 0.6)])]
		MapMarker.Kind.SCOUT:
			shape = PackedVector2Array([at + Vector2(0, -r * 1.2), at + Vector2(r * 1.05, r * 0.8), at + Vector2(-r * 1.05, r * 0.8), at + Vector2(0, -r * 1.2)])
		MapMarker.Kind.LZ:
			shape = PackedVector2Array([at + Vector2(-r, -r), at + Vector2(r, -r), at + Vector2(r, r), at + Vector2(-r, r), at + Vector2(-r, -r)])
	var width: float = _stats.outline_width
	for line: PackedVector2Array in [shape] + ticks:
		draw_polyline(line, UiTokens.BLACK * Color(1, 1, 1, alpha), width + EDGE * 2.0)
	for line: PackedVector2Array in [shape] + ticks:
		draw_polyline(line, color, width)
	draw_circle(at, width * 1.2, color)
	var font_size: int = UiTokens.TEXT_SMALL / 2
	var text: String = MapMarker.kind_label(kind)
	var origin := at + Vector2(-_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * 0.5, r * 1.4 + font_size)
	draw_string_outline(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, UiTokens.BLACK)
	draw_string(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


static func _circle(at: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 33:
		points.append(at + Vector2.from_angle(TAU * float(i) / 32.0) * radius)
	return points
