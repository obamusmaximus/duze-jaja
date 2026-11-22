class_name Carrier
extends StaticBody3D
## Placeholder for the large aircraft carrier that is a team's main, mostly static base (units will spawn from it, as
## in C&C 4). Today it is a stack of flat-coloured boxes: a hull, a flight deck with a lane stripe, a tower. Its deck
## is ground on the World layer (so the MapGrid sees it as walkable; its sides are drops, so they block) and the
## hull blocks shots on the Building layer. `Spawn` markers under `SpawnPoints` are where units will appear. Keep it
## level; it may turn about the vertical axis. Group: `carriers`.

## Length (along x), beam (along z) and deck height above the node, metres.
const LENGTH: float = 130.0
const BEAM: float = 34.0
const DECK_HEIGHT: float = 4.0
const HULL_DRAFT: float = 3.0

## The team that owns the carrier.
@export var team: int = 0

@onready var _spawn_points: Node3D = $SpawnPoints


func _ready() -> void:
	add_to_group(&"carriers")
	_build()


## Where units appear on the deck (world positions).
func spawn_positions() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for marker: Node in _spawn_points.get_children():
		out.append((marker as Node3D).global_position)
	return out


## The carrier's footprint on the water (world x, z), a box around the turned hull.
func footprint() -> Rect2:
	var half := Vector3(LENGTH * 0.5, 0.0, BEAM * 0.5)
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for corner: Vector3 in [half, Vector3(-half.x, 0.0, half.z), -half, Vector3(half.x, 0.0, -half.z)]:
		var point: Vector3 = global_transform * corner
		low = Vector2(minf(low.x, point.x), minf(low.y, point.z))
		high = Vector2(maxf(high.x, point.x), maxf(high.y, point.z))
	return Rect2(low, high - low)


func _build() -> void:
	collision_layer = (1 << 0) | (1 << 2)
	collision_mask = 0
	var hull: StandardMaterial3D = WorldMaterials.role(WorldMaterials.Role.HULL_MID)
	var deck: StandardMaterial3D = WorldMaterials.role(WorldMaterials.Role.HULL_DARK)
	var stripe: StandardMaterial3D = WorldMaterials.role(WorldMaterials.Role.WARNING)
	var tower: StandardMaterial3D = WorldMaterials.role(WorldMaterials.Role.HULL)
	var livery: StandardMaterial3D = WorldMaterials.role(WorldMaterials.Role.LIVERY, team)
	_box("Hull", Vector3(LENGTH, DECK_HEIGHT + HULL_DRAFT - 0.4, BEAM - 4.0), Vector3(0.0, (DECK_HEIGHT - HULL_DRAFT - 0.4) * 0.5, 0.0), hull)
	_box("Deck", Vector3(LENGTH, 0.4, BEAM), Vector3(0.0, DECK_HEIGHT - 0.2, 0.0), deck, true)
	_box("Stripe", Vector3(LENGTH - 16.0, 0.05, 0.8), Vector3(-4.0, DECK_HEIGHT + 0.03, 3.0), stripe)
	_box("Bow", Vector3(14.0, 0.4, BEAM - 8.0), Vector3(LENGTH * 0.5 + 7.0, DECK_HEIGHT - 0.2, 0.0), deck)
	_box("Tower", Vector3(14.0, 12.0, 7.0), Vector3(14.0, DECK_HEIGHT + 6.0, -BEAM * 0.5 + 5.0), tower)
	_box("Radar", Vector3(3.0, 5.0, 3.0), Vector3(14.0, DECK_HEIGHT + 14.5, -BEAM * 0.5 + 5.0), livery)


## One flat-coloured box: a mesh and, when `walk` is set, the collision that is the deck ground.
func _box(box_name: String, size: Vector3, at: Vector3, material: StandardMaterial3D, walk: bool = false) -> void:
	var view := MeshInstance3D.new()
	view.name = box_name
	var box := BoxMesh.new()
	box.size = size
	box.material = material
	view.mesh = box
	view.position = at
	add_child(view)
	if walk or box_name == "Hull" or box_name == "Tower":
		var shape := CollisionShape3D.new()
		var shape_box := BoxShape3D.new()
		shape_box.size = size
		shape.shape = shape_box
		shape.position = at
		add_child(shape)
