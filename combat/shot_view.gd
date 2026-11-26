class_name ShotView
extends Node3D
## Visual only: every projectile in flight drawn by one MultiMesh (one draw call), and instant shots as tracer lines
## that fade quickly, all in one ImmediateMesh. Beam weapons draw a wider ribbon turned to face the camera, whose near
## end stays with the shooter while it fades. Fire from a unit out of view (`FogView`) isn't drawn: it would give its
## place away.

const PROJECTILE_RADIUS: float = 0.12
const PROJECTILE_COLOR: Color = UiTokens.ORANGE
const TRACER_COLOR: Color = UiTokens.OFF_WHITE
const TRACER_SECONDS: float = 0.08
const BEAM_COLOR: Color = UiTokens.GREEN
## A beam's end is never wider than this share of its distance from the camera, so it doesn't fill the cockpit view
## where it starts just under the pilot.
const BEAM_NEAR_WIDTH: float = 0.006

var _shots: Shots
var _multimesh := MultiMesh.new()
var _projectiles := MultiMeshInstance3D.new()
var _tracer_mesh := ImmediateMesh.new()
var _tracers := MeshInstance3D.new()
var _tracer_material := StandardMaterial3D.new()
## Tracer lines: [from: Vector3, to: Vector3, age: float].
var _lines: Array = []
## Beams: [from: Vector3 (in the shooter's space while it lives), to: Vector3, age: float, shooter, weapon, from in the world].
var _beams: Array = []
var _beam_mesh := ImmediateMesh.new()
## Ids of the shooters whose projectiles were drawn last frame: those still fly on once the shooter is gone.
var _seen_sources: Dictionary = {}


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
	var beam_material: StandardMaterial3D = _tracer_material.duplicate()
	beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var beams := MeshInstance3D.new()
	beams.mesh = _beam_mesh
	beams.material_override = beam_material
	beams.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beams)


func _process(delta: float) -> void:
	if _shots == null:
		return
	_draw_projectiles()
	_draw_tracers(delta)
	_draw_beams(delta)


func _draw_projectiles() -> void:
	var points: PackedVector3Array = _shots.positions()
	if _multimesh.instance_count < points.size():
		_multimesh.instance_count = maxi(64, nearest_po2(points.size()))
	var drawn: int = 0
	var seen: Dictionary = {}
	for i: int in points.size():
		var id: int = _shots.source_id_of(i)
		var source: Unit = _shots.source_of(i)
		if source.is_drawn() if source != null else _seen_sources.has(id):
			seen[id] = true
			_multimesh.set_instance_transform(drawn, Transform3D(Basis.IDENTITY, points[i]))
			drawn += 1
	_seen_sources = seen
	_multimesh.visible_instance_count = drawn


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


func _draw_beams(delta: float) -> void:
	_beam_mesh.clear_surfaces()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if _beams.is_empty() or camera == null:
		return
	var kept: Array = []
	for beam: Array in _beams:
		beam[2] += delta
		var weapon: WeaponStats = beam[4]
		if beam[2] < weapon.beam_seconds:
			kept.append(beam)
	_beams = kept
	if _beams.is_empty():
		return
	_beam_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for beam: Array in _beams:
		var weapon: WeaponStats = beam[4]
		var from: Vector3 = beam[0]
		if is_instance_valid(beam[3]):
			from = (beam[3] as Unit).get_global_transform_interpolated() * from
		else:
			from = beam[5]
		var to: Vector3 = beam[1]
		var eye: Vector3 = camera.global_position
		var across: Vector3 = (to - from).cross(eye - from).normalized() * 0.5
		var near: Vector3 = across * minf(weapon.beam_width, eye.distance_to(from) * BEAM_NEAR_WIDTH)
		var far: Vector3 = across * minf(weapon.beam_width, eye.distance_to(to) * BEAM_NEAR_WIDTH)
		var color: Color = BEAM_COLOR
		color.a = 1.0 - beam[2] / weapon.beam_seconds
		_beam_mesh.surface_set_color(color)
		for corner: Vector3 in [from - near, from + near, to + far, from - near, to + far, to - far]:
			_beam_mesh.surface_add_vertex(corner)
	_beam_mesh.surface_end()


func _on_fired(from: Vector3, to: Vector3, source: Unit, weapon: WeaponStats) -> void:
	if not source.is_drawn():
		return
	if not weapon.beam:
		_lines.append([from, to, 0.0])
		return
	# A shooter that dies leaves the beam where it was fired from.
	_beams.append([source.global_transform.affine_inverse() * from, to, 0.0, source, weapon, from])
