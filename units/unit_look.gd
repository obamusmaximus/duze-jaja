class_name UnitLook
extends Node3D
## Visual only: the placeholder body in the team colour, a nose showing which way the unit faces, and the selection
## ring. Sized from the unit's stats and rebuilt when they change.

## Team number to colour. Teams past the end wrap around.
const TEAM_COLORS: Array = [Color(0.25, 0.5, 1.0), Color(0.9, 0.25, 0.2), Color(0.3, 0.8, 0.3), Color(0.9, 0.8, 0.2)]
const RING_COLOR: Color = Color(0.4, 1.0, 0.4)

var _stats: UnitStats
var _team: int
var _body := MeshInstance3D.new()
var _nose := MeshInstance3D.new()
var _ring := MeshInstance3D.new()


func setup(stats: UnitStats, team: int) -> void:
	_stats = stats
	_team = team
	for part: MeshInstance3D in [_body, _nose, _ring]:
		add_child(part)
	_ring.visible = false
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build()
	stats.changed.connect(_build)


func show_selected(on: bool) -> void:
	_ring.visible = on


func _build() -> void:
	var color: Color = TEAM_COLORS[_team % TEAM_COLORS.size()]
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
	_ring.position.y = 0.05


func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
