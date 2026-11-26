class_name PelletTracers
extends MeshInstance3D
## Visual only: the seeker shotgun's tracers. Each frame it adds every pellet's place (`SeekerPellets.flying`) to that
## pellet's trail, and draws each trail over the last `tracer_time` as a thin camera-facing additive ribbon,
## `tracer_width` at the newest point, narrowing and fading to the tail. A stopped pellet's trail fades out on its own.
## The colour is the HUD's (`UiTokens.HUD_LINE`, warm toward the head). One `ImmediateMesh` for all; in world space.

## A pellet's path: positions and the clock time each was passed. An object, so appends reach the stored arrays (a
## packed array taken out of an `Array` with `as` is a copy).
class Trail:
	var points := PackedVector3Array()
	var times := PackedFloat32Array()


## Pellet (the data object) to its `Trail`.
var _trails: Dictionary = {}
var _clock: float = 0.0
var _stats: SeekerShotgunStats
var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material_override = material


## One frame: `pellets` are those in flight now (null: none, the trails left fade out).
func draw_frame(delta: float, pellets: SeekerPellets) -> void:
	_clock += delta
	if pellets != null:
		_stats = pellets.stats
		for pellet: SeekerPellets.Pellet in pellets.flying:
			var trail: Trail = _trails.get(pellet)
			if trail == null:
				trail = Trail.new()
			trail.points.append(pellet.position)
			trail.times.append(_clock)
			_trails[pellet] = trail
	_mesh.clear_surfaces()
	if _stats == null or _trails.is_empty():
		return
	for pellet: Object in _trails.keys():
		if not _trim(_trails[pellet]):
			_trails.erase(pellet)
	_draw_trails()


## Drops every trail at once.
func clear() -> void:
	_trails.clear()
	_mesh.clear_surfaces()


## Drops points older than `tracer_time`; false once nothing is left to draw.
func _trim(trail: Trail) -> bool:
	var cut: int = 0
	while cut < trail.points.size() and _clock - trail.times[cut] > _stats.tracer_time:
		cut += 1
	if cut > 0:
		trail.points = trail.points.slice(cut)
		trail.times = trail.times.slice(cut)
	return not trail.points.is_empty()


func _draw_trails() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var eye: Vector3 = camera.global_position
	var begun: bool = false
	for trail: Trail in _trails.values():
		var points: PackedVector3Array = trail.points
		var times: PackedFloat32Array = trail.times
		for i: int in range(1, points.size()):
			var a: Vector3 = points[i - 1]
			var b: Vector3 = points[i]
			if a.is_equal_approx(b):
				continue
			if not begun:
				_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
				begun = true
			var fade_a: float = _fade(_clock - times[i - 1])
			var fade_b: float = _fade(_clock - times[i])
			var side: Vector3 = (b - a).cross(eye - b).normalized() * _stats.tracer_width * 0.5
			_quad(a, b, side * fade_a, side * fade_b, _tint(fade_a), _tint(fade_b))
	if begun:
		_mesh.surface_end()


## 1 for a point passed just now, falling to 0 at `tracer_time` old.
func _fade(age: float) -> float:
	return clampf(1.0 - age / maxf(_stats.tracer_time, 0.0001), 0.0, 1.0)


## The HUD's line colour, warming to white at the head.
func _tint(fade: float) -> Color:
	var color: Color = UiTokens.HUD_LINE.lerp(UiTokens.OFF_WHITE, fade * 0.6)
	color.a = fade
	return color


func _quad(a: Vector3, b: Vector3, half_a: Vector3, half_b: Vector3, color_a: Color, color_b: Color) -> void:
	for corner: Array in [[a - half_a, color_a], [a + half_a, color_a], [b + half_b, color_b],
			[a - half_a, color_a], [b + half_b, color_b], [b - half_b, color_b]]:
		_mesh.surface_set_color(corner[1])
		_mesh.surface_add_vertex(corner[0])
