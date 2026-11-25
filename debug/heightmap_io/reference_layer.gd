class_name ReferenceLayer
extends RefCounted
## Debug: the Krita reference layer (`docs/mechanics/heightmap.md`, "Reference layer"). A transparent PNG with one pixel
## per height sample, laid over the painting on its own layer and never exported with it: a labelled grid every 100 m,
## the map edge, a scale bar, the atoll ring, the motherships' footprints at their hover position, a one-unit dot and a
## 100-unit squad block for scale, and a ruler of grey values with sea level marked. Everything comes from the same data
## the game uses (`BattlefieldStats`, `HeightmapStats`), so regenerate it when those change.

const GRID_STEP: float = 100.0
const GRID_COLOR := Color(0.2, 0.45, 0.9, 0.35)
const GRID_MAJOR_COLOR := Color(0.2, 0.45, 0.9, 0.7)
const EDGE_COLOR := Color(1.0, 0.1, 0.1, 0.9)
const RING_COLOR := Color(1.0, 0.55, 0.0, 0.9)
const SHIP_COLOR := Color(0.8, 0.1, 0.8, 0.9)
const UNIT_COLOR := Color(0.0, 0.7, 0.2, 1.0)
const TEXT_COLOR := Color(0.0, 0.0, 0.0, 0.95)
const SEA_COLOR := Color(0.0, 0.5, 1.0, 1.0)
## Pixel size of one font dot.
const TEXT_SCALE: int = 2
## Spacing and row length of the test units, as the atoll level places them.
const UNIT_SPACING: float = 3.0
const UNITS_PER_ROW: int = 10
const RULER_STEPS: int = 10

## A 3 x 5 pixel font: each glyph is five rows of three bits, top row first.
const GLYPHS: Dictionary = {
	"0": [7, 5, 5, 5, 7], "1": [2, 6, 2, 2, 7], "2": [7, 1, 7, 4, 7], "3": [7, 1, 7, 1, 7], "4": [5, 5, 7, 1, 1],
	"5": [7, 4, 7, 1, 7], "6": [7, 4, 7, 5, 7], "7": [7, 1, 1, 1, 1], "8": [7, 5, 7, 5, 7], "9": [7, 5, 7, 1, 7],
	"-": [0, 0, 7, 0, 0], "+": [0, 2, 7, 2, 0], "%": [5, 1, 2, 4, 5], ".": [0, 0, 0, 0, 2],
	"A": [2, 5, 7, 5, 5], "E": [7, 4, 7, 4, 7], "G": [7, 4, 5, 5, 7], "H": [5, 5, 7, 5, 5], "I": [7, 2, 2, 2, 7],
	"M": [5, 7, 7, 5, 5], "N": [7, 5, 5, 5, 5], "P": [7, 5, 7, 4, 4], "R": [6, 5, 6, 5, 5], "S": [7, 4, 7, 1, 7],
	"T": [7, 2, 2, 2, 2], "U": [5, 5, 5, 5, 7],
}


## The layer for `heights` (one pixel per sample). `battlefield` gives the ring, the motherships and the map extent.
static func make(heights: TerrainHeights, battlefield: BattlefieldStats, ship: MothershipStats) -> Image:
	var image := Image.create(heights.samples.x, heights.samples.y, false, Image.FORMAT_RGBA8)
	var spacing: float = heights.spacing
	var map: Rect2 = heights.bounds()
	_grid(image, heights, map)
	# The painted area's edge, and the battlefield's own extent when it differs.
	_rect(image, heights, map, EDGE_COLOR)
	_rect(image, heights, Rect2(-battlefield.map_extent * 0.5, battlefield.map_extent), EDGE_COLOR)
	# The atoll ring.
	_circle(image, heights, Vector2.ZERO, battlefield.ring_radius, RING_COLOR)
	_text(image, _to_pixel(heights, Vector2(battlefield.ring_radius + 6.0, -8.0)), "ring %dm" % int(battlefield.ring_radius), RING_COLOR)
	# Mothership footprints at their hover position (x standoff, the hull and prow seen from above, as the shadow is sized).
	var prow: float = ship.beam * ship.prow_ratio
	var ship_size := Vector2(ship.beam, ship.hull_length + prow)
	for side: float in [-1.0, 1.0]:
		var centre := Vector2(side * battlefield.mothership_standoff, -prow * 0.5)
		var footprint := Rect2(centre - ship_size * 0.5, ship_size)
		_rect(image, heights, footprint, SHIP_COLOR)
		_text(image, _to_pixel(heights, footprint.position + Vector2(4.0, 4.0)), "ship", SHIP_COLOR)
	# Scale: one unit (a dot, at least two pixels) and a 100-unit squad block.
	var corner: Vector2 = map.position + Vector2(40.0, map.size.y - 140.0)
	var dot: int = maxi(2, roundi(2.0 / spacing))
	var dot_at: Vector2i = _to_pixel(heights, corner)
	image.fill_rect(Rect2i(dot_at, Vector2i(dot, dot)), UNIT_COLOR)
	_text(image, dot_at + Vector2i(8, -4), "1 unit", UNIT_COLOR)
	var block := Rect2(corner + Vector2(0.0, 20.0), Vector2(UNITS_PER_ROW, 100 / UNITS_PER_ROW) * UNIT_SPACING)
	var block_pixels := Rect2i(_to_pixel(heights, block.position), Vector2i(maxi(2, roundi(block.size.x / spacing)), maxi(2, roundi(block.size.y / spacing))))
	image.fill_rect(block_pixels, Color(UNIT_COLOR, 0.55))
	_text(image, block_pixels.position + Vector2i(block_pixels.size.x + 8, 0), "100 units", UNIT_COLOR)
	_scale_bar(image, heights, map)
	_ruler(image, heights)
	return image


## Writes the layer for `heights` to `path`.
static func save(heights: TerrainHeights, battlefield: BattlefieldStats, ship: MothershipStats, path: String) -> Error:
	return make(heights, battlefield, ship).save_png(path)


static func _to_pixel(heights: TerrainHeights, point: Vector2) -> Vector2i:
	return Vector2i(((point - heights.origin) / heights.spacing).round())


static func _grid(image: Image, heights: TerrainHeights, map: Rect2) -> void:
	var x: float = ceilf(map.position.x / GRID_STEP) * GRID_STEP
	while x <= map.end.x:
		var major: bool = is_zero_approx(fposmod(x, GRID_STEP * 5.0))
		var px: int = _to_pixel(heights, Vector2(x, 0.0)).x
		image.fill_rect(Rect2i(px, 0, 1, image.get_height()), GRID_MAJOR_COLOR if major else GRID_COLOR)
		_text(image, Vector2i(px + 3, 3), "%d" % int(x), TEXT_COLOR)
		x += GRID_STEP
	var z: float = ceilf(map.position.y / GRID_STEP) * GRID_STEP
	while z <= map.end.y:
		var major: bool = is_zero_approx(fposmod(z, GRID_STEP * 5.0))
		var pz: int = _to_pixel(heights, Vector2(0.0, z)).y
		image.fill_rect(Rect2i(0, pz, image.get_width(), 1), GRID_MAJOR_COLOR if major else GRID_COLOR)
		_text(image, Vector2i(3, pz + 3), "%d" % int(z), TEXT_COLOR)
		z += GRID_STEP


static func _rect(image: Image, heights: TerrainHeights, area: Rect2, color: Color) -> void:
	var a: Vector2i = _to_pixel(heights, area.position)
	var b: Vector2i = _to_pixel(heights, area.end)
	for edge: Rect2i in [Rect2i(a.x, a.y, b.x - a.x + 1, 2), Rect2i(a.x, b.y - 1, b.x - a.x + 1, 2),
			Rect2i(a.x, a.y, 2, b.y - a.y + 1), Rect2i(b.x - 1, a.y, 2, b.y - a.y + 1)]:
		image.fill_rect(edge.intersection(Rect2i(Vector2i.ZERO, image.get_size())), color)


static func _circle(image: Image, heights: TerrainHeights, centre: Vector2, radius: float, color: Color) -> void:
	var steps: int = maxi(64, int(TAU * radius / heights.spacing))
	for i: int in steps:
		var at: Vector2i = _to_pixel(heights, centre + Vector2.from_angle(TAU * i / steps) * radius)
		if Rect2i(Vector2i.ZERO, image.get_size()).has_point(at):
			image.set_pixelv(at, color)
			if at.x + 1 < image.get_width():
				image.set_pixel(at.x + 1, at.y, color)


## A bar 500 m long (ticks every 100 m) in the lower left, above the sea-level ruler.
static func _scale_bar(image: Image, heights: TerrainHeights, map: Rect2) -> void:
	var start: Vector2i = _to_pixel(heights, map.position + Vector2(40.0, map.size.y - 40.0))
	var length: int = roundi(500.0 / heights.spacing)
	image.fill_rect(Rect2i(start, Vector2i(length, 3)), TEXT_COLOR)
	for i: int in 6:
		image.fill_rect(Rect2i(start.x + roundi(i * 100.0 / heights.spacing), start.y - 6, 2, 9), TEXT_COLOR)
	_text(image, start + Vector2i(0, -18), "500 m", TEXT_COLOR)


## A strip of grey patches down the right edge: each says the grey (percent) and the height it stands for, sea level
## in blue. Paint with these values in Krita, or sample them with the picker.
static func _ruler(image: Image, heights: TerrainHeights) -> void:
	var patch: int = clampi((image.get_height() - 20) / (RULER_STEPS + 1) - 4, 6, 28)
	var x0: int = maxi(image.get_width() - 150, 40)
	for i: int in RULER_STEPS + 1:
		var grey: float = float(i) / RULER_STEPS
		var metres: float = heights.min_height + grey * heights.height_range
		var y: int = 10 + i * (patch + 4)
		image.fill_rect(Rect2i(x0, y, patch, patch), Color(grey, grey, grey, 1.0))
		if patch >= 24:
			_text(image, Vector2i(x0 + patch + 6, y + 2), "%d%%" % roundi(grey * 100.0), TEXT_COLOR)
			_text(image, Vector2i(x0 + patch + 6, y + 16), "%+dm" % roundi(metres), TEXT_COLOR)
	var sea_grey: float = clampf(-heights.min_height / heights.height_range, 0.0, 1.0)
	var sea_y: int = 10 + roundi(sea_grey * RULER_STEPS * (patch + 4)) + patch / 2
	image.fill_rect(Rect2i(x0 - 30, sea_y, 30, 3), SEA_COLOR)
	_text(image, Vector2i(x0 - 100, sea_y - 12), "sea %d%%" % roundi(sea_grey * 100.0), SEA_COLOR)


static func _text(image: Image, at: Vector2i, text: String, color: Color) -> void:
	var x: int = at.x
	for character: String in text.to_upper():
		if GLYPHS.has(character):
			var rows: Array = GLYPHS[character]
			for row: int in 5:
				for column: int in 3:
					if (int(rows[row]) >> (2 - column)) & 1 == 1:
						var cell := Rect2i(x + column * TEXT_SCALE, at.y + row * TEXT_SCALE, TEXT_SCALE, TEXT_SCALE)
						image.fill_rect(cell.intersection(Rect2i(Vector2i.ZERO, image.get_size())), color)
		x += 4 * TEXT_SCALE
