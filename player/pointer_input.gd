class_name PointerInput
extends Node
## Reads the RTS view's mouse buttons and reports gestures, decided on release: a left press that moved past
## `drag_threshold_px` is a box, otherwise a click; a right press that didn't move that far is a click (a farther
## move was a camera drag pan). Draws the box while dragging. Knows nothing about units.

signal left_clicked(screen_point: Vector2, double_click: bool)
signal box_released(rect: Rect2)
signal right_clicked(screen_point: Vector2)

var _stats: PlayerControlStats
var _box: SelectionBox
var _left_down: bool = false
var _left_start: Vector2
var _left_double: bool = false
var _boxing: bool = false
var _right_down: bool = false
var _right_start: Vector2
var _right_moved: bool = false


func setup(stats: PlayerControlStats, box: SelectionBox) -> void:
	_stats = stats
	_box = box


## True while a box is being dragged.
func is_boxing() -> bool:
	return _boxing


## Switched off with the RTS controls: a half-made gesture is dropped, not resumed on the way back.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED:
		_left_down = false
		_right_down = false
		_boxing = false
		if _box != null:
			_box.hide_rect()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_on_motion((event as InputEventMouseMotion).position)
		return
	if not event is InputEventMouseButton:
		return
	var point: Vector2 = (event as InputEventMouseButton).position
	if event.is_action_pressed(&"select"):
		_left_down = true
		_left_start = point
		_left_double = (event as InputEventMouseButton).double_click
		_boxing = false
	elif event.is_action_released(&"select") and _left_down:
		_left_down = false
		if _boxing:
			_boxing = false
			_box.hide_rect()
			box_released.emit(_rect_to(point))
		else:
			left_clicked.emit(point, _left_double)
	elif event.is_action_pressed(&"order_click"):
		_right_down = true
		_right_start = point
		_right_moved = false
	elif event.is_action_released(&"order_click") and _right_down:
		_right_down = false
		if not _right_moved:
			right_clicked.emit(point)


func _on_motion(point: Vector2) -> void:
	if _right_down and point.distance_to(_right_start) > _stats.drag_threshold_px:
		_right_moved = true
	if not _left_down:
		return
	if not _boxing and point.distance_to(_left_start) > _stats.drag_threshold_px:
		_boxing = true
	if _boxing:
		_box.show_rect(_rect_to(point))


func _rect_to(point: Vector2) -> Rect2:
	return Rect2(_left_start, Vector2.ZERO).expand(point)
