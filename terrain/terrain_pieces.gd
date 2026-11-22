class_name TerrainPieces
extends RefCounted
## The Kenney Space Kit terrain pieces behind each `TerrainLayout.Kind`: mesh, where its middle is, how it must turn
## so a ramp's high side faces north at turn 0, and a collision shape. Measured once from the model and cached. The
## kit's pieces are 1 unit wide and sit off their origin on a grid, so each is re-centred on its own bounds.

const DIR: String = "res://assets/kenney_space_kit/"
const FILES: Dictionary = {
	TerrainLayout.Kind.FLAT: "terrain.glb",
	TerrainLayout.Kind.RAMP: "terrain_ramp.glb",
	TerrainLayout.Kind.ROAD_STRAIGHT: "terrain_roadStraight.glb",
	TerrainLayout.Kind.ROAD_CORNER: "terrain_roadCorner.glb",
	TerrainLayout.Kind.ROAD_CROSS: "terrain_roadCross.glb",
	TerrainLayout.Kind.ROAD_SPLIT: "terrain_roadSplit.glb",
	TerrainLayout.Kind.ROAD_END: "terrain_roadEnd.glb",
}
const NAMES: Dictionary = {
	TerrainLayout.Kind.FLAT: "Flat",
	TerrainLayout.Kind.RAMP: "Ramp",
	TerrainLayout.Kind.ROAD_STRAIGHT: "Road straight",
	TerrainLayout.Kind.ROAD_CORNER: "Road corner",
	TerrainLayout.Kind.ROAD_CROSS: "Road cross",
	TerrainLayout.Kind.ROAD_SPLIT: "Road split",
	TerrainLayout.Kind.ROAD_END: "Road end",
}

## Kind to a Dictionary: mesh, centre (Vector3, model units), yaw (radians), local (the mesh node's transform in the
## model), shape.
static var _cache: Dictionary = {}


static func is_ramp(kind: int) -> bool:
	return kind == TerrainLayout.Kind.RAMP


static func mesh(kind: int) -> Mesh:
	return _info(kind)["mesh"]


static func shape(kind: int) -> Shape3D:
	return _info(kind)["shape"]


## Transform of a tile's mesh (unit size) for a cell: turn, scale and re-centring included. `ground` is the middle of
## the cell at the tile's base height.
static func tile_transform(kind: int, turn: int, ground: Vector3, tile_size: float) -> Transform3D:
	var info: Dictionary = _info(kind)
	var yaw: float = info["yaw"] - turn * PI * 0.5
	var basis := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * tile_size)
	var centre: Vector3 = info["centre"]
	var placed := Transform3D(basis, ground + basis * Vector3(-centre.x, 0.0, -centre.z))
	return placed * (info["local"] as Transform3D)


static func _info(kind: int) -> Dictionary:
	if _cache.has(kind):
		return _cache[kind]
	var root: Node = (load(DIR + FILES[kind]) as PackedScene).instantiate()
	var instance: MeshInstance3D = root.find_children("*", "MeshInstance3D", true, false)[0]
	var local: Transform3D = instance.transform
	var parent: Node = instance.get_parent()
	while parent != root and parent is Node3D:
		local = (parent as Node3D).transform * local
		parent = parent.get_parent()
	var mesh_resource: Mesh = instance.mesh
	var low := Vector3(INF, INF, INF)
	var high := Vector3(-INF, -INF, -INF)
	var points: PackedVector3Array = PackedVector3Array()
	for surface: int in mesh_resource.get_surface_count():
		for vertex: Vector3 in mesh_resource.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			var point: Vector3 = local * vertex
			points.append(point)
			low = low.min(point)
			high = high.max(point)
	var centre: Vector3 = (low + high) * 0.5
	var yaw: float = 0.0
	if kind == TerrainLayout.Kind.RAMP:
		yaw = _ramp_yaw(points, centre, high.y)
	var info: Dictionary = {"mesh": mesh_resource, "centre": centre, "yaw": yaw, "local": local}
	info["shape"] = _shape(mesh_resource, local, centre, yaw)
	root.free()
	_cache[kind] = info
	return info


## The yaw that turns the ramp's high side (where its vertices are tallest) to face -Z.
static func _ramp_yaw(points: PackedVector3Array, centre: Vector3, top: float) -> float:
	var sum := Vector3.ZERO
	var count: int = 0
	for point: Vector3 in points:
		if point.y > top * 0.9:
			sum += point - centre
			count += 1
	var high_side: Vector3 = Vector3(sum.x, 0.0, sum.z) / maxf(count, 1)
	var best: float = 0.0
	var best_dot: float = -INF
	for quarter: int in 4:
		var yaw: float = quarter * PI * 0.5
		var turned: Vector3 = Basis(Vector3.UP, yaw) * high_side
		var dot: float = turned.dot(Vector3(0, 0, -1))
		if dot > best_dot:
			best_dot = dot
			best = yaw
	return best


## Collision of one tile at unit size (re-centred), so a placement only scales and turns it.
static func _shape(mesh_resource: Mesh, local: Transform3D, centre: Vector3, _yaw: float) -> Shape3D:
	var faces: PackedVector3Array = mesh_resource.get_faces()
	var moved := PackedVector3Array()
	for vertex: Vector3 in faces:
		moved.append(local * vertex - Vector3(centre.x, 0.0, centre.z))
	var concave := ConcavePolygonShape3D.new()
	concave.backface_collision = true
	concave.set_faces(moved)
	return concave
