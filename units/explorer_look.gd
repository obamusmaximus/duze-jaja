class_name ExplorerLook
extends Node3D
## Visual only: the Explorer's searchlights, beacon lights, beam and bubble (`docs/mechanics/explorer.md`). While it
## flies, searchlights under the hull sweep the ground beneath in slow wandering paths (a spot light each, plus a faint
## cone of light in the air); beacon lights on the hull's extremes blink (orange) and strobe (white). Deployed, the
## searchlights go out, a beam shoots up from the top of the hull and the bubble unfurls from its top. Reads the
## `Explorer`'s state; never changes it. Numbers from `ExplorerStats`.

const BUBBLE_SHADER: Shader = preload("res://units/explorer_bubble.gdshader")
const BEAM_SHADER: Shader = preload("res://units/explorer_beam.gdshader")
const BEACON_SHADER: Shader = preload("res://units/explorer_beacon.gdshader")
## Where each searchlight hangs, as a direction from the hull's middle (the hull point farthest that way).
const SEARCHLIGHT_DIRS: Array[Vector3] = [Vector3(-0.6, -1.0, -0.7), Vector3(0.6, -1.0, -0.7), Vector3(0.0, -1.0, 0.8),
	Vector3(-0.7, -1.0, 0.3), Vector3(0.7, -1.0, 0.3), Vector3(0.0, -1.0, -0.2)]
## Beacons: a direction from the hull's middle (the hull point farthest that way) and whether it is a white strobe
## (else an orange blinker). Tops, bottoms, wingtips, nose and tail.
const BEACONS: Array[Dictionary] = [
	{dir = Vector3(0.0, 1.0, 0.0), strobe = false}, {dir = Vector3(0.0, -1.0, 0.0), strobe = false},
	{dir = Vector3(0.0, 1.0, 0.9), strobe = false}, {dir = Vector3(0.0, 1.0, -0.9), strobe = false},
	{dir = Vector3(-1.0, 0.1, 0.0), strobe = true}, {dir = Vector3(1.0, 0.1, 0.0), strobe = true},
	{dir = Vector3(0.0, 0.2, 1.0), strobe = true}, {dir = Vector3(0.0, -0.3, -1.0), strobe = true},
	{dir = Vector3(-1.0, -0.6, -1.0), strobe = false}, {dir = Vector3(1.0, -0.6, -1.0), strobe = false},
	{dir = Vector3(-1.0, -0.6, 1.0), strobe = false}, {dir = Vector3(1.0, -0.6, 1.0), strobe = false}]

var _explorer: Explorer
var _stats: ExplorerStats
var _team: int
## The airframe node (pitches and banks): lights and beacons hang from it.
var _frame: Node3D
## Hull vertices in the frame's space, to put lights on the hull's surface.
var _points := PackedVector3Array()
var _top := Vector3.ZERO
var _searchlights: Array[Dictionary] = []
var _beacons: Array[Dictionary] = []
var _beam := MeshInstance3D.new()
var _bubble := MeshInstance3D.new()
var _bubble_material := ShaderMaterial.new()
var _beam_material := ShaderMaterial.new()
var _cone_material := ShaderMaterial.new()
var _orange_material := ShaderMaterial.new()
var _white_material := ShaderMaterial.new()
## How lit the searchlights are, 0 to 1 (out while deployed).
var _lit: float = 1.0
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(explorer: Explorer, team: int, frame: Node3D) -> void:
	_explorer = explorer
	_stats = explorer.stats
	_team = team
	_frame = frame
	_rng.seed = hash(explorer.unit.id) # Each Explorer sweeps its own way; view only, so any seed will do.
	_clock = _rng.randf() * 100.0
	_bubble_material.shader = BUBBLE_SHADER
	_bubble_material.set_shader_parameter(&"tint", UiTokens.team_color(team))
	_beam_material.shader = BEAM_SHADER
	_beam_material.set_shader_parameter(&"tint", UiTokens.team_color(team))
	_beam_material.set_shader_parameter(&"falloff", 0.8)
	_cone_material.shader = BEAM_SHADER
	_cone_material.set_shader_parameter(&"tint", UiTokens.WORLD_SUN)
	_orange_material.shader = BEACON_SHADER
	_orange_material.set_shader_parameter(&"tint", UiTokens.ORANGE)
	_white_material.shader = BEACON_SHADER
	_white_material.set_shader_parameter(&"tint", UiTokens.OFF_WHITE)
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	_bubble.mesh = sphere
	_bubble.material_override = _bubble_material
	var column := CylinderMesh.new()
	column.top_radius = 0.5
	column.bottom_radius = 0.5
	column.height = 1.0
	column.radial_segments = 12
	column.cap_top = false
	column.cap_bottom = false
	_beam.mesh = column
	_beam.material_override = _beam_material
	for part: MeshInstance3D in [_beam, _bubble]:
		part.top_level = true
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		part.visible = false
		add_child(part)
	_stats.changed.connect(_rebuild)


## Reads the hull's shape from `model` (null: a box from the unit's size) and hangs the lights on it.
func fit_to(model: Node3D) -> void:
	_points = PackedVector3Array()
	if model != null and model.is_inside_tree():
		_collect(model)
	if _points.is_empty():
		var body: UnitStats = _explorer.unit.stats
		var half := Vector3(body.radius, body.height * 0.5, body.radius)
		for corner: int in 8:
			_points.append(Vector3(half.x * (1 if corner & 1 else -1), half.y * (1 if corner & 2 else -1),
				half.z * (1 if corner & 4 else -1)))
	_top = _support(Vector3.UP)
	_rebuild()


func _collect(node: Node) -> void:
	var mesh_node := node as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		var to_frame: Transform3D = _frame.global_transform.affine_inverse() * mesh_node.global_transform
		for surface: int in mesh_node.mesh.get_surface_count():
			var arrays: Array = mesh_node.mesh.surface_get_arrays(surface)
			for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array:
				_points.append(to_frame * vertex)
	for child: Node in node.get_children():
		_collect(child)


## The hull point farthest along `direction` (frame space).
func _support(direction: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var best_reach: float = -INF
	var toward: Vector3 = direction.normalized()
	for point: Vector3 in _points:
		var reach: float = point.dot(toward)
		if reach > best_reach:
			best_reach = reach
			best = point
	return best


func _rebuild() -> void:
	for light: Dictionary in _searchlights:
		(light.pivot as Node3D).queue_free()
	_searchlights.clear()
	for beacon: Dictionary in _beacons:
		(beacon.mesh as Node3D).queue_free()
	_beacons.clear()
	if _points.is_empty():
		return
	for i: int in mini(_stats.searchlight_count, SEARCHLIGHT_DIRS.size()):
		_searchlights.append(_make_searchlight(_support(SEARCHLIGHT_DIRS[i])))
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.custom_aabb = AABB(Vector3.ONE * -0.5 * _stats.beacon_size, Vector3.ONE * _stats.beacon_size)
	for spec: Dictionary in BEACONS:
		var mesh := MeshInstance3D.new()
		mesh.mesh = quad
		mesh.material_override = _white_material if spec.strobe else _orange_material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.position = _support(spec.dir as Vector3)
		_frame.add_child(mesh)
		_beacons.append({mesh = mesh, strobe = spec.strobe, phase = _rng.randf() * 0.25})
	for material: ShaderMaterial in [_orange_material, _white_material]:
		material.set_shader_parameter(&"size", _stats.beacon_size)


func _make_searchlight(at: Vector3) -> Dictionary:
	var pivot := Node3D.new()
	pivot.position = at
	_frame.add_child(pivot)
	var light := SpotLight3D.new()
	light.light_color = UiTokens.WORLD_SUN
	light.shadow_enabled = false
	light.spot_attenuation = 0.0 # No fall-off with distance: a searchlight's pool is as bright at 80 m as at 30 m.
	pivot.add_child(light)
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 0.0
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.cap_top = false
	mesh.cap_bottom = false
	cone.mesh = mesh
	cone.material_override = _cone_material
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cone.rotation.x = -PI * 0.5 # Its +Y (the wide end) points down the light's -Z.
	pivot.add_child(cone)
	var speeds := Vector4(_rng.randf_range(0.6, 1.4), _rng.randf_range(0.6, 1.4), _rng.randf_range(1.5, 2.6),
		_rng.randf_range(1.5, 2.6))
	var phases := Vector4(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
	return {pivot = pivot, light = light, cone = cone, speeds = speeds, phases = phases}


## In step with the physics tick, so the lights move with the interpolated airframe.
func _physics_process(delta: float) -> void:
	_clock += delta
	var flying: bool = _explorer.state == Explorer.State.FLYING or _explorer.state == Explorer.State.CLIMBING
	_lit = move_toward(_lit, 1.0 if flying else 0.0, delta / _stats.searchlight_fade_time)
	_aim_searchlights()
	_blink_beacons()
	_place_beam_and_bubble()


func _aim_searchlights() -> void:
	var lit: bool = _lit > 0.001
	var map: MapGrid = _explorer.unit.registry.map
	var ground: float = _explorer.unit.ground_point().y
	var below: Vector3 = _explorer.unit.global_position
	var sweep: float = _clock * _stats.searchlight_sweep * TAU * 0.25
	for light: Dictionary in _searchlights:
		var pivot: Node3D = light.pivot
		var spot: SpotLight3D = light.light
		var cone: MeshInstance3D = light.cone
		pivot.visible = lit
		if not lit:
			continue
		var speeds: Vector4 = light.speeds
		var phases: Vector4 = light.phases
		# Two slow sweeps and two quicker wobbles per axis: a search pattern that never quite repeats.
		var wander := Vector2(sin(sweep * speeds.x + phases.x) + 0.35 * sin(sweep * speeds.z + phases.z),
			cos(sweep * speeds.y + phases.y) + 0.35 * cos(sweep * speeds.w + phases.w)) / 1.35
		var origin: Vector3 = pivot.global_position
		var side := Vector2(origin.x - below.x, origin.z - below.z) * 0.6 # Each light keeps to its own side.
		var target := Vector3(origin.x + side.x + wander.x * _stats.searchlight_reach, ground,
			origin.z + side.y + wander.y * _stats.searchlight_reach)
		if map != null:
			target.y = maxf(map.ground_height(target), MapGrid.SEA_LEVEL)
		var to: Vector3 = target - origin
		var length: float = maxf(to.length(), 1.0)
		pivot.global_basis = Basis.looking_at(to / length, Vector3.FORWARD)
		spot.spot_angle = _stats.searchlight_angle_deg
		spot.spot_range = _stats.searchlight_range
		spot.light_energy = _stats.searchlight_energy * _lit
		var spread: float = tan(deg_to_rad(_stats.searchlight_angle_deg)) * length
		cone.scale = Vector3(spread, length, spread)
		cone.position = Vector3(0.0, 0.0, -length * 0.5)
	_cone_material.set_shader_parameter(&"intensity", _stats.searchlight_beam_opacity * _lit)


func _blink_beacons() -> void:
	for beacon: Dictionary in _beacons:
		var mesh: MeshInstance3D = beacon.mesh
		var phase: float = beacon.phase
		if beacon.strobe:
			var t: float = fposmod(_clock / _stats.strobe_period + phase, 1.0)
			mesh.visible = t < 0.04 or (t > 0.1 and t < 0.14) # A quick double flash.
		else:
			mesh.visible = fposmod(_clock / _stats.beacon_period + phase * 0.2, 1.0) < 0.35


func _place_beam_and_bubble() -> void:
	var center: Vector3 = _explorer.bubble_center()
	var radius: float = _stats.bubble_radius
	_bubble.visible = _explorer.bubble > 0.0
	if _bubble.visible:
		_bubble.global_transform = Transform3D(Basis.from_scale(Vector3.ONE * radius), center)
		var unfurl: float = _explorer.bubble
		_bubble_material.set_shader_parameter(&"reveal", 1.0 - pow(1.0 - unfurl, 2.0))
		_bubble_material.set_shader_parameter(&"opacity", _stats.bubble_opacity)
	_beam.visible = _explorer.beam > 0.0
	if _beam.visible:
		var bottom: Vector3 = _frame.global_transform * _top
		var full: float = center.y + radius + _stats.beam_overshoot - bottom.y
		var length: float = maxf(full * (1.0 - pow(1.0 - _explorer.beam, 3.0)), 0.1)
		_beam.global_transform = Transform3D(Basis.from_scale(Vector3(_stats.beam_width, length, _stats.beam_width)),
			bottom + Vector3.UP * length * 0.5)
		_beam_material.set_shader_parameter(&"intensity", 1.2 * _explorer.beam)
