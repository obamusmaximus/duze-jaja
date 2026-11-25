class_name TerrainBrush
extends RefCounted
## Brush maths on `TerrainHeights` (`docs/mechanics/heightmap.md`, "Brushes"): raise, lower, flatten and crater, soft at
## the edge. Plain data work with no nodes; the caller reports the returned area through `TerrainChunks.changed()`,
## the same map-change call gameplay will use (landing pads, craters from shells).

enum Mode { RAISE, LOWER, FLATTEN, CRATER }

const MODE_NAMES: PackedStringArray = ["Raise", "Lower", "Flatten", "Crater"]


## Applies `mode` around `center` (world x, z). `amount` is metres for raise and lower, a 0 to 1 pull for flatten
## (towards `target`, a height in metres) and the depth in metres for crater. Returns the world area touched.
static func apply(heights: TerrainHeights, mode: Mode, center: Vector2, radius: float, amount: float,
		target: float) -> Rect2:
	var area := Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
	var span: Rect2i = heights.samples_in(area)
	for iz: int in range(span.position.y, span.end.y):
		for ix: int in range(span.position.x, span.end.x):
			var d: float = (heights.origin + Vector2(ix, iz) * heights.spacing - center).length() / radius
			if d >= 1.0:
				continue
			var weight: float = smoothstep(0.0, 1.0, 1.0 - d)
			var height: float = heights.sample_height(ix, iz)
			match mode:
				Mode.RAISE:
					height += amount * weight
				Mode.LOWER:
					height -= amount * weight
				Mode.FLATTEN:
					height = lerpf(height, target, clampf(amount * weight, 0.0, 1.0))
				Mode.CRATER:
					height += -amount * weight + amount * 0.3 * exp(-pow((d - 0.85) / 0.1, 2.0))
			heights.set_sample_height(ix, iz, height)
	return area
