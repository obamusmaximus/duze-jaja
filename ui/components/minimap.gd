class_name Minimap
extends Control
## A top-down map of the whole play area (north up): a flat black field with the map's panel grid, corner brackets,
## a blip per living unit in its team colour, and the camera's view as an off-white outline of its footprint on the
## ground. Enemies only as far as the view knows them (`FogView`). Left press or drag moves the camera there (`CameraRig.focus_on`). View only. Placeholder until buildings exist.

## Metres between the minimap's grid lines.
const GRID_METRES: float = 20.0

var _area: Rect2
var _rig: CameraRig
var _stats: UiStats
var _dragging: bool = false


func setup(area: Rect2, rig: CameraRig, stats: UiStats) -> void:
	_area = area
	_rig = rig
	_stats = stats
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = button.pressed
		if _dragging:
			_focus_at(button.position)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_focus_at((event as InputEventMouseMotion).position)
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTokens.BLACK)
	_draw_grid()
	_draw_brackets()
	for node: Node in get_tree().get_nodes_in_group(&"units"):
		var unit := node as Unit
		if unit != null and unit.alive and unit.is_drawn():
			draw_circle(_to_map(unit.global_position), _stats.blip_radius,
					Color(UiTokens.team_color(unit.team), unit.view_level))
	_draw_view()


func _draw_grid() -> void:
	var line: Color = UiTokens.RULE
	var x: float = ceilf(_area.position.x / GRID_METRES) * GRID_METRES
	while x < _area.end.x:
		var from: Vector2 = _to_map(Vector3(x, 0.0, _area.position.y))
		draw_line(from, Vector2(from.x, size.y), line, 1.0)
		x += GRID_METRES
	var z: float = ceilf(_area.position.y / GRID_METRES) * GRID_METRES
	while z < _area.end.y:
		var from: Vector2 = _to_map(Vector3(_area.position.x, 0.0, z))
		draw_line(from, Vector2(size.x, from.y), line, 1.0)
		z += GRID_METRES


## Off-white L-shaped marks in the four corners.
func _draw_brackets() -> void:
	var arm: float = UiTokens.px(2)
	var w: float = UiTokens.BORDER
	for corner: Vector2 in [Vector2.ZERO, Vector2(1, 0), Vector2(0, 1), Vector2.ONE]:
		var origin: Vector2 = corner * (size - Vector2.ONE * w)
		var dir: Vector2 = Vector2.ONE - corner * 2.0 # Points into the map.
		draw_rect(Rect2(origin, Vector2(arm * dir.x, w)).abs(), UiTokens.OFF_WHITE)
		draw_rect(Rect2(origin, Vector2(w, arm * dir.y)).abs(), UiTokens.OFF_WHITE)


## The camera's footprint on the ground: the viewport's four corners cast onto the ground plane.
func _draw_view() -> void:
	var camera: Camera3D = _rig.get_camera()
	if camera == null:
		return
	var view: Vector2 = camera.get_viewport().get_visible_rect().size
	var corners: Array[Vector2] = [Vector2.ZERO, Vector2(view.x, 0.0), view, Vector2(0.0, view.y)]
	var points := PackedVector2Array()
	for corner: Vector2 in corners:
		var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(corner), camera.project_ray_normal(corner))
		if hit == null:
			return
		points.append(_to_map(hit as Vector3))
	points.append(points[0])
	draw_polyline(points, UiTokens.OFF_WHITE, UiTokens.BORDER)


func _to_map(world: Vector3) -> Vector2:
	return (Vector2(world.x, world.z) - _area.position) / _area.size * size


func _focus_at(point: Vector2) -> void:
	var ratio: Vector2 = (point / size).clamp(Vector2.ZERO, Vector2.ONE)
	var world: Vector2 = _area.position + ratio * _area.size
	_rig.focus_on(Vector3(world.x, 0.0, world.y))
