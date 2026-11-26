extends CanvasLayer
## Autoload `KeybindPage`: `show_keybinds` (Tab) opens a reference page over any level, the game controls in the left
## column and the debug and map-design tools in the right one. A view only: it does not pause and sends nothing. The
## keys are read from the Input Map, so a rebind shows here; only the labels are written below. Tab again closes it.

## Left column: a heading and rows of (label, the actions or fixed text whose keys are shown).
const GAME_ROWS: Array = [
	["Pan the camera", [&"camera_pan_forward", &"camera_pan_back", &"camera_pan_left", &"camera_pan_right"]],
	["Drag pan", [&"camera_drag"]],
	["Rotate", [&"camera_rotate", &"camera_rotate_left", &"camera_rotate_right"]],
	["Zoom", [&"camera_zoom_in", &"camera_zoom_out"]],
	["Reset the camera", [&"camera_reset"]],
	["Select (drag for a box)", [&"select"]],
	["Add to the selection", [&"select_add"]],
	["Order: move, attack, ...", [&"order_click"]],
	["Attack-move", [&"order_attack_move"]],
	["Stop", [&"order_stop"]],
	["Flyers: land at the nearest airfield (in the cockpit: autopilot on / off)", [&"order_seek_airfield"]],
	["Unit ability (main type; also in the cockpit)", [&"unit_ability"]],
	["Next main type in the selection", [&"cycle_main_type"]],
	["Queue orders (hold)", [&"order_queue"]],
	["Control group: recall", ["1 - 6"]],
	["Control group: set", [&"control_group_set", "+ 1 - 6"]],
	["Bird's-eye view", [&"toggle_strategy_view"]],
	["Pilot a selected flyer or commando / leave it", [&"inhabit"]],
	["Pilot: aim", ["MOUSE"]],
	["Pilot, jet: air brake (hold)", [&"air_brake"]],
	["Pilot, jet: pitch up / down (hold)", [&"pilot_pitch_up", &"pilot_pitch_down"]],
	["Pilot, jet: roll left / right (hold)", [&"pilot_roll_left", &"pilot_roll_right"]],
	["Pilot, hover: fly forward / back (hold)", [&"pilot_pitch_up", &"pilot_pitch_down"]],
	["Pilot, hover: strafe left / right (hold)", [&"pilot_roll_left", &"pilot_roll_right"]],
	["Pilot, hover: up / down (hold)", [&"pilot_up", &"pilot_down"]],
	["Commando: jet (tap: hover, hold + move: surge)", [&"pilot_jet"]],
	["Commando: walk / jump", [&"pilot_pitch_up", &"pilot_up"]],
	["Pilot: free look (hold)", [&"free_look"]],
	["Pilot: fire (hold)", [&"pilot_fire"]],
	["Pilot: lock the target at the crosshair", [&"pilot_lock"]],
	["Pause menu", [&"pause"]],
	["This page", [&"show_keybinds"]],
]
## Right column.
const DEBUG_ROWS: Array = [
	["Slower / faster / normal time", [&"debug_time_slower", &"debug_time_faster", &"debug_time_reset"]],
	["Save a playtest log", [&"save_playtest_log"]],
	["Show the map grid and paths", [&"debug_show_map_grid"]],
	["Heightmap: re-import the PNG", [&"debug_heightmap_reload"]],
	["Heightmap: save to the PNG", [&"debug_heightmap_save"]],
	["Krita reference layer: write PNG", [&"debug_reference_layer"]],
	["Terrain brush on / off", [&"debug_brush_toggle"]],
	["Brush mode", [&"debug_brush_mode"]],
	["Brush radius", [&"debug_brush_smaller", &"debug_brush_larger"]],
	["Height bands and contours", [&"debug_height_bands"]],
	["Day / night light", [&"debug_day_night"]],
	["Vision: contacts, sensors and sight lines", [&"debug_show_vision"]],
]

var _root := Control.new()


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(UiTokens.BLACK, 0.7)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelDeep"
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTokens.px(4))
	panel.add_child(margin)
	var page := VBoxContainer.new()
	margin.add_child(page)
	var title := Label.new()
	title.theme_type_variation = &"LabelTitle"
	title.text = "CONTROLS"
	page.add_child(title)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", UiTokens.px(8))
	page.add_child(columns)
	columns.add_child(_column("GAME", GAME_ROWS))
	columns.add_child(_column("DEBUG AND MAP DESIGN", DEBUG_ROWS))
	var hint := Label.new()
	hint.theme_type_variation = &"LabelMuted"
	hint.text = "TAB TO CLOSE"
	page.add_child(hint)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"show_keybinds"):
		_root.visible = not _root.visible
		get_viewport().set_input_as_handled()


func _column(heading: String, rows: Array) -> VBoxContainer:
	var column := VBoxContainer.new()
	var head := Label.new()
	head.theme_type_variation = &"LabelHeading"
	head.text = heading
	column.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", UiTokens.px(3))
	column.add_child(grid)
	for row: Array in rows:
		var name_label := Label.new()
		name_label.theme_type_variation = &"LabelCaption"
		name_label.text = (row[0] as String).to_upper()
		grid.add_child(name_label)
		var keys := Label.new()
		keys.theme_type_variation = &"LabelNumber"
		keys.text = _keys_text(row[1])
		grid.add_child(keys)
	return column


## The keys of `parts`: an action name gives its bindings, a string is shown as it is.
static func _keys_text(parts: Array) -> String:
	var words: PackedStringArray = []
	for part: Variant in parts:
		if part is String:
			words.append(part)
			continue
		var names: PackedStringArray = []
		for event: InputEvent in InputMap.action_get_events(part):
			names.append(event.as_text().replace(" - Physical", "").to_upper())
		words.append(" / ".join(names))
	return "  ".join(words)
