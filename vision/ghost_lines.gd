class_name GhostLines
extends RefCounted
## Visual only: the wireframe of a unit type's model for its last-known ghost (`LastKnownGhosts`). Keeps only the
## feature edges (the outline and the creases between facets), so a low-poly model reads as a clean line drawing
## rather than a mesh of triangles. Built once per type and cached; placed like `UnitLook` places the model (centred
## on its footprint, underside at the unit's origin).

## Facets meeting at less than this angle (degrees) are one surface: their shared edge is left out.
const CREASE_DEG: float = 28.0
## Vertices closer than this (model metres) are one point, so split flat-shaded vertices join up.
const WELD: float = 0.001

## UnitStats to its ArrayMesh of lines; private (see STATUS, static vars holding resources).
static var _cache: Dictionary = {}


## The line mesh of `type`'s model, or null if it has none. Vertex y runs from 0 (underside) upward; the mesh's AABB
## tells its height.
static func of(type: UnitStats) -> ArrayMesh:
	if type == null or type.model == null:
		return null
	if _cache.has(type):
		return _cache[type]
	var holder: Node3D = ModelFit.instance(type.model, type.model_scale, type.model_yaw_deg)
	var lines := PackedVector3Array()
	_collect(holder, Transform3D.IDENTITY, lines)
	holder.free()
	var mesh: ArrayMesh = null
	if not lines.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = lines
		mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	_cache[type] = mesh
	return mesh


## Adds the feature edges of every mesh under `node` to `lines` (pairs of points), in the holder's space.
static func _collect(node: Node, to_holder: Transform3D, lines: PackedVector3Array) -> void:
	var here: Transform3D = to_holder
	if node is Node3D:
		here = to_holder * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		_edges_of((node as MeshInstance3D).mesh, here, lines)
	for child: Node in node.get_children():
		_collect(child, here, lines)


static func _edges_of(mesh: Mesh, to_holder: Transform3D, lines: PackedVector3Array) -> void:
	# Welded edge key to [a, b, first normal, crease found]; an edge seen twice at an angle is a crease.
	var edges: Dictionary = {}
	var limit: float = cos(deg_to_rad(CREASE_DEG))
	for surface: int in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var count: int = indices.size() if not indices.is_empty() else points.size()
		for t: int in range(0, count - 2, 3):
			var corner := PackedVector3Array()
			for k: int in 3:
				var at: int = indices[t + k] if not indices.is_empty() else t + k
				corner.append(to_holder * points[at])
			var normal: Vector3 = (corner[1] - corner[0]).cross(corner[2] - corner[0])
			if normal.length_squared() < 1e-12:
				continue
			normal = normal.normalized()
			for k: int in 3:
				_add_edge(edges, corner[k], corner[(k + 1) % 3], normal, limit)
	for key: String in edges:
		var edge: Array = edges[key]
		if edge[3] or edge[4] == 1:
			lines.append(edge[0])
			lines.append(edge[1])


static func _add_edge(edges: Dictionary, a: Vector3, b: Vector3, normal: Vector3, limit: float) -> void:
	var ka: String = _weld_key(a)
	var kb: String = _weld_key(b)
	if ka == kb:
		return
	var key: String = ka + "|" + kb if ka < kb else kb + "|" + ka
	var edge: Array = edges.get(key, [])
	if edge.is_empty():
		edges[key] = [a, b, normal, false, 1]
		return
	edge[4] = int(edge[4]) + 1
	if (edge[2] as Vector3).dot(normal) < limit:
		edge[3] = true


static func _weld_key(point: Vector3) -> String:
	var q := Vector3i((point / WELD).round())
	return "%d,%d,%d" % [q.x, q.y, q.z]
