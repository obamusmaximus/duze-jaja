class_name UnitBrain
extends Node
## What drives a unit: each physics tick its UnitMovement asks the brain for the velocity it wants and, when it wants
## none, which way to face. The OrderBrain drives units now; direct first-person control will be another brain,
## swapped in with `Unit.set_brain()`.


## The flat velocity (metres per second) the unit wants this tick. Called once per tick, so a brain may advance its
## own state here (finish an order, take the next).
func wanted_velocity(_delta: float) -> Vector3:
	return Vector3.ZERO


## Which way the unit wants to face while standing (flat direction), or zero for no preference.
func wanted_facing() -> Vector3:
	return Vector3.ZERO
