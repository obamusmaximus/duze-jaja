class_name WarTableTokens
extends MultiMeshInstance3D
## Visual only: the squad tokens on the war table. One box per carryall, per mothership, per squad (at its members'
## centre) and per unit with no squad, in the team colour, sized by the camera's distance so they read at every zoom.
## Refreshed `token_hz` times a second from the unit registry.

const MAX_TOKENS: int = 512

var _stats: WarTableStats
var _units: UnitRegistry
var _heights: TerrainHeights
var _distance: Callable
var _team: int = 0
var _clock: float = 0.0
var _figures := StrategyFigures.new()


func setup(stats: WarTableStats, units: UnitRegistry, heights: TerrainHeights, distance: Callable, team: int) -> void:
	_stats = stats
	_units = units
	_heights = heights
	_distance = distance
	_team = team
	layers = WarTable.LAYER
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	box.material = material
	multi.mesh = box
	multi.instance_count = MAX_TOKENS
	multi.visible_instance_count = 0
	multimesh = multi
	custom_aabb = AABB(Vector3(-5000.0, _stats.table_height - 500.0, -5000.0), Vector3(10000.0, 1000.0, 10000.0))


func _process(delta: float) -> void:
	_clock += delta
	if _clock < 1.0 / _stats.token_hz:
		return
	_clock = 0.0
	_refresh()


func _refresh() -> void:
	if _units == null:
		return
	var size: float = float(_distance.call()) * _stats.token_size
	_figures.collect(_units, get_tree())
	var count: int = 0
	for i: int in _figures.size():
		var scale: float = 1.0
		match _figures.kinds[i]:
			StrategyFigures.Kind.CARRYALL:
				scale = _stats.carryall_scale
			StrategyFigures.Kind.MOTHERSHIP:
				scale = _stats.ship_scale
		count = _put(count, _figures.positions[i], size * scale, _figures.teams[i])
	multimesh.visible_instance_count = count


func _put(index: int, world: Vector3, size: float, team: int) -> int:
	if index >= MAX_TOKENS:
		return index
	var at := Vector3(world.x, (get_parent() as WarTable).surface_y(world.x, world.z) + _stats.token_lift + size * 0.5, world.z)
	multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3(size, size * 0.6, size)), at))
	multimesh.set_instance_color(index, UiTokens.team_color(team))
	return index + 1
