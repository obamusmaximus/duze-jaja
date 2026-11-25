class_name TerrainLight
extends RefCounted
## Baked ground light (`docs/mechanics/heightmap.md`): per height sample one colour multiplier holding the sun's horizon
## shadow (a sweep away from the sun), cavity occlusion (the sample against its neighbours) and a low-frequency tint.
## `TerrainChunkMesh` writes it into the vertex colours, so it costs nothing per frame in any view. The sweep is linear
## in the samples; an edit re-bakes its area plus the stretch upstream the shadows need, and `shadow_reach()` says how
## far downwind the change can show, so `TerrainChunks` rebuilds those chunks too.

var _heights: TerrainHeights
var _stats: HeightmapStats
## One RGB multiplier per sample (3 floats), in sample order.
var _colors: PackedColorArray = PackedColorArray()
## Horizontal unit vector toward the sun (x, z).
var _toward_sun: Vector2 = Vector2(0.0, 1.0)
var _tan_elevation: float = 0.7
var _tint_noise := FastNoiseLite.new()


func setup(heights: TerrainHeights, stats: HeightmapStats) -> void:
	_heights = heights
	_stats = stats
	_colors.resize(heights.samples.x * heights.samples.y)
	_tint_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_tint_noise.fractal_octaves = 2
	_tint_noise.seed = 11


## The sun's direction: `sun` is a directional light (it shines along its -z).
func set_sun(sun: DirectionalLight3D) -> void:
	var toward: Vector3 = sun.global_transform.basis.z
	var flat := Vector2(toward.x, toward.z)
	_toward_sun = flat.normalized() if flat.length() > 0.001 else Vector2(0.0, 1.0)
	_tan_elevation = maxf(toward.y, 0.05) / maxf(flat.length(), 0.001)


## Metres a shadow can reach from what casts it (the highest relief over the sun's slope, capped by the stats).
func shadow_reach() -> float:
	var relief: float = _heights.height_range * 0.5
	return minf(relief / _tan_elevation, _stats.light_reach)


## The world area whose light an edit of `area` can change: the area grown by the cavity radius, and swept downwind
## (away from the sun) by the shadow reach.
func affected(area: Rect2) -> Rect2:
	var grown: Rect2 = area.grow(_stats.light_ao_radius + _heights.spacing)
	var swept := Rect2(grown.position - _toward_sun * shadow_reach(), grown.size)
	return grown.merge(swept)


func color_at(ix: int, iz: int) -> Color:
	return _colors[clampi(iz, 0, _heights.samples.y - 1) * _heights.samples.x + clampi(ix, 0, _heights.samples.x - 1)]


## Bakes the samples `area` (inclusive sample indices) from the current heights.
func bake(area: Rect2i) -> void:
	var lit := _shadow_lit(area)
	var width: int = area.size.x
	var amount: float = _stats.light_shadow
	var cool: Color = _stats.light_shade_tint
	for z: int in area.size.y:
		for x: int in width:
			var ix: int = area.position.x + x
			var iz: int = area.position.y + z
			if _heights.sample_height(ix, iz) < MapGrid.SEA_LEVEL - 1.0: # Under the water: no light worth baking.
				_colors[iz * _heights.samples.x + ix] = Color.WHITE
				continue
			var shaded: Color = Color.WHITE.lerp(cool, amount * (1.0 - lit[z * width + x]))
			var ao: float = 1.0 - _stats.light_ao * _cavity(ix, iz)
			var tint: float = _tint_noise.get_noise_2d(
				(_heights.origin.x + ix * _heights.spacing) * _stats.tint_frequency,
				(_heights.origin.y + iz * _heights.spacing) * _stats.tint_frequency)
			var warm: Color = Color(1.0 + tint * _stats.tint_strength, 1.0 + tint * _stats.tint_strength * 0.5,
				1.0 - tint * _stats.tint_strength * 0.5)
			var out: Color = Color(shaded.r * ao * warm.r, shaded.g * ao * warm.g, shaded.b * ao * warm.b)
			_colors[iz * _heights.samples.x + ix] = out


## Per sample of `area`: 1 lit, 0 in shadow. Sweeps slice by slice (along the sun's major axis) from `margin` slices
## upstream; each sample takes the shadow surface of the slice before, read where the sun's ray crosses it, lowered by
## the sun's slope, or its own height if higher.
func _shadow_lit(area: Rect2i) -> PackedFloat32Array:
	var spacing: float = _heights.spacing
	var along_x: bool = absf(_toward_sun.x) >= absf(_toward_sun.y)
	var major: float = _toward_sun.x if along_x else _toward_sun.y
	var minor: float = _toward_sun.y if along_x else _toward_sun.x
	var step_sign: int = -1 if major > 0.0 else 1 # Slices run away from the sun.
	var shift: float = minor / absf(major) # Minor samples the sun lies over per slice upstream.
	var drop: float = spacing / absf(major) * _tan_elevation # The shadow surface's fall per slice.
	var a_min: int = area.position.x if along_x else area.position.y
	var a_len: int = area.size.x if along_x else area.size.y
	var b_min: int = area.position.y if along_x else area.position.x
	var b_len: int = area.size.y if along_x else area.size.x
	var a_count: int = _heights.samples.x if along_x else _heights.samples.y
	# Slices upstream that can still cast onto the area: the shadow reach, or up to the map edge.
	var upstream: int = (a_count - 1 - (a_min + a_len - 1)) if step_sign < 0 else a_min
	var margin: int = mini(ceili(_stats.light_reach / spacing), upstream)
	# Minor range wide enough for the ray to drift `margin` slices.
	var pad: int = ceili(absf(shift) * margin) + 2
	var lo: int = b_min - pad
	var width: int = b_len + pad * 2
	var count_a: int = a_len + margin
	var start: int = a_min + a_len - 1 + margin if step_sign < 0 else a_min - margin
	var prev := PackedFloat32Array()
	prev.resize(width)
	var cur := PackedFloat32Array()
	cur.resize(width)
	var result := PackedFloat32Array()
	result.resize(area.size.x * area.size.y)
	var soft: float = maxf(_stats.light_shadow_softness, 0.01)
	for k: int in count_a:
		var a: int = start + step_sign * k
		for i: int in width:
			var b: int = lo + i
			var h: float = _height(a, b, along_x)
			if k == 0:
				cur[i] = h
				continue
			# Where the ray from this sample toward the sun crossed the previous slice.
			var fb: float = float(i) + shift
			var i0: int = clampi(floori(fb), 0, width - 2)
			var t: float = clampf(fb - i0, 0.0, 1.0)
			var level: float = lerpf(prev[i0], prev[i0 + 1], t) - drop
			cur[i] = maxf(h, level)
		if k >= margin:
			var a_local: int = a - a_min
			if a_local >= 0 and a_local < a_len:
				for j: int in b_len:
					var i: int = pad + j
					var h: float = _height(a, b_min + j, along_x)
					var depth: float = cur[i] - h
					var value: float = 1.0 - smoothstep(0.0, soft, depth)
					var rx: int = a_local if along_x else j
					var rz: int = j if along_x else a_local
					result[rz * area.size.x + rx] = value
		var swap: PackedFloat32Array = prev
		prev = cur
		cur = swap
	return result


func _height(a: int, b: int, along_x: bool) -> float:
	return _heights.sample_height(a, b) if along_x else _heights.sample_height(b, a)


## How hollow the ground is at a sample, 0 to 1: how far the neighbours at `ao_radius` average above it.
func _cavity(ix: int, iz: int) -> float:
	var r: int = maxi(roundi(_stats.light_ao_radius / _heights.spacing), 1)
	var h: float = _heights.sample_height(ix, iz)
	var around: float = (_heights.sample_height(ix + r, iz) + _heights.sample_height(ix - r, iz)
		+ _heights.sample_height(ix, iz + r) + _heights.sample_height(ix, iz - r)) * 0.25
	return clampf((around - h) / _stats.light_ao_radius, 0.0, 1.0)
