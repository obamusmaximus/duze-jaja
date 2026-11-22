class_name ClockModule
extends HudModule
## HUD module: match time in big condensed figures. Counts game time (slows with slow time), from when the HUD was
## built.

var _elapsed: float = 0.0
var _since_refresh: float = 0.0
var _figures := HudModule.label("00:00", &"LabelDisplay")


func _title() -> String:
	return "MATCH TIME"


func _header_style() -> StringName:
	return &"ModuleHeaderAccent"


func _build() -> void:
	content.add_child(_figures)


func _process(delta: float) -> void:
	_elapsed += delta
	_since_refresh += delta
	if context != null and _since_refresh >= 1.0 / context.stats.readout_rate:
		_since_refresh = 0.0
		var seconds: int = floori(_elapsed)
		_figures.text = "%02d:%02d" % [seconds / 60, seconds % 60]
