class_name AirfieldLook
extends Node3D
## Visual only: placeholder airfield from primitives at true scale (style guide, prototyping rules): the deck on its
## plinth, six marked helipads and a hangar behind each, open toward its pad, with the team's livery on the roof.

const WALL: float = 0.5
const MARK_HEIGHT: float = 0.06
## Not a `const`: GDScript folds a const resource's properties at compile time, and live edits would not show.
static var lamp_stats: LampStats = preload("res://tuning/lamp_default.tres")
## Lamps and pools lie this far over the deck, clear of the pad markings.
const LAMP_LIFT: float = 0.25
const POOL_LIFT: float = 0.14


var _field: Airfield
var _plinth: float = 0.0


## `plinth` is how far the deck stands above the lowest ground under it.
func build(field: Airfield, plinth: float) -> void:
	_field = field
	_plinth = plinth
	if not lamp_stats.changed.is_connected(_rebuild):
		lamp_stats.changed.connect(_rebuild)
	var size: Vector2 = field.deck_size()
	var depth: float = plinth + 1.0
	_box(self, Vector3(size.x, depth, size.y), Vector3(0.0, -depth * 0.5, 0.0), WorldMaterials.Role.HULL_MID)
	var pad_side: float = field.stats.pad_size
	for pad: Pad in field.pads:
		var spot := Node3D.new()
		spot.position = pad.position - field.global_position
		spot.rotation.y = pad.yaw
		add_child(spot)
		# Layers a little apart, so they never fight for the same depth.
		_box(spot, Vector3(pad_side, MARK_HEIGHT, pad_side), Vector3(0.0, 0.02, 0.0), WorldMaterials.Role.WARNING)
		_box(spot, Vector3(pad_side - 0.8, MARK_HEIGHT, pad_side - 0.8), Vector3(0.0, 0.04, 0.0),
				WorldMaterials.Role.HULL_DARK)
		for x: float in [-1.4, 1.4]:
			_box(spot, Vector3(0.6, MARK_HEIGHT, 4.4), Vector3(x, 0.07, 0.0), WorldMaterials.Role.TRIM)
		_box(spot, Vector3(2.8, MARK_HEIGHT, 0.6), Vector3(0.0, 0.07, 0.0), WorldMaterials.Role.TRIM)
		_hangar(spot, field)
		_pad_lights(spot, pad_side)
	_deck_lights(size, field.team)


## A lamp setting changed: the lamps and pools are baked into the look, so all of it is built again.
func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	build(_field, _plinth)


## White lamps at the pad's corners and a soft pool on it.
func _pad_lights(spot: Node3D, side: float) -> void:
	var lamps := LampSet.new()
	spot.add_child(lamps)
	for corner: int in 4:
		lamps.add(Vector3((1 if corner & 1 else -1) * side * 0.5, LAMP_LIFT, (1 if corner & 2 else -1) * side * 0.5),
				UiTokens.WORLD_LAMP_WHITE, lamp_stats.pad_size, lamp_stats.pad_min_px, lamp_stats.pad_strength)
	var pool := LightPool.new()
	pool.setup(Vector2.ONE * side * 1.5, UiTokens.WORLD_LAMP_WHITE, lamp_stats.pad_pool)
	pool.position.y = POOL_LIFT
	spot.add_child(pool)


## Team-colour lamps round the deck's edge and a team-colour pool over it: whose field it is, from afar.
func _deck_lights(size: Vector2, team: int) -> void:
	var color: Color = UiTokens.team_color(team)
	var lamps := LampSet.new()
	add_child(lamps)
	var across: int = maxi(1, roundi(size.x / lamp_stats.airfield_edge_spacing))
	var along: int = maxi(1, roundi(size.y / lamp_stats.airfield_edge_spacing))
	for i: int in across + 1:
		for z: float in [-0.5, 0.5]:
			lamps.add(Vector3((float(i) / across - 0.5) * size.x, LAMP_LIFT, z * size.y), color, lamp_stats.edge_size,
					lamp_stats.edge_min_px)
	for i: int in range(1, along):
		for x: float in [-0.5, 0.5]:
			lamps.add(Vector3(x * size.x, LAMP_LIFT, (float(i) / along - 0.5) * size.y), color, lamp_stats.edge_size,
					lamp_stats.edge_min_px)
	var pool := LightPool.new()
	pool.setup(size, color, lamp_stats.airfield_pool, 0.4)
	pool.position.y = POOL_LIFT - 0.02
	add_child(pool)


## In the pad's space: -z is the way its craft faces, so the hangar is at +z with its mouth toward -z.
func _hangar(spot: Node3D, field: Airfield) -> void:
	var depth: float = field.stats.hangar_size.x
	var height: float = field.stats.hangar_size.y
	var width: float = field.stats.hangar_size.z
	var middle: float = field.stats.hangar_offset
	for side: float in [-1.0, 1.0]:
		_box(spot, Vector3(WALL, height - WALL, depth), Vector3(side * (width - WALL) * 0.5, (height - WALL) * 0.5, middle),
				WorldMaterials.Role.HULL)
	_box(spot, Vector3(width - WALL * 2.0, height - WALL, WALL),
			Vector3(0.0, (height - WALL) * 0.5, middle + (depth - WALL) * 0.5), WorldMaterials.Role.HULL_DARK)
	_box(spot, Vector3(width, WALL, depth), Vector3(0.0, height - WALL * 0.5, middle), WorldMaterials.Role.HULL_MID)
	_box(spot, Vector3(width * 0.7, 0.2, 1.2), Vector3(0.0, height + 0.1, middle), WorldMaterials.Role.LIVERY,
			field.team)


func _box(parent: Node3D, size: Vector3, at: Vector3, role: WorldMaterials.Role, team: int = -1) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = WorldMaterials.role(role, team)
	node.mesh = mesh
	node.position = at
	parent.add_child(node)
