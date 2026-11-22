class_name ModelFit
extends RefCounted
## Visual only: instances an imported model (a .glb) ready to place. Imported kits keep each mesh at an odd offset
## from its origin (Kenney's sit on a tile grid), so the model is shifted to be centred over its origin with its
## base at y = 0, then scaled and turned about that origin. Bounds are measured once per model and cached.

## Model scene to the model's bounds in its own space.
static var _bounds: Dictionary = {}


## A new node holding `scene` centred on its footprint with its underside at y = 0, scaled by `model_scale` and
## turned `yaw_deg` degrees about the vertical axis. Its materials are recoloured into the world palette
## (`WorldMaterials`), with `team` colouring the livery parts (-1: no team).
static func instance(scene: PackedScene, model_scale: float, yaw_deg: float, team: int = -1) -> Node3D:
	var model: Node3D = scene.instantiate() as Node3D
	WorldMaterials.recolour(model, team)
	var bounds: AABB = _bounds_of(scene, model)
	model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * model_scale
	holder.rotation_degrees.y = yaw_deg
	holder.add_child(model)
	return holder


static func _bounds_of(scene: PackedScene, model: Node3D) -> AABB:
	if not _bounds.has(scene):
		var found: Array[AABB] = []
		_collect(model, Transform3D.IDENTITY, found)
		_bounds[scene] = found[0] if not found.is_empty() else AABB()
	return _bounds[scene]


## Merges the bounds of every mesh under `node` into `found[0]`. `to_root` takes `node`'s space to the model root's.
static func _collect(node: Node, to_root: Transform3D, found: Array[AABB]) -> void:
	for child: Node in node.get_children():
		var child_3d := child as Node3D
		if child_3d == null:
			continue
		var child_to_root: Transform3D = to_root * child_3d.transform
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh != null:
			var box: AABB = child_to_root * mesh_instance.mesh.get_aabb()
			if found.is_empty():
				found.append(box)
			else:
				found[0] = found[0].merge(box)
		_collect(child, child_to_root, found)
