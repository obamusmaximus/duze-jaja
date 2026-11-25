class_name HeightmapBrush
extends Node
## Debug: a terrain brush for the heightmap (`docs/mechanics/heightmap.md`, "Brushes"). `debug_brush_toggle` (#) turns
## it on: the left mouse button then paints instead of selecting, `debug_brush_mode` (+) cycles raise, lower, flatten
## and crater, `debug_brush_smaller` / `debug_brush_larger` (- and =) change the radius. Edits go through
## `TerrainChunks.changed()`, the same map-change call gameplay uses, so units re-path. No undo: re-import the PNG.

var _heights: TerrainHeights
var _chunks: TerrainChunks
var _stats: HeightmapStats
var _active: bool = false
var _holding: bool = false
var _mode: TerrainBrush.Mode = TerrainBrush.Mode.RAISE
var _flatten_target: float = 0.0
var _ring := MeshInstance3D.new()
var _ring_mesh := ImmediateMesh.new()
var _label := Label.new()


func setup(heights: TerrainHeights, chunks: TerrainChunks, stats: HeightmapStats) -> void:
	_heights = heights
	_chunks = chunks
	_stats = stats
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = UiTokens.GREEN
	material.no_depth_test = true
	_ring.mesh = _ring_mesh
	_ring.material_override = material
	_ring.top_level = true
	_ring.visible = false
	add_child(_ring)
	var layer := CanvasLayer.new()
	layer.layer = 91
	add_child(layer)
	_label.theme_type_variation = &"LabelCaption"
	_label.position = Vector2(UiTokens.px(4), UiTokens.px(12))
	_label.visible = false
	layer.add_child(_label)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_brush_toggle"):
		_active = not _active
		_holding = false
		_ring.visible = _active
		_update_label()
		get_viewport().set_input_as_handled()
	elif not _active:
		return
	elif event.is_action_pressed(&"debug_brush_mode"):
		_mode = ((_mode + 1) % TerrainBrush.MODE_NAMES.size()) as TerrainBrush.Mode
		_update_label()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_brush_smaller") or event.is_action_pressed(&"debug_brush_larger"):
		var step: float = _stats.brush_radius_step * (1.0 if event.is_action_pressed(&"debug_brush_larger") else -1.0)
		_stats.brush_radius = clampf(_stats.brush_radius + step, 2.0, 150.0)
		_stats.emit_changed()
		_update_label()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.is_action(&"select"):
		get_viewport().set_input_as_handled()
		_holding = event.pressed
		if _holding:
			var point: Vector3 = _cursor_point()
			if point.is_finite():
				_flatten_target = point.y
				if _mode == TerrainBrush.Mode.CRATER:
					_paint(point, _stats.crater_depth)


func _physics_process(delta: float) -> void:
	if not (_active and _holding) or _mode == TerrainBrush.Mode.CRATER:
		return
	var point: Vector3 = _cursor_point()
	if not point.is_finite():
		return
	var amount: float = _stats.flatten_rate * delta if _mode == TerrainBrush.Mode.FLATTEN else _stats.brush_rate * delta
	_paint(point, amount)


func _process(_delta: float) -> void:
	if not _active:
		return
	var point: Vector3 = _cursor_point()
	_ring_mesh.clear_surfaces()
	if not point.is_finite():
		return
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	const SEGMENTS: int = 48
	for i: int in SEGMENTS + 1:
		var angle: float = TAU * float(i) / SEGMENTS
		var x: float = point.x + cos(angle) * _stats.brush_radius
		var z: float = point.z + sin(angle) * _stats.brush_radius
		_ring_mesh.surface_add_vertex(Vector3(x, _heights.height_at(x, z) + 0.3, z))
	_ring_mesh.surface_end()


func _paint(point: Vector3, amount: float) -> void:
	var area: Rect2 = TerrainBrush.apply(_heights, _mode, Vector2(point.x, point.z), _stats.brush_radius, amount,
			_flatten_target)
	_chunks.changed(area)


func _cursor_point() -> Vector3:
	var viewport: Viewport = get_viewport()
	return GroundPick.ground_point(viewport, viewport.get_mouse_position())


func _update_label() -> void:
	_label.visible = _active
	_label.text = "BRUSH  %s  RADIUS %d M   + MODE   , / . SIZE   # OFF" % [
			TerrainBrush.MODE_NAMES[_mode].to_upper(), roundi(_stats.brush_radius)]
