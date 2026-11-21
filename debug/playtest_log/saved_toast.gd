class_name SavedToast
extends CanvasLayer
## Debug: a short on-screen note in the top-left corner that fades out, e.g. "Playtest log saved".

const SHOW_TIME: float = 2.0

var _label: Label
var _tween: Tween


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(24.0, 24.0)
	_label.add_theme_font_size_override(&"font_size", 28)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 6)
	_label.modulate.a = 0.0
	add_child(_label)


func show_text(text: String) -> void:
	_label.text = text
	_label.modulate.a = 1.0
	if _tween:
		_tween.kill()
	# Real time: the note must fade during bullet time and while paused too.
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_interval(SHOW_TIME)
	_tween.tween_property(_label, "modulate:a", 0.0, 0.5)
