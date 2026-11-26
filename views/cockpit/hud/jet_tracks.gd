class_name JetTracks
extends JetPart
## Visual only: a box around each enemy the commando tracks (`JetTracking`), sized in world metres so it shrinks with
## distance (`marker_world_size`, at least `marker_min_px`), with a segmented health bar above it: one segment per
## `health_segment_hp` of max health. A marker blinks during the last `marker_blink_time` of its track. Enemies behind
## the camera get none.


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _paint() -> void:
	var stats: JetHudStats = hud.jet_stats
	var tracking: JetTracking = hud.flight.tracking
	var focal: float = size.y * 0.5 / tan(deg_to_rad(hud.camera.fov) * 0.5)
	var forward: Vector3 = -hud.camera.global_basis.z
	for tracked: Unit in tracking.targets():
		var center: Vector3 = tracked.get_global_transform_interpolated().origin + Vector3.UP * tracked.stats.height * 0.5
		var at: Vector2 = point_on_screen(center)
		if not at.is_finite():
			continue
		var left: float = tracking.time_left(tracked.id)
		if left < stats.marker_blink_time and fmod(left * stats.marker_blink_rate, 1.0) < 0.5:
			continue # The off half of a blink.
		var depth: float = maxf(forward.dot(center - hud.camera.global_position), 0.01)
		var side: float = maxf(stats.marker_world_size * focal / depth, stats.marker_min_px)
		var rect := Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side)
		box(rect)
		_health_bar(rect, tracked, stats)


## Segments in a row above `marker`, each filled by the health left in it; as wide as the marker or
## `health_bar_min_width`, so tougher types get more, narrower segments.
func _health_bar(marker: Rect2, tracked: Unit, stats: JetHudStats) -> void:
	var per: float = maxf(stats.health_segment_hp, 1.0)
	var count: int = maxi(ceili(tracked.stats.max_health / per - 0.001), 1)
	var ratio: float = tracked.health.current / (per * count)
	var width: float = maxf(marker.size.x, stats.health_bar_min_width)
	var left: float = marker.get_center().x - width * 0.5
	var top: float = marker.position.y - stats.health_bar_offset - stats.health_bar_height
	var segment: float = (width - stats.health_bar_gap * (count - 1)) / count
	for i: int in count:
		var cell := Rect2(left + i * (segment + stats.health_bar_gap), top, segment, stats.health_bar_height)
		var fill: float = clampf(ratio * count - i, 0.0, 1.0)
		draw_rect(cell.grow(UiTokens.BORDER * 0.5), UiTokens.HUD_EDGE)
		draw_rect(cell, Color(UiTokens.HUD_LINE, 0.25))
		if fill > 0.0:
			draw_rect(Rect2(cell.position, Vector2(cell.size.x * fill, cell.size.y)), UiTokens.HUD_LINE)
