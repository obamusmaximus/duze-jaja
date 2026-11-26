class_name ExplorerModule
extends HudModule
## HUD module: the mothership's Explorer pad. Builds an Explorer (with its progress and a cancel button) and fills the
## hold of the one being built or sitting on the pad, a row per loadable type. A view: it reads `ExplorerYard` and
## `Economy` (found by group) and changes the game only by sending orders through `CommandIssuer`.

var _economy: Economy
var _yard: ExplorerYard
var _issuer: CommandIssuer
var _build_button := Button.new()
var _status := label("", &"LabelCaption")
var _progress_row := HBoxContainer.new()
var _progress := StatBar.new()
var _hold_label := label("", &"LabelCaption")
var _hold_bar := StatBar.new()
## Type to `{count: Label, add: Button, remove: Button}`.
var _rows: Dictionary = {}
var _since_refresh: float = INF


func _title() -> String:
	return "EXPLORER"


func _build() -> void:
	_economy = get_tree().get_first_node_in_group(&"economy") as Economy
	_yard = get_tree().get_first_node_in_group(&"explorer_yard") as ExplorerYard
	_issuer = get_tree().get_first_node_in_group(&"command_issuer") as CommandIssuer
	if _economy == null or _yard == null or _issuer == null:
		set_note("NO PAD")
		return
	_build_button.pressed.connect(func() -> void: _send(Order.build_explorer(context.team)))
	content.add_child(_build_button)
	content.add_child(_status)
	_progress.warn_when_low = false
	_progress.fill_color = UiTokens.team_color(context.team)
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress_row.add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
	_progress_row.add_child(_progress)
	var cancel := Button.new()
	cancel.text = "X"
	cancel.pressed.connect(func() -> void: _send(Order.cancel_explorer(context.team)))
	_progress_row.add_child(cancel)
	content.add_child(_progress_row)
	content.add_child(label("HOLD", &"LabelMuted"))
	content.add_child(_hold_label)
	_hold_bar.warn_when_low = false
	_hold_bar.fill_color = UiTokens.team_color(context.team)
	content.add_child(_hold_bar)
	for type: UnitStats in ExplorerYard.LOADABLE:
		_add_row(type)
	_yard.changed.connect(_on_changed)
	_refresh()


func _apply() -> void:
	custom_minimum_size.x = UiTokens.px(context.stats.strategy_panel_units)


func _process(delta: float) -> void:
	if _yard == null:
		return
	_since_refresh += delta
	if _since_refresh >= 1.0 / context.stats.readout_rate:
		_since_refresh = 0.0
		_refresh()


func _on_changed(team: int) -> void:
	if team == context.team:
		_since_refresh = INF


## One loadable type: name and price, how many are aboard, take one off, put one in.
func _add_row(type: UnitStats) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.UNIT)
	var caption := label("%s  %d" % [type.display_name.to_upper(), type.cost], &"LabelCaption")
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.clip_text = true
	row.add_child(caption)
	var count := label("0", &"LabelCaption")
	count.custom_minimum_size.x = UiTokens.px(4)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(count)
	var id: StringName = UnitCatalog.id_of(type)
	var remove := _small_button("-", func() -> void: _send(Order.load_explorer(context.team, id, -1)))
	var add := _small_button("+", func() -> void: _send(Order.load_explorer(context.team, id, 1)))
	row.add_child(remove)
	row.add_child(add)
	content.add_child(row)
	_rows[type] = {count = count, add = add, remove = remove}


func _small_button(text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.x = UiTokens.px(5)
	button.pressed.connect(on_press)
	return button


func _send(order: Order) -> void:
	_issuer.issue(order)
	_since_refresh = INF


func _refresh() -> void:
	var team: int = context.team
	var building: bool = _yard.is_building(team)
	var ready_unit: Unit = _yard.docked(team)
	var bank: int = _economy.bank(team)
	var cost: int = ExplorerYard.explorer_type().cost
	_build_button.text = "BUILD EXPLORER  %d" % cost
	_build_button.disabled = not _yard.pad_free(team) or bank < cost
	_progress_row.visible = building
	_progress.fraction = _yard.progress(team)
	if building:
		_status.text = "BUILDING"
	elif ready_unit != null:
		_status.text = "READY ON THE PAD"
	elif _yard.pad_free(team):
		_status.text = "PAD FREE"
	else:
		_status.text = "PAD CLEARING"
	var cargo: Cargo = _yard.hold(team)
	var capacity: float = ExplorerYard.explorer_type().cargo.volume
	var used: float = cargo.used() if cargo != null else 0.0
	_hold_label.text = "%s / %s" % [String.num(used, 1).trim_suffix(".0"), String.num(capacity, 1).trim_suffix(".0")] \
			if cargo != null else "NO EXPLORER ON THE PAD"
	_hold_bar.fraction = used / maxf(capacity, 0.001)
	var counts: Dictionary = {}
	if cargo != null:
		for row: Dictionary in cargo.type_counts():
			counts[row.type] = row.count
	for type: UnitStats in _rows:
		var widgets: Dictionary = _rows[type]
		(widgets.count as Label).text = str(counts.get(type, 0))
		(widgets.add as Button).disabled = cargo == null or not cargo.can_load(type) or bank < type.cost
		(widgets.remove as Button).disabled = int(counts.get(type, 0)) == 0
