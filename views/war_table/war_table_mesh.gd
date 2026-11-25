class_name WarTableMesh
extends RefCounted
## Visual only: builds the war table's ground as flat-shaded coloured facets from `TerrainHeights`, one tile at a time.
## Shading is painted into the vertex colours (the material is unshaded), so no light touches the table.

const SEA_LEVEL: float = 0.0


## The mesh of the tile whose first table cell is `first` (cell indices), `cells` wide, at `origin_y` above the world.
static func build_tile(heights: TerrainHeights, stats: WarTableStats, first: Vector2i, cells: Vector2i) -> ArrayMesh:
	var step: float = heights.spacing * float(stats.sample_step)
	var light: Vector3 = stats.light_direction.normalized()
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for cz: int in cells.y:
		for cx: int in cells.x:
			var x0: float = heights.origin.x + float(first.x + cx) * step
			var z0: float = heights.origin.y + float(first.y + cz) * step
			var a: Vector3 = _point(heights, stats, x0, z0)
			var b: Vector3 = _point(heights, stats, x0 + step, z0)
			var c: Vector3 = _point(heights, stats, x0, z0 + step)
			var d: Vector3 = _point(heights, stats, x0 + step, z0 + step)
			_facet(stats, light, a, c, b, verts, colors)
			_facet(stats, light, b, c, d, verts, colors)
	var mesh := ArrayMesh.new()
	if verts.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _point(heights: TerrainHeights, stats: WarTableStats, x: float, z: float) -> Vector3:
	var h: float = heights.height_at(x, z)
	var shown: float = h * stats.height_scale if h > SEA_LEVEL else h * stats.depth_scale
	return Vector3(x, stats.table_height + shown, z)


static func _facet(stats: WarTableStats, light: Vector3, a: Vector3, b: Vector3, c: Vector3,
		verts: PackedVector3Array, colors: PackedColorArray) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	var mean: float = (a.y + b.y + c.y) / 3.0 - stats.table_height
	var base: Color = _ground_color(mean, stats)
	var shade: float = 1.0 - stats.shade_strength + stats.shade_strength * clampf(normal.dot(light), 0.0, 1.0) * 1.4
	var color := Color(base.r * shade, base.g * shade, base.b * shade, 1.0)
	verts.append_array([a, b, c])
	colors.append_array([color, color, color])


## Sea blue by depth, then sand at the shore, grass inland, stone high up (shown heights, after the scale).
static func _ground_color(shown: float, stats: WarTableStats) -> Color:
	if shown <= 0.0:
		var depth: float = clampf(-shown / (60.0 * maxf(stats.depth_scale, 0.01)), 0.0, 1.0)
		return UiTokens.WORLD_SEA_SHALLOW.lerp(UiTokens.WORLD_SEA_DEEP, depth)
	var land: float = shown / stats.height_scale
	if land < 2.5:
		return WorldMaterials.role(WorldMaterials.Role.SAND).albedo_color
	if land < 16.0:
		return WorldMaterials.role(WorldMaterials.Role.GRASS).albedo_color
	return WorldMaterials.role(WorldMaterials.Role.STONE).albedo_color
