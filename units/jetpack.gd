class_name Jetpack
extends RefCounted
## A jetpack unit (the commando) under the RTS: it hovers `rts_hover_height` over the ground; any move is a surge
## (`UnitStats.speed`); holding one direction for `rts_afterburner_delay` lights the afterburner, which speeds it up to
## `rts_afterburner_speed` and locks its weapon out until it ends (a turn past `rts_straight_deg`, or stopping). No
## fuel. Stepped by `Unit.think` after the movement decided; `UnitMovement` reads `boost`. First person is
## `JetpackModel`. Simulation.

enum Thrust { HOVER, SURGE, AFTERBURNER }

## Slower than this (metres per second, flat) counts as standing in the hover.
const MOVING_SPEED: float = 0.5

var stats: JetpackStats
var thrust: Thrust = Thrust.HOVER
## Top speed as a multiple of the surge speed: 1, rising toward the afterburner's under it.
var boost: float = 1.0

var _unit: Unit
## Where the present straight run began heading, and how long it has lasted.
var _run_heading := Vector3.ZERO
var _run_time: float = 0.0
## The lean shown, radians.
var _lean: float = 0.0


func _init(unit: Unit, jetpack_stats: JetpackStats) -> void:
	_unit = unit
	stats = jetpack_stats


## The weapon can't fire while the afterburner burns.
func afterburning() -> bool:
	return thrust == Thrust.AFTERBURNER


## One decision, with the flat velocity the movement just decided.
func step(delta: float, flat: Vector3) -> void:
	var speed: float = flat.length()
	if speed < MOVING_SPEED:
		thrust = Thrust.HOVER
		_run_time = 0.0
		_run_heading = Vector3.ZERO
	else:
		var heading: Vector3 = flat / speed
		if _run_heading.is_zero_approx() or heading.angle_to(_run_heading) > deg_to_rad(stats.rts_straight_deg):
			_run_heading = heading
			_run_time = 0.0
		else:
			_run_time += delta
		thrust = Thrust.AFTERBURNER if _run_time >= stats.rts_afterburner_delay else Thrust.SURGE
	var surge: float = maxf(_unit.stats.speed, 0.1)
	var top: float = maxf(stats.rts_afterburner_speed / surge, 1.0) if afterburning() else 1.0
	boost = move_toward(boost, top, stats.rts_afterburner_accel / surge * delta)
	_lean_into(delta, speed / surge)


## The ground point under a standing jetpack unit's body is this far below it.
func hover_height() -> float:
	return stats.rts_hover_height


## Leaves the RTS state as it is for a player's controls (first person), or takes it up again after.
func reset() -> void:
	thrust = Thrust.HOVER
	boost = 1.0
	_run_time = 0.0
	_run_heading = Vector3.ZERO
	_lean = 0.0
	_unit.set_attitude(0.0, 0.0)


## Look only: leans forward with speed, `rts_lean_deg` at the surge speed.
func _lean_into(delta: float, speed_share: float) -> void:
	var wanted: float = -deg_to_rad(stats.rts_lean_deg) * clampf(speed_share, 0.0, 1.6)
	_lean = lerpf(_lean, wanted, 1.0 - exp(-_unit.stats.flight_lean_rate * delta))
	_unit.set_attitude(_lean, 0.0)
