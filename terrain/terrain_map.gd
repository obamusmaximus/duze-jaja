@tool
class_name TerrainMap
extends Node3D
## Shows a TerrainLayout as ground: the Kenney tiles (one MultiMesh per kind), generated cliff walls between tiles of
## different height, and collision on the World layer so the MapGrid reads the heights and slopes from it (steep cliffs
## block paths by themselves; ramps are the way up). `paint` and `erase` change cells and rebuild only what changed;
## `changed_area` tells the level which part of the MapGrid to re-read. Group: `terrain_map`. Also builds in the editor.

## Part of the ground (world x, z) whose cells changed; the level re-reads the map grid there.
signal changed_area(area: Rect2)

@export var layout: TerrainLayout
@export var stats: TerrainStats

var _body := StaticBody3D.new()
var _views: Dictionary = {}
var _cell_shapes: Dictionary = {}
var _cliff_view := MeshInstance3D.new()
var _cliff_shape := CollisionShape3D.new()


func _ready() -> void:
	add_to_group(&"terrain_map")
	_body.name = "Body"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_cliff_view.name = "Cliffs"
	add_child(_cliff_view)
	_cliff_shape.name = "CliffShape"
	_body.add_child(_cliff_shape)
	if stats:
		stats.changed.connect(rebuild)
	rebuild()


func tile_size() -> float:
	return stats.tile_size


func step_height() -> float:
	return stats.tile_size * 0.5


## The grid cell under a world point (x, z).
func cell_at(point: Vector3) -> Vector2i:
	return Vector2i(floori(point.x / stats.tile_size), floori(point.z / stats.tile_size))


## Puts a tile in `cell` and rebuilds around it.
func paint(cell: Vector2i, kind: TerrainLayout.Kind, turn: int, level: int) -> void:
	if layout.get_cell(cell) == Vector3i(kind, posmod(turn, 4), level):
		return
	layout.set_cell(cell, kind, turn, level)
	_touched(cell)


func erase(cell: Vector2i) -> void:
	if layout.has_cell(cell):
		layout.erase_cell(cell)
		_touched(cell)


## Rebuilds everything from the layout.
func rebuild() -> void:
	if layout == null or stats == null or not is_node_ready():
		return
	for kind: int in TerrainPieces.FILES:
		_view(kind).multimesh.instance_count = 0
	for shape: CollisionShape3D in _cell_shapes.values():
		shape.queue_free()
	_cell_shapes.clear()
	for cell: Vector2i in layout.cells():
		_place_collision(cell)
	_rebuild_views()
	_rebuild_cliffs()


func _touched(cell: Vector2i) -> void:
	if _cell_shapes.has(cell):
		_cell_shapes[cell].queue_free()
		_cell_shapes.erase(cell)
	_place_collision(cell)
	_rebuild_views()
	_rebuild_cliffs()
	var size: float = stats.tile_size
	changed_area.emit(Rect2((Vector2(cell) - Vector2.ONE) * size, Vector2.ONE * size * 3.0))


func _place_collision(cell: Vector2i) -> void:
	var tile: Vector3i = layout.get_cell(cell)
	if tile == TerrainLayout.NONE:
		return
	var shape := CollisionShape3D.new()
	shape.shape = TerrainPieces.shape(tile.x)
	shape.transform = TerrainPieces.tile_transform(tile.x, tile.y, _ground(cell, tile.z), stats.tile_size)
	_body.add_child(shape)
	_cell_shapes[cell] = shape


func _ground(cell: Vector2i, level: int) -> Vector3:
	return Vector3((cell.x + 0.5) * stats.tile_size, level * step_height(), (cell.y + 0.5) * stats.tile_size)


## The shared palette material of `tile_role` when the stats ask for a tint, else null (the kit's own look).
func _tint_material() -> StandardMaterial3D:
	if not stats.tint_tiles:
		return null
	return WorldMaterials.role(stats.tile_role)


func _rebuild_views() -> void:
	for view: MultiMeshInstance3D in _views.values():
		view.material_override = _tint_material()
	var by_kind: Dictionary = {}
	for cell: Vector2i in layout.cells():
		var tile: Vector3i = layout.get_cell(cell)
		if not by_kind.has(tile.x):
			by_kind[tile.x] = []
		by_kind[tile.x].append(TerrainPieces.tile_transform(tile.x, tile.y, _ground(cell, tile.z), stats.tile_size))
	for kind: int in TerrainPieces.FILES:
		var multimesh: MultiMesh = _view(kind).multimesh
		var placed: Array = by_kind.get(kind, [])
		multimesh.instance_count = placed.size()
		for i: int in placed.size():
			multimesh.set_instance_transform(i, placed[i])


func _view(kind: int) -> MultiMeshInstance3D:
	if _views.has(kind):
		return _views[kind]
	var view := MultiMeshInstance3D.new()
	view.name = "Tiles_%s" % TerrainPieces.NAMES[kind].replace(" ", "")
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = TerrainPieces.mesh(kind)
	view.multimesh = multimesh
	view.material_override = _tint_material()
	add_child(view)
	_views[kind] = view
	return view


func _rebuild_cliffs() -> void:
	var mesh: ArrayMesh = TerrainCliffs.build(layout, stats.tile_size, WorldMaterials.color_of(stats.cliff_role))
	_cliff_view.mesh = mesh
	if mesh:
		var shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
		shape.backface_collision = true
		_cliff_shape.shape = shape
	else:
		_cliff_shape.shape = null
