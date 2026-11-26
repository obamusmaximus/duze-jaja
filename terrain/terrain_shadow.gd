class_name TerrainShadow
extends RefCounted
## The terrain's sun or moon shadow (`docs/mechanics/heightmap.md`, "Terrain shadow") as a mask texture: one byte per
## height sample, 255 lit and 0 in shadow. The ground and sea shaders read it through global uniforms and block only
## the directional light with it, so lamps and ambient light are untouched. The sea is a receiver at its own level.
## The trace is a horizon sweep away from the sun, linear in the samples; an edit re-traces everything downwind of it.
## Visual only: nothing in the simulation reads it.

var _heights: TerrainHeights
## One byte per sample, in sample order.
var _mask := PackedByteArray()
## Horizontal unit vector toward the sun (x, z).
var _toward_sun: Vector2 = Vector2(0.0, 1.0)
var _tan_elevation: float = 0.7
## Vertical metres over which a shadow's edge fades.
var _softness: float = 2.5
## The highest ground ever traced (m above the sea). It only grows, so lowering a peak still re-traces as far as its
## old shadow reached.
var _peak: float = 0.0
var _texture: ImageTexture


func setup(heights: TerrainHeights, softness: float) -> void:
	_heights = heights
	_softness = maxf(softness, 0.01)
	_peak = 0.0
	_texture = null
	_mask.resize(heights.samples.x * heights.samples.y)
	_mask.fill(255)


## The sun's direction: `sun` is a directional light (it shines along its -z). True if it changed.
func set_sun(sun: DirectionalLight3D) -> bool:
	var toward: Vector3 = sun.global_transform.basis.z
	var flat := Vector2(toward.x, toward.z)
	var direction: Vector2 = flat.normalized() if flat.length() > 0.001 else Vector2(0.0, 1.0)
	var slope: float = maxf(toward.y, 0.05) / maxf(flat.length(), 0.001)
	if direction.is_equal_approx(_toward_sun) and is_equal_approx(slope, _tan_elevation):
		return false
	_toward_sun = direction
	_tan_elevation = slope
	return true


## True if the softness changed.
func set_softness(softness: float) -> bool:
	var value: float = maxf(softness, 0.01)
	if is_equal_approx(value, _softness):
		return false
	_softness = value
	return true


## Metres the longest shadow reaches from what casts it: the highest ground over the sun's slope.
func reach() -> float:
	return _peak / _tan_elevation


## The world area whose shadow an edit of `area` can change: the area swept downwind (away from the sun) by `reach()`.
func affected(area: Rect2) -> Rect2:
	var grown: Rect2 = area.grow(_heights.spacing * 2.0)
	return grown.merge(Rect2(grown.position - _toward_sun * reach(), grown.size))


## Whether sample (`ix`, `iz`) is lit: 1 lit, 0 in shadow.
func lit_at(ix: int, iz: int) -> float:
	return _mask[clampi(iz, 0, _heights.samples.y - 1) * _heights.samples.x
		+ clampi(ix, 0, _heights.samples.x - 1)] / 255.0


## The whole mask, a byte per sample (for tests).
func mask() -> PackedByteArray:
	return _mask.duplicate()


## Traces the whole map. Safe on a worker thread once the heights are decoded; call `publish()` afterwards.
func bake_all() -> void:
	var whole := Rect2i(Vector2i.ZERO, _heights.samples)
	_raise_peak(whole)
	_bake(whole)


## The ground changed inside `area` (world x, z): traces everything its shadows can reach. Call `publish()` afterwards.
func bake_edit(area: Rect2) -> void:
	_raise_peak(_heights.samples_in(area))
	_bake(_heights.samples_in(affected(area)))


## Main thread: puts the mask in its texture and points the shaders at it.
func publish() -> void:
	var image: Image = Image.create_from_data(_heights.samples.x, _heights.samples.y, false, Image.FORMAT_R8, _mask)
	if _texture == null:
		_texture = ImageTexture.create_from_image(image)
	else:
		_texture.update(image)
	# A texel's centre lies on its sample, so the texture starts half a spacing before the first one.
	var corner: Vector2 = _heights.origin - Vector2.ONE * _heights.spacing * 0.5
	var scale: Vector2 = Vector2.ONE / (Vector2(_heights.samples) * _heights.spacing)
	RenderingServer.global_shader_parameter_set(&"terrain_shadow_mask", _texture)
	RenderingServer.global_shader_parameter_set(&"terrain_shadow_rect", Vector4(corner.x, corner.y, scale.x, scale.y))


## Takes the mask off the shaders (the terrain left the tree), so the next level starts unshadowed.
static func withdraw() -> void:
	RenderingServer.global_shader_parameter_set(&"terrain_shadow_rect", Vector4.ZERO)


func _raise_peak(area: Rect2i) -> void:
	for iz: int in range(area.position.y, area.end.y):
		for ix: int in range(area.position.x, area.end.x):
			_peak = maxf(_peak, _heights.sample_height(ix, iz) - MapGrid.SEA_LEVEL)


## Sweeps the samples of `area` slice by slice (along the sun's major axis) from as far upstream as a shadow reaches.
## Each sample takes the shadow surface of the slice before, read where the sun's ray crosses it, lowered by the sun's
## slope, or its own height if higher.
func _bake(area: Rect2i) -> void:
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
	# Slices upstream that can still cast onto the area: the longest shadow, or up to the map edge.
	var upstream: int = (a_count - 1 - (a_min + a_len - 1)) if step_sign < 0 else a_min
	var margin: int = mini(ceili(reach() * absf(major) / spacing) + 1, upstream)
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
	var stride: int = _heights.samples.x
	for k: int in count_a:
		var a: int = start + step_sign * k
		for i: int in width:
			var b: int = lo + i
			var h: float = _surface(a, b, along_x)
			if k == 0:
				cur[i] = h
				continue
			# Where the ray from this sample toward the sun crossed the previous slice.
			var fb: float = float(i) + shift
			var i0: int = clampi(floori(fb), 0, width - 2)
			var t: float = clampf(fb - i0, 0.0, 1.0)
			cur[i] = maxf(h, lerpf(prev[i0], prev[i0 + 1], t) - drop)
		if k >= margin:
			var a_local: int = a - a_min
			if a_local >= 0 and a_local < a_len:
				for j: int in b_len:
					var b: int = b_min + j
					var depth: float = cur[pad + j] - _surface(a, b, along_x)
					var index: int = b * stride + a if along_x else a * stride + b
					_mask[index] = roundi((1.0 - smoothstep(0.0, _softness, depth)) * 255.0)
		var swap: PackedFloat32Array = prev
		prev = cur
		cur = swap


## What casts and receives at a sample: the ground, or the sea where the ground is under it.
func _surface(a: int, b: int, along_x: bool) -> float:
	var h: float = _heights.sample_height(a, b) if along_x else _heights.sample_height(b, a)
	return maxf(h, MapGrid.SEA_LEVEL)
