class_name HullPoints
extends RefCounted
## Visual only: the vertices of a model in one node's space, to hang things (lamps, searchlights) on the hull's
## surface.

var points := PackedVector3Array()


## Collects every mesh under `model` in `frame`'s space. Both must be in the tree. With no model (or no mesh) it is a
## box of half-size `fallback_half` round the origin.
func _init(frame: Node3D, model: Node3D, fallback_half: Vector3) -> void:
	if model != null and model.is_inside_tree():
		_collect(frame, model)
	if points.is_empty():
		for corner: int in 8:
			points.append(Vector3(fallback_half.x * (1 if corner & 1 else -1), fallback_half.y * (1 if corner & 2 else -1),
				fallback_half.z * (1 if corner & 4 else -1)))


## The vertex farthest along `direction`.
func support(direction: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var best_reach: float = -INF
	var toward: Vector3 = direction.normalized()
	for point: Vector3 in points:
		var reach: float = point.dot(toward)
		if reach > best_reach:
			best_reach = reach
			best = point
	return best


## The middle of all the vertices within `slack` metres of the farthest along `direction`: the middle of a wingtip's
## edge, where `support` gives one of its corners.
func tip(direction: Vector3, slack: float) -> Vector3:
	var toward: Vector3 = direction.normalized()
	var farthest: float = support(toward).dot(toward)
	var found := AABB()
	var any: bool = false
	for point: Vector3 in points:
		if point.dot(toward) < farthest - slack:
			continue
		found = found.expand(point) if any else AABB(point, Vector3.ZERO)
		any = true
	return found.get_center()


func _collect(frame: Node3D, node: Node) -> void:
	var mesh_node := node as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		var to_frame: Transform3D = frame.global_transform.affine_inverse() * mesh_node.global_transform
		for surface: int in mesh_node.mesh.get_surface_count():
			var arrays: Array = mesh_node.mesh.surface_get_arrays(surface)
			for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array:
				points.append(to_frame * vertex)
	for child: Node in node.get_children():
		_collect(frame, child)
