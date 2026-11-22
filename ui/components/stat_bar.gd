class_name StatBar
extends Control
## A flat horizontal bar: a thin rule for the whole track, a solid fill for the fraction, and a tick every tenth.
## The fill is the colour you give it, and turns the warning accent when the fraction falls to
## `UiTokens.LOW_HEALTH`. Reusable for health, progress and capacity.

var fraction: float = 1.0:
	set(value):
		fraction = clampf(value, 0.0, 1.0)
		queue_redraw()
var fill_color: Color = UiTokens.CYAN:
	set(value):
		fill_color = value
		queue_redraw()
## Whether the fill turns orange when low.
var warn_when_low: bool = true


func _init() -> void:
	custom_minimum_size = Vector2(UiTokens.px(8), UiTokens.px(1))
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var rule: float = UiTokens.BORDER
	draw_rect(Rect2(0.0, (size.y - rule) * 0.5, size.x, rule), UiTokens.RULE)
	for i: int in range(1, 10):
		var x: float = roundf(size.x * i / 10.0)
		draw_rect(Rect2(x, size.y - rule * 2.0, rule * 0.5, rule * 2.0), UiTokens.RULE)
	var color: Color = UiTokens.ORANGE if warn_when_low and fraction <= UiTokens.LOW_HEALTH else fill_color
	draw_rect(Rect2(0.0, 0.0, roundf(size.x * fraction), size.y), color)
