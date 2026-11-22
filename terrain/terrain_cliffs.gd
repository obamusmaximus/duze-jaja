class_name TerrainCliffs
extends RefCounted
## Builds the cliff faces of a terrain: one vertical wall wherever two neighbouring tiles meet at different heights,
## and a skirt down to the ground from every raised tile's open edges. Generated from the layout, so any painted
## shape gets proper walls. Returns one mesh; the TerrainMap shows it and makes its collision.

## The four neighbours as (dx, dz): east, south, west, north.
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]


static func build(layout: TerrainLayout, tile_size: float, color: Color) -> ArrayMesh:
	var step: float = tile_size * 0.5
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any: bool = false
	for cell: Vector2i in layout.cells():
		var tile: Vector3i = layout.get_cell(cell)
		for side: int in SIDES.size():
			var other_cell: Vector2i = cell + SIDES[side]
			var other: Vector3i = layout.get_cell(other_cell)
			var here: Vector2 = _edge(tile, side, step)
			if other == TerrainLayout.NONE:
				if here.x > 0.001 or here.y > 0.001:
					_wall(surface, cell, side, tile_size, here, Vector2.ZERO, SIDES[side])
					any = true
			elif side < 2:  # Each shared edge once (east and south of each tile).
				var there: Vector2 = _edge(other, (side + 2) % 4, step)
				if not here.is_equal_approx(there):
					var out: Vector2i = SIDES[side] if here.x + here.y > there.x + there.y else -SIDES[side]
					_wall(surface, cell, side, tile_size, here, there, out)
					any = true
	if not any:
		return null
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	return surface.commit()


## Heights (metres) of the two corners of a tile's edge on `side`, in the order along +X or +Z.
static func _edge(tile: Vector3i, side: int, step: float) -> Vector2:
	var corners: Array[Vector2i]
	match side:
		0: corners = [Vector2i(1, -1), Vector2i(1, 1)]
		1: corners = [Vector2i(-1, 1), Vector2i(1, 1)]
		2: corners = [Vector2i(-1, -1), Vector2i(-1, 1)]
		_: corners = [Vector2i(-1, -1), Vector2i(1, -1)]
	return Vector2(_corner(tile, corners[0], step), _corner(tile, corners[1], step))


## Height of one corner (each coordinate -1 or 1) of a tile: a ramp's high-side corners are one step up.
static func _corner(tile: Vector3i, corner: Vector2i, step: float) -> float:
	var height: float = tile.z * step
	if TerrainPieces.is_ramp(tile.x):
		var high: Vector2i = SIDES[(tile.y + 3) % 4]  # Turn 0 is north (0, -1); each turn goes clockwise.
		if corner.x * high.x + corner.y * high.y > 0:
			height += step
	return height


## A wall along `side` of `cell` between the edge heights `a` (this tile's) and `b` (the other side's).
static func _wall(surface: SurfaceTool, cell: Vector2i, side: int, tile_size: float, a: Vector2, b: Vector2, out: Vector2i) -> void:
	var x0: float = cell.x * tile_size
	var z0: float = cell.y * tile_size
	var p0: Vector2
	var p1: Vector2
	match side:
		0: p0 = Vector2(x0 + tile_size, z0); p1 = Vector2(x0 + tile_size, z0 + tile_size)
		1: p0 = Vector2(x0, z0 + tile_size); p1 = Vector2(x0 + tile_size, z0 + tile_size)
		2: p0 = Vector2(x0, z0); p1 = Vector2(x0, z0 + tile_size)
		_: p0 = Vector2(x0, z0); p1 = Vector2(x0 + tile_size, z0)
	var normal := Vector3(out.x, 0.0, out.y)
	var corners: Array[Vector3] = [
		Vector3(p0.x, a.x, p0.y), Vector3(p1.x, a.y, p1.y), Vector3(p1.x, b.y, p1.y), Vector3(p0.x, b.x, p0.y)]
	for index: int in [0, 1, 2, 0, 2, 3]:
		surface.set_normal(normal)
		surface.add_vertex(corners[index])
