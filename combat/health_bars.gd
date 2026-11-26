class_name HealthBars
extends Control
## Visual only: a flat health bar over every unit that is damaged or selected, all drawn by this one Control from the
## units' screen positions (no node per bar).

const BAR_SIZE: Vector2 = Vector2(64.0, 8.0)
const BORDER: float = 2.0
## Metres above the unit's top.
const LIFT: float = 0.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## The RTS player is off in the strategy views, where the bars would hang in the air: hide with it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED:
		hide()
	elif what == NOTIFICATION_ENABLED:
		show()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var view: Rect2 = get_viewport_rect().grow(BAR_SIZE.x)
	for node: Node in get_tree().get_nodes_in_group(&"units"):
		var unit := node as Unit
		if unit == null or not unit.alive or not unit.is_drawn() or (not unit.selected and not unit.health.is_damaged()):
			continue
		var top: Vector3 = unit.get_global_transform_interpolated().origin + Vector3.UP * (unit.stats.height + LIFT)
		if camera.is_position_behind(top):
			continue
		var point: Vector2 = camera.unproject_position(top)
		if not view.has_point(point):
			continue
		var fraction: float = unit.health.fraction()
		var back := Rect2(point - Vector2(BAR_SIZE.x * 0.5, BAR_SIZE.y), BAR_SIZE)
		draw_rect(back.grow(BORDER), Color(UiTokens.BLACK, unit.view_level))
		var fill := Rect2(back.position, Vector2(BAR_SIZE.x * fraction, BAR_SIZE.y))
		draw_rect(fill, Color(_color(unit.team, fraction), unit.view_level))


## The unit's team colour, safety orange when low (flat, one colour per meaning).
func _color(team: int, fraction: float) -> Color:
	return UiTokens.ORANGE if fraction <= UiTokens.LOW_HEALTH else UiTokens.team_color(team)
