class_name TerrainTestMap
extends RefCounted
## Makes a test heightmap: a hilly island in a sea, with a beach, a hill, a reef ring and a gully. Stands in for an
## imported map until step 3 (`docs/plans/battlefield.md`).


## A rough atoll for the starter heightmap PNG: a reef ring around a shallow lagoon with a small island in it, on a sea
## floor that drops away outside. Sampled at the import spacing and range so it round-trips through the PNG.
static func make_atoll(extent: Vector2, stats: HeightmapStats) -> TerrainHeights:
	var map: TerrainHeights = TerrainHeights.create(-extent * 0.5, extent, stats.import_spacing, stats.min_height,
			stats.height_range, -30.0)
	var noise := FastNoiseLite.new()
	noise.seed = 11
	noise.frequency = 0.02
	var radius: float = minf(extent.x, extent.y) * 0.35
	for iz: int in map.samples.y:
		for ix: int in map.samples.x:
			var at: Vector2 = map.origin + Vector2(ix, iz) * map.spacing
			var d: float = at.length() / radius
			var height: float = -30.0 + 26.0 * (1.0 - smoothstep(0.9, 1.7, d))
			var wobble: float = 1.0 + noise.get_noise_2dv(at) * 0.6
			height += 12.0 * exp(-pow((d - 1.0) / 0.12, 2.0)) * wobble
			height += 14.0 * exp(-pow(d / 0.22, 2.0)) * wobble
			map.set_sample_height(ix, iz, height)
	return map


## A map of `extent` metres centred on the origin, sampled every `stats.sample_spacing` metres.
static func make(extent: Vector2, stats: HeightmapStats) -> TerrainHeights:
	var map: TerrainHeights = TerrainHeights.create(-extent * 0.5, extent, stats.sample_spacing, -20.0, 60.0, -10.0)
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.012
	var radius: float = minf(extent.x, extent.y) * 0.4
	for iz: int in map.samples.y:
		for ix: int in map.samples.x:
			var at: Vector2 = map.origin + Vector2(ix, iz) * map.spacing
			var d: float = at.length() / radius
			var height: float = -10.0 + 14.0 * clampf(1.4 - d, 0.0, 1.0) * 2.0
			height += 16.0 * exp(-pow((at - Vector2(radius * 0.3, -radius * 0.2)).length() / (radius * 0.28), 2.0))
			height += noise.get_noise_2dv(at) * 3.0 * clampf(1.2 - d, 0.0, 1.0)
			map.set_sample_height(ix, iz, height)
	return map
