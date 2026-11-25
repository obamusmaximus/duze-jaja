class_name CommandsModule
extends HudModule
## HUD module: the strategist's commands on the left of the strategy HUD. Map markers (attack, guard, gather,
## scout; they are placeholders for now, the game behaviour comes with the AI commander): a button arms one and the
## next ground click in the strategy view puts it down (`StrategyControl`). The carryall list from `CarryallFleet`
## (state, click selects), SET LZ (arms the landing zone marker; selected loaded carryalls deliver there) and
## EXFIL NEAREST (the nearest idle empty carryall flies to the selection; picking units up is not built yet, so it
## only hovers there). A view: it sends only orders, through `CommandIssuer`.

const MARKERS: Array[MapMarker.Kind] = [MapMarker.Kind.ATTACK, MapMarker.Kind.GUARD, MapMarker.Kind.GATHER, MapMarker.Kind.SCOUT]

var _fleet: CarryallFleet
var _issuer: CommandIssuer
var _units: UnitRegistry
var _marker_buttons: Dictionary = {}
var _list := VBoxContainer.new()
var _empty := label("NO CARRYALLS LISTED", &"LabelMuted")
var _lz_button := Button.new()
var _exfil_button := Button.new()
var _hint := label("", &"LabelMuted")
## Carryall ids and states shown in the list; a different list rebuilds the rows.
var _shown: Array = []
var _since_refresh: float = INF


func _title() -> String:
	return "COMMANDS"


func _build() -> void:
	_fleet = get_tree().get_first_node_in_group(&"carryalls") as CarryallFleet
	content.add_child(label("MARKERS", &"LabelMuted"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", UiTokens.UNIT)
	grid.add_theme_constant_override(&"v_separation", UiTokens.UNIT)
	for kind: MapMarker.Kind in MARKERS:
		grid.add_child(_tool_button(kind))
	content.add_child(grid)
	content.add_child(label("CARRYALLS", &"LabelMuted"))
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"PanelHatch"
	frame.custom_minimum_size.y = UiTokens.px(16)
	var inner := VBoxContainer.new()
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_empty)
	inner.add_child(_list)
	frame.add_child(inner)
	content.add_child(frame)
	var commands := GridContainer.new()
	commands.columns = 2
	commands.add_theme_constant_override(&"h_separation", UiTokens.UNIT)
	commands.add_child(_tool_button(MapMarker.Kind.LZ, _lz_button, "SET LZ"))
	_exfil_button.text = "EXFIL NEAREST"
	_exfil_button.focus_mode = Control.FOCUS_NONE
	_exfil_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exfil_button.pressed.connect(_exfil)
	commands.add_child(_exfil_button)
	content.add_child(commands)
	content.add_child(_hint)
	context.tools.changed.connect(_sync_tools)
	context.selection.changed.connect(_refresh)
	if _fleet != null:
		_fleet.changed.connect(func(_team: int) -> void: _since_refresh = INF)
	_refresh()


func _apply() -> void:
	custom_minimum_size.x = UiTokens.px(context.stats.command_panel_units)


func _process(delta: float) -> void:
	_since_refresh += delta
	if _since_refresh >= 1.0 / context.stats.readout_rate:
		_since_refresh = 0.0
		_refresh()


func _tool_button(kind: MapMarker.Kind, button: Button = null, text: String = "") -> Button:
	var made: Button = button if button != null else Button.new()
	made.text = text if text != "" else MapMarker.kind_label(kind)
	made.toggle_mode = true
	made.focus_mode = Control.FOCUS_NONE
	made.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	made.pressed.connect(func() -> void: context.tools.arm(kind))
	_marker_buttons[kind] = made
	return made


## The armed marker shows as pressed; the hint says what the next click does.
func _sync_tools() -> void:
	for kind: MapMarker.Kind in _marker_buttons:
		(_marker_buttons[kind] as Button).set_pressed_no_signal(context.tools.armed == kind)
	if context.tools.armed != -1:
		_hint.text = ("CLICK THE MAP TO PLACE %s · RIGHT CLICK CANCELS" % MapMarker.kind_label(context.tools.armed as MapMarker.Kind)).to_upper()
	else:
		_hint.text = ""


func _refresh() -> void:
	_sync_tools()
	var team: int = context.team
	var list: Array[Dictionary] = _fleet.snapshot(team) if _fleet != null else []
	var signature: Array = []
	for entry: Dictionary in list:
		signature.append([entry["id"], entry["state"]])
	set_note(str(list.size()))
	_empty.visible = list.is_empty()
	var chosen: PackedInt32Array = context.selection.ids()
	if signature != _shown:
		_shown = signature
		for child: Node in _list.get_children():
			child.queue_free()
		for entry: Dictionary in list:
			var row := Button.new()
			row.text = ("CARRYALL %d  %s" % [entry["id"], String(Carryall.State.keys()[entry["state"]])]).to_upper()
			row.toggle_mode = true
			row.focus_mode = Control.FOCUS_NONE
			row.alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.set_meta(&"unit_id", entry["id"])
			row.pressed.connect(_select_carryall.bind(entry["id"]))
			_list.add_child(row)
	for row: Node in _list.get_children():
		if row is Button:
			(row as Button).set_pressed_no_signal(chosen.size() == 1 and chosen[0] == int(row.get_meta(&"unit_id")))
	_exfil_button.disabled = _fleet == null or _command_issuer() == null or _exfil_group().is_empty()


## The registry and issuer join their groups after the HUD builds, so they are looked up on first use.
func _registry() -> UnitRegistry:
	if _units == null:
		_units = get_tree().get_first_node_in_group(&"unit_registry") as UnitRegistry
	return _units


func _command_issuer() -> CommandIssuer:
	if _issuer == null:
		_issuer = get_tree().get_first_node_in_group(&"command_issuer") as CommandIssuer
	return _issuer


func _select_carryall(unit_id: int) -> void:
	var registry: UnitRegistry = _registry()
	var unit: Unit = registry.get_unit(unit_id) if registry != null else null
	if unit != null:
		var one: Array[Unit] = [unit]
		context.selection.set_units(one)


## The selected units an exfil is for: not carryalls themselves.
func _exfil_group() -> Array[Unit]:
	var group: Array[Unit] = []
	for unit: Unit in context.selection.units:
		if unit.carryall == null:
			group.append(unit)
	return group


## The nearest idle empty carryall flies to the selection (pick-up itself comes later).
func _exfil() -> void:
	var group: Array[Unit] = _exfil_group()
	if group.is_empty():
		return
	var sum := Vector3.ZERO
	for unit: Unit in group:
		sum += unit.global_position
	var centre: Vector3 = sum / float(group.size())
	var carryall: Carryall = _fleet.closest_idle(context.team, centre)
	if carryall == null:
		_hint.text = "NO FREE CARRYALL"
		return
	_command_issuer().issue(Order.move(context.team, PackedInt32Array([carryall.unit.id]), centre))
	_since_refresh = INF
