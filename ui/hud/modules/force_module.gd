class_name ForceModule
extends HudModule
## HUD module: each team on the map, one row per team: team colour block, name, living units, and a bar of the
## team's total health. The local player's team comes first. Refreshes at `UiStats.readout_rate`.

## Team to its line (swatch and row) and to its `StatRow`.
var _lines: Dictionary = {}
var _rows: Dictionary = {}
var _since_refresh: float = INF


func _title() -> String:
	return "FORCES"


func _process(delta: float) -> void:
	_since_refresh += delta
	if context != null and _since_refresh >= 1.0 / context.stats.readout_rate:
		_since_refresh = 0.0
		_refresh()


func _refresh() -> void:
	# Team to [living, health, max health].
	var teams: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group(&"units"):
		var unit := node as Unit
		if unit == null:
			continue
		var entry: Array = teams.get(unit.team, [0, 0.0, 0.0])
		if unit.alive:
			entry[0] += 1
			entry[1] += unit.health.current
		entry[2] += unit.stats.max_health
		teams[unit.team] = entry
	var order: Array = teams.keys()
	order.sort_custom(func(a: int, b: int) -> bool: return _rank(a) < _rank(b))
	for team: int in order:
		if not _lines.has(team):
			_lines[team] = _team_row(team)
			content.add_child(_lines[team])
		content.move_child(_lines[team], order.find(team))
		var entry: Array = teams[team]
		var row: StatRow = _rows[team]
		row.set_value("%d" % entry[0], entry[1] / maxf(entry[2], 1.0), UiTokens.team_color(team))
	set_note("%d TEAMS" % order.size())


## The local player's team sorts first, then the others by number.
func _rank(team: int) -> int:
	return -1 if team == context.team else team


func _team_row(team: int) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", UiTokens.UNIT)
	var swatch := ColorRect.new()
	swatch.color = UiTokens.team_color(team)
	swatch.custom_minimum_size = Vector2(UiTokens.px(1), UiTokens.px(3))
	line.add_child(swatch)
	var row := StatRow.new("YOU" if team == context.team else "TEAM %d" % (team + 1))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.x = UiTokens.px(40)
	line.add_child(row)
	_rows[team] = row
	return line
