class_name HelmetWarnings
extends HelmetPart
## Visual only: the angle-of-attack indexer (inside the speed tape: how much of the stall angle is in use, with the
## warning and the stall marked and a caret for where it is heading), the stall and pull-up warnings, and the air
## brake and hover notes.

## The indexer's size, and how far inside the speed tape it stands.
const GAUGE := Vector2(18.0, 300.0)
const GAUGE_INSET: float = 90.0
const BANNER_PADDING: float = 24.0
const BANNER_HEIGHT: float = 60.0


func _paint() -> void:
	if not hud.flight.hovering():
		_indexer()
	_words()


func _indexer() -> void:
	var stats: HelmetHudStats = hud.stats
	var left: float = size.x * 0.5 - stats.tape_offset + GAUGE_INSET
	var rect := Rect2(Vector2(left, (size.y - GAUGE.y) * 0.5), GAUGE)
	var color: Color = UiTokens.HUD_WARNING if hud.stall_warning else UiTokens.HUD_LINE
	box(rect, color)
	var filled: float = clampf(hud.load_now / stats.gauge_top, 0.0, 1.0) * GAUGE.y
	draw_rect(Rect2(rect.position.x + 4.0, rect.end.y - filled, GAUGE.x - 8.0, filled), color)
	var stall_y: float = rect.end.y - GAUGE.y / stats.gauge_top
	line(Vector2(rect.position.x - 10.0, stall_y), Vector2(rect.end.x + 10.0, stall_y), UiTokens.HUD_WARNING)
	text(Vector2(rect.end.x + 18.0, stall_y), "STALL", HORIZONTAL_ALIGNMENT_LEFT, UiTokens.HUD_WARNING)
	var warn_y: float = rect.end.y - GAUGE.y * hud.sound_stats.warning_load / stats.gauge_top
	line(Vector2(rect.end.x, warn_y), Vector2(rect.end.x + 8.0, warn_y))
	var caret := Vector2(rect.position.x - 3.0,
			rect.end.y - clampf(hud.load_ahead / stats.gauge_top, 0.0, 1.0) * GAUGE.y)
	line(caret + Vector2(-12.0, -8.0), caret, color)
	line(caret + Vector2(-12.0, 8.0), caret, color)
	var degrees: float = hud.load_now * hud.flight.jet.stats.stall_angle_deg
	text(Vector2(rect.get_center().x, rect.end.y + 30.0), "α %d" % roundi(degrees), HORIZONTAL_ALIGNMENT_CENTER, color)


func _words() -> void:
	var middle: float = size.x * 0.5
	var y: float = size.y * 0.5 + hud.stats.warning_drop
	if hud.pull_up and hud.flash_on:
		_banner(Vector2(middle, y), "PULL UP")
	# Steady as a warning, flashing once the wing has stalled.
	if hud.stall_warning and (hud.flash_on or not hud.flight.model.stalled):
		_banner(Vector2(middle, y + 70.0), "STALL")
	var notes: PackedStringArray = []
	if hud.flight.hovering():
		notes.append("HOVER")
	else:
		if hud.flight.controls.air_brake:
			notes.append("AIR BRAKE")
		if hud.flight.jet.support > 0.0:
			notes.append("TRANSITION")
	if not notes.is_empty():
		text(Vector2(middle, y + 140.0), "   ".join(notes))


func _banner(at: Vector2, content: String) -> void:
	var font: Font = get_theme_font(&"font", &"LabelHeading")
	var width: float = font.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			get_theme_font_size(&"font_size", &"LabelHeading")).x + BANNER_PADDING * 2.0
	var frame := Rect2(at - Vector2(width, BANNER_HEIGHT) * 0.5, Vector2(width, BANNER_HEIGHT))
	draw_rect(frame, UiTokens.HUD_EDGE)
	box(frame, UiTokens.HUD_WARNING)
	text(at, content, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.HUD_WARNING, &"LabelHeading")
