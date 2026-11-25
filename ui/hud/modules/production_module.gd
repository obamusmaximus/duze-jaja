class_name ProductionModule
extends HudModule
## HUD module: the squad builder and the production lines (the bank is `ResourceModule`'s). The presets (one click queues one),
## a custom builder (pick unit types within the hold's slots, then build), a row per production line with its
## progress and a cancel button, and the squads waiting aboard. A view: it reads `Economy`, `Production` and
## `SquadRegistry` (found by group) and changes the game only by sending `produce` and `cancel` orders through
## `CommandIssuer`. Without an economy in the level it shows a note and nothing else.

var _economy: Economy
var _production: Production
var _squads: SquadRegistry
var _issuer: CommandIssuer
var _draft: SquadSpec = SquadSpec.new()
var _draft_label := label("", &"LabelCaption")
var _build_button := Button.new()
var _type_buttons: Dictionary = {}
var _lines_box := VBoxContainer.new()
var _aboard_label := label("", &"LabelCaption")
## The tickets shown in the lines box; a different list rebuilds the rows.
var _shown: Array[int] = []
var _bars: Dictionary = {}
var _since_refresh: float = INF


func _title() -> String:
	return "PRODUCTION"


func _build() -> void:
	_economy = get_tree().get_first_node_in_group(&"economy") as Economy
	_production = get_tree().get_first_node_in_group(&"production") as Production
	_squads = get_tree().get_first_node_in_group(&"squads") as SquadRegistry
	_issuer = get_tree().get_first_node_in_group(&"command_issuer") as CommandIssuer
	if _economy == null or _production == null or _issuer == null:
		set_note("NO ECONOMY")
		return
	_shown = [-1]  # never equal to a real list, so the idle line rows are built on the first refresh
	content.add_child(label("PRESETS", &"LabelMuted"))
	var presets := HFlowContainer.new()
	for preset: SquadStats in SquadPresets.ALL:
		var button := Button.new()
		button.text = "%s  %d" % [preset.display_name.to_upper(), preset.to_spec().cost()]
		button.pressed.connect(_queue.bind(preset.to_spec()))
		presets.add_child(button)
	content.add_child(presets)
	content.add_child(label("CUSTOM", &"LabelMuted"))
	var types := HFlowContainer.new()
	for type: UnitStats in UnitCatalog.TYPES:
		var button := Button.new()
		button.text = "+ %s" % type.display_name.to_upper()
		button.pressed.connect(_add_to_draft.bind(type))
		types.add_child(button)
		_type_buttons[type] = button
	content.add_child(types)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
	_build_button.text = "BUILD"
	_build_button.pressed.connect(_build_draft)
	var clear := Button.new()
	clear.text = "CLEAR"
	clear.pressed.connect(_clear_draft)
	actions.add_child(_build_button)
	actions.add_child(clear)
	_draft_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_draft_label)
	content.add_child(actions)
	content.add_child(label("LINES", &"LabelMuted"))
	content.add_child(_lines_box)
	content.add_child(_aboard_label)
	_production.changed.connect(_on_changed)
	_refresh_draft()
	_refresh()


func _apply() -> void:
	custom_minimum_size.x = UiTokens.px(context.stats.strategy_panel_units)


func _process(delta: float) -> void:
	if _economy == null:
		return
	_since_refresh += delta
	if _since_refresh >= 1.0 / context.stats.readout_rate:
		_since_refresh = 0.0
		_refresh()


func _on_changed(team: int) -> void:
	if team == context.team:
		_since_refresh = INF


func _queue(spec: SquadSpec) -> void:
	_issuer.issue(Order.produce(context.team, spec))
	_since_refresh = INF


func _cancel(ticket: int) -> void:
	_issuer.issue(Order.cancel(context.team, ticket))
	_since_refresh = INF


func _add_to_draft(type: UnitStats) -> void:
	_draft.type_ids.append(UnitCatalog.id_of(type))
	_refresh_draft()


func _clear_draft() -> void:
	_draft.type_ids = PackedStringArray()
	_refresh_draft()


func _build_draft() -> void:
	var spec := SquadSpec.new()
	spec.display_name = "Custom"
	spec.job = SquadSpec.Job.ASSAULT
	spec.type_ids = _draft.type_ids.duplicate()
	_queue(spec)
	_clear_draft()


## The draft's text, and which types still fit the hold (a type that doesn't is disabled).
func _refresh_draft() -> void:
	_draft_label.text = ("EMPTY" if _draft.type_ids.is_empty() else "%s  %d CR" % [_draft_text(), _draft.cost()]).to_upper()
	_build_button.disabled = _draft.type_ids.is_empty()
	var probe := SquadSpec.new()
	for type: UnitStats in _type_buttons:
		probe.type_ids = _draft.type_ids.duplicate()
		probe.type_ids.append(UnitCatalog.id_of(type))
		(_type_buttons[type] as Button).disabled = probe.validate(_economy.stats) != ""


func _draft_text() -> String:
	var counts: Dictionary = {}
	for type: UnitStats in _draft.types():
		counts[type.display_name] = int(counts.get(type.display_name, 0)) + 1
	var parts: PackedStringArray = []
	for type_name: String in counts:
		parts.append("%d %s" % [counts[type_name], type_name])
	return ", ".join(parts)


func _refresh() -> void:
	var team: int = context.team
	_build_button.text = "BUILD %d" % _draft.cost() if not _draft.type_ids.is_empty() else "BUILD"
	var tickets: Array[int] = []
	for line: ProductionLine in _production.lines_of(team):
		for job: ProductionLine.Job in line.jobs:
			tickets.append(job.ticket)
	if tickets != _shown:
		_shown = tickets
		_rebuild_lines(team)
	for line: ProductionLine in _production.lines_of(team):
		if not line.jobs.is_empty():
			var bar: StatBar = _bars.get(line.jobs[0].ticket)
			if bar != null:
				bar.fraction = line.jobs[0].progress()
	var aboard: PackedStringArray = []
	for squad: SquadRecord in _squads.aboard_of(team):
		aboard.append(squad.display_name)
	_aboard_label.text = ("ABOARD: " + ", ".join(aboard) if not aboard.is_empty() else "NOTHING ABOARD").to_upper()


func _rebuild_lines(team: int) -> void:
	for child: Node in _lines_box.get_children():
		child.queue_free()
	_bars.clear()
	for line: ProductionLine in _production.lines_of(team):
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
		var caption := label("L%d" % (line.index + 1), &"LabelCaption")
		caption.custom_minimum_size.x = UiTokens.px(5)
		row.add_child(caption)
		if line.jobs.is_empty():
			row.add_child(label("IDLE", &"LabelMuted"))
		else:
			var job: ProductionLine.Job = line.jobs[0]
			var column := VBoxContainer.new()
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.add_child(label(job.spec.display_name.to_upper() + ("  +%d" % (line.length() - 1) if line.length() > 1 else ""), &"LabelCaption"))
			var bar := StatBar.new()
			bar.warn_when_low = false
			bar.fill_color = UiTokens.team_color(team)
			bar.fraction = job.progress()
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.add_child(bar)
			_bars[job.ticket] = bar
			row.add_child(column)
			var cancel := Button.new()
			cancel.text = "X"
			cancel.pressed.connect(_cancel.bind(job.ticket))
			row.add_child(cancel)
		_lines_box.add_child(row)
