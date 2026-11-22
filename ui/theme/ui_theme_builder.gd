class_name UiThemeBuilder
extends RefCounted
## Builds the game's one `Theme` from `UiTokens` (`docs/style_guide.md`, "UI"): flat boxes with hard corners and one
## border weight, hatching for empty slots, the Anybody faces (condensed, text, numbers, wide, display), and the
## theme variations scenes pick by name. Run `ui/theme/build_theme.gd` to write `ui/theme/game_theme.tres`, which
## the project loads. The variations are listed in `docs/mechanics/ui.md`.

## Faces made so far, by axes, so the theme shares one resource per face.
static var _faces: Dictionary = {}


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = face(UiTokens.FACE_TEXT)
	theme.default_font_size = UiTokens.TEXT_BODY
	_panels(theme)
	_labels(theme)
	_buttons(theme)
	_bars(theme)
	_inputs(theme)
	_tabs(theme)
	return theme


## A flat rectangle: hard corners, a fill, and a border of the one weight (none when `border` is transparent).
static func box(fill: Color, border: Color = Color(0, 0, 0, 0), margin_units: float = 1.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	if border.a > 0.0:
		style.set_border_width_all(UiTokens.BORDER)
		style.border_color = border
	style.set_corner_radius_all(0)
	style.anti_aliasing = false
	style.set_content_margin_all(UiTokens.UNIT * margin_units)
	return style


static func hatch(fill: Color, line: Color, border: Color = Color(0, 0, 0, 0), margin_units: float = 1.0) -> StyleBoxHatch:
	var style := StyleBoxHatch.new()
	style.fill = fill
	style.line = line
	style.border = border
	style.set_content_margin_all(UiTokens.UNIT * margin_units)
	return style


## One face of the type family: (width, weight) on Anybody's axes, with tabular figures. Falls back to the system
## sans if the font file is missing.
static func face(axes: Vector2i, path: String = UiTokens.FONT_PATH) -> Font:
	var key: String = "%s %s" % [path, axes]
	if _faces.has(key):
		return _faces[key]
	var variation := FontVariation.new()
	_faces[key] = variation
	var file: Font = load(path) if ResourceLoader.exists(path) else null
	if file == null:
		var system := SystemFont.new()
		system.font_names = PackedStringArray(["Helvetica Neue", "Arial", "Liberation Sans"])
		file = system
	variation.base_font = file
	var server: TextServer = TextServerManager.get_primary_interface()
	variation.variation_opentype = {server.name_to_tag("wdth"): axes.x, server.name_to_tag("wght"): axes.y}
	variation.opentype_features = {server.name_to_tag("tnum"): 1}
	return variation


static func _panels(theme: Theme) -> void:
	theme.set_stylebox(&"panel", &"PanelContainer", box(UiTokens.GRAPHITE, UiTokens.RULE, 2))
	theme.set_stylebox(&"panel", &"Panel", box(UiTokens.GRAPHITE, UiTokens.RULE, 2))
	var panels: Dictionary = {
		&"PanelDeep": box(UiTokens.BLACK, UiTokens.RULE, 2),
		&"PanelInset": box(UiTokens.BLACK, UiTokens.RULE, 1),
		&"PanelLight": box(UiTokens.BONE, Color(0, 0, 0, 0), 2),
		&"PanelBright": box(UiTokens.OFF_WHITE, Color(0, 0, 0, 0), 2),
		&"PanelAccent": box(UiTokens.GREEN, Color(0, 0, 0, 0), 2),
		&"PanelHatch": hatch(UiTokens.BLACK, UiTokens.RULE, UiTokens.RULE, 1),
		&"PanelClear": StyleBoxEmpty.new(),
		# A module: no padding of its own; its header strip and body carry the look.
		&"ModuleFrame": StyleBoxEmpty.new(),
		&"ModuleBody": box(UiTokens.GRAPHITE, UiTokens.RULE, 2),
		&"ModuleHeader": _header(UiTokens.BONE),
		&"ModuleHeaderAccent": _header(UiTokens.GREEN),
		&"Tag": box(UiTokens.BLACK, UiTokens.RULE, 0.5),
		&"TagLight": box(UiTokens.BONE, Color(0, 0, 0, 0), 0.5),
		&"TagAccent": box(UiTokens.GREEN, Color(0, 0, 0, 0), 0.5),
	}
	for variation: StringName in panels:
		theme.set_type_variation(variation, &"PanelContainer")
		theme.set_stylebox(&"panel", variation, panels[variation])
	# HUD bands: deep black with a rule on the edge that faces the map.
	for side: int in [SIDE_TOP, SIDE_BOTTOM, SIDE_LEFT, SIDE_RIGHT]:
		var band := box(UiTokens.BLACK, Color(0, 0, 0, 0), 0)
		var inner: int = [SIDE_RIGHT, SIDE_BOTTOM, SIDE_LEFT, SIDE_TOP][side] # The opposite side.
		band.set_border_width(inner, UiTokens.BORDER)
		band.border_color = UiTokens.RULE
		var variation := StringName("HudBand" + ["Left", "Top", "Right", "Bottom"][side])
		theme.set_type_variation(variation, &"PanelContainer")
		theme.set_stylebox(&"panel", variation, band)


static func _header(fill: Color) -> StyleBoxFlat:
	var style := box(fill)
	style.content_margin_left = UiTokens.UNIT
	style.content_margin_right = UiTokens.UNIT
	style.content_margin_top = UiTokens.UNIT * 0.25
	style.content_margin_bottom = 0
	return style


static func _labels(theme: Theme) -> void:
	theme.set_color(&"font_color", &"Label", UiTokens.OFF_WHITE)
	theme.set_color(&"font_shadow_color", &"Label", Color(0, 0, 0, 0))
	theme.set_font_size(&"font_size", &"Label", UiTokens.TEXT_BODY)
	theme.set_font(&"font", &"Label", face(UiTokens.FACE_TEXT))
	# Name, face, colour, size.
	for entry: Array in [
			[&"LabelDark", UiTokens.FACE_TEXT, UiTokens.BLACK, UiTokens.TEXT_BODY],
			[&"LabelCaption", UiTokens.FACE_CONDENSED, UiTokens.CONCRETE, UiTokens.TEXT_SMALL],
			[&"LabelCaptionLight", UiTokens.FACE_CONDENSED, UiTokens.OFF_WHITE, UiTokens.TEXT_SMALL],
			[&"LabelCaptionDark", UiTokens.FACE_CONDENSED, UiTokens.BLACK, UiTokens.TEXT_SMALL],
			[&"LabelMuted", UiTokens.FACE_CONDENSED, UiTokens.CONCRETE, UiTokens.TEXT_SMALL],
			[&"LabelNumber", UiTokens.FACE_NUMBERS, UiTokens.OFF_WHITE, UiTokens.TEXT_BODY],
			[&"LabelNumberDark", UiTokens.FACE_NUMBERS, UiTokens.BLACK, UiTokens.TEXT_BODY],
			[&"LabelWarning", UiTokens.FACE_NUMBERS, UiTokens.ORANGE, UiTokens.TEXT_BODY],
			[&"LabelHeading", UiTokens.FACE_WIDE, UiTokens.OFF_WHITE, UiTokens.TEXT_HEADING],
			[&"LabelHeadingDark", UiTokens.FACE_WIDE, UiTokens.BLACK, UiTokens.TEXT_HEADING],
			[&"LabelTitle", UiTokens.FACE_WIDE, UiTokens.OFF_WHITE, UiTokens.TEXT_TITLE],
			[&"LabelDisplay", UiTokens.FACE_DISPLAY, UiTokens.OFF_WHITE, UiTokens.TEXT_DISPLAY]]:
		theme.set_type_variation(entry[0], &"Label")
		theme.set_font(&"font", entry[0], face(entry[1]))
		theme.set_color(&"font_color", entry[0], entry[2])
		theme.set_font_size(&"font_size", entry[0], entry[3])


## Button states are distinct flat colour pairs, never opacity. Default: graphite/off-white, hover bone/black, pressed
## or toggled acid green/black, disabled hatched/concrete. Command cells: bone/black, hover acid green/black, pressed
## black/acid green, disabled hatched.
static func _buttons(theme: Theme) -> void:
	var condensed: Font = face(UiTokens.FACE_CONDENSED)
	for type_name: StringName in [&"Button", &"CheckButton", &"CheckBox", &"OptionButton", &"MenuButton"]:
		_button_states(theme, type_name, [UiTokens.GRAPHITE, UiTokens.OFF_WHITE, UiTokens.RULE],
				[UiTokens.BONE, UiTokens.BLACK], [UiTokens.GREEN, UiTokens.BLACK], 1)
		theme.set_font(&"font", type_name, condensed)
	theme.set_type_variation(&"CommandCell", &"Button")
	_button_states(theme, &"CommandCell", [UiTokens.BONE, UiTokens.BLACK, Color(0, 0, 0, 0)],
			[UiTokens.GREEN, UiTokens.BLACK], [UiTokens.BLACK, UiTokens.GREEN], 0.5)
	theme.set_stylebox(&"pressed", &"CommandCell", box(UiTokens.BLACK, UiTokens.GREEN, 0.5))
	theme.set_font_size(&"font_size", &"CommandCell", UiTokens.TEXT_HEADING)
	theme.set_font(&"font", &"CommandCell", condensed)


## `normal` is [fill, text, border]; `hover` and `pressed` are [fill, text].
static func _button_states(theme: Theme, type_name: StringName, normal: Array, hover: Array, pressed: Array, margin_units: float) -> void:
	theme.set_stylebox(&"normal", type_name, box(normal[0], normal[2], margin_units))
	theme.set_stylebox(&"hover", type_name, box(hover[0], Color(0, 0, 0, 0), margin_units))
	theme.set_stylebox(&"pressed", type_name, box(pressed[0], Color(0, 0, 0, 0), margin_units))
	theme.set_stylebox(&"hover_pressed", type_name, box(pressed[0], Color(0, 0, 0, 0), margin_units))
	theme.set_stylebox(&"disabled", type_name, hatch(UiTokens.BLACK, UiTokens.RULE, UiTokens.RULE, margin_units))
	var focus := box(Color(0, 0, 0, 0), UiTokens.GREEN, margin_units)
	focus.draw_center = false
	theme.set_stylebox(&"focus", type_name, focus)
	theme.set_color(&"font_color", type_name, normal[1])
	theme.set_color(&"font_focus_color", type_name, normal[1])
	theme.set_color(&"font_hover_color", type_name, hover[1])
	theme.set_color(&"font_pressed_color", type_name, pressed[1])
	theme.set_color(&"font_hover_pressed_color", type_name, pressed[1])
	theme.set_color(&"font_disabled_color", type_name, UiTokens.CONCRETE)
	theme.set_font_size(&"font_size", type_name, UiTokens.TEXT_BODY)


static func _bars(theme: Theme) -> void:
	theme.set_stylebox(&"background", &"ProgressBar", box(UiTokens.BLACK, UiTokens.RULE, 0))
	theme.set_stylebox(&"fill", &"ProgressBar", box(UiTokens.CYAN, Color(0, 0, 0, 0), 0))
	theme.set_color(&"font_color", &"ProgressBar", UiTokens.OFF_WHITE)
	theme.set_font(&"font", &"ProgressBar", face(UiTokens.FACE_NUMBERS))
	# Sliders: a thin rule rail, an acid-green filled part, a square grabber.
	var rail := box(UiTokens.RULE, Color(0, 0, 0, 0), 0)
	rail.content_margin_top = UiTokens.UNIT * 0.5
	rail.content_margin_bottom = UiTokens.UNIT * 0.5
	var filled := box(UiTokens.GREEN, Color(0, 0, 0, 0), 0)
	filled.content_margin_top = UiTokens.UNIT * 0.5
	filled.content_margin_bottom = UiTokens.UNIT * 0.5
	theme.set_stylebox(&"slider", &"HSlider", rail)
	theme.set_stylebox(&"grabber_area", &"HSlider", filled)
	theme.set_stylebox(&"grabber_area_highlight", &"HSlider", filled)
	theme.set_icon(&"grabber", &"HSlider", _square(UiTokens.OFF_WHITE, UiTokens.UNIT * 2))
	theme.set_icon(&"grabber_highlight", &"HSlider", _square(UiTokens.GREEN, UiTokens.UNIT * 2))
	theme.set_icon(&"grabber_disabled", &"HSlider", _square(UiTokens.CONCRETE, UiTokens.UNIT * 2))


static func _inputs(theme: Theme) -> void:
	theme.set_stylebox(&"normal", &"LineEdit", box(UiTokens.BLACK, UiTokens.RULE, 1))
	theme.set_stylebox(&"focus", &"LineEdit", box(UiTokens.BLACK, UiTokens.GREEN, 1))
	theme.set_stylebox(&"read_only", &"LineEdit", hatch(UiTokens.BLACK, UiTokens.RULE, UiTokens.RULE, 1))
	theme.set_font(&"font", &"LineEdit", face(UiTokens.FACE_NUMBERS))
	theme.set_color(&"font_color", &"LineEdit", UiTokens.OFF_WHITE)
	theme.set_color(&"caret_color", &"LineEdit", UiTokens.GREEN)
	theme.set_color(&"selection_color", &"LineEdit", UiTokens.GREEN)
	theme.set_color(&"font_selected_color", &"LineEdit", UiTokens.BLACK)
	theme.set_stylebox(&"normal", &"SpinBox", box(UiTokens.BLACK, UiTokens.RULE, 1))
	for type_name: StringName in [&"VScrollBar", &"HScrollBar"]:
		theme.set_stylebox(&"scroll", type_name, box(UiTokens.BLACK, Color(0, 0, 0, 0), 0))
		theme.set_stylebox(&"grabber", type_name, box(UiTokens.RULE, Color(0, 0, 0, 0), 0))
		theme.set_stylebox(&"grabber_highlight", type_name, box(UiTokens.BONE, Color(0, 0, 0, 0), 0))
		theme.set_stylebox(&"grabber_pressed", type_name, box(UiTokens.GREEN, Color(0, 0, 0, 0), 0))
	theme.set_font(&"font", &"TooltipLabel", face(UiTokens.FACE_TEXT))
	theme.set_color(&"font_color", &"TooltipLabel", UiTokens.BLACK)
	theme.set_stylebox(&"panel", &"TooltipPanel", box(UiTokens.BONE, Color(0, 0, 0, 0), 1))


static func _tabs(theme: Theme) -> void:
	var condensed: Font = face(UiTokens.FACE_CONDENSED)
	for type_name: StringName in [&"TabContainer", &"TabBar"]:
		theme.set_stylebox(&"tab_unselected", type_name, box(UiTokens.GRAPHITE, UiTokens.RULE, 1))
		theme.set_stylebox(&"tab_hovered", type_name, box(UiTokens.BONE, Color(0, 0, 0, 0), 1))
		theme.set_stylebox(&"tab_selected", type_name, box(UiTokens.GREEN, Color(0, 0, 0, 0), 1))
		theme.set_stylebox(&"tab_focus", type_name, box(Color(0, 0, 0, 0), UiTokens.GREEN, 1))
		theme.set_color(&"font_unselected_color", type_name, UiTokens.OFF_WHITE)
		theme.set_color(&"font_hovered_color", type_name, UiTokens.BLACK)
		theme.set_color(&"font_selected_color", type_name, UiTokens.BLACK)
		theme.set_font(&"font", type_name, condensed)
	theme.set_stylebox(&"panel", &"TabContainer", box(UiTokens.BLACK, UiTokens.RULE, 1))


static func _square(color: Color, size: int) -> ImageTexture:
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
