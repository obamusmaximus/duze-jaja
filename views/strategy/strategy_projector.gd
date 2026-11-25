class_name StrategyProjector
extends RefCounted
## Maps between world points and the screen for the two strategy views, so picking, markers and outlines work the
## same in both. In the bird's-eye view the live world is seen through the viewport's camera; on the war table the
## model sits far above the world with scaled heights (`WarTable.surface_y`), so a world point is first moved onto it.
## Pure maths: it reads the camera and the heights and changes nothing.

## Ray marching steps when finding the ground under a screen point (the ground is a height field).
const STEPS: int = 6

var table: WarTable
var heights: TerrainHeights
## The view being shown (`ViewSwitcher.View`).
var view: ViewSwitcher.View = ViewSwitcher.View.BIRDS_EYE


## The screen point of a world point, or `Vector2.INF` when it is behind the camera.
func to_screen(viewport: Viewport, world: Vector3) -> Vector2:
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return Vector2.INF
	var at: Vector3 = world
	if view == ViewSwitcher.View.WAR_TABLE:
		at = Vector3(world.x, table.surface_y(world.x, world.z), world.z)
	if camera.is_position_behind(at):
		return Vector2.INF
	return camera.unproject_position(at)


## The ground (x, y, z in world space) under a screen point, or `Vector3.INF` off the map.
func ground_at(viewport: Viewport, screen: Vector2) -> Vector3:
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return Vector3.INF
	var origin: Vector3 = camera.project_ray_origin(screen)
	var direction: Vector3 = camera.project_ray_normal(screen)
	if direction.y > -0.01:
		return Vector3.INF
	var base_y: float = table.surface_y(0.0, 0.0) if view == ViewSwitcher.View.WAR_TABLE else 0.0
	var plane_y: float = base_y
	var point: Vector3 = Vector3.ZERO
	var ground: float = 0.0
	for i: int in STEPS:
		point = origin + direction * ((plane_y - origin.y) / direction.y)
		ground = maxf(heights.height_at(point.x, point.z), 0.0)
		plane_y = table.surface_y(point.x, point.z) if view == ViewSwitcher.View.WAR_TABLE else ground
	if not heights.bounds().has_point(Vector2(point.x, point.z)):
		return Vector3.INF
	return Vector3(point.x, ground, point.z)
