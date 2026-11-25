class_name AirLayer
extends RefCounted
## The air layer of the map model (`docs/mechanics/pathing.md`, "Air layer"): where flyers move. No cells, paths or
## land regions: any point inside the map bounds is open air, over land and sea alike. It answers what a flyer keeps
## above and keeps points on the map. Simulation.

## The map area (world x, z) flyers stay inside; empty means no limit.
var bounds: Rect2

var _map: MapGrid


func _init(map: MapGrid) -> void:
	_map = map


## The height under `point`, at least the sea level: from the heightmap where the level has one (it covers the whole
## map, the grid only the land), else from the grid, and open sea outside both.
func ground_height(point: Vector3) -> float:
	if _map.terrain != null:
		return maxf(_map.terrain.height_at(point.x, point.z), MapGrid.SEA_LEVEL)
	if _map.is_built() and _map.bounds.has_point(Vector2(point.x, point.z)):
		return _map.ground_height(point)
	return MapGrid.SEA_LEVEL


## `point` moved at least `margin` metres inside the map bounds (x, z).
func clamp_point(point: Vector3, margin: float = 0.0) -> Vector3:
	if not bounds.has_area():
		return point
	var inset: float = clampf(margin, 0.0, minf(bounds.size.x, bounds.size.y) * 0.5)
	return Vector3(
		clampf(point.x, bounds.position.x + inset, bounds.end.x - inset), point.y,
		clampf(point.z, bounds.position.y + inset, bounds.end.y - inset))
