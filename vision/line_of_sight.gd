class_name LineOfSight
## Whether one point sees another over the heightmap: the straight line between them stays above the ground. Only
## terrain blocks it (no units, buildings or bubbles). Simulation.


## True if nothing of `terrain` rises above the line from `from` to `to`, sampled every `step` metres between the
## ends. No terrain: always true.
static func clear(terrain: TerrainHeights, from: Vector3, to: Vector3, step: float) -> bool:
	if terrain == null:
		return true
	var span := Vector2(to.x - from.x, to.z - from.z)
	var count: int = ceili(span.length() / maxf(step, 0.5))
	for i: int in range(1, count):
		var t: float = float(i) / float(count)
		if terrain.height_at(from.x + span.x * t, from.z + span.y * t) > lerpf(from.y, to.y, t):
			return false
	return true
