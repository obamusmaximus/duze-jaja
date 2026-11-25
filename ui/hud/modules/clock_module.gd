class_name ClockModule
extends HudModule
## HUD module: match time, a small caption and condensed figures on one line, no header. Counts game time (slows
## with slow time), from when the HUD was built.

var _elapsed: float = 0.0
var _since_refresh: float = 0.0
var _figures := HudModule.label("00:00", &"LabelDisplaySmall")


func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.UNIT)
	var caption := HudModule.label("T", &"LabelCaption")
	caption.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(caption)
	row.add_child(_figures)
	content.add_child(row)


func _process(delta: float) -> void:
	_elapsed += delta
	_since_refresh += delta
	if context != null and _since_refresh >= 1.0 / context.stats.readout_rate:
		_since_refresh = 0.0
		var seconds: int = floori(_elapsed)
		_figures.text = "%02d:%02d" % [seconds / 60, seconds % 60]
