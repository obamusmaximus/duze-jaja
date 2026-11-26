class_name LampField
extends MultiMeshInstance3D
## Visual only: draws every `LampSet` in the tree as camera-facing glows (`lamp.gdshader`) in one draw call. Each
## frame it takes the visible sets' lamps into the world; a set that hasn't moved or changed is copied from its
## cache, so still lamps (pads, hulls) cost next to nothing. Blinking runs in the shader. One per level.

const SHADER: Shader = preload("res://lighting/lamp.gdshader")
## Floats per instance in the MultiMesh buffer: transform (12), colour (4), custom data (4).
const INSTANCE: int = 20
## No frustum culling of the whole batch: the lamps are all over the map.
const EVERYWHERE := AABB(Vector3.ONE * -50000.0, Vector3.ONE * 100000.0)

## Lamps drawn last frame.
var drawn: int = 0
var _material := ShaderMaterial.new()
var _buffer := PackedFloat32Array()
var _capacity: int = 0


func _init() -> void:
	_material.shader = SHADER
	# After the bird's-eye post pass (priority 0), which would otherwise paint over them.
	_material.render_priority = 1
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = quad
	material_override = _material
	custom_aabb = EVERYWHERE
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF # Written every frame, already interpolated.
	process_priority = 1000 # After everything that moves or hides a lamp's owner.


## Off: only steady lamps are drawn (the night check compares still frames).
func set_blinking(on: bool) -> void:
	_material.set_shader_parameter(&"blinking", on)


func _process(_delta: float) -> void:
	_buffer.clear()
	for node: Node in get_tree().get_nodes_in_group(&"lamp_sets"):
		var set_node: LampSet = node as LampSet
		if set_node.data.is_empty() or not set_node.is_visible_in_tree():
			continue
		var at: Transform3D = set_node.get_global_transform_interpolated()
		if set_node.cached_revision != set_node.revision or set_node.cached_transform != at:
			_place(set_node, at)
		_buffer.append_array(set_node.cached)
	drawn = _buffer.size() / INSTANCE
	if drawn > _capacity:
		_capacity = nearest_po2(drawn)
		multimesh.instance_count = _capacity
	if _capacity == 0:
		return
	_buffer.resize(_capacity * INSTANCE)
	multimesh.buffer = _buffer
	multimesh.visible_instance_count = drawn


func _place(set_node: LampSet, at: Transform3D) -> void:
	var source: PackedFloat32Array = set_node.data
	var out := PackedFloat32Array()
	out.resize(set_node.count() * INSTANCE) # Zeroed: only the non-zero parts are written.
	for i: int in set_node.count():
		var s: int = i * LampSet.STRIDE
		var o: int = i * INSTANCE
		var world: Vector3 = at * Vector3(source[s], source[s + 1], source[s + 2])
		out[o] = 1.0
		out[o + 3] = world.x
		out[o + 5] = 1.0
		out[o + 7] = world.y
		out[o + 10] = 1.0
		out[o + 11] = world.z
		for k: int in 8: # Colour and strength, then size, smallest screen size, period and phase.
			out[o + 12 + k] = source[s + 3 + k]
		out[o + 15] *= set_node.fade
	set_node.cached = out
	set_node.cached_transform = at
	set_node.cached_revision = set_node.revision
