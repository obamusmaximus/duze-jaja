class_name HelmetTapes
extends HelmetPart
## Visual only: the speed tape (km/h, left, with the wing's stall speed marked), the altitude tape (metres above the
## sea, right, with the height above the ground under it) and the compass heading tape (top; north is -z, as on the
## minimap). The tapes belong to the helmet: they stay put on screen.

const KMH: float = 3.6
## Tick lengths of a tape, pixels.
const TICK: float = 10.0
const LONG_TICK: float = 18.0
## Size of the box round a tape's present value.
const READOUT := Vector2(112.0, 52.0)
const COMPASS: Dictionary = {0: "N", 90: "E", 180: "S", 270: "W"}


func _paint() -> void:
	var middle: Vector2 = size * 0.5
	var stats: HelmetHudStats = hud.stats
	var speed: float = hud.velocity.length() * KMH
	_tape(middle.x - stats.tape_offset, speed, stats.speed_window, 10.0, -1.0, "KM/H", true)
	if not hud.flight.hovering():
		_mark(middle.x - stats.tape_offset, speed, stats.speed_window, hud.flight.jet.stats.stall_speed * KMH)
	_tape(middle.x + stats.tape_offset, hud.altitude, stats.altitude_window, 10.0, 1.0, "ALT M", false)
	text(Vector2(middle.x + stats.tape_offset, middle.y + stats.tape_height * 0.5 + 70.0),
			"GND %d" % roundi(hud.clearance))
	_heading(middle.x)


## One vertical tape with its scale line at `x`. `side` is which way the ticks and figures go (-1 left, 1 right).
func _tape(x: float, value: float, window: float, step: float, side: float, caption: String,
		positive_only: bool) -> void:
	var middle: float = size.y * 0.5
	var half: float = hud.stats.tape_height * 0.5
	var per_unit: float = hud.stats.tape_height / window
	line(Vector2(x, middle - half), Vector2(x, middle + half))
	var first: int = ceili((value - window * 0.5) / step)
	var last: int = floori((value + window * 0.5) / step)
	var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT if side > 0.0 else HORIZONTAL_ALIGNMENT_RIGHT
	for i: int in range(first, last + 1):
		if positive_only and i < 0:
			continue
		var y: float = middle - (i * step - value) * per_unit
		var major: bool = posmod(i, 2) == 0
		line(Vector2(x, y), Vector2(x + side * (LONG_TICK if major else TICK), y))
		# The readout box covers the middle.
		if major and absf(y - middle) > READOUT.y * 0.5 + LONG_TICK:
			text(Vector2(x + side * (LONG_TICK + 8.0), y), str(roundi(i * step)), align)
	var corner := Vector2(x + (6.0 if side > 0.0 else -6.0 - READOUT.x), middle - READOUT.y * 0.5)
	draw_rect(Rect2(corner, READOUT), UiTokens.HUD_EDGE)
	box(Rect2(corner, READOUT))
	text(corner + READOUT * 0.5, str(roundi(value)), HORIZONTAL_ALIGNMENT_CENTER, UiTokens.HUD_LINE, &"LabelNumber")
	text(Vector2(x, middle - half - 30.0), caption)


## The stall speed on the speed tape: below it the wing can't hold level flight.
func _mark(x: float, value: float, window: float, stall_speed: float) -> void:
	if absf(stall_speed - value) > window * 0.5:
		return
	var y: float = size.y * 0.5 - (stall_speed - value) * hud.stats.tape_height / window
	line(Vector2(x, y), Vector2(x + LONG_TICK * 1.5, y), UiTokens.HUD_WARNING)


## The heading is where the nose points over the ground.
func _heading(middle: float) -> void:
	var stats: HelmetHudStats = hud.stats
	var heading: float = fposmod(rad_to_deg(atan2(hud.nose.x, -hud.nose.z)), 360.0)
	var y: float = stats.heading_top
	var per_degree: float = stats.heading_width / stats.heading_window
	line(Vector2(middle - stats.heading_width * 0.5, y), Vector2(middle + stats.heading_width * 0.5, y))
	var first: int = ceili((heading - stats.heading_window * 0.5) / 5.0)
	var last: int = floori((heading + stats.heading_window * 0.5) / 5.0)
	for i: int in range(first, last + 1):
		var degrees: int = posmod(i * 5, 360)
		var x: float = middle + (i * 5.0 - heading) * per_degree
		var major: bool = degrees % 10 == 0
		line(Vector2(x, y), Vector2(x, y - (LONG_TICK if major else TICK)))
		if degrees % 30 == 0:
			text(Vector2(x, y - LONG_TICK - 18.0), COMPASS.get(degrees, "%02d" % floori(degrees / 10.0)))
	line(Vector2(middle, y + 2.0), Vector2(middle - 8.0, y + 14.0))
	line(Vector2(middle, y + 2.0), Vector2(middle + 8.0, y + 14.0))
	text(Vector2(middle, y + 40.0), "%03d" % posmod(roundi(heading), 360), HORIZONTAL_ALIGNMENT_CENTER,
			UiTokens.HUD_LINE, &"LabelNumber")
