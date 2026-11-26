class_name LastKnownHeat
extends Node3D
## Visual only: the player's team's last-known records of enemy units without a ghost, as heat on unwatched ground
## (drawn by the ground material, `WorldMaterials.ground`) and a cross at each spot. Commander views only: off while
## the team has a pilot. Rebuilt only when the records change (`Vision.memory_changed`, at most every `REBUILD_GAP`):
## the texture stores each texel's heat and how fast it cools, so the shader fades it over `memory_time` on its own.

const CROSS_SHADER: Shader = preload("res://vision/last_known_cross.gdshader")
## Least seconds between two rebuilds, so a battle losing contacts every tick rebuilds a few times a second at most.
const REBUILD_GAP: float = 0.25
## Metres the crosses float over the ground.
const CROSS_LIFT: float = 0.6

var _vision: Vision
var _seats: PilotSeats
var _heights: TerrainHeights
var _team: int = 0
var _stats: VisionStats
var _area: Rect2
var _size: Vector2i = Vector2i.ZERO
var _texture: ImageTexture
var _crosses: MultiMeshInstance3D
var _cross_material: ShaderMaterial
var _grounds: Array[ShaderMaterial] = []
## `Vision.time` of the last rebuild, and whether the records changed since.
var _built_at: float = 0.0
var _dirty: bool = true
var _since: float = 0.0
var _shown: float = -1.0
## Total microseconds spent rebuilding, and rebuilds so far (measuring reads them).
var build_usec: int = 0
var builds: int = 0


func setup(vision: Vision, seats: PilotSeats, heights: TerrainHeights, team: int, stats: VisionStats) -> void:
	_vision = vision
	_seats = seats
	_heights = heights
	_team = team
	_stats = stats
	_area = heights.bounds()
	for role: WorldMaterials.Role in WorldMaterials.Role.values():
		_grounds.append(WorldMaterials.ground(role))
	_cross_material = ShaderMaterial.new()
	_cross_material.shader = CROSS_SHADER
	_crosses = MultiMeshInstance3D.new()
	_crosses.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_crosses.material_override = _cross_material
	add_child(_crosses)
	_vision.memory_changed.connect(_on_memory_changed)
	_stats.changed.connect(_on_stats_changed)
	_on_stats_changed()


func _on_memory_changed(team: int) -> void:
	if team == _team:
		_dirty = true


func _on_stats_changed() -> void:
	_size = Vector2i(maxi(ceili(_area.size.x / _stats.heat_cell), 1), maxi(ceili(_area.size.y / _stats.heat_cell), 1))
	_texture = null
	_dirty = true
	_cross_material.set_shader_parameter(&"life", _stats.memory_time)
	_cross_material.set_shader_parameter(&"strength", _stats.heat_strength * 2.0)
	for material: ShaderMaterial in _grounds:
		material.set_shader_parameter(&"heat_strength", _stats.heat_strength)
		material.set_shader_parameter(&"heat_bands", float(_stats.heat_bands))


func _process(delta: float) -> void:
	_since += delta
	if _dirty and _since >= REBUILD_GAP:
		_rebuild()
	var show: float = 0.0 if _seats.unit_id_of(_team) != 0 else 1.0
	_crosses.visible = show > 0.0
	var elapsed: float = _vision.time - _built_at
	_cross_material.set_shader_parameter(&"elapsed", elapsed)
	for material: ShaderMaterial in _grounds:
		material.set_shader_parameter(&"heat_elapsed", elapsed)
		if show != _shown:
			material.set_shader_parameter(&"heat_show", show)
	_shown = show


func _rebuild() -> void:
	var started: int = Time.get_ticks_usec()
	_dirty = false
	_since = 0.0
	_built_at = _vision.time
	var records: Array[LastKnown] = []
	for record: LastKnown in _vision.of_team(_team).memory.values():
		if not record.ghost:
			records.append(record)
	_build_texture(records)
	_build_crosses(records)
	build_usec += Time.get_ticks_usec() - started
	builds += 1


## Splats each record's heat into a fresh picture: per texel the heat now (r) and how much it loses a second (g).
func _build_texture(records: Array[LastKnown]) -> void:
	var data := PackedFloat32Array()
	data.resize(_size.x * _size.y * 2)
	data.fill(0.0)
	var reach: float = _stats.heat_radius / _stats.heat_cell
	var life: float = _stats.memory_time
	for record: LastKnown in records:
		var left: float = clampf(1.0 - (_built_at - record.time) / life, 0.0, 1.0)
		if left <= 0.0:
			continue
		var centre: Vector2 = (Vector2(record.position.x, record.position.z) - _area.position) / _stats.heat_cell
		var low := Vector2i((centre - Vector2(reach, reach)).floor())
		var high := Vector2i((centre + Vector2(reach, reach)).ceil())
		for z: int in range(maxi(low.y, 0), mini(high.y, _size.y - 1) + 1):
			for x: int in range(maxi(low.x, 0), mini(high.x, _size.x - 1) + 1):
				var near: float = 1.0 - (Vector2(x + 0.5, z + 0.5) - centre).length_squared() / (reach * reach)
				if near <= 0.0:
					continue
				var k: float = _stats.heat_weight * near * near
				var at: int = (z * _size.x + x) * 2
				data[at] += k * left
				data[at + 1] += k / life
	var image := Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGF, data.to_byte_array())
	image.convert(Image.FORMAT_RGH)
	if _texture == null or _texture.get_size() != Vector2(_size):
		_texture = ImageTexture.create_from_image(image)
	else:
		_texture.update(image)
	var color: Color = _heat_color(records)
	for material: ShaderMaterial in _grounds:
		material.set_shader_parameter(&"heat_map", _texture)
		material.set_shader_parameter(&"heat_area", Vector4(_area.position.x, _area.position.y,
				_size.x * _stats.heat_cell, _size.y * _stats.heat_cell))
		material.set_shader_parameter(&"heat_color", color)
		material.set_shader_parameter(&"heat_elapsed", 0.0)


## One cross per record, in its team's colour, its age in the custom data.
func _build_crosses(records: Array[LastKnown]) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	var quad := QuadMesh.new()
	quad.orientation = PlaneMesh.FACE_Y
	quad.size = Vector2.ONE * _stats.cross_size
	multimesh.mesh = quad
	multimesh.instance_count = records.size()
	for i: int in records.size():
		var record: LastKnown = records[i]
		var ground: float = maxf(_heights.height_at(record.position.x, record.position.z), MapGrid.SEA_LEVEL)
		var place := Transform3D(Basis.IDENTITY, Vector3(record.position.x, ground + CROSS_LIFT,
				record.position.z))
		multimesh.set_instance_transform(i, place)
		multimesh.set_instance_color(i, UiTokens.team_color(record.team))
		multimesh.set_instance_custom_data(i, Color(_built_at - record.time, 0.0, 0.0, 0.0))
	_crosses.multimesh = multimesh


## The colour of the team most of the records belong to (the enemy, with two teams).
func _heat_color(records: Array[LastKnown]) -> Color:
	var counts: Dictionary = {}
	var best: int = posmod(_team + 1, 2)
	for record: LastKnown in records:
		counts[record.team] = int(counts.get(record.team, 0)) + 1
		if int(counts[record.team]) > int(counts.get(best, 0)):
			best = record.team
	return UiTokens.team_color(best)

