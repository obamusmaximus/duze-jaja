class_name UnitLook
extends Node3D
## Visual only: the unit's model (or, with none, a placeholder hull cylinder with a livery nose showing which way it
## faces) over a flat base plate in the team colour, and the selection ring. A flyer's plate and ring stay on the
## ground under it, with a round shadow straight below it and a line from plate to body, so its height and place read
## at a glance. Colours come from `WorldMaterials`.
## Built from the unit's stats and rebuilt when they change.

## The selection ring: acid green, the selection accent (`UiTokens`).
const RING_COLOR: Color = UiTokens.GREEN
const PLATE_HEIGHT: float = 0.08
## A height line shorter than this (a flyer on its pad or landed) is hidden.
const MIN_LINE: float = 0.3

var _stats: UnitStats
var _team: int
var _body := MeshInstance3D.new()
var _nose := MeshInstance3D.new()
var _ring := MeshInstance3D.new()
var _selected: bool = false
var _plate := MeshInstance3D.new()
## Flyers only: the round shadow under them and the line up from the plate. Null on ground units.
var _shadow: MeshInstance3D
var _height_line: MeshInstance3D
var _model: Node3D
## Holds the body, nose and model at mid-height, so a flyer can pitch and bank them about it.
var _frame := Node3D.new()
## How far the unit hovers above its ground (flyers only; 0 on the ground).
var _hover: float = 0.0
## Where an inhabiting player's eyes are; made the first time it is asked for.
var _cockpit: Node3D
## A first-person camera sits in this unit: nothing of its airframe is drawn.
var _occupied: bool = false
## Where a flyer's ground marks read the slope they lie on; null on a level without a map.
var air: AirLayer
## The Explorer's lights, beam and bubble (`add_explorer`); null on other units.
var _explorer_look: ExplorerLook


func setup(stats: UnitStats, team: int) -> void:
	_stats = stats
	_team = team
	add_child(_frame)
	for part: MeshInstance3D in [_body, _nose]:
		_frame.add_child(part)
	for part: MeshInstance3D in [_ring, _plate]:
		add_child(part)
	_ring.visible = false
	_plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build()
	stats.changed.connect(_build)


## Adds the Explorer's searchlights, beacons, beam and bubble (look only).
func add_explorer(explorer: Explorer) -> void:
	_explorer_look = ExplorerLook.new()
	_explorer_look.name = "ExplorerLook"
	add_child(_explorer_look)
	_explorer_look.setup(explorer, _team, _frame)
	_explorer_look.fit_to(_model)


func show_selected(on: bool) -> void:
	_ring.visible = on and not _occupied
	_selected = on


## The cockpit mount point (`UnitStats.cockpit_offset`): a child of the airframe, so it pitches and banks with it.
func cockpit_mount() -> Node3D:
	if _cockpit == null:
		_cockpit = Node3D.new()
		_cockpit.name = "CockpitMount"
		_frame.add_child(_cockpit)
		_place_cockpit()
	return _cockpit


## Hides (or shows again) the airframe and its marks while a first-person camera sits inside. The shadow on the
## ground stays: it tells the pilot how high they are.
func set_cockpit_occupied(occupied: bool) -> void:
	if _occupied == occupied:
		return
	_occupied = occupied
	_frame.visible = not occupied
	_plate.visible = not occupied
	_ring.visible = _selected and not occupied
	_place_ground_parts()


func _place_cockpit() -> void:
	if _cockpit != null:
		_cockpit.position = _stats.cockpit_offset - Vector3.UP * _frame.position.y


func _build() -> void:
	var color: Color = UiTokens.team_color(_team)
	if _model != null:
		_model.queue_free()
		_model = null
	var has_model: bool = _stats.model != null
	var flying: bool = _stats.flying
	_body.visible = not has_model
	_nose.visible = not has_model
	# The plate marks the team (and a flyer's ground) under every unit; the model itself stays mostly neutral.
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(_stats.radius * 2.0, PLATE_HEIGHT, _stats.radius * 2.0)
	_plate.mesh = plate_mesh
	_plate.material_override = WorldMaterials.mark(color)
	var lift: float = 0.0 if flying else PLATE_HEIGHT
	var pivot: float = _stats.height * 0.5
	_frame.position.y = pivot
	_place_cockpit()
	if has_model:
		_model = ModelFit.instance(_stats.model, _stats.model_scale, _stats.model_yaw_deg, _team)
		_model.position.y = lift - pivot
		_frame.add_child(_model)
	else:
		var body_mesh := CylinderMesh.new()
		body_mesh.top_radius = _stats.radius
		body_mesh.bottom_radius = _stats.radius
		body_mesh.height = _stats.height
		body_mesh.radial_segments = 8
		_body.mesh = body_mesh
		_body.material_override = WorldMaterials.role(WorldMaterials.Role.HULL)
		_body.position.y = lift + _stats.height * 0.5 - pivot
		var nose_mesh := BoxMesh.new()
		nose_mesh.size = Vector3(_stats.radius * 0.5, _stats.height * 0.3, _stats.radius * 0.8)
		_nose.mesh = nose_mesh
		_nose.material_override = WorldMaterials.role(WorldMaterials.Role.LIVERY, _team)
		_nose.position = Vector3(0.0, lift + _stats.height * 0.6 - pivot, -_stats.radius)
	_build_height_marks(color)
	if _explorer_look != null:
		_explorer_look.fit_to(_model)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = _stats.radius * 1.15
	ring_mesh.outer_radius = _stats.radius * 1.3
	_ring.mesh = ring_mesh
	_ring.material_override = WorldMaterials.mark(RING_COLOR)
	_place_ground_parts()


## Over open sea a flyer's marks ride above the wave crests, which would otherwise cover them.
func _sea_lift() -> float:
	if air == null or not _stats.flying or air.ground_height(global_position) > MapGrid.SEA_LEVEL:
		return 0.0
	return _stats.sea_mark_lift


## The slope under a flyer, in this node's space (it turns with the unit). Straight up for ground units.
func _ground_normal() -> Vector3:
	if air == null or not _stats.flying:
		return Vector3.UP
	var at: Vector3 = global_position - Vector3.UP * _hover
	var reach: float = _stats.radius
	var east: float = air.ground_height(at + Vector3(reach, 0.0, 0.0)) - air.ground_height(at - Vector3(reach, 0.0, 0.0))
	var south: float = air.ground_height(at + Vector3(0.0, 0.0, reach)) - air.ground_height(at - Vector3(0.0, 0.0, reach))
	var normal := Vector3(-east, reach * 2.0, -south).normalized()
	return (global_basis.orthonormalized().inverse() * normal).normalized()


func _build_height_marks(color: Color) -> void:
	if _shadow != null:
		_shadow.queue_free()
		_height_line.queue_free()
		_shadow = null
		_height_line = null
	if not _stats.flying:
		return
	_shadow = MeshInstance3D.new()
	var disc := PlaneMesh.new()
	disc.size = Vector2.ONE * _stats.radius * 2.0 * _stats.shadow_scale
	_shadow.mesh = disc
	_shadow.material_override = WorldMaterials.blob_shadow(_stats.shadow_opacity)
	_height_line = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(_stats.height_line_width, 1.0, _stats.height_line_width)
	_height_line.mesh = bar
	_height_line.material_override = WorldMaterials.mark(color)
	for part: MeshInstance3D in [_shadow, _height_line]:
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(part)


## Pitches and banks a flyer's airframe (radians); the plate and ring stay flat.
func set_attitude(pitch: float, bank: float) -> void:
	_frame.rotation = Vector3(pitch, 0.0, bank)


## The airframe's whole orientation within the node's yaw (any attitude, loops and rolls included).
func set_airframe(basis_in_node: Basis) -> void:
	_frame.basis = basis_in_node


## The unit is `height` metres above the ground under it (a flyer). The plate and ring stay on that ground.
func set_hover(height: float) -> void:
	_hover = height
	_place_ground_parts()


## The plate, ring and shadow, on the ground under the unit. A flyer's lie along the slope there, or half of each
## would sink into a hillside.
func _place_ground_parts() -> void:
	var up: Vector3 = _ground_normal()
	var tilt := Basis(Quaternion(Vector3.UP, up))
	var ground := Vector3(0.0, -_hover + _sea_lift(), 0.0)
	_plate.transform = Transform3D(tilt, ground + up * PLATE_HEIGHT * 0.5)
	_ring.transform = Transform3D(tilt, ground + up * (PLATE_HEIGHT + 0.02))
	if _shadow == null:
		return
	_shadow.transform = Transform3D(tilt, ground + up * (PLATE_HEIGHT + 0.01))
	var length: float = -ground.y - PLATE_HEIGHT
	_height_line.visible = length > MIN_LINE and not _occupied
	if _height_line.visible:
		_height_line.position.y = -length * 0.5
		_height_line.scale.y = length
