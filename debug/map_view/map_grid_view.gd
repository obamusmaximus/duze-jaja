extends MultiMeshInstance3D
## Debug: `debug_show_map_grid` (F4) shows the MapGrid's impassable cells as red tiles (one MultiMesh), and the paths
## of the selected units as lines, kept up to date as the map changes. Finds the grid through the `map_grid` group.

const BLOCKED_COLOR: Color = Color(1.0, 0.2, 0.2, 0.45)
const PATH_COLOR: Color = Color(0.3, 0.9, 1.0)
const LIFT: float = 0.06

var _map: MapGrid
var _dirty: bool = true
var _paths := MeshInstance3D.new()
var _path_mesh := ImmediateMesh.new()
var _path_material := StandardMaterial3D.new()


func _ready() -> void:
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tile := PlaneMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = BLOCKED_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tile.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = tile
	_path_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_path_material.albedo_color = PATH_COLOR
	_paths.mesh = _path_mesh
	_paths.top_level = true
	add_child(_paths)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_show_map_grid"):
		get_viewport().set_input_as_handled()
		visible = not visible
		_dirty = true


func _process(_delta: float) -> void:
	if not visible:
		return
	if _map == null:
		_map = get_tree().get_first_node_in_group(&"map_grid") as MapGrid
		if _map == null:
			return
		_map.cells_changed.connect(func(_area: Rect2, _opened: bool) -> void: _dirty = true)
	if _dirty and _map.is_built():
		_dirty = false
		_rebuild_tiles()
	_draw_paths()


func _rebuild_tiles() -> void:
	var tile := multimesh.mesh as PlaneMesh
	tile.size = Vector2.ONE * _map.cell_size * 0.9
	var transforms: Array[Transform3D] = []
	for y: int in _map.size.y:
		for x: int in _map.size.x:
			var cell := Vector2i(x, y)
			if not _map.is_walkable(cell):
				transforms.append(Transform3D(Basis.IDENTITY, _map.cell_center(cell) + Vector3.UP * LIFT))
	multimesh.instance_count = transforms.size()
	for i: int in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])


func _draw_paths() -> void:
	_path_mesh.clear_surfaces()
	var lines := PackedVector3Array()
	for node: Node in get_tree().get_nodes_in_group(&"units"):
		var unit := node as Unit
		if unit == null or not unit.selected or not unit.navigator.active:
			continue
		var from: Vector3 = unit.global_position
		for point: Vector3 in unit.navigator.remaining_path():
			lines.append(from + Vector3.UP * 0.2)
			lines.append(point + Vector3.UP * 0.2)
			from = point
	if lines.is_empty():
		return
	_path_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _path_material)
	for point: Vector3 in lines:
		_path_mesh.surface_add_vertex(point)
	_path_mesh.surface_end()
