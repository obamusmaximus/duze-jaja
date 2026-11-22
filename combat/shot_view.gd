class_name ShotView
extends Node3D
## Visual only: every projectile in flight drawn by one MultiMesh (one draw call), and instant shots as tracer lines
## that fade quickly, all in one ImmediateMesh.

const PROJECTILE_RADIUS: float = 0.12
const PROJECTILE_COLOR: Color = UiTokens.ORANGE
const TRACER_COLOR: Color = UiTokens.OFF_WHITE
const TRACER_SECONDS: float = 0.08

var _shots: Shots
var _multimesh := MultiMesh.new()
var _projectiles := MultiMeshInstance3D.new()
var _tracer_mesh := ImmediateMesh.new()
var _tracers := MeshInstance3D.new()
var _tracer_material := StandardMaterial3D.new()
## Tracer lines: [from: Vector3, to: Vector3, age: float].
var _lines: Array = []


func setup(shots: Shots) -> void:
	_shots = shots
	shots.fired.connect(_on_fired)
	var sphere := SphereMesh.new()
	sphere.radius = PROJECTILE_RADIUS
	sphere.height = PROJECTILE_RADIUS * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = PROJECTILE_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.mesh = sphere
	_projectiles.multimesh = _multimesh
	_projectiles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_projectiles)
	_tracer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tracer_material.vertex_color_use_as_albedo = true
	_tracer_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tracers.mesh = _tracer_mesh
	_tracers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_tracers)


func _process(delta: float) -> void:
	if _shots == null:
		return
	_draw_projectiles()
	_draw_tracers(delta)


func _draw_projectiles() -> void:
	var points: PackedVector3Array = _shots.positions()
	if _multimesh.instance_count < points.size():
		_multimesh.instance_count = maxi(64, nearest_po2(points.size()))
	_multimesh.visible_instance_count = points.size()
	for i: int in points.size():
		_multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, points[i]))


func _draw_tracers(delta: float) -> void:
	_tracer_mesh.clear_surfaces()
	if _lines.is_empty():
		return
	_tracer_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _tracer_material)
	var kept: Array = []
	for line: Array in _lines:
		line[2] += delta
		if line[2] >= TRACER_SECONDS:
			continue
		var color: Color = TRACER_COLOR
		color.a = 1.0 - line[2] / TRACER_SECONDS
		_tracer_mesh.surface_set_color(color)
		_tracer_mesh.surface_add_vertex(line[0])
		_tracer_mesh.surface_set_color(color)
		_tracer_mesh.surface_add_vertex(line[1])
		kept.append(line)
	_tracer_mesh.surface_end()
	_lines = kept


func _on_fired(from: Vector3, to: Vector3) -> void:
	_lines.append([from, to, 0.0])
