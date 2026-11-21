class_name SelectionBox
extends Control
## Visual only: the drag box while box selecting. Never takes the mouse.

const FILL: Color = Color(0.4, 1.0, 0.4, 0.12)
const EDGE: Color = Color(0.4, 1.0, 0.4, 0.9)
const EDGE_WIDTH: float = 2.0

var _rect: Rect2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


func show_rect(rect: Rect2) -> void:
	_rect = rect
	visible = true
	queue_redraw()


func hide_rect() -> void:
	visible = false


func _draw() -> void:
	draw_rect(_rect, FILL)
	draw_rect(_rect, EDGE, false, EDGE_WIDTH)
