class_name HeightmapReloader
extends Node
## Debug: the heightmap authoring loop (`docs/mechanics/heightmap.md`, "Authoring"). Watches the source PNG and, when it
## is saved, re-imports it into the level's `TerrainHeights` in place; only the chunks whose samples changed rebuild.
## `debug_heightmap_reload` re-imports by hand, `debug_heightmap_save` writes the current heights (brush edits
## included) back to the PNG, `debug_reference_layer` writes the Krita reference layer (`ReferenceLayer`). A PNG of a different size is refused: restart the level for that.

signal reloaded(area: Rect2)

## File name `debug_reference_layer` writes the Krita reference layer under (next to the heightmap PNG; never imported).
const REFERENCE_FILE: String = "reference_layer.png"
const BATTLEFIELD: BattlefieldStats = preload("res://tuning/battlefield_default.tres")
const MOTHERSHIP: MothershipStats = preload("res://tuning/mothership_default.tres")

var _heights: TerrainHeights
var _chunks: TerrainChunks
var _stats: HeightmapStats
var _mtime: int = 0
var _since_poll: float = 0.0


func setup(heights: TerrainHeights, chunks: TerrainChunks, stats: HeightmapStats) -> void:
	_heights = heights
	_chunks = chunks
	_stats = stats
	_mtime = FileAccess.get_modified_time(stats.source_path)


func _process(delta: float) -> void:
	_since_poll += delta
	if _since_poll < _stats.reload_poll_seconds:
		return
	_since_poll = 0.0
	var mtime: int = FileAccess.get_modified_time(_stats.source_path)
	if mtime != _mtime:
		_mtime = mtime
		reload()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_heightmap_reload"):
		reload()
	elif event.is_action_pressed(&"debug_reference_layer"):
		var path: String = _stats.source_path.get_base_dir().path_join(REFERENCE_FILE)
		var error: Error = ReferenceLayer.save(_heights, BATTLEFIELD, MOTHERSHIP, path)
		print("Krita reference layer saved to %s (%s)" % [path, error_string(error)])
	elif event.is_action_pressed(&"debug_heightmap_save"):
		var error: Error = HeightmapImport.save_file(_heights, _stats.source_path)
		_mtime = FileAccess.get_modified_time(_stats.source_path)
		print("Heightmap saved to %s (%s)" % [_stats.source_path, error_string(error)])


## Re-imports the PNG now. Returns the area that changed (empty when nothing did or the file was refused).
func reload() -> Rect2:
	var fresh: TerrainHeights = HeightmapImport.load_file(_stats.source_path, _stats)
	if fresh == null:
		return Rect2()
	if fresh.samples != _heights.samples or not is_equal_approx(fresh.spacing, _heights.spacing):
		push_warning("Heightmap: %s is %s samples at %s m, the level has %s at %s m. Restart the level to use it."
				% [_stats.source_path, fresh.samples, fresh.spacing, _heights.samples, _heights.spacing])
		return Rect2()
	var scaled: bool = not is_equal_approx(fresh.min_height, _heights.min_height) \
			or not is_equal_approx(fresh.height_range, _heights.height_range)
	var first: Vector2i = _heights.samples
	var last := Vector2i(-1, -1)
	for i: int in _heights.samples.x * _heights.samples.y:
		if fresh.data.decode_u16(i * 2) != _heights.data.decode_u16(i * 2):
			var at := Vector2i(i % _heights.samples.x, i / _heights.samples.x)
			first = first.min(at)
			last = last.max(at)
	if last.x < 0 and not scaled:
		return Rect2()
	_heights.min_height = fresh.min_height
	_heights.height_range = fresh.height_range
	_heights.data = fresh.data
	var area: Rect2 = _heights.bounds()
	if not scaled:
		area = Rect2(_heights.origin + Vector2(first) * _heights.spacing, Vector2(last - first) * _heights.spacing)
	_chunks.changed(area)
	reloaded.emit(area)
	return area
