class_name CameraGroundFollow
extends Node
## Keeps the focus point on the ground: samples the ground height under it (a ray down on the World layer) on the
## physics tick and eases the focus height toward it.

const WORLD_LAYER: int = 1 << 0
## The ray runs between these heights, well above and below any ground.
const RAY_TOP: float = 1000.0
const RAY_BOTTOM: float = -1000.0

## The focus point's height now.
var height: float

var _stats: CameraStats
var _ground_height: float


func setup(stats: CameraStats, start_height: float) -> void:
	_stats = stats
	height = start_height
	_ground_height = start_height


## Finds the ground under `point` (x, z). Keeps the last height if there is no ground there.
func sample(space: PhysicsDirectSpaceState3D, point: Vector2) -> void:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(point.x, RAY_TOP, point.y), Vector3(point.x, RAY_BOTTOM, point.y), WORLD_LAYER)
	var hit: Dictionary = space.intersect_ray(query)
	if not hit.is_empty():
		_ground_height = (hit["position"] as Vector3).y


func step(delta: float) -> void:
	height = lerpf(height, _ground_height, CameraEase.weight(_stats.height_follow_smoothing, delta))
