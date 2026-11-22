class_name FxBuilder
extends RefCounted
## Builds the one-shot GPU particle systems the combat effects use, from `FxStats`. Colours come from the style guide
## (`UiTokens`). Visual only. Sizes are at effect scale 1; the node's scale does the rest.

const HIDDEN_BOX: AABB = AABB(Vector3(-20, -10, -20), Vector3(40, 30, 40))


static func flash(stats: FxStats) -> GPUParticles3D:
	var material := _process(stats.flash_size * 0.2, Vector3(0, 0, 0))
	material.initial_velocity_min = 0.2
	material.initial_velocity_max = 1.5
	material.spread = 180.0
	material.scale_min = stats.flash_size * 0.6
	material.scale_max = stats.flash_size
	material.scale_curve = _curve([Vector2(0, 1), Vector2(1, 0)])
	material.color_ramp = _ramp([UiTokens.OFF_WHITE, UiTokens.ORANGE, Color(UiTokens.ORANGE, 0.0)])
	return _system(stats.flash_count, stats.flash_seconds, material, _quad(true))


static func spark(stats: FxStats) -> GPUParticles3D:
	var material := _process(0.05, Vector3(0, -14, 0))
	material.direction = Vector3.UP
	material.spread = 75.0
	material.initial_velocity_min = stats.spark_speed * 0.3
	material.initial_velocity_max = stats.spark_speed
	material.damping_min = 2.0
	material.damping_max = 4.0
	material.scale_min = stats.spark_size * 0.6
	material.scale_max = stats.spark_size
	material.scale_curve = _curve([Vector2(0, 1), Vector2(1, 0.1)])
	material.color_ramp = _ramp([UiTokens.OFF_WHITE, UiTokens.ORANGE, Color(UiTokens.ORANGE, 0.0)])
	return _system(stats.spark_count, stats.spark_seconds, material, _quad(true))


static func fire(stats: FxStats) -> GPUParticles3D:
	var material := _process(stats.fire_size * 0.25, Vector3(0, 1.5, 0))
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = stats.fire_size * 1.4
	material.spread = 180.0
	material.damping_min = 3.0
	material.damping_max = 5.0
	material.scale_min = stats.fire_size * 0.6
	material.scale_max = stats.fire_size
	material.scale_curve = _curve([Vector2(0, 0.35), Vector2(0.25, 1), Vector2(1, 0.5)])
	material.color_ramp = _ramp([UiTokens.OFF_WHITE, UiTokens.ORANGE, Color(UiTokens.BLACK, 0.0)], [0.0, 0.3, 1.0])
	return _system(stats.fire_count, stats.fire_seconds, material, _quad(true))


static func debris(stats: FxStats) -> GPUParticles3D:
	var material := _process(0.2, Vector3(0, -18, 0))
	material.direction = Vector3.UP
	material.spread = 70.0
	material.initial_velocity_min = stats.debris_speed * 0.4
	material.initial_velocity_max = stats.debris_speed
	material.angle_min = 0.0
	material.angle_max = 360.0
	material.angular_velocity_min = -540.0
	material.angular_velocity_max = 540.0
	material.scale_min = 0.5
	material.scale_max = 1.0
	material.scale_curve = _curve([Vector2(0, 1), Vector2(0.8, 1), Vector2(1, 0)])
	material.color_ramp = _ramp([UiTokens.CONCRETE, UiTokens.ORANGE, UiTokens.BLACK], [0.0, 0.2, 0.6])
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.22, 0.22, 0.22)
	var chunk_material := StandardMaterial3D.new()
	chunk_material.vertex_color_use_as_albedo = true
	chunk_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chunk.material = chunk_material
	return _system(stats.debris_count, stats.debris_seconds, material, chunk)


static func smoke(stats: FxStats) -> GPUParticles3D:
	var material := _process(stats.smoke_size * 0.2, Vector3(0, 0.8, 0))
	material.direction = Vector3.UP
	material.spread = 35.0
	material.initial_velocity_min = 0.4
	material.initial_velocity_max = 1.6
	material.scale_min = stats.smoke_size * 0.5
	material.scale_max = stats.smoke_size
	material.scale_curve = _curve([Vector2(0, 0.3), Vector2(1, 1)])
	material.color_ramp = _ramp([Color(UiTokens.BLACK, 0.0), Color(UiTokens.BLACK, 0.55), Color(UiTokens.CONCRETE, 0.0)], [0.0, 0.2, 1.0])
	var system := _system(stats.smoke_count, stats.smoke_seconds, material, _quad(false))
	system.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	return system


static func _system(amount: int, seconds: float, material: ParticleProcessMaterial, mesh: Mesh) -> GPUParticles3D:
	var system := GPUParticles3D.new()
	system.amount = amount
	system.lifetime = seconds
	system.one_shot = true
	system.explosiveness = 1.0
	system.emitting = false
	system.local_coords = false
	system.process_material = material
	system.draw_pass_1 = mesh
	system.visibility_aabb = HIDDEN_BOX
	system.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return system


static func _process(radius: float, gravity: Vector3) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = maxf(radius, 0.01)
	material.gravity = gravity
	return material


static func _quad(additive: bool) -> QuadMesh:
	var quad := QuadMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_texture = _soft_dot()
	quad.material = material
	return quad


## A soft round blob, so quads read as glows and puffs instead of squares.
static func _soft_dot() -> Texture2D:
	var texture := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	return texture


static func _ramp(colors: Array[Color], offsets: Array[float] = []) -> GradientTexture1D:
	var gradient := Gradient.new()
	var o: PackedFloat32Array = PackedFloat32Array()
	for i: int in colors.size():
		o.append(offsets[i] if offsets.size() == colors.size() else float(i) / float(colors.size() - 1))
	gradient.offsets = o
	gradient.colors = PackedColorArray(colors)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


static func _curve(points: Array[Vector2]) -> CurveTexture:
	var curve := Curve.new()
	for point: Vector2 in points:
		curve.add_point(point)
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture
