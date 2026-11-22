class_name AtollLand
extends StaticBody3D
## The scale reference level's land, built from primitives (`BattlefieldStats`): a flat seabed picture, a reef ring
## round a lagoon, a big island in the lagoon and a few small islands outside the ring. The land is one body on the
## World layer, so the map grid sees every top as ground and every side as a drop. The seabed has no collision (units
## can't walk on it). `rebuild()` redoes everything from the stats, so live edits show. Blockout only: step 5 of
## `docs/plans/battlefield.md` replaces it with sculpted terrain.

const RING_SEGMENTS: int = 24
## Small islands as fractions of half the map extent (x, z).
const SMALL_ISLANDS: Array[Vector2] = [
	Vector2(-0.55, 0.40), Vector2(-0.45, -0.50), Vector2(0.50, 0.45),
	Vector2(0.60, -0.35), Vector2(0.0, 0.75), Vector2(0.10, -0.80),
]

@export var stats: BattlefieldStats

## Land rectangles (world x, z), for the sea's shore.
var _rects: Array[Rect2] = []


func _ready() -> void:
	add_to_group(&"atoll_land")
	collision_layer = 1 << 0
	collision_mask = 0
	rebuild()


## The land as rectangles (x, z): the sea measures its shore from them.
func rects() -> Array[Rect2]:
	return _rects


func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_rects.clear()
	_seabed()
	var sand: StandardMaterial3D = WorldMaterials.role(WorldMaterials.Role.SAND)
	var grass: StandardMaterial3D = WorldMaterials.role(WorldMaterials.Role.GRASS)
	for i: int in RING_SEGMENTS:
		var angle: float = TAU * float(i) / RING_SEGMENTS
		var length: float = 2.0 * stats.ring_radius * tan(PI / RING_SEGMENTS) * 1.04
		var centre := Vector2(cos(angle), sin(angle)) * stats.ring_radius
		var box_size := Vector2(stats.ring_width, length)
		_block("Ring%d" % i, centre, box_size, stats.ring_height, -angle, sand)
	_block("BigIsland", Vector2.ZERO, stats.big_island_size, stats.island_height, 0.0, grass)
	var half: Vector2 = stats.map_extent * 0.5
	for i: int in SMALL_ISLANDS.size():
		_block("Islet%d" % i, SMALL_ISLANDS[i] * half, stats.small_island_size, stats.small_island_height, 0.0,
			sand if i % 2 == 0 else grass)


## The flat seabed: a mesh only.
func _seabed() -> void:
	var view := MeshInstance3D.new()
	view.name = "Seabed"
	var plane := PlaneMesh.new()
	plane.size = stats.map_extent + Vector2(400.0, 400.0)
	plane.material = WorldMaterials.role(WorldMaterials.Role.STONE_DARK)
	view.mesh = plane
	view.position.y = -stats.seabed_depth
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)


## One block rising from the seabed to `height` above the sea, `yaw` radians about the vertical axis.
func _block(block_name: String, centre: Vector2, size: Vector2, height: float, yaw: float,
		material: StandardMaterial3D) -> void:
	var total: float = height + stats.seabed_depth
	var at := Vector3(centre.x, (height - stats.seabed_depth) * 0.5, centre.y)
	var view := MeshInstance3D.new()
	view.name = block_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, total, size.y)
	mesh.material = material
	view.mesh = mesh
	view.position = at
	view.rotation.y = yaw
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	var shape := CollisionShape3D.new()
	shape.name = block_name + "Shape"
	var box := BoxShape3D.new()
	box.size = mesh.size
	shape.shape = box
	shape.position = at
	shape.rotation.y = yaw
	add_child(shape)
	var turned: Vector2 = (size * 0.5).abs()
	var reach := Vector2(
		absf(cos(yaw)) * turned.x + absf(sin(yaw)) * turned.y,
		absf(sin(yaw)) * turned.x + absf(cos(yaw)) * turned.y)
	_rects.append(Rect2(centre - reach, reach * 2.0))
