class_name CockpitAimMark
extends Control
## Visual only: a placeholder ring where the mouse aim points, so the player can steer before the flight HUD exists
## (`docs/plans/flight.md` step 3c replaces it).

var _stats: CockpitStats
var _controls: PilotControls


func setup(stats: CockpitStats, controls: PilotControls) -> void:
	_stats = stats
	_controls = controls
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _controls == null or not _controls.is_active():
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var point: Vector3 = camera.global_position + _controls.aim() * 1000.0
	if camera.is_position_behind(point):
		return
	var at: Vector2 = camera.unproject_position(point)
	draw_arc(at, _stats.aim_mark_radius, 0.0, TAU, 32, UiTokens.BLACK, UiTokens.BORDER * 2.0, true)
	draw_arc(at, _stats.aim_mark_radius, 0.0, TAU, 32, UiTokens.GREEN, UiTokens.BORDER, true)
