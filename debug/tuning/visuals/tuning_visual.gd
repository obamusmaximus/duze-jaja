class_name TuningVisual
extends Control
## Debug: base of the tuning panel's animated diagrams. One subclass draws one scenario (a unit's path, a
## weapon's range...) from the live values of a stats resource, and covers the tunables that scenario shows; the one being
## edited (`prop`) is drawn in the accent colour. Subclasses override `covers()` and `paint()`.
##
## Shared style, so the diagrams read as one set: dark background, neutral ink for bodies and geometry, blue for motion
## and paths, red for the enemy, orange for the tunable in focus. Distances use one of four fixed scales (BODY, NEAR, FAR,
## VAST, and CLOSE for body-sized detail), shown by the scale bar in the bottom-left corner next to a human figure at that scale.

const SIZE := Vector2(360.0, 240.0)

const BG := Color(0.07, 0.08, 0.1)
const GRID := Color(1.0, 1.0, 1.0, 0.035)
const INK := Color(0.86, 0.89, 0.93)
const DIM := Color(0.55, 0.6, 0.68, 0.7)
const FAINT := Color(0.55, 0.6, 0.68, 0.25)
const ACCENT := Color(1.0, 0.58, 0.15)
const PATH := Color(0.35, 0.7, 1.0)
const ENEMY := Color(1.0, 0.3, 0.25)
const GOOD := Color(0.3, 1.0, 0.4)

## Pixels per metre. Every metric diagram uses one of these, so sizes compare across diagrams.
const CLOSE := 48.0
const BODY := 16.0
const NEAR := 5.0
const FAR := 1.4
const VAST := 0.42

const PLAYER_HEIGHT := 1.8
const PLAYER_RADIUS := 0.4

enum Units { METRES, PIXELS, NONE }

## The stats resource being edited.
var stats: Resource
## The tunable in focus.
var prop: String = ""
## Real seconds since the diagram was shown. The game is paused behind the panel, so it doesn't use game time.
var t: float = 0.0
## Pixels per metre of this diagram (one of the scale constants).
var ppm: float = BODY
## World origin on screen (metres to pixels go through `w`).
var origin: Vector2 = Vector2.ZERO
## What the scale bar shows.
var units: Units = Units.METRES
## A short line at the top-left saying what is shown.
var caption: String = ""

var _start_ms: int = 0
var _font: Font


## Every subclass also defines `static func covers() -> Dictionary`: stats class name to the property names it covers.


func _ready() -> void:
	custom_minimum_size = SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	_start_ms = Time.get_ticks_msec()
	setup()


func _process(_delta: float) -> void:
	t = float(Time.get_ticks_msec() - _start_ms) / 1000.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	paint()
	if units == Units.METRES:
		_draw_scale_bar()
	elif units == Units.PIXELS:
		text(Vector2(size.x - 8.0, size.y - 8.0), "1:1 px", DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	if caption != "":
		text(Vector2(8.0, 16.0), caption, DIM)


## Called once before the first frame: set `ppm`, `origin`, `units` and `caption` here.
func setup() -> void:
	pass


## Draws the diagram. Overridden.
func paint() -> void:
	pass


# --- values ---------------------------------------------------------------------------------------------------------

func f(name: String) -> float:
	return float(stats.get(name))


## A tunable of another stats class, from its default .tres (the instance the game and the panel share).
func fo(stats_class: String, name: String) -> float:
	return float(other(stats_class).get(name))


## The default resource of another stats class (`PlayerStats` is tuning/player_default.tres).
func other(stats_class: String) -> Resource:
	if stats != null and (stats.get_script() as Script).get_global_name() == stats_class:
		return stats
	return load("res://tuning/%s_default.tres" % stats_class.trim_suffix("Stats").to_snake_case())


func on(name: String) -> bool:
	return bool(stats.get(name))


func col(name: String) -> Color:
	return stats.get(name) as Color


## True when `name` is the tunable in focus.
func is_focus(name: String) -> bool:
	return prop == name


## ACCENT when `name` is in focus, else `base`.
func hl(name: String, base: Color) -> Color:
	return ACCENT if prop == name else base


## True when any of `names` is in focus.
func focus_any(names: Array) -> bool:
	return names.has(prop)


## Seconds into a loop of `period` seconds.
func phase(period: float) -> float:
	return fmod(t, maxf(period, 0.01))


# --- coordinates ----------------------------------------------------------------------------------------------------

## Metres (x right, y up) to pixels, through `origin` and `ppm`. Top-down diagrams use y as "forward".
func w(x: float, y: float) -> Vector2:
	return origin + Vector2(x, -y) * ppm


func wv(p: Vector2) -> Vector2:
	return origin + Vector2(p.x, -p.y) * ppm


## Isometric projection of a world point (x right, y up, z toward the viewer), in metres.
func iso(p: Vector3) -> Vector2:
	return origin + Vector2((p.x - p.z) * 0.866, (p.x + p.z) * 0.5 - p.y) * ppm


# --- drawing --------------------------------------------------------------------------------------------------------

func text(pos: Vector2, s: String, color: Color = DIM, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, font_size: int = 11) -> void:
	var width: float = -1.0
	var at: Vector2 = pos
	if align != HORIZONTAL_ALIGNMENT_LEFT:
		width = 220.0
		at.x -= width if align == HORIZONTAL_ALIGNMENT_RIGHT else width * 0.5
	draw_string(_font, at, s, align, width, font_size, color)


func arrow(from: Vector2, to: Vector2, color: Color, width: float = 1.5, head: float = 6.0) -> void:
	if from.distance_to(to) < 1.0:
		return
	draw_line(from, to, color, width, true)
	var dir: Vector2 = (to - from).normalized()
	var side: Vector2 = dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([to, to - dir * head + side * head * 0.45, to - dir * head - side * head * 0.45]), color)


func dashed(from: Vector2, to: Vector2, color: Color, width: float = 1.0, dash: float = 4.0) -> void:
	draw_dashed_line(from, to, color, width, dash, true)


## A measure line between two points with end ticks and a label at its middle.
func measure(from: Vector2, to: Vector2, label: String, color: Color = DIM, offset: Vector2 = Vector2(4.0, 4.0)) -> void:
	draw_line(from, to, color, 1.0, true)
	var side: Vector2 = (to - from).normalized().orthogonal() * 3.0
	draw_line(from - side, from + side, color, 1.0)
	draw_line(to - side, to + side, color, 1.0)
	text((from + to) * 0.5 + offset, label, color)


func ring(center: Vector2, radius: float, color: Color, width: float = 1.0) -> void:
	draw_arc(center, radius, 0.0, TAU, maxi(16, int(radius)), color, width, true)


## A filled wedge (pie slice) from `from_angle` to `to_angle` (radians, screen space).
func wedge(center: Vector2, radius: float, from_angle: float, to_angle: float, color: Color) -> void:
	var points := PackedVector2Array([center])
	var steps: int = maxi(4, int(absf(to_angle - from_angle) * 12.0))
	for i: int in steps + 1:
		var a: float = lerpf(from_angle, to_angle, float(i) / steps)
		points.append(center + Vector2.from_angle(a) * radius)
	draw_colored_polygon(points, color)


## Ground line across the view at metre height `y`, with hatching below.
func ground(y: float = 0.0, color: Color = DIM) -> void:
	var sy: float = w(0.0, y).y
	draw_line(Vector2(0.0, sy), Vector2(size.x, sy), color, 1.5)
	var x: float = fposmod(origin.x, 10.0) - 10.0
	while x < size.x:
		draw_line(Vector2(x, sy + 1.0), Vector2(x - 6.0, sy + 7.0), FAINT, 1.0)
		x += 10.0


## Faint metre grid at `step` metres.
func grid(step: float) -> void:
	var px: float = step * ppm
	if px < 6.0:
		return
	var x0: float = fposmod(origin.x, px)
	var x: float = x0
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), GRID)
		x += px
	var y: float = fposmod(origin.y, px)
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), GRID)
		y += px


## The player seen from the side, feet at `feet` (pixels), at the diagram's scale.
func player_side(feet: Vector2, color: Color = INK) -> void:
	var h: float = PLAYER_HEIGHT * ppm
	var r: float = PLAYER_RADIUS * ppm
	if h < 3.0:
		draw_circle(feet - Vector2(0.0, 1.5), 2.0, color)
		return
	var body := Rect2(feet.x - r, feet.y - h, r * 2.0, h)
	draw_rect(Rect2(body.position + Vector2(0.0, r), Vector2(body.size.x, maxf(body.size.y - r * 2.0, 0.0))), color)
	draw_circle(Vector2(feet.x, feet.y - h + r), r, color)
	draw_circle(Vector2(feet.x, feet.y - r), r, color)


## The player seen from above at `pos` (pixels), facing `dir`.
func player_top(pos: Vector2, dir: Vector2 = Vector2.UP, color: Color = INK) -> void:
	var r: float = maxf(PLAYER_RADIUS * ppm, 2.5)
	draw_circle(pos, r, color)
	if dir.length() > 0.01:
		draw_line(pos, pos + dir.normalized() * (r + 5.0), color, 1.5, true)


## A graph frame in `rect` with x running to `x_max` and y to `y_max`, axis labels and a tick at each end.
func graph_frame(rect: Rect2, x_max: float, y_max: float, x_label: String, y_label: String) -> void:
	draw_line(rect.position + Vector2(0.0, rect.size.y), rect.end, DIM, 1.0)
	draw_line(rect.position, rect.position + Vector2(0.0, rect.size.y), DIM, 1.0)
	text(rect.end + Vector2(0.0, 12.0), "%s %s" % [num(x_max), x_label], DIM, HORIZONTAL_ALIGNMENT_RIGHT, 10)
	text(rect.position + Vector2(3.0, 8.0), "%s %s" % [num(y_max), y_label], DIM, HORIZONTAL_ALIGNMENT_LEFT, 10)


func graph_pt(rect: Rect2, x_max: float, y_max: float, x: float, y: float) -> Vector2:
	return Vector2(rect.position.x + x / maxf(x_max, 0.0001) * rect.size.x, rect.end.y - y / maxf(y_max, 0.0001) * rect.size.y)


## A horizontal marker line across a graph at value `y`, labelled.
func graph_level(rect: Rect2, y_max: float, y: float, label: String, color: Color) -> void:
	var py: float = graph_pt(rect, 1.0, y_max, 0.0, y).y
	if py < rect.position.y - 2.0 or py > rect.end.y + 2.0:
		return
	dashed(Vector2(rect.position.x, py), Vector2(rect.end.x, py), color)
	text(Vector2(rect.end.x - 2.0, py - 3.0), label, color, HORIZONTAL_ALIGNMENT_RIGHT, 10)


## A short number: no trailing zeros, at most two decimals.
func num(v: float) -> String:
	if absf(v - roundf(v)) < 0.005:
		return str(int(roundf(v)))
	if absf(v) >= 10.0:
		return "%.1f" % v
	return "%.2f" % v


func _draw_scale_bar() -> void:
	var length: float = 1.0
	for candidate: float in [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0]:
		length = candidate
		if candidate * ppm >= 36.0:
			break
	var px: float = length * ppm
	var base := Vector2(10.0, size.y - 10.0)
	draw_rect(Rect2(base - Vector2(2.0, 22.0), Vector2(px + 64.0, 26.0)), Color(BG, 0.75))
	draw_line(base, base + Vector2(px, 0.0), INK, 1.5)
	draw_line(base + Vector2(0.0, -4.0), base, INK, 1.5)
	draw_line(base + Vector2(px, -4.0), base + Vector2(px, 0.0), INK, 1.5)
	text(base + Vector2(px + 6.0, 0.0), "%s m" % num(length), INK, HORIZONTAL_ALIGNMENT_LEFT, 10)
	# A human at the same scale, for a sense of size (left out where the diagram's own player is that big).
	if PLAYER_HEIGHT * ppm <= 40.0:
		player_side(base + Vector2(px * 0.5, -3.0), DIM)
