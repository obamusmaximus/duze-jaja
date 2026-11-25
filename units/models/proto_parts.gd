class_name ProtoParts
extends RefCounted
## Helpers for primitive prototype models (`docs/style_guide.md`, prototyping rules): hard-edged boxes, low-sided
## cylinders and wedges in shared palette materials. A model built from these is a scene in `units/models/` named
## `*_proto.tscn`, plugged into a `UnitStats.model` like an imported one, so an artist's `.glb` replaces it by
## changing that one field. Origin of a model: middle of the footprint, underside at y = 0, front toward -Z.

## Placeholder named like the imported livery material, so `ModelFit` (`WorldMaterials.recolour`) swaps in the team's.
static var _livery: StandardMaterial3D


static func box(parent: Node3D, part_name: String, size: Vector3, at: Vector3, role: WorldMaterials.Role) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, part_name, mesh, at, WorldMaterials.role(role))


## A box in the team's livery colour (the model's one deliberate accent block).
static func livery_box(parent: Node3D, part_name: String, size: Vector3, at: Vector3) -> MeshInstance3D:
	if _livery == null:
		_livery = StandardMaterial3D.new()
		_livery.resource_name = "metalRed"
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, part_name, mesh, at, _livery)


## A low-sided cylinder lying across the model (a wheel): its axis along X.
static func wheel(parent: Node3D, part_name: String, radius: float, width: float, at: Vector3, role: WorldMaterials.Role) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = width
	mesh.radial_segments = 8
	mesh.rings = 1
	var node: MeshInstance3D = _add(parent, part_name, mesh, at, WorldMaterials.role(role))
	node.rotation_degrees.z = 90.0
	return node


## A low-sided cylinder along Z (a gun barrel), `length` long, its middle at `at`.
static func barrel(parent: Node3D, part_name: String, radius: float, length: float, at: Vector3, role: WorldMaterials.Role) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 6
	mesh.rings = 1
	var node: MeshInstance3D = _add(parent, part_name, mesh, at, WorldMaterials.role(role))
	node.rotation_degrees.x = 90.0
	return node


## A wedge in profile: its full height at the back (+Z), sloping down to nothing at the front (-Z), as a glacis
## plate. `size` is width, height and length; `at` is the middle of its bounding box.
static func wedge(parent: Node3D, part_name: String, size: Vector3, at: Vector3, role: WorldMaterials.Role) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = Vector3(size.z, size.y, size.x)
	mesh.left_to_right = 0.0
	var node: MeshInstance3D = _add(parent, part_name, mesh, at, WorldMaterials.role(role))
	node.rotation_degrees.y = 90.0
	return node


static func marker(parent: Node3D, marker_name: String, at: Vector3) -> Marker3D:
	var point := Marker3D.new()
	point.name = marker_name
	point.position = at
	parent.add_child(point)
	return point


static func _add(parent: Node3D, part_name: String, mesh: PrimitiveMesh, at: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = part_name
	(mesh as PrimitiveMesh).material = material
	node.mesh = mesh
	node.position = at
	parent.add_child(node)
	return node
