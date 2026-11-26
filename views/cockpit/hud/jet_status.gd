class_name JetStatus
extends JetPart
## Visual only: the commando's kit under the crosshair: hover (H, filled while on) and surge (S: its outline runs
## clockwise from the top middle while the jet key is held toward a surge, filled while thrusting), the speed in
## km/h and "A/B" in the warning colour while the afterburner burns.

const KMH: float = 3.6


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _paint() -> void:
	var stats: JetHudStats = hud.jet_stats
	var jet: JetpackModel = hud.flight.jetpack
	var side: float = stats.indicator_size
	var row: float = size.y * stats.indicator_row_share
	var hover_box := Rect2(Vector2(size.x * 0.5 - side - stats.indicator_gap * 0.5, row - side * 0.5), Vector2.ONE * side)
	var surge_box := Rect2(hover_box.position + Vector2(side + stats.indicator_gap, 0.0), Vector2.ONE * side)
	_indicator(hover_box, "H", jet.hover_on, 0.0)
	_indicator(surge_box, "S", jet.thrust != JetpackModel.Thrust.OFF, jet.hold_ratio())
	var below: float = row + side * 0.5 + stats.indicator_gap + UiTokens.TEXT_SMALL * 0.5
	text(Vector2(size.x * 0.5, below), "%d KM/H" % roundi(jet.velocity.length() * KMH), HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.HUD_LINE, &"LabelNumber")
	if jet.afterburning():
		text(Vector2(size.x * 0.5, below + UiTokens.TEXT_SMALL * 1.2), "A/B", HORIZONTAL_ALIGNMENT_CENTER,
			UiTokens.HUD_WARNING, &"LabelNumber")


## A lit box is filled with its letter cut out in the edge colour; an unlit one is outlined, with `progress` (0 to 1)
## of its outline drawn bright clockwise from the top middle.
func _indicator(rect: Rect2, letter: String, lit: bool, progress: float) -> void:
	if lit:
		draw_rect(rect, UiTokens.HUD_LINE)
		box(rect)
		_letter(rect, letter, UiTokens.BLACK)
		return
	box(rect, UiTokens.HUD_REFERENCE)
	if progress > 0.0:
		draw_polyline(_outline_part(rect, progress), UiTokens.HUD_LINE, UiTokens.BORDER * 1.5)
	_letter(rect, letter, UiTokens.HUD_REFERENCE)


func _letter(rect: Rect2, letter: String, color: Color) -> void:
	var font: Font = get_theme_font(&"font", &"LabelNumber")
	var font_size: int = get_theme_font_size(&"font_size", &"LabelNumber")
	var width: float = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var base: Vector2 = rect.get_center() + Vector2(-width * 0.5,
		(font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	draw_string(font, base, letter, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


## The first `share` of the box's outline, clockwise from the top middle.
func _outline_part(rect: Rect2, share: float) -> PackedVector2Array:
	var corners: Array[Vector2] = [Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y), rect.position]
	var points := PackedVector2Array([Vector2(rect.get_center().x, rect.position.y)])
	var left: float = share * (rect.size.x + rect.size.y) * 2.0
	for corner: Vector2 in corners + [points[0]]:
		var from: Vector2 = points[points.size() - 1]
		var length: float = from.distance_to(corner)
		if left <= length:
			points.append(from.move_toward(corner, left))
			return points
		points.append(corner)
		left -= length
	return points
