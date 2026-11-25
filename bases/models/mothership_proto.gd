class_name MothershipProto
extends Node3D
## Prototype hull for a hovering mothership, built from primitives at true scale (style guide, prototyping rules).
## Origin: middle of the underside, bow toward -z. Attachment points an artist's version must also provide:
## `CarryallPad0..n`, `ProductionBay0..n` (under the hull) and `NavalDropBay` (stern, reserved), all `Marker3D`.


## Builds the hull from the stats; `team` picks the livery stripes.
func build(stats: MothershipStats, team: int) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var length: float = stats.hull_length
	var beam: float = stats.beam
	var height: float = stats.hull_height
	var prow: float = beam * stats.prow_ratio
	_box("Hull", Vector3(beam, height, length), Vector3(0.0, height * 0.5, 0.0), WorldMaterials.Role.HULL_MID)
	var wedge := MeshInstance3D.new()
	wedge.name = "Prow"
	var prism := PrismMesh.new()
	prism.size = Vector3(beam, prow, height)
	prism.material = WorldMaterials.role(WorldMaterials.Role.HULL_MID)
	wedge.mesh = prism
	wedge.rotation_degrees.x = -90.0
	wedge.position = Vector3(0.0, height * 0.5, -length * 0.5 - prow * 0.5)
	add_child(wedge)
	_box("Superstructure", Vector3(beam * 0.4, height * 0.5, length * 0.18), Vector3(0.0, height * 1.25, length * 0.36), WorldMaterials.Role.HULL)
	_box("Bridge", Vector3(beam * 0.2, height * 0.3, length * 0.06), Vector3(0.0, height * 1.65, length * 0.38), WorldMaterials.Role.HULL_DARK)
	for side: float in [-1.0, 1.0]:
		_box("Livery", Vector3(3.0, 0.6, length * 0.9), Vector3(side * (beam * 0.5 - 3.0), height + 0.3, 0.0), WorldMaterials.Role.LIVERY, team)
		_engine_pod(side, beam, length, height)
	_pads(stats, length, beam, height)
	_bays(stats, length, beam)
	_marker("NavalDropBay", Vector3(0.0, height * 0.2, length * 0.5))


func _pads(stats: MothershipStats, length: float, beam: float, height: float) -> void:
	var count: int = stats.carryall_pads
	if count == 0:
		return
	var span: float = length * 0.6
	var pitch: float = span / float(count)
	var size: float = minf(beam * 0.6, pitch * 0.85)
	for i: int in count:
		var z: float = -length * 0.45 + pitch * (float(i) + 0.5)
		_box("PadRim%d" % i, Vector3(size + 3.0, 0.4, size + 3.0), Vector3(0.0, height + 0.2, z), WorldMaterials.Role.WARNING)
		_box("Pad%d" % i, Vector3(size, 0.6, size), Vector3(0.0, height + 0.5, z), WorldMaterials.Role.HULL_DARK)
		_marker("CarryallPad%d" % i, Vector3(0.0, height + 0.8, z))


func _bays(stats: MothershipStats, length: float, beam: float) -> void:
	var count: int = stats.production_bays
	if count == 0:
		return
	var pitch: float = length * 0.8 / float(count)
	for i: int in count:
		var z: float = -length * 0.4 + pitch * (float(i) + 0.5)
		_box("BayDoor%d" % i, Vector3(beam * 0.5, 3.0, pitch * 0.7), Vector3(0.0, -1.0, z), WorldMaterials.Role.HULL_DARK)
		_marker("ProductionBay%d" % i, Vector3(0.0, -3.5, z))


func _engine_pod(side: float, beam: float, length: float, height: float) -> void:
	var x: float = side * (beam * 0.5 + 7.0)
	var z: float = length * 0.5 - 22.0
	var y: float = height * 0.4
	_box("EnginePod", Vector3(14.0, 16.0, 44.0), Vector3(x, y, z), WorldMaterials.Role.HULL_MID)
	var nozzle := MeshInstance3D.new()
	nozzle.name = "Thruster"
	var cone := CylinderMesh.new()
	cone.top_radius = 5.0
	cone.bottom_radius = 7.0
	cone.height = 8.0
	cone.radial_segments = 8
	cone.material = WorldMaterials.role(WorldMaterials.Role.HULL_DARK)
	nozzle.mesh = cone
	nozzle.position = Vector3(x, y - 12.0, z)
	add_child(nozzle)


func _box(box_name: String, size: Vector3, at: Vector3, role: WorldMaterials.Role, team: int = -1) -> void:
	var node := MeshInstance3D.new()
	node.name = box_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = WorldMaterials.role(role, team)
	node.mesh = mesh
	node.position = at
	add_child(node)


func _marker(marker_name: String, at: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = at
	add_child(marker)
