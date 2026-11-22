class_name StatRow
extends HBoxContainer
## One line of a stat sheet: a condensed caption, an optional bar, and a figure at the right. `set_value` updates it;
## a negative fraction hides the bar.

var _caption := Label.new()
var _bar := StatBar.new()
var _value := Label.new()


func _init(caption: String = "") -> void:
	add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
	_caption.theme_type_variation = &"LabelCaption"
	_caption.text = caption.to_upper()
	_caption.custom_minimum_size.x = UiTokens.px(12)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_value.theme_type_variation = &"LabelNumber"
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value.custom_minimum_size.x = UiTokens.px(14)
	_value.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_child(_caption)
	add_child(_bar)
	add_child(_value)


func set_value(text: String, fraction: float = -1.0, color: Color = UiTokens.CYAN) -> void:
	_value.text = text
	_bar.visible = fraction >= 0.0
	_value.size_flags_horizontal = Control.SIZE_SHRINK_END if _bar.visible else Control.SIZE_EXPAND_FILL
	if _bar.visible:
		_bar.fraction = fraction
		_bar.fill_color = color
	_value.theme_type_variation = &"LabelWarning" if _bar.visible and fraction <= UiTokens.LOW_HEALTH else &"LabelNumber"
