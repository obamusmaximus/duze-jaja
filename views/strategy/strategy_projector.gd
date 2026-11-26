class_name StrategyProjector
extends RefCounted
## Maps between world points and the screen for the bird's-eye view, for picking, markers and outlines: the live
## world seen through the viewport's camera. Pure maths: it reads the camera and the heights and changes nothing.

## Ray marching steps when finding the ground under a screen point (the ground is a height field).
const STEPS: int = 6

var heights: TerrainHeights


## The screen point of a world point, or `Vector2.INF` when it is behind the camera.
func to_screen(viewport: Viewport, world: Vector3) -> Vector2:
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return Vector2.INF
	if camera.is_position_behind(world):
		return Vector2.INF
	return camera.unproject_position(world)

## The ground (x, y, z in world space) under a screen point, or `Vector3.INF` off the map.
func ground_at(viewport: Viewport, screen: Vector2) -> Vector3:
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return Vector3.INF
	var origin: Vector3 = camera.project_ray_origin(screen)
	var direction: Vector3 = camera.project_ray_normal(screen)
	if direction.y > -0.01:
		return Vector3.INF
	var plane_y: float = 0.0
	var point: Vector3 = Vector3.ZERO
	var ground: float = 0.0
	for i: int in STEPS:
		point = origin + direction * ((plane_y - origin.y) / direction.y)
		ground = maxf(heights.height_at(point.x, point.z), 0.0)
		plane_y = ground
	if not heights.bounds().has_point(Vector2(point.x, point.z)):
		return Vector3.INF
	return Vector3(point.x, ground, point.z)
