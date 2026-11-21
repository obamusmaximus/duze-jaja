class_name Prop
extends StaticBody3D
## A static object in a level: scenery or a building shell. It shows its model, and when its type `blocks` it
## collides on the Building layer and blocks its footprint in the MapGrid, so paths go around it. The level calls
## `block_in(map)` once the map is built. Keep it upright; it may turn about the vertical axis. Group: `props`.

@export var stats: PropStats

var _map: MapGrid
var _area: Rect2 = Rect2()
var _look: Node3D

@onready var _shape: CollisionShape3D = $Shape


func _ready() -> void:
	add_to_group(&"props")
	_shape.shape = BoxShape3D.new()
	_build()
	stats.changed.connect(_build)


## Blocks the prop's footprint in `map` (and keeps it up to date if the type is edited).
func block_in(map: MapGrid) -> void:
	_map = map
	_block()


## The prop's footprint on the ground (world x, z), a box around the turned rectangle.
func footprint() -> Rect2:
	var half := Vector3(stats.footprint_x * 0.5, 0.0, stats.footprint_z * 0.5)
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for corner: Vector3 in [half, Vector3(-half.x, 0.0, half.z), -half, Vector3(half.x, 0.0, -half.z)]:
		var point: Vector3 = global_transform * corner
		low = Vector2(minf(low.x, point.x), minf(low.y, point.z))
		high = Vector2(maxf(high.x, point.x), maxf(high.y, point.z))
	return Rect2(low, high - low)


func _build() -> void:
	if _look != null:
		_look.queue_free()
		_look = null
	if stats.model != null:
		_look = ModelFit.instance(stats.model, stats.model_scale, stats.model_yaw_deg)
		add_child(_look)
	collision_layer = (1 << 2) if stats.blocks else 0
	_shape.disabled = not stats.blocks
	(_shape.shape as BoxShape3D).size = Vector3(stats.footprint_x, stats.height, stats.footprint_z)
	_shape.position.y = stats.height * 0.5
	_block()


func _block() -> void:
	if _map == null:
		return
	if _area.has_area():
		_map.set_blocked(_area, false)
		_area = Rect2()
	if stats.blocks:
		_area = footprint()
		_map.set_blocked(_area, true)
