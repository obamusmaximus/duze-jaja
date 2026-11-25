class_name HudFrame
extends Control
## Lays a `HudLayout` out on the screen: a top row and a bottom row of three sections each, a left and a right
## column, and the centre between them; which pair runs the full length is `HudLayout.sides_first`. A framed edge gets a band (`HudBand*` theme variation) that
## blocks clicks; unframed parts ignore the mouse so clicks reach the map, and only modules take them. Empty
## unframed parts are hidden so they take no room.

const SECTION := HudPlacement.Section

var _layout: HudLayout
var _context: HudContext
## Section to the box its modules go in.
var _sections: Dictionary = {}
## Band (`HudLayout.BAND_*`) to its panel and margin.
var _bands: Dictionary = {}
var _modules: Array[HudModule] = []
## One glitch trace per module, in layout order (`HudSwap` runs them).
var reveals: Array[HudReveal] = []


func build(layout: HudLayout, context: HudContext) -> void:
	_layout = layout
	_context = context
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top: Control = _edge_row(HudLayout.BAND_TOP, [SECTION.TOP_LEFT, SECTION.TOP, SECTION.TOP_RIGHT], Control.SIZE_SHRINK_BEGIN)
	var bottom: Control = _edge_row(HudLayout.BAND_BOTTOM, [SECTION.BOTTOM_LEFT, SECTION.BOTTOM, SECTION.BOTTOM_RIGHT], Control.SIZE_SHRINK_END)
	var left: Control = _edge_column(HudLayout.BAND_LEFT, SECTION.LEFT)
	var right: Control = _edge_column(HudLayout.BAND_RIGHT, SECTION.RIGHT)
	var centre := _box(true)
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	_sections[SECTION.CENTER] = centre
	# Rows first: [top, [left, centre, right], bottom]. Sides first: [left, [top, centre, bottom], right].
	var outer := _box(not layout.sides_first)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override(&"separation", 0)
	var inner := _box(layout.sides_first)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override(&"separation", 0)
	var first: Array = [left, right] if layout.sides_first else [top, bottom]
	var second: Array = [top, bottom] if layout.sides_first else [left, right]
	inner.add_child(second[0])
	inner.add_child(centre)
	inner.add_child(second[1])
	outer.add_child(first[0])
	outer.add_child(inner)
	outer.add_child(first[1])
	add_child(outer)
	for section: int in _sections:
		for placement: HudPlacement in layout.in_section(section):
			_add_module(placement, section)
	context.stats.changed.connect(_apply)
	_apply()


## The screen-space rectangles the framed bands cover, so views can keep clear of them.
func band_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for band: int in _bands:
		var panel: PanelContainer = _bands[band][0]
		if _layout.has_band(band) and panel.is_visible_in_tree():
			rects.append(panel.get_global_rect())
	return rects


func _edge_row(band: int, sections: Array, vertical: int) -> Control:
	var row := _box(false)
	for i: int in sections.size():
		var section := _box(false)
		# The middle section takes the room between the corners.
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL if i == 1 else Control.SIZE_FILL
		section.size_flags_vertical = Control.SIZE_FILL if _layout.has_band(band) else vertical
		section.alignment = [BoxContainer.ALIGNMENT_BEGIN, BoxContainer.ALIGNMENT_CENTER, BoxContainer.ALIGNMENT_END][i]
		_sections[sections[i]] = section
		row.add_child(section)
	return _band(band, row, "Top" if band == HudLayout.BAND_TOP else "Bottom")


func _edge_column(band: int, section_id: int) -> Control:
	var column := _box(true)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sections[section_id] = column
	var panel: PanelContainer = _band(band, column, "Left" if band == HudLayout.BAND_LEFT else "Right")
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return panel


## Wraps an edge's sections in a band panel and a margin.
func _band(band: int, inner: Control, side: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var framed: bool = _layout.has_band(band)
	panel.theme_type_variation = StringName("HudBand" + side) if framed else &"PanelClear"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP if framed else Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner)
	panel.add_child(margin)
	_bands[band] = [panel, margin, inner]
	return panel


func _box(vertical: bool) -> BoxContainer:
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


func _add_module(placement: HudPlacement, section: int) -> void:
	var module := placement.module.instantiate() as HudModule
	if module == null:
		push_error("HUD module %s has no HudModule root" % placement.module.resource_path)
		return
	var box: BoxContainer = _sections[section]
	if box is HBoxContainer:
		module.size_flags_vertical = box.size_flags_vertical
		if placement.expand:
			module.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		module.size_flags_horizontal = Control.SIZE_FILL if section != SECTION.CENTER else Control.SIZE_SHRINK_CENTER
		if placement.expand:
			module.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(module)
	module.bind(_context)
	_modules.append(module)
	var reveal := HudReveal.new(module, _side_of(section))
	reveal.apply_stats(_context.stats)
	reveals.append(reveal)


## The screen edge a section's modules trace in from: corners and sides from their side, the middle row from its edge.
static func _side_of(section: int) -> Side:
	match section:
		SECTION.TOP_LEFT, SECTION.LEFT, SECTION.BOTTOM_LEFT:
			return SIDE_LEFT
		SECTION.TOP:
			return SIDE_TOP
		SECTION.TOP_RIGHT, SECTION.RIGHT, SECTION.BOTTOM_RIGHT:
			return SIDE_RIGHT
	return SIDE_BOTTOM


func _apply() -> void:
	for reveal: HudReveal in reveals:
		reveal.apply_stats(_context.stats)
	var gap: int = UiTokens.px(_context.stats.gap_units)
	for box: BoxContainer in _sections.values():
		box.add_theme_constant_override(&"separation", gap)
	for band: int in _bands:
		var panel: PanelContainer = _bands[band][0]
		var margin: MarginContainer = _bands[band][1]
		var inner: BoxContainer = _bands[band][2]
		inner.add_theme_constant_override(&"separation", gap)
		for side: String in ["left", "top", "right", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, gap)
		var framed: bool = _layout.has_band(band)
		var thickness: int = UiTokens.px(_context.stats.band_units) if framed else 0
		if band == HudLayout.BAND_TOP or band == HudLayout.BAND_BOTTOM:
			panel.custom_minimum_size.y = thickness
		else:
			panel.custom_minimum_size.x = thickness
		panel.visible = framed or _has_modules(inner)


func _has_modules(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is HudModule or _has_modules(child):
			return true
	return false
