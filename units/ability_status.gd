class_name AbilityStatus
extends RefCounted
## View side: what a HUD shows about the ability of some units of one type (the selection's main type, or the flown
## unit): whether any can use it, how long until it can or until it ends, and charges. A reading of the moment; it
## changes nothing.

enum State { READY, ACTIVE, COOLING, BUSY }

var stats: AbilityStats
var state: State = State.COOLING
## Units counted (alive, with the ability) and how many of them can use it now.
var total: int = 0
var ready: int = 0
## The most charges any one of them holds.
var charges: int = 0
## Seconds left: of the running effect (`ACTIVE`, the longest) or until the first charge is back (`COOLING`).
var seconds: float = 0.0
## Seconds until the soonest next charge of a unit that is refilling; 0 if none is.
var next_charge: float = 0.0
## How full the bar is: whole when ready, running down while active, filling while it cools.
var fraction: float = 0.0


## Null when no living unit among `units` has an ability.
static func of(units: Array[Unit]) -> AbilityStatus:
	var status := AbilityStatus.new()
	var active_for: float = 0.0
	var cooling_for: float = INF
	var busy: bool = false
	for unit: Unit in units:
		if not is_instance_valid(unit) or not unit.alive or unit.ability == null:
			continue
		var ability: UnitAbility = unit.ability
		status.stats = ability.stats
		status.total += 1
		status.charges = maxi(status.charges, ability.charges)
		if ability.cooldown_left > 0.0 and not ability.is_active():
			status.next_charge = ability.cooldown_left if status.next_charge <= 0.0 \
					else minf(status.next_charge, ability.cooldown_left)
		if ability.is_ready():
			status.ready += 1
		elif ability.is_active():
			active_for = maxf(active_for, ability.active_left)
		elif ability.charges > 0:
			busy = true
		else:
			cooling_for = minf(cooling_for, ability.cooldown_left)
	if status.total == 0:
		return null
	if status.ready > 0:
		status.state = State.READY
		status.fraction = 1.0
	elif active_for > 0.0:
		status.state = State.ACTIVE
		status.seconds = active_for
		status.fraction = active_for / maxf(status.stats.duration, active_for)
	elif busy:
		status.state = State.BUSY
	else:
		status.state = State.COOLING
		status.seconds = cooling_for if cooling_for < INF else 0.0
		status.fraction = 1.0 - status.seconds / maxf(status.stats.cooldown, maxf(status.seconds, 0.001))
	return status


## The state in a few words, upper case, with the charges when the type holds more than one.
func text() -> String:
	var words: String
	match state:
		State.READY:
			words = "READY" if total == 1 else "%d/%d READY" % [ready, total]
		State.ACTIVE:
			words = "ACTIVE %.1f S" % seconds
		State.BUSY:
			words = "BUSY"
		_:
			words = "COOLDOWN %d S" % ceili(seconds)
	if stats.charges > 1:
		words += "  ·  %d/%d CHARGES" % [charges, stats.charges]
		if state == State.READY and next_charge > 0.0:
			words += "  ·  +1 IN %d S" % ceili(next_charge)
	return words
