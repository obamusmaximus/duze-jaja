class_name PilotBrain
extends UnitBrain
## Drives an inhabited unit by the player's controls (`input`) instead of by orders. Made and removed by
## `PilotSeats`. Simulation.
##
## Placeholder flying until the flight model (`docs/plans/flight.md` step 3a): the autopilot flies toward the aim,
## flattened onto the air layer, and keeps its own height. A fixed wing flies at top speed, or its slowest with the
## air brake; without an aim it flies straight on. A hover type flies where it aims, stops and turns on the spot with
## the air brake, and without an aim hovers. The stick and ability do nothing yet.

## An aim closer to straight up or down than this (length of its flat part) points nowhere on the air layer.
const MIN_FLAT_AIM: float = 0.05

## The controls as last received.
var input := PilotInput.new()

var _unit: Unit


func setup(unit: Unit) -> void:
	_unit = unit
	input.team = unit.team
	input.unit_id = unit.id


func wanted_velocity(_delta: float) -> Vector3:
	var autopilot: FlightAutopilot = _unit.movement.autopilot
	var aim: Vector3 = _flat_aim()
	if autopilot != null and autopilot.is_fixed_wing():
		var heading: Vector3 = aim if aim != Vector3.ZERO else -_unit.global_basis.z
		return heading * (_unit.stats.flight_min_speed if input.air_brake else _unit.stats.speed)
	return Vector3.ZERO if input.air_brake else aim * _unit.stats.speed


func wanted_facing() -> Vector3:
	return _flat_aim()


## The aim's direction on the air layer (unit length), or zero.
func _flat_aim() -> Vector3:
	var flat := Vector3(input.aim.x, 0.0, input.aim.z)
	return flat.normalized() if flat.length() >= MIN_FLAT_AIM else Vector3.ZERO
