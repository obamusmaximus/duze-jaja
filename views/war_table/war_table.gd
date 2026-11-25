class_name WarTable
extends Node3D
## Visual only: the strategy view's table (`docs/mechanics/war_table.md`). A coarse model of the map drawn from
## `TerrainHeights` in tiles, held far above the live world on its own visual layer (`LAYER`), with its own camera rig
## (the same `CameraRig` as the RTS view, a different `CameraStats` preset), squad tokens and a tilt-shift blur.
## It reads the simulation (heights, units) and never changes it.

## The visual layer (bit mask) the table lives on: its camera sees only this, the RTS camera never sees it.
const LAYER: int = 1 << 19
const RIG_SCENE: PackedScene = preload("res://camera/camera_rig.tscn")
const CAMERA_STATS: CameraStats = preload("res://tuning/camera_table.tres")

@export var stats: WarTableStats

var rig: CameraRig
var _heights: TerrainHeights
var _tiles: Dictionary = {}
var _dirty: Array[Vector2i] = []
var _tile_count: Vector2i = Vector2i.ZERO
var _material: StandardMaterial3D
var _attributes := CameraAttributesPractical.new()
var _tokens: WarTableTokens


## Builds the table from `heights`; `bounds` limits the camera focus, `home_yaw` is the rig's reset yaw.
func setup(heights: TerrainHeights, bounds: Rect2, home_yaw: float, units: UnitRegistry, player_team: int) -> void:
	_heights = heights
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cells: Vector2i = Vector2i(ceili(float(heights.samples.x - 1) / stats.sample_step),
		ceili(float(heights.samples.y - 1) / stats.sample_step))
	_tile_count = Vector2i(ceili(float(cells.x) / stats.tile_cells), ceili(float(cells.y) / stats.tile_cells))
	for tz: int in _tile_count.y:
		for tx: int in _tile_count.x:
			_dirty.append(Vector2i(tx, tz))
	_flush(_dirty.size())
	_tokens = WarTableTokens.new()
	_tokens.name = "Tokens"
	add_child(_tokens)
	_tokens.setup(stats, units, heights, rig_camera_distance, player_team)
	rig = RIG_SCENE.instantiate()
	rig.stats = CAMERA_STATS
	rig.follow_ground = false
	rig.position = Vector3(0.0, stats.table_height, 0.0)
	add_child(rig)
	rig.setup(bounds, home_yaw)
	_setup_camera(rig.get_camera())
	rig.process_mode = Node.PROCESS_MODE_DISABLED


## Marks the map area (x, z) changed: the tiles it touches are redrawn a few per frame.
func mark_changed(area: Rect2) -> void:
	if _heights == null:
		return
	var step: float = _heights.spacing * float(stats.sample_step) * float(stats.tile_cells)
	var first := Vector2i(floori((area.position.x - _heights.origin.x) / step), floori((area.position.y - _heights.origin.y) / step))
	var last := Vector2i(floori((area.end.x - _heights.origin.x) / step), floori((area.end.y - _heights.origin.y) / step))
	for tz: int in range(maxi(first.y, 0), mini(last.y, _tile_count.y - 1) + 1):
		for tx: int in range(maxi(first.x, 0), mini(last.x, _tile_count.x - 1) + 1):
			if not _dirty.has(Vector2i(tx, tz)):
				_dirty.append(Vector2i(tx, tz))


func _process(_delta: float) -> void:
	if not _dirty.is_empty():
		_flush(stats.tiles_per_frame)
	_apply_blur()


## Height on the table (world y) of the ground at the world point (x, z): the table plane plus the scaled land height.
func surface_y(x: float, z: float) -> float:
	return stats.table_height + maxf(_heights.height_at(x, z), 0.0) * stats.height_scale


func rig_camera_distance() -> float:
	return rig.distance() if rig != null else 1000.0


func _flush(count: int) -> void:
	for i: int in mini(count, _dirty.size()):
		_build_tile(_dirty.pop_front())


func _build_tile(tile: Vector2i) -> void:
	var cells: int = stats.tile_cells
	var total := Vector2i(ceili(float(_heights.samples.x - 1) / stats.sample_step), ceili(float(_heights.samples.y - 1) / stats.sample_step))
	var first: Vector2i = tile * cells
	var size: Vector2i = (total - first).clamp(Vector2i.ZERO, Vector2i(cells, cells))
	var view: MeshInstance3D = _tiles.get(tile)
	if view == null:
		view = MeshInstance3D.new()
		view.layers = LAYER
		view.material_override = _material
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(view)
		_tiles[tile] = view
	view.mesh = WarTableMesh.build_tile(_heights, stats, first, size)


func _setup_camera(camera: Camera3D) -> void:
	camera.cull_mask = LAYER
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = UiTokens.BLACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	camera.environment = environment
	camera.attributes = _attributes


## Tilt-shift: the camera's depth-of-field blur, near and far of a band around the focus (shares of the distance).
func _apply_blur() -> void:
	var distance: float = rig.distance()
	_attributes.dof_blur_far_enabled = stats.blur_enabled
	_attributes.dof_blur_far_distance = distance * stats.far_start
	_attributes.dof_blur_far_transition = distance * stats.far_transition
	_attributes.dof_blur_near_enabled = stats.blur_enabled
	_attributes.dof_blur_near_distance = distance * stats.near_end
	_attributes.dof_blur_near_transition = distance * stats.near_transition
	_attributes.dof_blur_amount = stats.blur_amount
