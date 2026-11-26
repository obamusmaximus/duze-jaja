extends Node3D
## Debug: `debug_show_vision` (7) shows what `shown_team` detects (`vision/`): a ring on every enemy it knows (growing
## in as it is gained, shrinking as it is lost), a cross at every last-known spot, the sensor rings (range against
## signature 1) of its airfields, motherships and selected units, and a line from each selected unit to the enemies it
## detects itself. A readout counts them. Drawn over everything. Finds the simulation through the `vision` group.

const RING_SIDES: int = 48
## A contact's ring is this many times its radius, at least this wide (metres).
const MARK_SCALE: float = 1.8
const MARK_MIN: float = 2.0
const LIFT: float = 0.5

## The team whose picture is shown (the local player's).
@export var shown_team: int = 0

var _vision: Vision
var _mesh := ImmediateMesh.new()
var _lines := MeshInstance3D.new()
var _layer := CanvasLayer.new()
var _readout := Label.new()
## The frame's line vertices and their colours, in pairs.
var _points := PackedVector3Array()
var _colors := PackedColorArray()


func _ready() -> void:
	visible = false
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = true
	material.render_priority = 2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_lines.mesh = _mesh
	_lines.material_override = material
	_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lines.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_lines)
	_layer.layer = 50
	_layer.visible = false
	_readout.theme_type_variation = &"LabelNumber"
	_readout.position = Vector2(UiTokens.px(4), UiTokens.px(26))
	_layer.add_child(_readout)
	add_child(_layer)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_show_vision"):
		get_viewport().set_input_as_handled()
		visible = not visible
		_layer.visible = visible


func _process(_delta: float) -> void:
	if not visible:
		return
	if _vision == null:
		_vision = get_tree().get_first_node_in_group(&"vision") as Vision
		if _vision == null:
			return
	_draw()


func _draw() -> void:
	_mesh.clear_surfaces()
	var picture: TeamVision = _vision.of_team(shown_team)
	_points.clear()
	_colors.clear()
	var known: int = 0
	for id: int in picture.contacts:
		var contact: VisionContact = picture.contacts[id]
		if contact.known:
			known += 1
		var size: float = maxf(contact.type.radius * MARK_SCALE, MARK_MIN) * contact.level
		_ring(contact.position, size, UiTokens.ORANGE)
	for id: int in picture.memory:
		var record: LastKnown = picture.memory[id]
		var arm: float = maxf(record.type.radius, MARK_MIN)
		var middle: Vector3 = record.position + Vector3.UP * LIFT
		for corner: Vector3 in [Vector3(arm, 0.0, arm), Vector3(arm, 0.0, -arm)]:
			_line(middle - corner, middle + corner, UiTokens.ORANGE)
	for sensor: VisionSensor in _vision.sensors():
		if sensor.team == shown_team:
			_ring(sensor.body.global_position, sensor.reach(), Color(UiTokens.team_color(shown_team), 0.6))
	for node: Node in get_tree().get_nodes_in_group(&"units"):
		var unit := node as Unit
		if unit == null or not unit.alive or not unit.selected or unit.team != shown_team:
			continue
		_ring(unit.ground_point(), _vision.reach_of(unit), UiTokens.team_color(shown_team))
		for id: int in picture.contacts:
			var target: Unit = unit.registry.get_unit(id)
			if target != null and _vision.detects(unit, target):
				_line(_vision.eye_of(unit), _vision.eye_of(target), UiTokens.ORANGE)
	_readout.text = "VISION TEAM %d   KNOWN %d   CHANGING %d   LAST KNOWN %d" % [shown_team, known,
			picture.contacts.size() - known, picture.memory.size()]
	if _points.is_empty():
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i: int in _points.size():
		_mesh.surface_set_color(_colors[i])
		_mesh.surface_add_vertex(_points[i])
	_mesh.surface_end()


## A flat circle round `middle`, a little above it.
func _ring(middle: Vector3, radius: float, color: Color) -> void:
	for i: int in RING_SIDES:
		var from := Vector2.from_angle(TAU * i / RING_SIDES) * radius
		var to := Vector2.from_angle(TAU * (i + 1) / RING_SIDES) * radius
		_line(middle + Vector3(from.x, LIFT, from.y), middle + Vector3(to.x, LIFT, to.y), color)


func _line(from: Vector3, to: Vector3, color: Color) -> void:
	_points.append(from)
	_points.append(to)
	_colors.append(color)
	_colors.append(color)
