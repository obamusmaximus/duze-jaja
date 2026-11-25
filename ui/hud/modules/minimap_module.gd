class_name MinimapModule
extends HudModule
## HUD module: the minimap (`Minimap`) in a deep-black well, no header.

var _minimap := Minimap.new()


func _body_style() -> StringName:
	return &"PanelDeep"


func _build() -> void:
	_minimap.setup(context.area, context.rig, context.stats)
	_minimap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(_minimap)


func _apply() -> void:
	_minimap.custom_minimum_size = Vector2.ONE * UiTokens.px(context.stats.minimap_units)
