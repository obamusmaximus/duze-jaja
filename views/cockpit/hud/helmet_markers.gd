class_name HelmetMarkers
extends HelmetPart
## Visual only: the boresight (where the nose points), the flight path marker (where the aircraft is going), the
## mouse-aim ring with a hairline to it from the centre, and the stall limit: a bar one stall angle above the flight path along the airframe's pitch, so the
## boresight reaching it is the stall.

## Gap between the dashes of the aim ring, radians.
const AIM_GAP: float = 0.5
## Half the width of the stall limit bar, in flight path marker radii.
const LIMIT_HALF_WIDTH: float = 2.6


func _paint() -> void:
	_boresight()
	_flight_path()
	_aim()


## A flat "W" with the nose at its middle point.
func _boresight() -> void:
	if not ahead(hud.nose):
		return
	var at: Vector2 = project(hud.nose)
	var size_px: float = hud.stats.boresight_size
	var shape: Array[Vector2] = [Vector2(-1.6, 0.0), Vector2(-0.8, 0.0), Vector2(-0.4, 0.5), Vector2.ZERO,
		Vector2(0.4, 0.5), Vector2(0.8, 0.0), Vector2(1.6, 0.0)]
	for i: int in shape.size() - 1:
		line(at + shape[i] * size_px, at + shape[i + 1] * size_px)


func _flight_path() -> void:
	var speed: float = hud.velocity.length()
	if speed < hud.stats.path_min_speed:
		return
	var course: Vector3 = hud.velocity / speed
	var radius: float = hud.stats.path_radius
	var area := Rect2(Vector2.ZERO, size).grow(-hud.stats.path_edge_inset)
	var at := Vector2.ZERO
	var held: bool = not ahead(course)
	if not held:
		at = project(course)
		held = not area.has_point(at)
	if held and hud.flight.hovering():
		return # Backing and climbing put it out of view all the time: no use held at the edge.
	if held:
		# Out of view: held at the edge on the side it left by, crossed out.
		var local: Vector3 = hud.camera.global_basis.inverse() * course
		var way := Vector2(local.x, -local.y)
		way = way.normalized() if way.length() > 0.001 else Vector2.DOWN
		var half: Vector2 = area.size * 0.5
		var reach: float = minf(half.x / maxf(absf(way.x), 0.001), half.y / maxf(absf(way.y), 0.001))
		at = area.get_center() + way * reach
		line(at + Vector2(-radius, -radius), at + Vector2(radius, radius))
		line(at + Vector2(-radius, radius), at + Vector2(radius, -radius))
	ring(at, radius)
	line(at + Vector2(-radius, 0.0), at + Vector2(-radius * 2.4, 0.0))
	line(at + Vector2(radius, 0.0), at + Vector2(radius * 2.4, 0.0))
	line(at + Vector2(0.0, -radius), at + Vector2(0.0, -radius * 1.9))
	if not held and not hud.flight.hovering():
		_stall_limit(course, at)


func _stall_limit(course: Vector3, path_at: Vector2) -> void:
	if maxf(hud.load_now, hud.load_ahead) < hud.stats.limit_from:
		return
	var limit: Vector3 = course.rotated(hud.right, hud.flight.jet.stall_alpha())
	if not ahead(limit):
		return
	var at: Vector2 = project(limit)
	var toward_path: Vector2 = (path_at - at).normalized()
	var along: Vector2 = toward_path.orthogonal() * hud.stats.path_radius * LIMIT_HALF_WIDTH
	var tick: Vector2 = toward_path * hud.stats.path_radius * 0.8
	var color: Color = UiTokens.HUD_WARNING if hud.stall_warning else UiTokens.HUD_LINE
	line(at - along, at + along, color)
	line(at - along, at - along + tick, color)
	line(at + along, at + along + tick, color)


## A hairline from the centre (the boresight, mid-screen unless the head is turned) to the aim ring: how far and which
## way the mouse stick is held. It stops short of both marks, and is left out while they are on top of each other.
func _stick_line(aim_at: Vector2) -> void:
	if not ahead(hud.nose):
		return
	var from: Vector2 = project(hud.nose)
	var way: Vector2 = aim_at - from
	var start_gap: float = hud.stats.boresight_size * 0.5
	if way.length() <= start_gap + hud.stats.aim_radius:
		return
	way = way.normalized()
	draw_line(from + way * start_gap, aim_at - way * hud.stats.aim_radius, UiTokens.HUD_REFERENCE, UiTokens.BORDER * 0.5,
			true)


## A ring in four dashes with a dot: what the player steers.
func _aim() -> void:
	var aim: Vector3 = hud.controls.aim()
	if not ahead(aim):
		return
	var at: Vector2 = project(aim)
	_stick_line(at)
	for quarter: int in 4:
		var from: float = quarter * PI * 0.5 + AIM_GAP * 0.5
		ring(at, hud.stats.aim_radius, UiTokens.HUD_LINE, from, from + PI * 0.5 - AIM_GAP)
	draw_circle(at, UiTokens.BORDER * 2.0, UiTokens.HUD_EDGE)
	draw_circle(at, UiTokens.BORDER, UiTokens.HUD_LINE)
