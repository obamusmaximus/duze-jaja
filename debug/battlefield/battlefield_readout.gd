class_name BattlefieldReadout
extends CanvasLayer
## Debug: a corner readout for the scale reference level: frame time, the map's and the grid's size, how long the grid
## took to build, and the travel time of the test flyer from each mothership to the atoll. Reads `BattlefieldStats`
## live. Numbers for the "Measured" section of `docs/plans/battlefield.md`.

const REFRESH_TIME: float = 0.25

@export var stats: BattlefieldStats

## How long the map grid took to build, in milliseconds (set by the level).
var grid_build_ms: float = 0.0
## Cells in the map grid (set by the level).
var grid_cells: int = 0

var _label := Label.new()
var _since: float = 0.0


func _ready() -> void:
	layer = 99
	_label.position = Vector2(24.0, 24.0)
	_label.add_theme_font_size_override(&"font_size", 18)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 5)
	add_child(_label)
	_refresh()


func _process(delta: float) -> void:
	_since += delta
	if _since >= REFRESH_TIME:
		_since = 0.0
		_refresh()


## Seconds the test flyer needs to cover `metres`.
func travel_time(metres: float) -> float:
	return metres / maxf(stats.flyer_speed, 0.1)


func _refresh() -> void:
	var to_ring: float = maxf(stats.mothership_standoff - stats.ring_radius - stats.ring_width * 0.5, 0.0)
	var to_island: float = maxf(stats.mothership_standoff - stats.big_island_size.x * 0.5, 0.0)
	_label.text = "%d fps, %.1f ms/frame, %d draw calls\nmap %d x %d m, grid %d cells (built in %.0f ms)\nmothership to reef ring: %d m, %.1f s at %d m/s\nmothership to big island: %d m, %.1f s" % [
		Engine.get_frames_per_second(), 1000.0 / maxf(Engine.get_frames_per_second(), 1.0),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(stats.map_extent.x), int(stats.map_extent.y), grid_cells, grid_build_ms,
		int(to_ring), travel_time(to_ring), int(stats.flyer_speed),
		int(to_island), travel_time(to_island)]
