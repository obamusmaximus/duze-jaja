class_name ExplorerYard
extends Node
## The Explorer pad of every team's mothership (`docs/mechanics/explorer.md`). `build` pays for an Explorer and builds
## it on the fixed tick; it appears on the pad when done and stays until an order flies it off, which frees the pad for
## the next. While it is building or sitting on the pad, units go into its hold with no build time: paid when loaded,
## refunded in full when taken off again. No limit on how many Explorers a team has. Reached only through
## `CommandIssuer`. Simulation. A playtest probe (events `explorer_build`, `explorer_ready`, `explorer_cancel`,
## `explorer_load`). Group `explorer_yard`.

signal playtest_event(event: StringName, data: Dictionary)
## A team's pad or the hold of the Explorer on it changed (for the HUD).
signal changed(team: int)

## Read from outside through `explorer_type()`: a direct read of another script's `static var` breaks the engine's cleanup at exit.
static var _explorer_type: UnitStats = preload("res://tuning/unit_explorer.tres")
## What can be loaded into an Explorer: ground units and the small flyers.
const LOADABLE: Array[UnitStats] = [
	preload("res://tuning/unit_trooper.tres"), preload("res://tuning/unit_rover.tres"),
	preload("res://tuning/unit_ifv.tres"), preload("res://tuning/unit_tank.tres"),
	preload("res://tuning/unit_vtol.tres"), preload("res://tuning/unit_fighter.tres")]

class Slot:
	extends RefCounted
	var field: Airfield
	## While one is being built: its hold so far, and seconds to go of `total`. `manifest` is null otherwise.
	var manifest: Cargo
	var left: float = 0.0
	var total: float = 0.0
	## What was paid for the hull being built.
	var cost: int = 0

var _economy: Economy
var _squads: SquadRegistry
var _units: UnitRegistry
## Team to Slot.
var _slots: Dictionary = {}


static func explorer_type() -> UnitStats:
	return _explorer_type



func setup(economy: Economy, squads: SquadRegistry, units: UnitRegistry) -> void:
	_economy = economy
	_squads = squads
	_units = units
	add_to_group(&"explorer_yard")
	add_to_group(&"playtest_probe")


## `field` is the one-pad deck on `team`'s mothership.
func add_pad(team: int, field: Airfield) -> void:
	var slot := Slot.new()
	slot.field = field
	_slots[team] = slot
	changed.emit(team)


func _physics_process(delta: float) -> void:
	for team: int in _slots:
		var slot: Slot = _slots[team]
		if slot.manifest == null:
			continue
		slot.left = maxf(slot.left - delta, 0.0)
		if slot.left <= 0.0:
			_finish(team, slot)


func has_pad(team: int) -> bool:
	return _slots.has(team)


func is_building(team: int) -> bool:
	return _slots.has(team) and (_slots[team] as Slot).manifest != null


## How far the Explorer being built is, 0 to 1.
func progress(team: int) -> float:
	if not is_building(team):
		return 0.0
	var slot: Slot = _slots[team]
	return 1.0 - slot.left / maxf(slot.total, 0.001)


## The finished Explorer sitting on the team's pad, or null.
func docked(team: int) -> Unit:
	if not _slots.has(team):
		return null
	var unit: Unit = _units.get_unit((_slots[team] as Slot).field.pads[0].holder())
	return unit if unit != null and unit.landing != null and unit.landing.is_down() else null


## Nothing is being built and nothing holds the pad (one taking off holds it until it is clear).
func pad_free(team: int) -> bool:
	return _slots.has(team) and not is_building(team) and (_slots[team] as Slot).field.pads[0].is_free()


## The hold that can be loaded now: of the Explorer being built or sitting on the pad; null if there is none.
func hold(team: int) -> Cargo:
	if is_building(team):
		return (_slots[team] as Slot).manifest
	var unit: Unit = docked(team)
	return unit.cargo if unit != null else null


## Pays for an Explorer and starts it. False if the pad is taken or the bank is short.
func build(team: int) -> bool:
	if not pad_free(team) or not _economy.spend(team, _explorer_type.cost):
		return false
	var slot: Slot = _slots[team]
	slot.manifest = Cargo.new(_explorer_type.cargo)
	slot.cost = _explorer_type.cost
	slot.total = _explorer_type.build_time * _economy.stats.build_time_scale
	slot.left = slot.total
	playtest_event.emit(&"explorer_build", {"team": team, "cost": slot.cost})
	changed.emit(team)
	return true


## Stops the build: `cancel_refund` of the hull's price comes back, and all of what the units aboard cost.
func cancel(team: int) -> bool:
	if not is_building(team):
		return false
	var slot: Slot = _slots[team]
	var refund: int = int(round(float(slot.cost) * _economy.stats.cancel_refund))
	for entry: CargoEntry in slot.manifest.entries:
		refund += entry.unit_type.cost
	slot.manifest = null
	_economy.deposit(team, refund)
	playtest_event.emit(&"explorer_cancel", {"team": team, "refund": refund})
	changed.emit(team)
	return true


## Puts `count` units of the type `id` aboard, as many of them as fit and the bank covers; a negative count takes that
## many off again for their price. False if nothing changed.
func load_units(team: int, id: StringName, count: int) -> bool:
	var cargo: Cargo = hold(team)
	var type: UnitStats = loadable(id)
	if cargo == null or type == null:
		return false
	var moved: int = 0
	if count > 0:
		for i: int in count:
			if not cargo.can_load(type) or not _economy.spend(team, type.cost):
				break
			cargo.load_entry(CargoEntry.new(0, type))
			moved += 1
	else:
		for i: int in range(cargo.entries.size() - 1, -1, -1):
			if moved >= -count:
				break
			var entry: CargoEntry = cargo.entries[i]
			if entry.unit_type != type:
				continue
			cargo.remove_entry(entry)
			_economy.deposit(team, type.cost) # The bank's cap applies, as to any refund.
			moved += 1
	if moved == 0:
		return false
	playtest_event.emit(&"explorer_load", {"team": team, "type": String(id), "count": moved * signi(count)})
	changed.emit(team)
	return true


## The loadable type with `id`, or null.
static func loadable(id: StringName) -> UnitStats:
	for type: UnitStats in LOADABLE:
		if UnitCatalog.id_of(type) == id:
			return type
	return null


## The Explorer appears on the pad with what was loaded while it was built.
func _finish(team: int, slot: Slot) -> void:
	var unit: Unit = _units.spawn(_explorer_type, team, slot.field.global_position)
	unit.explorer.squads = _squads
	for entry: CargoEntry in slot.manifest.entries:
		unit.cargo.load_entry(entry)
	slot.manifest = null
	var pad: Pad = slot.field.request_pad(unit.id)
	unit.landing = Landing.new(unit) # Only to sit on this pad and leave it (`Unit.think` drops it after).
	unit.landing.dock(slot.field, pad)
	playtest_event.emit(&"explorer_ready", {"team": team, "unit": unit.id})
	changed.emit(team)
