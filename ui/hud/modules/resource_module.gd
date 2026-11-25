class_name ResourceModule
extends HudModule
## HUD module: the local team's credits, top of the strategy HUD. An acid-green "CR" tag beside big display figures
## that roll toward the bank (a spend or refund counts down or up instead of jumping), the income per second under
## them, and the bank's fill when it has a cap. A view: it reads `Economy` (found by group) and changes nothing.

## How fast the shown figure closes on the bank, per second (a fraction of the gap).
const ROLL_RATE: float = 12.0

var _economy: Economy
var _figures := label("0", &"LabelDisplay")
var _income := label("", &"LabelCaption")
var _cap_bar := StatBar.new()
var _shown: float = 0.0


func _body_style() -> StringName:
	return &"PanelDeep"


func _build() -> void:
	_economy = get_tree().get_first_node_in_group(&"economy") as Economy
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.UNIT * 2)
	var tag := PanelContainer.new()
	tag.theme_type_variation = &"TagAccent"
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_child(label("CR", &"LabelCaptionDark"))
	row.add_child(tag)
	_figures.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_figures.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_figures)
	content.add_child(row)
	_income.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(_income)
	_cap_bar.warn_when_low = false
	_cap_bar.fill_color = UiTokens.GREEN
	content.add_child(_cap_bar)
	if _economy == null:
		_income.text = "NO ECONOMY"
		_cap_bar.visible = false
		return
	_shown = _economy.bank(context.team)
	_refresh()


func _apply() -> void:
	custom_minimum_size.x = UiTokens.px(context.stats.strategy_panel_units)


func _process(delta: float) -> void:
	if _economy == null or not is_visible_in_tree():
		return
	var bank: float = _economy.bank(context.team)
	if absf(bank - _shown) >= 0.5:
		_shown = lerpf(_shown, bank, minf(1.0, ROLL_RATE * delta))
		if absf(bank - _shown) < 0.5:
			_shown = bank
		_refresh()


func _refresh() -> void:
	var stats: EconomyStats = _economy.stats
	_figures.text = str(roundi(_shown))
	_income.text = "INCOME +%s / S" % String.num(stats.income_per_second, 1)
	_cap_bar.visible = stats.bank_cap > 0
	if stats.bank_cap > 0:
		_cap_bar.fraction = _shown / float(stats.bank_cap)
		_income.text += "   CAP %d" % stats.bank_cap
