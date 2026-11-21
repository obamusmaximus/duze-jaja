class_name HealthBars
extends Control
## Visual only: a health bar over every unit that is damaged or selected, all drawn by this one Control from the
## units' screen positions (no node per bar).

const BAR_SIZE: Vector2 = Vector2(64.0, 8.0)
## Metres above the unit's top.
const LIFT: float = 0.5
const BACK_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
const FULL_COLOR: Color = Color(0.3, 0.9, 0.3)
const HALF_COLOR: Color = Color(0.95, 0.8, 0.2)
const LOW_COLOR: Color = Color(0.95, 0.25, 0.2)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var view: Rect2 = get_viewport_rect().grow(BAR_SIZE.x)
	for node: Node in get_tree().get_nodes_in_group(&"units"):
		var unit := node as Unit
		if unit == null or not unit.alive or (not unit.selected and not unit.health.is_damaged()):
			continue
		var top: Vector3 = unit.get_global_transform_interpolated().origin + Vector3.UP * (unit.stats.height + LIFT)
		if camera.is_position_behind(top):
			continue
		var point: Vector2 = camera.unproject_position(top)
		if not view.has_point(point):
			continue
		var fraction: float = unit.health.fraction()
		var back := Rect2(point - Vector2(BAR_SIZE.x * 0.5, BAR_SIZE.y), BAR_SIZE)
		draw_rect(back.grow(1.0), BACK_COLOR)
		var fill := Rect2(back.position, Vector2(BAR_SIZE.x * fraction, BAR_SIZE.y))
		draw_rect(fill, _color(fraction))


func _color(fraction: float) -> Color:
	if fraction > 0.5:
		return HALF_COLOR.lerp(FULL_COLOR, (fraction - 0.5) * 2.0)
	return LOW_COLOR.lerp(HALF_COLOR, fraction * 2.0)
