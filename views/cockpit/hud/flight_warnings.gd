class_name FlightWarnings
extends RefCounted
## What the pilot should be warned of, read from the flight. One rule each, so the sound and the HUD agree. View side.

## Samples of the flight path ahead that the ground check looks at.
const PATH_SAMPLES: int = 16


## Whether the stall warning is on: at the warning load and, once on, until a little below it.
static func stall(model: PilotModel, was_on: bool, stats: FlightSoundStats) -> bool:
	var from: float = stats.warning_load - (stats.warning_release if was_on else 0.0)
	return model.stalled or model.stall_load() >= from


## Whether the flight path, held as it is, comes down to the ground or sea soon. Only while closing on it, so level
## flight low over flat ground stays quiet. It doesn't know about buildings, props or other flyers.
static func ground(model: PilotModel, air: AirLayer, half_height: float, stats: HelmetHudStats) -> bool:
	var speed: float = model.velocity.length()
	if stats.pull_up_time <= 0.0 or speed < stats.path_min_speed:
		return false
	var dive: float = clampf(-asin(clampf(model.velocity.y / speed, -1.0, 1.0)) / (PI * 0.5), 0.0, 1.0)
	var horizon: float = stats.pull_up_time + stats.pull_up_dive_time * dive
	var now: float = model.position.y - half_height - air.ground_height(model.position)
	for i: int in range(1, PATH_SAMPLES + 1):
		var ahead: Vector3 = model.position + model.velocity * (horizon * i / PATH_SAMPLES)
		var clearance: float = ahead.y - half_height - air.ground_height(ahead)
		if clearance < stats.pull_up_clearance and clearance < now - 0.5:
			return true
	return false
