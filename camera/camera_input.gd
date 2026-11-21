class_name CameraInput
extends Node
## Reads the RTS camera's input (named actions, the mouse, the screen edge) and reports it to the rig. Knows
## nothing about the camera itself: events go up as signals, held input is polled by the rig each frame.

## Mouse moved (pixels, viewport units) while the drag button is held.
signal drag_moved(pixels: Vector2)
## Mouse moved (pixels, viewport units) while the rotate button is held.
signal rotate_moved(pixels: Vector2)
## Mouse wheel turned: positive zooms out, negative zooms in. Fractional on smooth-scrolling devices.
signal zoom_notches(notches: float)
## The camera reset action was pressed.
signal reset_pressed

var _stats: CameraStats


func setup(stats: CameraStats) -> void:
	_stats = stats
	_confine(not get_tree().paused)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if Input.is_action_pressed(&"camera_drag"):
			drag_moved.emit(motion.relative)
		elif Input.is_action_pressed(&"camera_rotate"):
			rotate_moved.emit(motion.relative)
		return
	if event.is_action_pressed(&"camera_zoom_in"):
		zoom_notches.emit(-_wheel_factor(event))
	elif event.is_action_pressed(&"camera_zoom_out"):
		zoom_notches.emit(_wheel_factor(event))
	elif event.is_action_pressed(&"camera_reset"):
		reset_pressed.emit()


## Wanted pan this frame from the keys and the screen edge: x is right, y is forward (up the screen), length at most 1.
func pan_direction() -> Vector2:
	var direction: Vector2 = Input.get_vector(&"camera_pan_left", &"camera_pan_right", &"camera_pan_back", &"camera_pan_forward")
	if _stats.edge_scroll_enabled and not _mouse_busy():
		direction += _edge_direction()
	return direction.limit_length(1.0)


## Wanted rotation this frame from the rotate keys: -1 left, 1 right.
func rotate_direction() -> float:
	return Input.get_axis(&"camera_rotate_left", &"camera_rotate_right")


## Dragging or rotating with the mouse: the edge mustn't scroll as well.
func _mouse_busy() -> bool:
	return Input.is_action_pressed(&"camera_drag") or Input.is_action_pressed(&"camera_rotate")


## In viewport units, which under the project's canvas_items stretch are the 2560x1440 base units that
## `edge_margin_px` is given in. An unfocused window or a mouse outside the viewport never scrolls.
func _edge_direction() -> Vector2:
	if not get_window().has_focus():
		return Vector2.ZERO
	var view: Rect2 = get_viewport().get_visible_rect()
	var mouse: Vector2 = get_viewport().get_mouse_position()
	if not view.grow(1.0).has_point(mouse):
		return Vector2.ZERO
	var margin: float = _stats.edge_margin_px
	var direction := Vector2.ZERO
	if mouse.x < view.position.x + margin:
		direction.x -= 1.0
	elif mouse.x > view.end.x - margin:
		direction.x += 1.0
	if mouse.y < view.position.y + margin:
		direction.y += 1.0
	elif mouse.y > view.end.y - margin:
		direction.y -= 1.0
	return direction


## Keeps the cursor inside the window while the game runs (so the edge can be reached in a window), and frees it
## while paused or when the rig goes away.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_UNPAUSED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_confine(not get_tree().paused)
		NOTIFICATION_PAUSED, NOTIFICATION_EXIT_TREE:
			_confine(false)


func _confine(on: bool) -> void:
	if _stats == null or DisplayServer.get_name() == "headless":
		return
	var want: Input.MouseMode = Input.MOUSE_MODE_CONFINED if on and _stats.confine_mouse else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != want:
		Input.mouse_mode = want


func _wheel_factor(event: InputEvent) -> float:
	var button := event as InputEventMouseButton
	if button and button.factor > 0.0:
		return button.factor
	return 1.0
