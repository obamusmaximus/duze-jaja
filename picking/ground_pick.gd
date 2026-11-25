class_name GroundPick
## Turns screen points into world points and objects, with a ray from the viewport's active camera. Everything that
## clicks the world goes through here. Call from `_physics_process` (the physics space is only safe to query there).
## Screen points are viewport coordinates, as in input events.

## Returned by `ground_point` when the ray hits no ground.
const NONE: Vector3 = Vector3.INF
const WORLD_MASK: int = 1 << 0
## Units (layer 2) and buildings (layer 3).
const OBJECT_MASK: int = (1 << 1) | (1 << 2)
const RAY_LENGTH: float = 4000.0


## The ground point under `screen_point`, or `NONE` (test with `is_finite()`). In a level with water the sea's surface
## counts as ground: a click on the sea is the point on the water, not on the seabed seen through it.
static func ground_point(viewport: Viewport, screen_point: Vector2) -> Vector3:
	var hit: Dictionary = _cast(viewport, screen_point, WORLD_MASK)
	var point: Vector3 = NONE if hit.is_empty() else hit["position"]
	if point.is_finite() and point.y >= MapGrid.SEA_LEVEL:
		return point
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null or camera.get_tree().get_first_node_in_group(&"water") == null:
		return point
	var on_sea: Variant = Plane(Vector3.UP, MapGrid.SEA_LEVEL).intersects_ray(
			camera.project_ray_origin(screen_point), camera.project_ray_normal(screen_point))
	return point if on_sea == null else on_sea as Vector3


## The unit or building under `screen_point`, or null. A unit or building in front of the ground wins; one behind a
## hill doesn't count. Flyers are picked on screen (`FlyerPick`), in this order: a flyer's body in the air, whatever
## the ray hits, then a flyer's plate on the ground (so a ground unit standing on a plate still wins).
## `flyer_min_px` is the least pick radius of a flyer on screen.
static func object_under(viewport: Viewport, screen_point: Vector2, flyer_min_px: float) -> Node3D:
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return null
	var hit: Dictionary = _cast(viewport, screen_point, WORLD_MASK | OBJECT_MASK)
	var object: Node3D = null
	var ground_depth: float = INF
	if not hit.is_empty():
		var collider := hit["collider"] as CollisionObject3D
		if collider != null and collider.collision_layer & OBJECT_MASK:
			object = collider
		else:
			ground_depth = camera.global_position.distance_to(hit["position"])
	var flyer: Unit = FlyerPick.body_under(camera, screen_point, flyer_min_px, ground_depth)
	if flyer != null:
		return flyer
	if object != null:
		return object
	return FlyerPick.plate_under(camera, screen_point, flyer_min_px, ground_depth)


static func _cast(viewport: Viewport, screen_point: Vector2, mask: int) -> Dictionary:
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return {}
	var from: Vector3 = camera.project_ray_origin(screen_point)
	var to: Vector3 = from + camera.project_ray_normal(screen_point) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	return camera.get_world_3d().direct_space_state.intersect_ray(query)
