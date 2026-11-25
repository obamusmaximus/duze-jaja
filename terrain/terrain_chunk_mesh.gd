class_name TerrainChunkMesh
extends RefCounted
## Builds the flat-shaded facet mesh of one terrain chunk from `TerrainHeights`: two triangles per quad, one surface
## per palette role (materials come from `WorldMaterials`, so the ground recolours with the palette). Roles are
## painted or picked from slope and height (`HeightmapStats`, "Surface").


## The mesh for the cells (`first`, `cells`) of `heights`, using every `step`-th sample (a coarser level of detail).
## Positions are relative to the chunk's corner sample. Null if nothing to draw.
static func build(heights: TerrainHeights, stats: HeightmapStats, first: Vector2i, cells: Vector2i, step: int,
		light: TerrainLight = null) -> ArrayMesh:
	var positions: Dictionary = {}
	var normals: Dictionary = {}
	var colors: Dictionary = {}
	var spacing: float = heights.spacing
	var corner := Vector3(first.x * spacing, 0.0, first.y * spacing)
	var rock_cos: float = cos(deg_to_rad(stats.rock_slope_deg))
	for cz: int in range(0, cells.y, step):
		var nz: int = mini(cz + step, cells.y)
		for cx: int in range(0, cells.x, step):
			var nx: int = mini(cx + step, cells.x)
			var ix0: int = first.x + cx
			var iz0: int = first.y + cz
			var ix1: int = first.x + nx
			var iz1: int = first.y + nz
			var p00 := Vector3(cx * spacing, heights.sample_height(ix0, iz0), cz * spacing)
			var p10 := Vector3(nx * spacing, heights.sample_height(ix1, iz0), cz * spacing)
			var p01 := Vector3(cx * spacing, heights.sample_height(ix0, iz1), nz * spacing)
			var p11 := Vector3(nx * spacing, heights.sample_height(ix1, iz1), nz * spacing)
			var painted: int = heights.painted_role(ix0, iz0)
			var c00 := Color.WHITE
			var c10 := Color.WHITE
			var c01 := Color.WHITE
			var c11 := Color.WHITE
			if light != null:
				c00 = light.color_at(ix0, iz0)
				c10 = light.color_at(ix1, iz0)
				c01 = light.color_at(ix0, iz1)
				c11 = light.color_at(ix1, iz1)
			_triangle(positions, normals, colors, stats, rock_cos, painted, [p00, p01, p10], [c00, c01, c10])
			_triangle(positions, normals, colors, stats, rock_cos, painted, [p10, p01, p11], [c10, c01, c11])
	if positions.is_empty():
		return null
	var mesh := ArrayMesh.new()
	for role: int in positions:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = positions[role]
		arrays[Mesh.ARRAY_NORMAL] = normals[role]
		arrays[Mesh.ARRAY_COLOR] = colors[role]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, WorldMaterials.role(role as WorldMaterials.Role))
	return mesh


static func _triangle(positions: Dictionary, normals: Dictionary, colors: Dictionary, stats: HeightmapStats,
		rock_cos: float, painted: int, corners: Array, shades: Array) -> void:
	var a: Vector3 = corners[0]
	var b: Vector3 = corners[1]
	var c: Vector3 = corners[2]
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	var role: int = painted if painted >= 0 else _auto_role(stats, rock_cos, normal, (a.y + b.y + c.y) / 3.0)
	# Packed arrays are values: take it out, append, put it back.
	var verts: PackedVector3Array = positions.get(role, PackedVector3Array())
	var faces: PackedVector3Array = normals.get(role, PackedVector3Array())
	var tints: PackedColorArray = colors.get(role, PackedColorArray())
	# Godot's front face is clockwise seen from the front, so the vertices go a, c, b for the up-pointing normal.
	verts.append_array(PackedVector3Array([a, c, b]))
	faces.append_array(PackedVector3Array([normal, normal, normal]))
	tints.append_array(PackedColorArray([shades[0], shades[2], shades[1]])) # Same a, c, b order as the vertices.
	positions[role] = verts
	normals[role] = faces
	colors[role] = tints


## The role of a facet picked from its steepness and mean height (world y, the sea at 0).
static func _auto_role(stats: HeightmapStats, rock_cos: float, normal: Vector3, height: float) -> int:
	if height < MapGrid.SEA_LEVEL:
		return WorldMaterials.Role.STONE_DARK if height < -stats.deep_depth else WorldMaterials.Role.SAND
	if normal.y < rock_cos:
		return WorldMaterials.Role.STONE
	if height < stats.beach_height:
		return WorldMaterials.Role.SAND
	if height > stats.soil_height:
		return WorldMaterials.Role.SOIL
	return WorldMaterials.Role.GRASS
