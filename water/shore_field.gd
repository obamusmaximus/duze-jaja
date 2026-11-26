class_name ShoreField
extends Node
## The sea's shore, baked from the heightmap into a low-resolution texture (`docs/mechanics/water.md`, "Shore field"):
## per texel the signed distance to the nearest shore in metres (red, negative on land, kept to +-`reach`) and the water
## depth (green, metres below the sea, 0 on land). `water.gdshader` reads it for the foam, the calm and the shallow reef
## colour, so any number of islands cost the same. `bake` does the whole map; `rebake(area)` redoes only the texels a
## change can reach (within `reach` of the area). That is still tens of milliseconds to a second, so `mark_changed`
## collects changed areas and re-bakes them together once nothing changed for `settle` seconds (a brush stroke is one
## re-bake, not one per tick). A node so it can wait; visual data only.

## World x, z of texel (0, 0)'s centre.
var origin: Vector2 = Vector2.ZERO
## Metres between texel centres.
var texel: float = 4.0
## Texels across x and z.
var size: Vector2i = Vector2i.ZERO
## Metres the distance is kept to (and the value over open sea).
var reach: float = 640.0
var texture: ImageTexture
## Seconds without a change before the marked areas are re-baked.
var settle: float = 0.6

var _dirty := Rect2()
var _dirty_for: float = -1.0

var _heights: TerrainHeights
var _image: Image


## Bakes the whole map from `heights`. `texel_size` is metres per texel; `max_reach` how far the distance is kept.
func bake(heights: TerrainHeights, texel_size: float, max_reach: float, settle_seconds: float = 0.6) -> void:
	prepare(heights, texel_size, max_reach, settle_seconds)
	compute()
	finish()


## The first part of `bake()`, on the main thread: sizes the field.
func prepare(heights: TerrainHeights, texel_size: float, max_reach: float, settle_seconds: float = 0.6) -> void:
	settle = settle_seconds
	_heights = heights
	texel = texel_size
	reach = max_reach
	var extent: Vector2 = heights.bounds().size
	size = Vector2i((extent / texel).ceil()) + Vector2i.ONE
	origin = heights.bounds().position
	_image = Image.create(size.x, size.y, false, Image.FORMAT_RGF)


## The second part, safe on a worker thread (after `TerrainHeights.prepare()`): the distances, into the CPU image.
func compute() -> void:
	_bake_window(Rect2i(Vector2i.ZERO, size), Rect2i(Vector2i.ZERO, size))


## The last part, on the main thread: the texture.
func finish() -> void:
	texture = ImageTexture.create_from_image(_image)


## Notes that the ground under `area` (world x, z) changed; the re-bake follows once changes stop.
func mark_changed(area: Rect2) -> void:
	_dirty = area if _dirty_for < 0.0 else _dirty.merge(area)
	_dirty_for = 0.0


func _process(delta: float) -> void:
	if _dirty_for < 0.0:
		return
	_dirty_for += delta
	if _dirty_for >= settle:
		_dirty_for = -1.0
		rebake(_dirty)


## Re-bakes the texels `area` (world x, z) can change. Land that moved nearer or further shifts the distance of every
## texel within `reach` of it, so the window is the area grown by `reach`; the distances are computed over a window
## grown by `reach` again, so land just outside the written one still counts.
func rebake(area: Rect2) -> void:
	if _image == null:
		return
	var whole := Rect2i(Vector2i.ZERO, size)
	var first: Vector2i = Vector2i(((area.position - origin) / texel).floor())
	var last: Vector2i = Vector2i(((area.end - origin) / texel).ceil())
	var margin: int = ceili(reach / texel)
	var write: Rect2i = Rect2i(first, last - first + Vector2i.ONE).grow(margin).intersection(whole)
	_bake_window(write, write.grow(margin).intersection(whole))
	texture.update(_image)


## Where `point` (x, z) is on the texture, in texels.
func to_texel(point: Vector2) -> Vector2:
	return (point - origin) / texel


## Signed shore distance and depth at `point`, read from the baked image (nearest texel); for tests and CPU users.
func sample(point: Vector2) -> Vector2:
	var at: Vector2i = Vector2i(to_texel(point).round()).clamp(Vector2i.ZERO, size - Vector2i.ONE)
	var color: Color = _image.get_pixelv(at)
	return Vector2(color.r, color.g)


## Computes distances over `compute` and stores the texels of `write` (inside it).
func _bake_window(write: Rect2i, compute: Rect2i) -> void:
	var w: int = compute.size.x
	var h: int = compute.size.y
	var land := PackedByteArray()
	land.resize(w * h)
	var depth := PackedFloat32Array()
	depth.resize(w * h)
	for y: int in h:
		var z: float = origin.y + float(compute.position.y + y) * texel
		for x: int in w:
			var height: float = _heights.height_at(origin.x + float(compute.position.x + x) * texel, z)
			land[y * w + x] = 1 if height >= 0.0 else 0
			depth[y * w + x] = maxf(-height, 0.0)
	var to_land: PackedFloat32Array = _chamfer(land, w, h, 1)
	var to_water: PackedFloat32Array = _chamfer(land, w, h, 0)
	if not write.has_area():
		return
	# Red and green per texel, handed to the image in one go (far cheaper than a `set_pixel` each).
	var texels := PackedFloat32Array()
	texels.resize(write.size.x * write.size.y * 2)
	var o: int = 0
	for y: int in range(write.position.y, write.end.y):
		for x: int in range(write.position.x, write.end.x):
			var i: int = (y - compute.position.y) * w + (x - compute.position.x)
			var distance: float
			if land[i] == 1:
				distance = -(to_water[i] - 0.5) * texel
			else:
				distance = (to_land[i] - 0.5) * texel
			texels[o] = clampf(distance, -reach, reach)
			texels[o + 1] = depth[i]
			o += 2
	var baked: Image = Image.create_from_data(write.size.x, write.size.y, false, Image.FORMAT_RGF, texels.to_byte_array())
	_image.blit_rect(baked, Rect2i(Vector2i.ZERO, write.size), write.position)


## Distance in texels from every texel to the nearest texel whose mask is `target` (a two-pass chamfer with
## 1 / 1.414 steps; texels with no such neighbour inside the window get a large value).
func _chamfer(mask: PackedByteArray, w: int, h: int, target: int) -> PackedFloat32Array:
	var far: float = 1.0e6
	var d := PackedFloat32Array()
	d.resize(w * h)
	for i: int in w * h:
		d[i] = 0.0 if mask[i] == target else far
	const DIAGONAL: float = 1.41421356
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			var best: float = d[i]
			if x > 0:
				best = minf(best, d[i - 1] + 1.0)
			if y > 0:
				best = minf(best, d[i - w] + 1.0)
				if x > 0:
					best = minf(best, d[i - w - 1] + DIAGONAL)
				if x < w - 1:
					best = minf(best, d[i - w + 1] + DIAGONAL)
			d[i] = best
	for y: int in range(h - 1, -1, -1):
		for x: int in range(w - 1, -1, -1):
			var i: int = y * w + x
			var best: float = d[i]
			if x < w - 1:
				best = minf(best, d[i + 1] + 1.0)
			if y < h - 1:
				best = minf(best, d[i + w] + 1.0)
				if x < w - 1:
					best = minf(best, d[i + w + 1] + DIAGONAL)
				if x > 0:
					best = minf(best, d[i + w - 1] + DIAGONAL)
			d[i] = best
	return d
