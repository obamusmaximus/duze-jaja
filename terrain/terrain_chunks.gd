class_name TerrainChunks
extends Node3D
## The views of a `TerrainHeights` map: per chunk (`HeightmapStats.chunk_cells` cells a side) a flat-shaded mesh at two
## levels of detail (visibility ranges) and a `HeightMapShape3D` on the World layer. A change names an area
## (`changed()`); only the chunks it touches rebuild, `chunks_per_tick` at a time, and once the queue empties
## `changed_area` carries the whole changed area (the level then re-reads the map grid there).
## View and collision only: the simulation reads the heights from the data.

## The queued rebuilds finished: the ground in `area` (world x, z) now matches the data.
signal changed_area(area: Rect2)

const WORLD_LAYER: int = 1 << 0

@export var stats: HeightmapStats

var heights: TerrainHeights
## Chunks across x and z.
var chunk_count: Vector2i = Vector2i.ZERO
var _body: StaticBody3D
## Per chunk (Vector2i): {"near": MeshInstance3D, "far": MeshInstance3D, "shape": CollisionShape3D}.
var _chunks: Dictionary = {}
## Chunks waiting to rebuild (Vector2i keys, insertion order), and the area they cover so far.
var _queue: Dictionary = {}
var _pending: Rect2 = Rect2()
var _has_pending: bool = false
var _overlay: Material
## What shows when no debug overlay does (the bird's-eye view's cloud shadows).
var _base_overlay: Material
## The baked light (null until a sun is given with `set_sun`: chunks are then plain white vertex colours).
var _light: TerrainLight
var _light_key: Array = []


## Gives the ground its baked light from `sun` (horizon shadows, hollows, tint). Call before `setup`.
func set_sun(sun: DirectionalLight3D) -> void:
	_light = TerrainLight.new()
	_light.set_sun(sun)


## Builds every chunk of `data`. Call once the node is in the tree.
func setup(data: TerrainHeights) -> void:
	for child: Node in get_children():
		child.queue_free()
	_chunks.clear()
	_queue.clear()
	heights = data
	if _light != null:
		_light.setup(heights, stats)
		_light.bake(Rect2i(Vector2i.ZERO, heights.samples))
		_light_key = _key()
		if not stats.changed.is_connected(_on_stats_changed):
			stats.changed.connect(_on_stats_changed)
	_body = StaticBody3D.new()
	_body.name = "Ground"
	_body.collision_layer = WORLD_LAYER
	_body.collision_mask = 0
	add_child(_body)
	var n: int = stats.chunk_cells
	var cells: Vector2i = heights.samples - Vector2i.ONE
	chunk_count = Vector2i(ceili(float(cells.x) / n), ceili(float(cells.y) / n))
	for cz: int in chunk_count.y:
		for cx: int in chunk_count.x:
			_build_chunk(Vector2i(cx, cz), true)


## The map changed inside `area` (world x, z): queue the chunks it touches for a rebuild.
func changed(area: Rect2) -> void:
	if heights == null:
		return
	var touched: Rect2i = heights.samples_in(area)
	if _light != null:
		# Light carries across chunks (a new hill shades the ground downwind): re-bake and rebuild what it reaches.
		touched = heights.samples_in(_light.affected(area))
		_light.bake(touched)
	var n: int = stats.chunk_cells
	var first := Vector2i(maxi(touched.position.x - 1, 0) / n, maxi(touched.position.y - 1, 0) / n)
	var last := Vector2i(mini(touched.end.x - 1, heights.samples.x - 1) / n, mini(touched.end.y - 1, heights.samples.y - 1) / n)
	for cz: int in range(first.y, mini(last.y, chunk_count.y - 1) + 1):
		for cx: int in range(first.x, mini(last.x, chunk_count.x - 1) + 1):
			_queue[Vector2i(cx, cz)] = true
	_pending = _pending.merge(area) if _has_pending else area
	_has_pending = true


## Draws `material` over every chunk (a debug overlay such as the height bands), or nothing for null.
func set_overlay(material: Material) -> void:
	_overlay = material if material != null else _base_overlay
	_show_overlay()


## The overlay under any debug one (null for none).
func set_base_overlay(material: Material) -> void:
	_base_overlay = material
	_overlay = _overlay if _overlay != null and _overlay != _base_overlay else material
	_show_overlay()


## The baked light's settings; a change to any re-bakes everything.
func _key() -> Array:
	return [stats.light_shadow, stats.light_shade_tint, stats.light_shadow_softness, stats.light_reach, stats.light_ao,
		stats.light_ao_radius, stats.tint_strength, stats.tint_frequency]


func _on_stats_changed() -> void:
	if _light == null or heights == null or _key() == _light_key:
		return
	_light_key = _key()
	_light.bake(Rect2i(Vector2i.ZERO, heights.samples))
	for cz: int in chunk_count.y:
		for cx: int in chunk_count.x:
			_queue[Vector2i(cx, cz)] = true


func _show_overlay() -> void:
	for parts: Dictionary in _chunks.values():
		(parts["near"] as MeshInstance3D).material_overlay = _overlay
		(parts["far"] as MeshInstance3D).material_overlay = _overlay


func has_pending() -> bool:
	return not _queue.is_empty()


func _physics_process(_delta: float) -> void:
	if _queue.is_empty():
		return
	var keys: Array = _queue.keys()
	for i: int in mini(stats.chunks_per_tick, keys.size()):
		_queue.erase(keys[i])
		_build_chunk(keys[i] as Vector2i, false)
	if _queue.is_empty() and _has_pending:
		_has_pending = false
		changed_area.emit(_pending)


## Where chunk `chunk` starts (its corner sample) and how many cells it spans (the last row and column may be short).
func _chunk_span(chunk: Vector2i) -> Array[Vector2i]:
	var n: int = stats.chunk_cells
	var first: Vector2i = chunk * n
	var cells: Vector2i = (heights.samples - Vector2i.ONE - first).clamp(Vector2i.ONE, Vector2i(n, n))
	return [first, cells]


func _build_chunk(chunk: Vector2i, create: bool) -> void:
	var span: Array[Vector2i] = _chunk_span(chunk)
	var first: Vector2i = span[0]
	var cells: Vector2i = span[1]
	var corner := Vector3(heights.origin.x + first.x * heights.spacing, 0.0, heights.origin.y + first.y * heights.spacing)
	var parts: Dictionary
	if create:
		parts = {"near": _make_view(corner, 0.0, stats.lod_distance), "far": _make_view(corner, stats.lod_distance, 0.0),
			"shape": _make_shape()}
		_chunks[chunk] = parts
	else:
		parts = _chunks[chunk]
	(parts["near"] as MeshInstance3D).mesh = TerrainChunkMesh.build(heights, stats, first, cells, 1, _light)
	var far_view: MeshInstance3D = parts["far"]
	far_view.visible = stats.lod_step > 1
	far_view.mesh = TerrainChunkMesh.build(heights, stats, first, cells, stats.lod_step, _light) if stats.lod_step > 1 else null
	var shape: CollisionShape3D = parts["shape"]
	var map := shape.shape as HeightMapShape3D
	map.map_width = cells.x + 1
	map.map_depth = cells.y + 1
	var values := PackedFloat32Array()
	values.resize((cells.x + 1) * (cells.y + 1))
	var i: int = 0
	for z: int in cells.y + 1:
		for x: int in cells.x + 1:
			values[i] = heights.sample_height(first.x + x, first.y + z)
			i += 1
	map.map_data = values
	# The shape is centred on its node and one sample apart per unit, so scale it to the spacing.
	shape.position = corner + Vector3(cells.x, 0.0, cells.y) * heights.spacing * 0.5
	shape.scale = Vector3(heights.spacing, 1.0, heights.spacing)


func _make_view(corner: Vector3, range_begin: float, range_end: float) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.position = corner
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.visibility_range_begin = range_begin
	view.visibility_range_end = range_end
	view.material_overlay = _overlay
	add_child(view)
	return view


func _make_shape() -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	shape.shape = HeightMapShape3D.new()
	_body.add_child(shape)
	return shape
