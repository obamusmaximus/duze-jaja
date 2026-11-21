extends StaticBody3D
## Debug: a wall across the sandbox that `debug_toggle_wall` (F3) raises and lowers during play, to test changing
## maps: raised, it blocks its cells in the MapGrid (found through the `map_grid` group) and collides on the World
## layer; units whose path crosses it re-path and go around. Units caught inside when it rises are pushed out by
## physics. Its area is its BoxShape3D's footprint (keep the wall unrotated).

const WORLD_LAYER: int = 1 << 0

var _raised: bool = false

@onready var _shape: CollisionShape3D = $Shape
@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle_wall"):
		get_viewport().set_input_as_handled()
		_raised = not _raised
		_apply()
		var map := get_tree().get_first_node_in_group(&"map_grid") as MapGrid
		if map:
			map.set_blocked(area(), _raised)


## The wall's footprint (world x, z).
func area() -> Rect2:
	var box := _shape.shape as BoxShape3D
	var centre: Vector3 = _shape.global_position
	return Rect2(Vector2(centre.x - box.size.x * 0.5, centre.z - box.size.z * 0.5), Vector2(box.size.x, box.size.z))


func _apply() -> void:
	collision_layer = WORLD_LAYER if _raised else 0
	_mesh.visible = _raised
