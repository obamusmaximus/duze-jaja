class_name HeightmapImport
extends RefCounted
## Turns a 16-bit greyscale PNG into `TerrainHeights` and back (`docs/mechanics/heightmap.md`, "Authoring"). Black is
## `stats.min_height`, white is `min_height + height_range`; one pixel is one sample, `stats.import_spacing` metres
## apart, the map centred on the origin. Surface roles are not stored in the image (slope and height pick them).


## The map in `path`, or null when it can't be read.
static func load_file(path: String, stats: HeightmapStats) -> TerrainHeights:
	var image: Dictionary = HeightmapPng.read(path)
	if image.is_empty():
		return null
	var map := TerrainHeights.new()
	var size: Vector2i = image["size"]
	map.spacing = stats.import_spacing
	map.samples = size
	map.origin = -Vector2(size - Vector2i.ONE) * map.spacing * 0.5
	map.min_height = stats.min_height
	map.height_range = stats.height_range
	map.data = image["values"]
	map.roles.resize(size.x * size.y)
	return map


## Writes the heights (brush edits included) to a 16-bit PNG at `path`.
static func save_file(heights: TerrainHeights, path: String) -> Error:
	return HeightmapPng.write(path, heights.samples, heights.data)
