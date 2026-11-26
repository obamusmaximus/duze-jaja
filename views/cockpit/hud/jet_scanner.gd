class_name JetScanner
extends JetPart
## Visual only: the commando's scanner (`JetTracking`): a faint frame through the scanner's four corner directions,
## projected through the camera so it is exactly the pyramid tracking uses, with brighter corner marks.


func _paint() -> void:
	var stats: TrackingStats = hud.flight.tracking.stats
	var view: Basis = hud.camera.global_basis.orthonormalized()
	var x: float = tan(deg_to_rad(stats.scanner_half_width_deg))
	var y: float = tan(deg_to_rad(stats.scanner_half_height_deg))
	var corners: Array[Vector2] = []
	for corner: Vector2 in [Vector2(-x, y), Vector2(x, y), Vector2(x, -y), Vector2(-x, -y)]:
		corners.append(project(view * Vector3(corner.x, corner.y, -1.0)))
	var shortest: float = minf(corners[0].distance_to(corners[1]), corners[1].distance_to(corners[2]))
	var mark: float = shortest * hud.jet_stats.frame_corner_share
	for i: int in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var before: Vector2 = corners[(i + 3) % 4]
		draw_line(a, b, UiTokens.HUD_REFERENCE, UiTokens.BORDER * 0.5, true)
		line(a, a + (b - a).normalized() * mark)
		line(a, a + (before - a).normalized() * mark)
