class_name FlyerPick
## Screen-space picking of flyers (`docs/mechanics/rts_controls.md`): a flyer is clicked or boxed by its body in the
## air or by its plate and ring on the ground under it. Works on projected circles, not physics, so a small fast body
## stays easy to hit and the plate works over the sea (no ground to cast against). View side.


## The flyer whose body circle holds `point`, the nearest to the camera if several do; null for none.
## Bodies farther than `max_depth` metres from the camera are hidden (by the ground) and don't count.
static func body_under(camera: Camera3D, point: Vector2, min_radius_px: float, max_depth: float) -> Unit:
	return _under(camera, point, min_radius_px, max_depth, false)


## The same for the plates on the ground.
static func plate_under(camera: Camera3D, point: Vector2, min_radius_px: float, max_depth: float) -> Unit:
	return _under(camera, point, min_radius_px, max_depth, true)


## Whether the box `rect` takes `unit`: the middle of its body is inside, or for a flyer its ground point.
static func in_box(camera: Camera3D, unit: Unit, rect: Rect2) -> bool:
	if _holds(camera, unit.center(), rect):
		return true
	return unit.is_flying() and _holds(camera, unit.ground_point(), rect)


static func _holds(camera: Camera3D, world: Vector3, rect: Rect2) -> bool:
	return not camera.is_position_behind(world) and rect.has_point(camera.unproject_position(world))


static func _under(camera: Camera3D, point: Vector2, min_radius_px: float, max_depth: float, plate: bool) -> Unit:
	var best: Unit = null
	var best_depth: float = max_depth
	for node: Node in camera.get_tree().get_nodes_in_group(&"units"):
		var unit := node as Unit
		if unit == null or not unit.alive or not unit.is_flying():
			continue
		var at: Vector3 = unit.ground_point() if plate else unit.center()
		if camera.is_position_behind(at):
			continue
		var depth: float = camera.global_position.distance_to(at)
		# A plate sits on the ground itself: allow its own size before calling it hidden.
		if depth - (unit.stats.radius * 2.0 if plate else 0.0) > best_depth:
			continue
		var middle: Vector2 = camera.unproject_position(at)
		var edge: Vector2 = camera.unproject_position(at + camera.global_basis.x * unit.stats.radius)
		if point.distance_to(middle) > maxf(middle.distance_to(edge), min_radius_px):
			continue
		best = unit
		best_depth = depth
	return best
