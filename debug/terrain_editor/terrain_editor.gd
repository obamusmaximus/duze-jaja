class_name TerrainEditor
extends Node
## Debug: paints the level's terrain with the mouse while the game runs. `debug_terrain_editor` (F2) turns it on; then
## left button paints the chosen tile (hold to drag), Shift + left button erases (the right button stays the camera's), 1-7 pick the tile (flat, ramp, road pieces),
## R turns it (Shift+R back), Page Down and Page Up lower and raise the height level (the brackets are slow time's), Ctrl+S (Cmd+S) saves the layout .tres.
## While on it takes the mouse and these keys from the RTS controls. Painting changes the real map: the MapGrid
## re-reads the changed cells, so units re-path over new ramps and around new cliffs. Edits TerrainLayout through the
## level's TerrainMap only; gameplay never depends on this node.

const TOGGLE_ACTION: StringName = &"debug_terrain_editor"
const MAX_LEVEL: int = 6
const BRUSHES: Array[TerrainLayout.Kind] = [
	TerrainLayout.Kind.FLAT, TerrainLayout.Kind.RAMP, TerrainLayout.Kind.ROAD_STRAIGHT, TerrainLayout.Kind.ROAD_CORNER,
	TerrainLayout.Kind.ROAD_CROSS, TerrainLayout.Kind.ROAD_SPLIT, TerrainLayout.Kind.ROAD_END,
]
const WORLD_MASK: int = 1 << 0

var _terrain: TerrainMap
var _active: bool = false
var _kind: TerrainLayout.Kind = TerrainLayout.Kind.FLAT
var _turn: int = 0
var _level: int = 0
var _painting: bool = false
var _erasing: bool = false
var _hover: Vector2i = Vector2i.ZERO
var _has_hover: bool = false
var _saved_note: String = ""
var _ghost := MeshInstance3D.new()
var _layer := CanvasLayer.new()
var _label := Label.new()


func setup(terrain: TerrainMap) -> void:
	_terrain = terrain
	_ghost.visible = false
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(UiTokens.CYAN, 0.55)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost.material_override = material
	add_child(_ghost)
	_label.position = Vector2(UiTokens.px(2), UiTokens.px(2))
	_label.visible = false
	_layer.add_child(_label)
	add_child(_layer)


func _input(event: InputEvent) -> void:
	if _terrain == null:
		return
	if event.is_action_pressed(TOGGLE_ACTION):
		_set_active(not _active)
		get_viewport().set_input_as_handled()
		return
	if not _active:
		return
	if event is InputEventMouseButton:
		_on_mouse_button(event as InputEventMouseButton)
	elif event is InputEventKey and event.pressed and not event.echo:
		_on_key(event as InputEventKey)


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	var hit: Dictionary = _ray()
	_has_hover = not hit.is_empty()
	if _has_hover:
		var point: Vector3 = hit["position"]
		var normal: Vector3 = hit["normal"]
		if normal.y < 0.6:  # A cliff wall: the cell is the one on its open side.
			point += Vector3(normal.x, 0.0, normal.z).normalized() * 0.5
		_hover = _terrain.cell_at(point)
		if _painting:
			_terrain.paint(_hover, _kind, _turn, _level)
		elif _erasing:
			_terrain.erase(_hover)
	_update_ghost()


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed and get_viewport().gui_get_hovered_control() != null:
		return
	get_viewport().set_input_as_handled()
	_painting = event.pressed and not event.shift_pressed
	_erasing = event.pressed and event.shift_pressed


func _on_key(event: InputEventKey) -> void:
	var handled: bool = true
	var index: int = event.keycode - KEY_1
	if index >= 0 and index < BRUSHES.size():
		_kind = BRUSHES[index]
	elif event.keycode == KEY_R:
		_turn = posmod(_turn + (-1 if event.shift_pressed else 1), 4)
	elif event.keycode == KEY_PAGEUP:
		_level = mini(_level + 1, MAX_LEVEL)
	elif event.keycode == KEY_PAGEDOWN:
		_level = maxi(_level - 1, 0)
	elif event.keycode == KEY_S and (event.ctrl_pressed or event.meta_pressed):
		_save()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()
		_refresh_label()


func _save() -> void:
	var layout: TerrainLayout = _terrain.layout
	layout.commit()
	if layout.resource_path.is_empty():
		_saved_note = "  [layout has no file: set one on the TerrainMap]"
		return
	var error: Error = ResourceSaver.save(layout, layout.resource_path)
	_saved_note = "  [saved %s]" % layout.resource_path.get_file() if error == OK else "  [save failed: %d]" % error


func _set_active(on: bool) -> void:
	_active = on
	_painting = false
	_erasing = false
	_label.visible = on
	_ghost.visible = on
	_refresh_label()


func _refresh_label() -> void:
	_label.text = "TERRAIN EDITOR (F2 off)\n%s, turn %d, level %d%s\nLMB paint, Shift+LMB erase, 1-7 tile, R turn, PgUp/PgDn level, Ctrl+S save" % [
		TerrainPieces.NAMES[_kind], _turn, _level, _saved_note]


func _update_ghost() -> void:
	_ghost.visible = _has_hover
	if not _has_hover:
		return
	var size: float = _terrain.tile_size()
	var ground := Vector3((_hover.x + 0.5) * size, _level * _terrain.step_height() + 0.05, (_hover.y + 0.5) * size)
	_ghost.mesh = TerrainPieces.mesh(_kind)
	_ghost.transform = TerrainPieces.tile_transform(_kind, _turn, ground, size)


func _ray() -> Dictionary:
	var viewport: Viewport = get_viewport()
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return {}
	var mouse: Vector2 = viewport.get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mouse)
	var query := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(mouse) * 4000.0, WORLD_MASK)
	return camera.get_world_3d().direct_space_state.intersect_ray(query)
