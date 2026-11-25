class_name PilotInput
extends RefCounted
## What a player is doing with the controls of the unit they inhabit, as plain data: the control channel. Unlike an
## `Order` it is a stream, sent every tick through `CommandIssuer.pilot()`; the last one received holds until the
## next, so a lost one (over a network, later) changes nothing. Directions are in the world, never screen or mouse
## values, so a server can read them.

## The team and the unit the controls are for.
var team: int = 0
var unit_id: int = 0
## Where the player aims: a world direction (the mouse-aim reticle). Zero: no aim.
var aim := Vector3.ZERO
## The direct axes (WASD), each -1 to 1: x right, y up. What they turn is decided with the flight model.
var stick := Vector2.ZERO
## The air brake is held.
var air_brake: bool = false
## The ability key is held (`docs/plans/flight.md` step 4).
var ability: bool = false


## Takes over `other`'s controls (not its team or unit), made safe: a unit-length aim, axes in range, no NaNs.
func copy_controls(other: PilotInput) -> void:
	aim = other.aim.normalized() if other.aim.is_finite() else Vector3.ZERO
	stick = other.stick.clamp(-Vector2.ONE, Vector2.ONE) if other.stick.is_finite() else Vector2.ZERO
	air_brake = other.air_brake
	ability = other.ability


func to_dict() -> Dictionary:
	return {"team": team, "unit_id": unit_id, "aim": aim, "stick": stick, "air_brake": air_brake, "ability": ability}
