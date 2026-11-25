class_name AtollBlockout
extends RefCounted
## Makes the atoll's starter heightmap (`docs/plans/battlefield.md`, step 5) from `BattlefieldStats`: a reef ring with
## two passes round a shallow lagoon, a big island in it with a mountain, plains and beaches, six small islands between
## the ring and the motherships, and a seabed that drops away to open sea. It is written once to the level's PNG, which
## is then the source of truth (edit it in Krita, `docs/mechanics/heightmap.md`); the stats only shape this first draft.
## Sizes are approximate: the land edge sits near the stated size, wobbled by noise.

## Small islands as fractions of half the map extent (x, z).
const SMALL_ISLANDS: Array[Vector2] = [
	Vector2(-0.55, 0.40), Vector2(-0.45, -0.50), Vector2(0.50, 0.45),
	Vector2(0.60, -0.35), Vector2(0.0, 0.75), Vector2(0.10, -0.80),
]
## Angles (radians) of the two passes through the reef ring.
const PASS_ANGLES: Array[float] = [2.6, -0.55]
const PASS_WIDTH: float = 0.13
## Lagoon floor and open-sea floor, metres (negative is below the sea).
const LAGOON_FLOOR: float = -4.0
const SEA_FLOOR: float = -30.0
## Height of the big island's mountain above its plain, metres, and its radius.
const MOUNTAIN_HEIGHT: float = 38.0
const MOUNTAIN_RADIUS: float = 45.0


## Centres (x, z) of the capture points, as markers: the big island's two plains and summit, each small island, and
## the reef ring's north and south crests.
static func capture_points(stats: BattlefieldStats) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var half: Vector2 = stats.map_extent * 0.5
	points.append(Vector2.ZERO)
	points.append(mountain_centre(stats))
	for island: Vector2 in SMALL_ISLANDS:
		points.append(island * half)
	points.append(Vector2(0.0, -stats.ring_radius))
	points.append(Vector2(0.0, stats.ring_radius))
	return points


## Where the big island's mountain stands: north of the middle, leaving the plains south of it for the units.
static func mountain_centre(stats: BattlefieldStats) -> Vector2:
	return Vector2(0.0, -stats.big_island_size.y * 0.3)


static func make(stats: BattlefieldStats, heightmap: HeightmapStats) -> TerrainHeights:
	var extent: Vector2 = stats.map_extent
	var map: TerrainHeights = TerrainHeights.create(-extent * 0.5, extent, heightmap.import_spacing,
			heightmap.min_height, heightmap.height_range, SEA_FLOOR)
	var noise := FastNoiseLite.new()
	noise.seed = 23
	noise.frequency = 0.012
	var fine := FastNoiseLite.new()
	fine.seed = 5
	fine.frequency = 0.05
	var half: Vector2 = extent * 0.5
	for iz: int in map.samples.y:
		for ix: int in map.samples.x:
			var at: Vector2 = map.origin + Vector2(ix, iz) * map.spacing
			var wobble: float = noise.get_noise_2dv(at)
			var floor_h: float = _seabed(at, stats, wobble)
			var h: float = floor_h
			h = maxf(h, _ring(at, stats, wobble))
			h = maxf(h, _island(at, Vector2.ZERO, stats.big_island_size * 0.5, stats.island_height,
					LAGOON_FLOOR, 0.65, 1.15, wobble))
			h += _mountain(at, stats) * (1.0 + wobble * 0.3) + fine.get_noise_2dv(at) * 0.4 * float(h > 0.0)
			for island: Vector2 in SMALL_ISLANDS:
				h = maxf(h, _island(at, island * half, stats.small_island_size * 0.5, stats.small_island_height,
						floor_h, 0.8, 1.6, wobble))
			map.set_sample_height(ix, iz, h)
	return map


## The seabed: lagoon floor inside the ring, falling to the open-sea floor outside it.
static func _seabed(at: Vector2, stats: BattlefieldStats, wobble: float) -> float:
	var r: float = at.length()
	var outer: float = stats.ring_radius + stats.ring_width
	var drop: float = smoothstep(outer - 30.0, outer + 280.0, r)
	return lerpf(LAGOON_FLOOR, SEA_FLOOR, drop) + wobble * 2.0 * drop


## The reef ring: a crest a little above the sea with a gap at each pass.
static func _ring(at: Vector2, stats: BattlefieldStats, wobble: float) -> float:
	var ring_r: float = stats.ring_radius * (1.0 + wobble * 0.04)
	var across: float = (at.length() - ring_r) / (stats.ring_width * 0.67)
	var angle: float = atan2(at.y, at.x)
	var gap: float = 0.0
	for pass_angle: float in PASS_ANGLES:
		var turn: float = absf(wrapf(angle - pass_angle, -PI, PI))
		gap = maxf(gap, exp(-pow(turn / PASS_WIDTH, 2.0)))
	var crest: float = (stats.ring_height + 4.0) * (1.0 + wobble * 0.5) * (1.0 - gap)
	return LAGOON_FLOOR + crest * exp(-across * across)


## An island: its top at `top` metres, sloping down to `floor_h` between `inner` and `outer` times its half size.
static func _island(at: Vector2, centre: Vector2, half: Vector2, top: float, floor_h: float, inner: float,
		outer: float, wobble: float) -> float:
	var d: float = ((at - centre) / half).length() * (1.0 + wobble * 0.25)
	return lerpf(top, floor_h, smoothstep(inner, outer, d))


static func _mountain(at: Vector2, stats: BattlefieldStats) -> float:
	var d: float = (at - mountain_centre(stats)).length() / MOUNTAIN_RADIUS
	return MOUNTAIN_HEIGHT * exp(-d * d)
