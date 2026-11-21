class_name UnitLook
extends Node3D
## Visual only: the unit's model (or, with none, a placeholder cylinder with a nose showing which way it faces) over
## a flat base plate in the team colour, and the selection ring. Built from the unit's stats and rebuilt when they
## change.

## Team number to colour (the style guide's saturated accents: electric cyan, UV violet, safety orange, acid green).
## Teams past the end wrap around.
const TEAM_COLORS: Array = [Color(0.0, 0.85, 1.0), Color(0.6, 0.2, 1.0), Color(1.0, 0.45, 0.0), Color(0.7, 1.0, 0.0)]
## Acid green, so it never matches a team.
const RING_COLOR: Color = Color(0.75, 1.0, 0.0)
const PLATE_HEIGHT: float = 0.08

var _stats: UnitStats
var _team: int
var _body := MeshInstance3D.new()
var _nose := MeshInstance3D.new()
var _ring := MeshInstance3D.new()
var _plate := MeshInstance3D.new()
var _model: Node3D


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
	var color: Color = TEAM_COLORS[_team % TEAM_COLORS.size()]
	if _model != null:
		_model.queue_free()
		_model = null
	var has_model: bool = _stats.model != null
	_body.visible = not has_model
	_nose.visible = not has_model
	_plate.visible = has_model
	if has_model:
		_model = ModelFit.instance(_stats.model, _stats.model_scale, _stats.model_yaw_deg)
		_model.position.y = PLATE_HEIGHT
		add_child(_model)
		var plate_mesh := BoxMesh.new()
		plate_mesh.size = Vector3(_stats.radius * 2.0, PLATE_HEIGHT, _stats.radius * 2.0)
		_plate.mesh = plate_mesh
		_plate.material_override = _material(color, true)
		_plate.position.y = PLATE_HEIGHT * 0.5
	else:
		var body_mesh := CylinderMesh.new()
		body_mesh.top_radius = _stats.radius
		body_mesh.bottom_radius = _stats.radius
		body_mesh.height = _stats.height
		_body.mesh = body_mesh
		_body.material_override = _material(color)
		_body.position.y = _stats.height * 0.5
		var nose_mesh := BoxMesh.new()
		nose_mesh.size = Vector3(_stats.radius * 0.5, _stats.height * 0.3, _stats.radius * 0.8)
		_nose.mesh = nose_mesh
		_nose.material_override = _material(color.lightened(0.5))
		_nose.position = Vector3(0.0, _stats.height * 0.6, -_stats.radius)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = _stats.radius * 1.15
	ring_mesh.outer_radius = _stats.radius * 1.3
	_ring.mesh = ring_mesh
	_ring.material_override = _material(RING_COLOR, true)
	_ring.position.y = PLATE_HEIGHT + 0.02


func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
