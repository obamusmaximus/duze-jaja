class_name TuningThemeBuilder
extends RefCounted
## Debug: builds the tuning panel's own `Theme` from `UiTokens`: the tool type scale (IBM Plex Sans for reading,
## Anybody for structure), flat boxes on the 8 px grid, and the variations the panel scene and `TuningFields` use.
## It only sets what differs from the game theme; the panel's root node carries it, so the HUD is untouched.
## Run `debug/tuning/build_tuning_theme.gd` to write `debug/tuning/tuning_theme.tres` after changing this or the tokens.

const CLEAR: Color = Color(0, 0, 0, 0)


static func build() -> Theme:
	var theme := Theme.new()
	var reading: Font = UiThemeBuilder.face(UiTokens.FACE_TOOL, UiTokens.TOOL_FONT_PATH)
	var strong: Font = UiThemeBuilder.face(UiTokens.FACE_TOOL_STRONG, UiTokens.TOOL_FONT_PATH)
	theme.default_font = reading
	theme.default_font_size = UiTokens.TEXT_TOOL
	_layout(theme)
	_labels(theme, reading)
	_buttons(theme, strong)
	_inputs(theme, reading)
	_tabs(theme)
	_folds(theme)
	_rows(theme)
	return theme


## Margins and gaps, in base units.
static func _layout(theme: Theme) -> void:
	theme.set_type_variation(&"TuningMargin", &"MarginContainer")
	for side: String in ["left", "top", "right", "bottom"]:
		theme.set_constant("margin_" + side, &"TuningMargin", UiTokens.UNIT * 3)
	theme.set_type_variation(&"TuningCardMargin", &"MarginContainer")
	for side: String in ["left", "top", "right", "bottom"]:
		theme.set_constant("margin_" + side, &"TuningCardMargin", UiTokens.UNIT * 2)
	for base: StringName in [&"VBoxContainer", &"HBoxContainer"]:
		for entry: Array in [[&"TuningGap", 2], [&"TuningTight", 1], [&"TuningNone", 0]]:
			var variation := StringName(str(entry[0]) + ("V" if base == &"VBoxContainer" else "H"))
			theme.set_type_variation(variation, base)
			theme.set_constant(&"separation", variation, UiTokens.UNIT * int(entry[1]))


static func _labels(theme: Theme, reading: Font) -> void:
	theme.set_font(&"font", &"Label", reading)
	theme.set_font_size(&"font_size", &"Label", UiTokens.TEXT_TOOL)
	theme.set_color(&"font_color", &"Label", UiTokens.OFF_WHITE)
	var condensed: Font = UiThemeBuilder.face(UiTokens.FACE_TOOL_CAPS, UiTokens.TOOL_FONT_PATH)
	var wide: Font = UiThemeBuilder.face(UiTokens.FACE_WIDE)
	# Name, font, colour, size.
	for entry: Array in [
			[&"TuningTitle", wide, UiTokens.BLACK, UiTokens.TEXT_TOOL_HEADING],
			[&"TuningResourceLabel", condensed, UiTokens.BLACK, UiTokens.TEXT_TOOL_HEADING],
			[&"TuningPreviewTitle", wide, UiTokens.OFF_WHITE, UiTokens.TEXT_TOOL_HEADING],
			[&"TuningDescription", reading, UiTokens.OFF_WHITE, UiTokens.TEXT_TOOL],
			[&"TuningMuted", reading, UiTokens.CONCRETE, UiTokens.TEXT_TOOL_SMALL]]:
		theme.set_type_variation(entry[0], &"Label")
		theme.set_font(&"font", entry[0], entry[1])
		theme.set_color(&"font_color", entry[0], entry[2])
		theme.set_font_size(&"font_size", entry[0], entry[3])
	# Strips: a flat solid header (the game's own bone and green strips, a little tighter).
	var strips: Dictionary = {&"TuningTitleStrip": UiTokens.BONE, &"TuningResourceStrip": UiTokens.GREEN}
	for variation: StringName in strips:
		var style := UiThemeBuilder.box(strips[variation], CLEAR, 1)
		style.content_margin_top = UiTokens.UNIT * 0.5
		style.content_margin_bottom = UiTokens.UNIT * 0.5
		theme.set_type_variation(variation, &"PanelContainer")
		theme.set_stylebox(&"panel", variation, style)
	theme.set_type_variation(&"TuningCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TuningCard", UiThemeBuilder.box(UiTokens.BLACK, UiTokens.RULE, 0))


static func _buttons(theme: Theme, strong: Font) -> void:
	for type_name: StringName in [&"Button", &"OptionButton", &"MenuButton"]:
		UiThemeBuilder._button_states(theme, type_name, [UiTokens.GRAPHITE, UiTokens.OFF_WHITE, UiTokens.RULE],
				[UiTokens.BONE, UiTokens.BLACK], [UiTokens.GREEN, UiTokens.BLACK], 1)
		theme.set_font(&"font", type_name, strong)
		theme.set_font_size(&"font_size", type_name, UiTokens.TEXT_TOOL)
	# Checkbox: no button box, a square tick box of its own. Off is a black square with an off-white edge, on is acid green.
	var plain := StyleBoxEmpty.new()
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		theme.set_stylebox(state, &"CheckBox", plain)
	var focus := UiThemeBuilder.box(CLEAR, UiTokens.GREEN, 0)
	focus.draw_center = false
	theme.set_stylebox(&"focus", &"CheckBox", focus)
	var size: int = UiTokens.UNIT * 3
	theme.set_icon(&"unchecked", &"CheckBox", _tick_box(UiTokens.BLACK, UiTokens.OFF_WHITE, size))
	theme.set_icon(&"checked", &"CheckBox", _tick_box(UiTokens.GREEN, UiTokens.OFF_WHITE, size))
	theme.set_icon(&"unchecked_disabled", &"CheckBox", _tick_box(UiTokens.BLACK, UiTokens.CONCRETE, size))
	theme.set_icon(&"checked_disabled", &"CheckBox", _tick_box(UiTokens.CONCRETE, UiTokens.CONCRETE, size))
	theme.set_font(&"font", &"CheckBox", strong)
	theme.set_font_size(&"font_size", &"CheckBox", UiTokens.TEXT_TOOL)
	theme.set_constant(&"h_separation", &"CheckBox", UiTokens.UNIT)


static func _inputs(theme: Theme, reading: Font) -> void:
	theme.set_font(&"font", &"LineEdit", reading)
	theme.set_font_size(&"font_size", &"LineEdit", UiTokens.TEXT_TOOL)
	theme.set_font_size(&"font_size", &"TooltipLabel", UiTokens.TEXT_TOOL)
	theme.set_font(&"font", &"TooltipLabel", reading)
	for state: StringName in [&"normal", &"focus"]:
		var line_edit: StyleBox = UiThemeBuilder.box(UiTokens.BLACK, UiTokens.RULE if state == &"normal" else UiTokens.GREEN, 0.5)
		line_edit.content_margin_left = UiTokens.UNIT
		line_edit.content_margin_right = UiTokens.UNIT
		theme.set_stylebox(state, &"LineEdit", line_edit)
	# The SpinBox draws its LineEdit; its own box would show a second border.
	theme.set_stylebox(&"normal", &"SpinBox", StyleBoxEmpty.new())


static func _tabs(theme: Theme) -> void:
	var condensed: Font = UiThemeBuilder.face(UiTokens.FACE_TOOL_CAPS, UiTokens.TOOL_FONT_PATH)
	for type_name: StringName in [&"TabContainer", &"TabBar"]:
		theme.set_stylebox(&"tab_unselected", type_name, UiThemeBuilder.box(UiTokens.GRAPHITE, UiTokens.RULE, 1))
		theme.set_stylebox(&"tab_hovered", type_name, UiThemeBuilder.box(UiTokens.BONE, CLEAR, 1))
		theme.set_stylebox(&"tab_selected", type_name, UiThemeBuilder.box(UiTokens.GREEN, CLEAR, 1))
		theme.set_stylebox(&"tab_focus", type_name, UiThemeBuilder.box(CLEAR, UiTokens.GREEN, 1))
		theme.set_color(&"font_unselected_color", type_name, UiTokens.OFF_WHITE)
		theme.set_color(&"font_hovered_color", type_name, UiTokens.BLACK)
		theme.set_color(&"font_selected_color", type_name, UiTokens.BLACK)
		theme.set_font(&"font", type_name, condensed)
		theme.set_font_size(&"font_size", type_name, UiTokens.TEXT_TOOL)
	var panel := UiThemeBuilder.box(UiTokens.BLACK, UiTokens.RULE, 1)
	theme.set_stylebox(&"panel", &"TabContainer", panel)


## Foldable group: a concrete caps title over a rule, a graphite hover fill, no box around the body.
static func _folds(theme: Theme) -> void:
	var condensed: Font = UiThemeBuilder.face(UiTokens.FACE_TOOL_CAPS, UiTokens.TOOL_FONT_PATH)
	for entry: Array in [[&"title_panel", false], [&"title_collapsed_panel", false],
			[&"title_hover_panel", true], [&"title_collapsed_hover_panel", true]]:
		var style := UiThemeBuilder.box(UiTokens.GRAPHITE if entry[1] else UiTokens.BLACK, CLEAR, 0.5)
		style.set_border_width(SIDE_BOTTOM, UiTokens.BORDER)
		style.border_color = UiTokens.RULE
		style.content_margin_left = UiTokens.UNIT
		theme.set_stylebox(entry[0], &"FoldableContainer", style)
	theme.set_stylebox(&"panel", &"FoldableContainer", StyleBoxEmpty.new())
	var focus := UiThemeBuilder.box(CLEAR, UiTokens.GREEN, 0)
	focus.draw_center = false
	theme.set_stylebox(&"focus", &"FoldableContainer", focus)
	for color_name: StringName in [&"font_color", &"collapsed_font_color"]:
		theme.set_color(color_name, &"FoldableContainer", UiTokens.CONCRETE)
	theme.set_color(&"hover_font_color", &"FoldableContainer", UiTokens.OFF_WHITE)
	theme.set_font(&"font", &"FoldableContainer", condensed)
	theme.set_font_size(&"font_size", &"FoldableContainer", UiTokens.TEXT_TOOL)


## One settings row: clear, with a rule under it; the active row (the one in the preview) is graphite with a green bar.
static func _rows(theme: Theme) -> void:
	var normal := UiThemeBuilder.box(CLEAR, CLEAR, 0)
	normal.set_border_width(SIDE_BOTTOM, 1)
	normal.border_color = UiTokens.RULE
	normal.content_margin_left = UiTokens.UNIT
	normal.content_margin_right = UiTokens.UNIT
	var active := normal.duplicate() as StyleBoxFlat
	active.bg_color = UiTokens.GRAPHITE
	active.set_border_width(SIDE_LEFT, UiTokens.ACCENT_BAR)
	active.border_color = UiTokens.GREEN
	theme.set_type_variation(&"TuningRow", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TuningRow", normal)
	theme.set_type_variation(&"TuningRowActive", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TuningRowActive", active)


static func _tick_box(fill: Color, edge: Color, size: int) -> ImageTexture:
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	image.fill(edge)
	image.fill_rect(Rect2i(UiTokens.BORDER, UiTokens.BORDER, size - UiTokens.BORDER * 2, size - UiTokens.BORDER * 2), fill)
	return ImageTexture.create_from_image(image)
