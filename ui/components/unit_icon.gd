class_name UnitIcon
extends Control
## A unit type's symbol (`UnitStats.icon`) tinted one colour, or the type's initial when it has none. One component
## for every place a type is shown as a symbol: the cargo view, and the production queue and squad builder later.
## View only.

var _stats: UnitStats
var _color: Color
var _texture := TextureRect.new()
var _initial := Label.new()


func _init(stats: UnitStats = null, color: Color = UiTokens.OFF_WHITE) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_initial.theme_type_variation = &"LabelHeading"
	_initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_initial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_texture)
	add_child(_initial)
	show_type(stats, color)


func show_type(stats: UnitStats, color: Color = UiTokens.OFF_WHITE) -> void:
	_stats = stats
	_color = color
	var has_icon: bool = stats != null and stats.icon != null
	_texture.texture = stats.icon if has_icon else null
	_texture.modulate = color
	_texture.visible = has_icon
	_initial.visible = not has_icon and stats != null
	_initial.text = stats.display_name.left(1).to_upper() if stats != null else ""
	_initial.add_theme_color_override(&"font_color", color)
