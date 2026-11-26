class_name FlightControls
extends RefCounted
## What the `FlightModel` is asked to do in one tick: the control surfaces, each -1 to 1, and the air brake.

## Nose up (+) or down.
var pitch: float = 0.0
## Nose right (+) or left.
var yaw: float = 0.0
## Roll right (+) or left.
var roll: float = 0.0
var air_brake: bool = false
