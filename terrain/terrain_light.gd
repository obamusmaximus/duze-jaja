class_name TerrainLight
extends RefCounted
## Baked ground colour (`docs/mechanics/heightmap.md`, "Baked light"): per height sample one colour multiplier holding
## cavity occlusion (the sample against its neighbours) and a low-frequency tint. `TerrainChunkMesh` writes it into the
## vertex colours, so it costs nothing per frame in any view. The sun's and moon's shadow is not in it (`TerrainShadow`).

var _heights: TerrainHeights
var _stats: HeightmapStats
## One RGB multiplier per sample (3 floats), in sample order.
var _colors: PackedColorArray = PackedColorArray()
var _tint_noise := FastNoiseLite.new()


func setup(heights: TerrainHeights, stats: HeightmapStats) -> void:
	_heights = heights
	_stats = stats
	_colors.resize(heights.samples.x * heights.samples.y)
	_tint_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_tint_noise.fractal_octaves = 2
	_tint_noise.seed = 11


## The world area whose colour an edit of `area` can change: the area grown by the cavity radius.
func affected(area: Rect2) -> Rect2:
	return area.grow(_stats.light_ao_radius + _heights.spacing)


func color_at(ix: int, iz: int) -> Color:
	return _colors[clampi(iz, 0, _heights.samples.y - 1) * _heights.samples.x + clampi(ix, 0, _heights.samples.x - 1)]


## Bakes the samples `area` (inclusive sample indices) from the current heights.
func bake(area: Rect2i) -> void:
	for z: int in area.size.y:
		for x: int in area.size.x:
			var ix: int = area.position.x + x
			var iz: int = area.position.y + z
			if _heights.sample_height(ix, iz) < MapGrid.SEA_LEVEL - 1.0: # Under the water: nothing worth baking.
				_colors[iz * _heights.samples.x + ix] = Color.WHITE
				continue
			var ao: float = 1.0 - _stats.light_ao * _cavity(ix, iz)
			var tint: float = _tint_noise.get_noise_2d(
				(_heights.origin.x + ix * _heights.spacing) * _stats.tint_frequency,
				(_heights.origin.y + iz * _heights.spacing) * _stats.tint_frequency)
			var warm: Color = Color(1.0 + tint * _stats.tint_strength, 1.0 + tint * _stats.tint_strength * 0.5,
				1.0 - tint * _stats.tint_strength * 0.5)
			_colors[iz * _heights.samples.x + ix] = Color(ao * warm.r, ao * warm.g, ao * warm.b)


## How hollow the ground is at a sample, 0 to 1: how far the neighbours at `ao_radius` average above it.
func _cavity(ix: int, iz: int) -> float:
	var r: int = maxi(roundi(_stats.light_ao_radius / _heights.spacing), 1)
	var h: float = _heights.sample_height(ix, iz)
	var around: float = (_heights.sample_height(ix + r, iz) + _heights.sample_height(ix - r, iz)
		+ _heights.sample_height(ix, iz + r) + _heights.sample_height(ix, iz - r)) * 0.25
	return clampf((around - h) / _stats.light_ao_radius, 0.0, 1.0)
