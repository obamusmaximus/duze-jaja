class_name LastKnownGhosts
extends Node3D
## Visual only: a wireframe ghost of each big enemy unit (`UnitStats.leaves_ghost`) where the player's team last saw
## it, from the team's last-known records (`TeamVision.memory`). Commander views only: hidden while the team has a
## pilot. A ghost shows its type and how long ago it was lost, decays as the record ages (`ghost_time`) and dissolves
## when the record ends. Rebuilt only when the records change (`Vision.memory_changed`); it never changes them.

const SHADER: Shader = preload("res://vision/ghost.gdshader")
## Footprint bracket arms on the ground, as a share of the unit's radius.
const BRACKET: float = 0.35

var _vision: Vision
var _seats: PilotSeats
var _heights: TerrainHeights
var _team: int = 0
var _stats: VisionStats
var _font: Font
## Enemy unit id to its ghost (a Node3D with `mesh`, `label` and `born` metadata).
var _ghosts: Dictionary = {}
## Ghosts whose record ended, to their seconds into the dissolve.
var _dissolving: Dictionary = {}
var _materials: Dictionary = {}


func setup(vision: Vision, seats: PilotSeats, heights: TerrainHeights, team: int, stats: VisionStats) -> void:
	_vision = vision
	_seats = seats
	_heights = heights
	_team = team
	_stats = stats
	_font = UiThemeBuilder.face(UiTokens.FACE_CONDENSED)
	_vision.memory_changed.connect(_on_memory_changed)
	_stats.changed.connect(_on_stats_changed)


func _on_stats_changed() -> void:
	for material: ShaderMaterial in _materials.values():
		material.set_shader_parameter(&"strength", _stats.ghost_strength)


func _on_memory_changed(team: int) -> void:
	if team != _team:
		return
	var memory: Dictionary = _vision.of_team(_team).memory
	for id: int in _ghosts.keys():
		var ghost: Node3D = _ghosts[id]
		if memory.get(id) != ghost.get_meta(&"record"):
			_dissolving[ghost] = 0.0
			_ghosts.erase(id)
	for id: int in memory:
		var record: LastKnown = memory[id]
		if record.ghost and not _ghosts.has(id):
			var ghost: Node3D = _make(record)
			if ghost != null:
				_ghosts[id] = ghost


func _process(delta: float) -> void:
	visible = _seats.unit_id_of(_team) == 0
	var memory: Dictionary = _vision.of_team(_team).memory
	for id: int in _ghosts:
		var ghost: Node3D = _ghosts[id]
		var record: LastKnown = memory.get(id)
		if record == null:
			continue
		var seconds: float = _vision.time - record.time
		_set_look(ghost, clampf(seconds / _stats.ghost_time, 0.0, 1.0), 0.0)
		var label: Label3D = ghost.get_meta(&"label")
		label.text = "%s\nLOST %d:%02d" % [record.type.display_name.to_upper(), int(seconds) / 60, int(seconds) % 60]
	for ghost: Node3D in _dissolving.keys():
		var through: float = float(_dissolving[ghost]) + delta / _stats.ghost_dissolve
		if through >= 1.0:
			_dissolving.erase(ghost)
			ghost.queue_free()
			continue
		_dissolving[ghost] = through
		_set_look(ghost, float(ghost.get_meta(&"age", 0.0)), through)


func _set_look(ghost: Node3D, age: float, dissolve: float) -> void:
	ghost.set_meta(&"age", age)
	for part: GeometryInstance3D in [ghost.get_meta(&"mesh"), ghost.get_meta(&"marks")]:
		part.set_instance_shader_parameter(&"age", age)
		part.set_instance_shader_parameter(&"dissolve", dissolve)
	var label: Label3D = ghost.get_meta(&"label")
	label.modulate.a = (1.0 - age * 0.7) * (1.0 - dissolve)


func _make(record: LastKnown) -> Node3D:
	var lines: ArrayMesh = GhostLines.of(record.type)
	if lines == null:
		return null
	var ghost := Node3D.new()
	ghost.position = record.position
	ghost.rotation.y = record.yaw
	add_child(ghost)
	var height: float = lines.get_aabb().end.y
	var material: ShaderMaterial = _material_for(UiTokens.team_color(record.team))
	var mesh := MeshInstance3D.new()
	mesh.mesh = lines
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.set_instance_shader_parameter(&"height", height)
	ghost.add_child(mesh)
	var marks := MeshInstance3D.new()
	marks.mesh = _ground_marks(record, ghost)
	marks.material_override = material
	marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marks.set_instance_shader_parameter(&"height", height)
	ghost.add_child(marks)
	var label := Label3D.new()
	label.font = _font
	label.font_size = UiTokens.TEXT_SMALL
	label.pixel_size = 0.0006
	label.fixed_size = true
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.shaded = false
	label.modulate = UiTokens.team_color(record.team)
	label.outline_modulate = UiTokens.HUD_EDGE
	label.outline_size = UiTokens.BORDER * 2
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.position = Vector3(0.0, height + 2.0, 0.0)
	label.offset = Vector2(24.0, 0.0)
	ghost.add_child(label)
	ghost.set_meta(&"record", record)
	ghost.set_meta(&"mesh", mesh)
	ghost.set_meta(&"marks", marks)
	ghost.set_meta(&"label", label)
	return ghost


## A drop line from the ghost to the ground (for one lost in the air) and corner brackets around its footprint there.
func _ground_marks(record: LastKnown, ghost: Node3D) -> ArrayMesh:
	var ground: float = MapGrid.SEA_LEVEL
	if _heights != null:
		ground = maxf(_heights.height_at(record.position.x, record.position.z), MapGrid.SEA_LEVEL)
	var down: float = minf(ground - ghost.position.y, 0.0) + 0.3
	var points := PackedVector3Array()
	if down < -1.0:
		points.append(Vector3.ZERO)
		points.append(Vector3(0.0, down, 0.0))
	var r: float = record.type.radius
	var arm: float = r * BRACKET
	for corner: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		var at := Vector3(corner.x * r, down, corner.y * r)
		points.append(at)
		points.append(at - Vector3(corner.x * arm, 0.0, 0.0))
		points.append(at)
		points.append(at - Vector3(0.0, 0.0, corner.y * arm))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh


## One material per colour (one per enemy team), shared by its ghosts.
func _material_for(color: Color) -> ShaderMaterial:
	var key: String = color.to_html()
	if not _materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter(&"line_color", color)
		material.set_shader_parameter(&"strength", _stats.ghost_strength)
		_materials[key] = material
	return _materials[key]
