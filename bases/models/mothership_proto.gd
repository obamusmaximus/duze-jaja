class_name MothershipProto
extends Node3D
## Prototype hull for a hovering mothership, built from primitives at true scale (style guide, prototyping rules).
## Origin: middle of the underside, bow toward -z. Attachment points an artist's version must also provide:
## `CarryallPad0..n`, `ExplorerPad0`, `ProductionBay0..n` (under the hull) and `NavalDropBay` (stern, reserved), all `Marker3D`.

## Not a `const`: GDScript folds a const resource's properties at compile time, and live edits would not show.
## Read from outside through `lamp_stats()`: a direct read of another script's `static var` breaks the engine's cleanup at exit.
static var _lamp_stats: LampStats = preload("res://tuning/lamp_default.tres")
## Height over a pad's deck of its lamps and its pool.
const LAMP_LIFT: float = 1.0
const POOL_LIFT: float = 0.9


static func lamp_stats() -> LampStats:
	return _lamp_stats



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
	_helipads(stats, length, beam, height)
	_explorer_pad(length, beam, height, prow)
	_bays(stats, length, beam)
	_marker("NavalDropBay", Vector3(0.0, height * 0.2, length * 0.5))
	_hull_lamps(stats, team)


## The ship's own lamps, as on any aircraft (red port, green starboard, white stern, strobes at the bow and over the
## bridge), and team-colour lamps along both deck edges.
func _hull_lamps(stats: MothershipStats, team: int) -> void:
	var length: float = stats.hull_length
	var half: float = stats.beam * 0.5
	var height: float = stats.hull_height
	var prow: float = stats.beam * stats.prow_ratio
	var scale: float = _lamp_stats.ship_nav_scale
	var lamps := LampSet.new()
	add_child(lamps)
	for end: float in [-0.35, 0.35]:
		lamps.add(Vector3(-half, height, length * end), UiTokens.WORLD_LAMP_PORT, _lamp_stats.nav_size * scale, _lamp_stats.nav_min_px)
		lamps.add(Vector3(half, height, length * end), UiTokens.WORLD_LAMP_STARBOARD, _lamp_stats.nav_size * scale,
				_lamp_stats.nav_min_px)
	lamps.add(Vector3(0.0, height, length * 0.5), UiTokens.WORLD_LAMP_WHITE, _lamp_stats.tail_size * scale, _lamp_stats.tail_min_px)
	var strobes: Array[Vector3] = [Vector3(0.0, height + 1.0, -length * 0.5 - prow),
			Vector3(0.0, height * 1.85, length * 0.38)]
	for i: int in strobes.size():
		lamps.add(strobes[i], UiTokens.WORLD_LAMP_WHITE, _lamp_stats.strobe_size * scale, _lamp_stats.strobe_min_px, 1.0,
				LampSet.Pattern.STROBE, _lamp_stats.strobe_period, i * 0.5)
	var color: Color = UiTokens.team_color(team)
	var count: int = maxi(1, roundi(length / _lamp_stats.ship_edge_spacing))
	for i: int in count + 1:
		for side: float in [-1.0, 1.0]:
			lamps.add(Vector3(side * half, height + LAMP_LIFT, (float(i) / count - 0.5) * length), color, _lamp_stats.edge_size,
					_lamp_stats.edge_min_px)


## White lamps at a deck pad's corners and a soft pool on it.
func _pad_lights(size: Vector2, at: Vector3) -> void:
	var lamps := LampSet.new()
	add_child(lamps)
	for corner: int in 4:
		lamps.add(at + Vector3((1 if corner & 1 else -1) * size.x * 0.5, LAMP_LIFT,
				(1 if corner & 2 else -1) * size.y * 0.5), UiTokens.WORLD_LAMP_WHITE, _lamp_stats.pad_size, _lamp_stats.pad_min_px,
				_lamp_stats.pad_strength)
	var pool := LightPool.new()
	pool.setup(size * 1.4, UiTokens.WORLD_LAMP_WHITE, _lamp_stats.pad_pool)
	pool.position = at + Vector3.UP * POOL_LIFT
	add_child(pool)


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
		_pad_lights(Vector2.ONE * size, Vector3(0.0, height, z))


## On the prow, ahead of the carryall pads: long enough for an Explorer lying along the ship.
func _explorer_pad(length: float, beam: float, height: float, prow: float) -> void:
	var size := Vector2(beam * 0.38, prow * 0.76)
	var z: float = -length * 0.5 - prow * 0.17
	_box("ExplorerPadRim", Vector3(size.x + 2.0, 0.4, size.y + 2.0), Vector3(0.0, height + 0.2, z), WorldMaterials.Role.WARNING)
	_box("ExplorerPadDeck", Vector3(size.x, 0.6, size.y), Vector3(0.0, height + 0.5, z), WorldMaterials.Role.HULL_DARK)
	_marker("ExplorerPad0", Vector3(0.0, height + 0.8, z))
	_pad_lights(size, Vector3(0.0, height, z))


## Two rows of three between the carryall pads and the superstructure.
func _helipads(stats: MothershipStats, length: float, beam: float, height: float) -> void:
	var size: float = minf(beam * 0.14, length * 0.035)
	for i: int in stats.helipads:
		var x: float = (float(i % 3) - 1.0) * beam * 0.27
		var z: float = length * (0.19 if i < 3 else 0.235)
		_box("HeliPadRim%d" % i, Vector3(size + 1.5, 0.4, size + 1.5), Vector3(x, height + 0.2, z), WorldMaterials.Role.WARNING)
		_box("HeliPadDeck%d" % i, Vector3(size, 0.6, size), Vector3(x, height + 0.5, z), WorldMaterials.Role.HULL_DARK)
		_marker("HeliPad%d" % i, Vector3(x, height + 0.8, z))
		_pad_lights(Vector2.ONE * size, Vector3(x, height, z))


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
