class_name TerrainHeights
extends Resource
## Heightmap data (`docs/mechanics/heightmap.md`): ground heights on a regular grid of samples `spacing` metres apart,
## seabed included (a height below the sea level is water depth), plus an optional painted surface role per sample.
## Compact: a height is 16 bits (`min_height` + `height_range` * value / 65535) in a byte array, a role one byte.
## Plain data with no nodes, so a headless server reads the same map the views draw. Setting a sample does not emit
## anything: after a batch of edits tell `TerrainChunks.changed()` which area moved.
##
## Reads go through a decoded copy of the heights in metres, because the load reads them millions of times. It is made
## on the first read (call `prepare()` before other threads read), kept up to date by `set_index_height`, and dropped when `data`, `min_height` or `height_range`
## is assigned. So write heights through these, never into `data` in place.

## World x, z of sample (0, 0).
@export var origin: Vector2 = Vector2.ZERO
## Metres between neighbouring samples.
@export_range(0.5, 32.0, 0.5) var spacing: float = 2.0
## Samples across x and z.
@export var samples: Vector2i = Vector2i(2, 2)
## Height (world y) of the lowest storable value, metres.
@export var min_height: float = -20.0:
	set(value):
		min_height = value
		_stale = true
## Metres between the lowest and the highest storable height.
@export var height_range: float = 60.0:
	set(value):
		height_range = value
		_stale = true
## 16-bit heights, little endian, row by row along x.
@export var data: PackedByteArray = PackedByteArray():
	set(value):
		data = value
		_stale = true
## Painted role per sample: 0 picks one from slope and height, otherwise `WorldMaterials.Role + 1`.
@export var roles: PackedByteArray = PackedByteArray()

## `data` decoded to metres (see the top comment), and whether it must be decoded again.
var _meters := PackedFloat32Array()
var _stale: bool = true


## A flat map at `height` covering `extent` metres from `at`, at least two samples each way.
static func create(at: Vector2, extent: Vector2, sample_spacing: float, low: float, range_m: float,
		height: float) -> TerrainHeights:
	var map := TerrainHeights.new()
	map.origin = at
	map.spacing = sample_spacing
	map.samples = Vector2i(maxi(ceili(extent.x / sample_spacing) + 1, 2), maxi(ceili(extent.y / sample_spacing) + 1, 2))
	map.min_height = low
	map.height_range = range_m
	var count: int = map.samples.x * map.samples.y
	map.data.resize(count * 2)
	map.roles.resize(count)
	for i: int in count:
		map.set_index_height(i, height)
	return map


## The area (world x, z) the samples cover.
func bounds() -> Rect2:
	return Rect2(origin, Vector2(samples - Vector2i.ONE) * spacing)


## Decodes now if needed. The decode on first read isn't thread-safe: call this on the main thread before worker
## threads read.
func prepare() -> void:
	if _stale:
		_decode()


func index_height(index: int) -> float:
	if _stale:
		_decode()
	return _meters[index]


func set_index_height(index: int, height: float) -> void:
	var value: int = clampi(roundi((height - min_height) / height_range * 65535.0), 0, 65535)
	data.encode_u16(index * 2, value)
	if not _stale:
		_meters[index] = min_height + height_range * float(value) / 65535.0


## Height of sample (`ix`, `iz`), indices clamped to the map.
func sample_height(ix: int, iz: int) -> float:
	if _stale:
		_decode()
	return _meters[clampi(iz, 0, samples.y - 1) * samples.x + clampi(ix, 0, samples.x - 1)]


func set_sample_height(ix: int, iz: int, height: float) -> void:
	if ix >= 0 and iz >= 0 and ix < samples.x and iz < samples.y:
		set_index_height(iz * samples.x + ix, height)


## Painted role of a sample, or -1 when it picks one itself.
func painted_role(ix: int, iz: int) -> int:
	return int(roles[clampi(iz, 0, samples.y - 1) * samples.x + clampi(ix, 0, samples.x - 1)]) - 1


func paint_role(ix: int, iz: int, role: int) -> void:
	if ix >= 0 and iz >= 0 and ix < samples.x and iz < samples.y:
		roles[iz * samples.x + ix] = role + 1


## Ground height at world (x, z), blended between the four samples around it (outside the map: the nearest edge).
func height_at(x: float, z: float) -> float:
	var fx: float = clampf((x - origin.x) / spacing, 0.0, float(samples.x - 1))
	var fz: float = clampf((z - origin.y) / spacing, 0.0, float(samples.y - 1))
	var x0: int = mini(floori(fx), samples.x - 2)
	var z0: int = mini(floori(fz), samples.y - 2)
	var tx: float = fx - x0
	var tz: float = fz - z0
	var row: int = z0 * samples.x + x0
	if _stale:
		_decode()
	var a: float = _meters[row]
	var b: float = _meters[row + 1]
	var c: float = _meters[row + samples.x]
	var d: float = _meters[row + samples.x + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)


## The sample indices (inclusive) a world area touches, clamped to the map.
func samples_in(area: Rect2) -> Rect2i:
	var first := Vector2i(floori((area.position.x - origin.x) / spacing), floori((area.position.y - origin.y) / spacing))
	var last := Vector2i(ceili((area.end.x - origin.x) / spacing), ceili((area.end.y - origin.y) / spacing))
	first = first.clamp(Vector2i.ZERO, samples - Vector2i.ONE)
	last = last.clamp(Vector2i.ZERO, samples - Vector2i.ONE)
	return Rect2i(first, last - first + Vector2i.ONE)


func _decode() -> void:
	var count: int = data.size() / 2
	_meters.resize(count)
	for i: int in count:
		_meters[i] = min_height + height_range * float(data.decode_u16(i * 2)) / 65535.0
	_stale = false
