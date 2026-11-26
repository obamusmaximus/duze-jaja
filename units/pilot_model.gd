class_name PilotModel
extends RefCounted
## What an inhabited flyer is flown by: the state shared by the jet (`FlightModel`) and the hover (`HoverModel`)
## control types, and what views read of either. Plain state: no nodes, nothing read from the world. Simulation.

## The middle of the airframe (world).
var position := Vector3.ZERO
## Metres per second.
var velocity := Vector3.ZERO
## The airframe's orientation: -z is the nose, y up, x the right wing.
var basis := Basis.IDENTITY
## The wing is past its stall angle (a hover never stalls).
var stalled: bool = false


func forward() -> Vector3:
	return -basis.z


## How much of the stall angle the wing is using: 1 and above is past the stall.
func stall_load() -> float:
	return 0.0


## The share of the weight carried by the engine rather than a wing, 0 to 1.
func hover_share() -> float:
	return 0.0


## The type's level top speed in this control type, metres per second. Views scale speed effects by it.
func top_speed() -> float:
	return 1.0


## The aim that asks for nothing: the mouse stick's centre.
func neutral_aim() -> Vector3:
	return forward()
