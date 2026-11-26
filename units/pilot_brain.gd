class_name PilotBrain
extends UnitBrain
## The brain of an inhabited unit: it holds the player's controls (`input`). A flyer is moved by the flight model,
## which reads them itself (`PilotFlight`), so this brain asks the movement for nothing. Made and removed by
## `PilotSeats`. Simulation.

## The controls as last received.
var input := PilotInput.new()


func setup(unit: Unit) -> void:
	input.team = unit.team
	input.unit_id = unit.id
