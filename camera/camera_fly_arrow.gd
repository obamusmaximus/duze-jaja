class_name CameraFlyArrow
extends Control
## Visual only: while a fly drag is held (`CameraInput`), an anchor mark where the button went down and an arrow at
## the cursor pointing away from it, so the view's flight reads as a direction and a strength.

const ANCHOR_RADIUS: float = 6.0
const LINE_WIDTH: float = 3.0
const HEAD_LENGTH: float = 26.0
const HEAD_HALF_WIDTH: float = 14.0

var _input: CameraInput


func setup(input: CameraInput) -> void:
	_input = input
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## A rig that is switched off (a strategy view is up) shows nothing.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED:
		hide()
	elif what == NOTIFICATION_ENABLED:
		show()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _input == null or not _input.is_flying():
		return
	var anchor: Vector2 = _input.fly_anchor()
	var pull: Vector2 = _input.fly_pull()
	if pull == Vector2.ZERO:
		return
	var direction: Vector2 = pull.normalized()
	var tip: Vector2 = get_viewport().get_mouse_position()
	var side := Vector2(-direction.y, direction.x)
	var base: Vector2 = tip - direction * HEAD_LENGTH
	draw_circle(anchor, ANCHOR_RADIUS, UiTokens.OFF_WHITE)
	draw_line(anchor, base, UiTokens.OFF_WHITE, LINE_WIDTH)
	draw_colored_polygon(PackedVector2Array([tip, base + side * HEAD_HALF_WIDTH, base - side * HEAD_HALF_WIDTH]),
			UiTokens.ORANGE)
