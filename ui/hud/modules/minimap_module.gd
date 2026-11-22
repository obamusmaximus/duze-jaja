class_name MinimapModule
extends HudModule
## HUD module: the minimap (`Minimap`) in a deep-black well, the map's size in the header note.

var _minimap := Minimap.new()


func _title() -> String:
	return "TACTICAL MAP"


func _body_style() -> StringName:
	return &"PanelDeep"


func _build() -> void:
	_minimap.setup(context.area, context.rig, context.stats)
	_minimap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(_minimap)
	set_note("%d×%d M" % [roundi(context.area.size.x), roundi(context.area.size.y)])


func _apply() -> void:
	_minimap.custom_minimum_size = Vector2.ONE * UiTokens.px(context.stats.minimap_units)
