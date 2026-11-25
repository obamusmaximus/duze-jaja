class_name Economy
extends Node
## Each team's bank: the same flat income for everyone, credits spent on squads and handed back on a cancel. Runs on
## the fixed tick and never reads a view. Credits are whole numbers; income accrues fractionally. A playtest probe
## (event `income`, once a second, with every bank). Group `economy`.

signal playtest_event(event: StringName, data: Dictionary)
## A team's bank changed (spent, refunded or income arrived).
signal bank_changed(team: int)

@export var stats: EconomyStats

## Team to whole credits, and to the fraction of a credit not yet paid out.
var _bank: Dictionary = {}
var _fraction: Dictionary = {}
var _since_event: float = 0.0


func setup(teams: Array[int]) -> void:
	add_to_group(&"economy")
	add_to_group(&"playtest_probe")
	for team: int in teams:
		_bank[team] = stats.starting_bank
		_fraction[team] = 0.0


func _physics_process(delta: float) -> void:
	for team: int in _bank:
		var gained: float = float(_fraction[team]) + stats.income_per_second * delta
		var whole: int = int(gained)
		_fraction[team] = gained - float(whole)
		if whole > 0:
			deposit(team, whole)
	_since_event += delta
	if _since_event >= 1.0:
		_since_event = 0.0
		playtest_event.emit(&"income", {"banks": _bank.duplicate(), "per_second": stats.income_per_second})


func has_team(team: int) -> bool:
	return _bank.has(team)


func bank(team: int) -> int:
	return int(_bank.get(team, 0))


func can_afford(team: int, amount: int) -> bool:
	return bank(team) >= amount


## Takes `amount` if the team has it; false (nothing taken) if not.
func spend(team: int, amount: int) -> bool:
	if not can_afford(team, amount):
		return false
	_bank[team] = bank(team) - amount
	bank_changed.emit(team)
	return true


## Adds credits, up to the bank cap.
func deposit(team: int, amount: int) -> void:
	if not _bank.has(team):
		return
	var total: int = bank(team) + amount
	if stats.bank_cap > 0:
		total = mini(total, stats.bank_cap)
	_bank[team] = total
	bank_changed.emit(team)
