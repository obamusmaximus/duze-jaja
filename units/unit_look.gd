class_name UnitLook
extends Node3D
## Visual only: the unit's model (or, with none, a placeholder hull cylinder with a livery nose showing which way it
## faces) over a flat base plate in the team colour, and the selection ring. Colours come from `WorldMaterials`.
## Built from the unit's stats and rebuilt when they change.

## The selection ring: acid green, the selection accent (`UiTokens`).
const RING_COLOR: Color = UiTokens.GREEN
const PLATE_HEIGHT: float = 0.08

var _stats: UnitStats
var _team: int
var _body := MeshInstance3D.new()
var _nose := MeshInstance3D.new()
var _ring := MeshInstance3D.new()
var _plate := MeshInstance3D.new()
var _model: Node3D
## How far the unit hovers above its ground (flyers only; 0 on the ground).
var _hover: float = 0.0


func setup(stats: UnitStats, team: int) -> void:
	_stats = stats
	_team = team
	for part: MeshInstance3D in [_body, _nose, _ring, _plate]:
		add_child(part)
	_ring.visible = false
	_plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build()
	stats.changed.connect(_build)


func show_selected(on: bool) -> void:
	_ring.visible = on


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
	if has_model:
		_model = ModelFit.instance(_stats.model, _stats.model_scale, _stats.model_yaw_deg, _team)
		_model.position.y = lift
		add_child(_model)
	else:
		var body_mesh := CylinderMesh.new()
		body_mesh.top_radius = _stats.radius
		body_mesh.bottom_radius = _stats.radius
		body_mesh.height = _stats.height
		body_mesh.radial_segments = 8
		_body.mesh = body_mesh
		_body.material_override = WorldMaterials.role(WorldMaterials.Role.HULL)
		_body.position.y = lift + _stats.height * 0.5
		var nose_mesh := BoxMesh.new()
		nose_mesh.size = Vector3(_stats.radius * 0.5, _stats.height * 0.3, _stats.radius * 0.8)
		_nose.mesh = nose_mesh
		_nose.material_override = WorldMaterials.role(WorldMaterials.Role.LIVERY, _team)
		_nose.position = Vector3(0.0, lift + _stats.height * 0.6, -_stats.radius)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = _stats.radius * 1.15
	ring_mesh.outer_radius = _stats.radius * 1.3
	_ring.mesh = ring_mesh
	_ring.material_override = WorldMaterials.mark(RING_COLOR)
	_place_ground_parts()


## The unit is `height` metres above the ground under it (a flyer). The plate and ring stay on that ground.
func set_hover(height: float) -> void:
	if _hover == height:
		return
	_hover = height
	_place_ground_parts()


func _place_ground_parts() -> void:
	_plate.position.y = -_hover + PLATE_HEIGHT * 0.5
	_ring.position.y = -_hover + PLATE_HEIGHT + 0.02
