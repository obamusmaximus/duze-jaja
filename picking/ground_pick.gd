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


## The ground point under `screen_point`, or `NONE` (test with `is_finite()`).
static func ground_point(viewport: Viewport, screen_point: Vector2) -> Vector3:
	var hit: Dictionary = _cast(viewport, screen_point, WORLD_MASK)
	if hit.is_empty():
		return NONE
	return hit["position"]


## The unit or building under `screen_point`, or null. A unit or building in front of the ground wins; one behind a
## hill doesn't count.
static func object_under(viewport: Viewport, screen_point: Vector2) -> Node3D:
	var hit: Dictionary = _cast(viewport, screen_point, WORLD_MASK | OBJECT_MASK)
	if hit.is_empty():
		return null
	var collider: Object = hit["collider"]
	if collider is CollisionObject3D and (collider as CollisionObject3D).collision_layer & OBJECT_MASK:
		return collider as Node3D
	return null


static func _cast(viewport: Viewport, screen_point: Vector2, mask: int) -> Dictionary:
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return {}
	var from: Vector3 = camera.project_ray_origin(screen_point)
	var to: Vector3 = from + camera.project_ray_normal(screen_point) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	return camera.get_world_3d().direct_space_state.intersect_ray(query)
