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
## Last cursor position inside the viewport, and whether the cursor has left the window (it left through an edge,
## so the last position says which). Lets the edge scroll without confining the cursor.
var _last_mouse: Vector2 = Vector2(-1.0, -1.0)
var _mouse_left_window: bool = false
## Fly drag: where the drag button went down (viewport units), and whether it is down.
var _fly_anchor: Vector2
var _flying: bool = false


func setup(stats: CameraStats) -> void:
	_stats = stats
	_confine(not get_tree().paused)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_mouse_left_window = false
		_last_mouse = motion.position
		if Input.is_action_pressed(&"camera_drag"):
			if _stats.drag_mode == CameraStats.DragMode.GRAB:
				drag_moved.emit(motion.relative)
		elif Input.is_action_pressed(&"camera_rotate"):
			rotate_moved.emit(motion.relative)
		return
	if event.is_action(&"camera_drag") and event is InputEventMouseButton:
		_flying = event.is_pressed() and _stats.drag_mode == CameraStats.DragMode.FLY
		if _flying:
			_fly_anchor = (event as InputEventMouseButton).position
	if event is InputEventPanGesture:
		var gesture := event as InputEventPanGesture
		if gesture.alt_pressed: # Option + two-finger scroll turns the camera (a trackpad has no middle button).
			rotate_moved.emit(Vector2(gesture.delta.x * _stats.trackpad_rotate_px, 0.0))
		else: # Two-finger trackpad scroll: up zooms in.
			zoom_notches.emit(gesture.delta.y * _stats.trackpad_zoom_notches)
	elif event is InputEventMagnifyGesture: # Pinch: spreading the fingers zooms in.
		zoom_notches.emit(-log((event as InputEventMagnifyGesture).factor) * _stats.trackpad_pinch_notches)
	elif event.is_action_pressed(&"camera_zoom_in"):
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


## Fly drag: the pull of the cursor from the anchor, pixels (x right, y down), dead zone taken off and the length
## capped; zero when not flying or not pulled past the dead zone.
func fly_pull() -> Vector2:
	if not _flying or _stats == null:
		return Vector2.ZERO
	var pull: Vector2 = get_viewport().get_mouse_position() - _fly_anchor
	var length: float = pull.length()
	if length <= _stats.fly_deadzone_px:
		return Vector2.ZERO
	return pull / length * minf(length - _stats.fly_deadzone_px, _stats.fly_max_px)


func fly_anchor() -> Vector2:
	return _fly_anchor


func is_flying() -> bool:
	return _flying


## Wanted rotation this frame from the rotate keys: -1 left, 1 right.
func rotate_direction() -> float:
	return Input.get_axis(&"camera_rotate_left", &"camera_rotate_right")


## Dragging or rotating with the mouse: the edge mustn't scroll as well.
func _mouse_busy() -> bool:
	return Input.is_action_pressed(&"camera_drag") or Input.is_action_pressed(&"camera_rotate")


## In viewport units, which under the project's canvas_items stretch are the 1920x1080 base units that
## `edge_margin_px` is given in. An unfocused window or a mouse outside the viewport never scrolls.
func _edge_direction() -> Vector2:
	if not get_window().has_focus():
		return Vector2.ZERO
	var view: Rect2 = get_viewport().get_visible_rect()
	var mouse: Vector2 = get_viewport().get_mouse_position()
	if _mouse_left_window:
		mouse = _last_mouse
	elif not view.grow(1.0).has_point(mouse):
		return Vector2.ZERO
	else:
		_last_mouse = mouse
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
		NOTIFICATION_WM_MOUSE_EXIT:
			_mouse_left_window = true
		NOTIFICATION_WM_MOUSE_ENTER:
			_mouse_left_window = false
		NOTIFICATION_UNPAUSED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_confine(not get_tree().paused)
		NOTIFICATION_PAUSED, NOTIFICATION_EXIT_TREE:
			_confine(false)


func _confine(on: bool) -> void:
	if _stats == null or DisplayServer.get_name() == "headless":
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return # A first-person view holds the mouse and frees it itself.
	var want: Input.MouseMode = Input.MOUSE_MODE_CONFINED if on and _stats.confine_mouse else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != want:
		Input.mouse_mode = want


func _wheel_factor(event: InputEvent) -> float:
	var button := event as InputEventMouseButton
	if button and button.factor > 0.0:
		return button.factor
	return 1.0
