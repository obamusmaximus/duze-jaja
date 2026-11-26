class_name HelmetPart
extends Control
## Visual only: base of one part of the `HelmetHud`: the shared strokes and text (each with a dark edge under it) and
## projecting world directions onto the screen. Subclasses override `_paint`.

## A direction is projected as a point this far from the camera, metres.
const FAR_POINT: float = 1000.0

var hud: HelmetHud


func setup(owner_hud: HelmetHud) -> void:
	hud = owner_hud
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	if hud != null and hud.flight != null and hud.camera != null:
		_paint()


func _paint() -> void:
	pass


## Whether this part belongs on the HUD of `flight`: the flight marks are a flyer's, not a jetpack type's.
func shows(flight: PilotFlight) -> bool:
	return not flight.is_jetpack()


## Whether the world direction is in front of the camera, so it has a place on screen.
func ahead(direction: Vector3) -> bool:
	return direction.dot(-hud.camera.global_basis.z) > 0.05


func project(direction: Vector3) -> Vector2:
	return hud.camera.unproject_position(hud.camera.global_position + direction.normalized() * FAR_POINT)


## A straight line between two world directions; left out unless both ends are in front.
func world_line(from: Vector3, to: Vector3, color: Color = UiTokens.HUD_LINE) -> void:
	if ahead(from) and ahead(to):
		line(project(from), project(to), color)


func line(from: Vector2, to: Vector2, color: Color = UiTokens.HUD_LINE) -> void:
	draw_line(from, to, UiTokens.HUD_EDGE, UiTokens.BORDER * 2.0, true)
	draw_line(from, to, color, UiTokens.BORDER, true)


func ring(at: Vector2, radius: float, color: Color = UiTokens.HUD_LINE, from: float = 0.0, to: float = TAU) -> void:
	draw_arc(at, radius, from, to, 32, UiTokens.HUD_EDGE, UiTokens.BORDER * 2.0, true)
	draw_arc(at, radius, from, to, 32, color, UiTokens.BORDER, true)


func box(rect: Rect2, color: Color = UiTokens.HUD_LINE) -> void:
	draw_rect(rect, UiTokens.HUD_EDGE, false, UiTokens.BORDER * 2.0)
	draw_rect(rect, color, false, UiTokens.BORDER)


## Text placed by `at`: its vertical middle, and its left end, middle or right end as `align` says.
func text(at: Vector2, content: String, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER,
		color: Color = UiTokens.HUD_LINE, variation: StringName = &"LabelCaption") -> void:
	var font: Font = get_theme_font(&"font", variation)
	var font_size: int = get_theme_font_size(&"font_size", variation)
	var width: float = font.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var start: Vector2 = at + Vector2(0.0, (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		start.x -= width * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		start.x -= width
	draw_string_outline(font, start, content, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, UiTokens.BORDER * 2,
			UiTokens.HUD_EDGE)
	draw_string(font, start, content, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
