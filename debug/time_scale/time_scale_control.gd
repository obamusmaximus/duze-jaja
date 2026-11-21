extends CanvasLayer
## Debug autoload `DebugTimeScale`: steps `Engine.time_scale` through `TimeScaleStats.steps` with
## `debug_time_slower` / `debug_time_faster`, and back to 1 with `debug_time_reset`, to watch fights in slow motion.
## A label shows the speed while it isn't 1. Debug builds only; removes itself otherwise.

const STATS_PATH: String = "res://tuning/time_scale_default.tres"
const FONT_SIZE: int = 40
const TOP_MARGIN: float = 24.0

var _stats: TimeScaleStats = load(STATS_PATH)
var _label: Label


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 90
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.position.y = TOP_MARGIN
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_label.add_theme_constant_override(&"outline_size", 8)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_show_speed()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_time_slower"):
		step(-1)
	elif event.is_action_pressed(&"debug_time_faster"):
		step(1)
	elif event.is_action_pressed(&"debug_time_reset"):
		set_speed(1.0)
	else:
		return
	get_viewport().set_input_as_handled()


## Moves `direction` steps (-1 slower, 1 faster) from the listed speed nearest the current one.
func step(direction: int) -> void:
	var speeds: Array = Array(_stats.steps)
	if speeds.is_empty():
		return
	speeds.sort()
	var nearest: int = 0
	for i: int in speeds.size():
		if absf(speeds[i] - Engine.time_scale) < absf(speeds[nearest] - Engine.time_scale):
			nearest = i
	set_speed(speeds[clampi(nearest + direction, 0, speeds.size() - 1)])


func set_speed(speed: float) -> void:
	Engine.time_scale = speed
	_show_speed()


func _show_speed() -> void:
	_label.visible = not is_equal_approx(Engine.time_scale, 1.0)
	_label.text = "Speed x%s" % snappedf(Engine.time_scale, 0.01)
