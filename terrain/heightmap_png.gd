class_name HeightmapPng
extends RefCounted
## Reads and writes 16-bit greyscale PNGs for heightmaps (`docs/mechanics/heightmap.md`). Godot's own image saver
## only writes 8 bits, which would step the ground in 1/256ths of the height range. Values travel as little-endian
## 16-bit samples in a byte array, the layout `TerrainHeights.data` uses, row by row from the top (north) row.
## Reads greyscale, grey + alpha, RGB and RGBA at 8 or 16 bits (the first channel counts), not interlaced or palette.

const SIGNATURE: PackedByteArray = [137, 80, 78, 71, 13, 10, 26, 10]

static var _crc_table: PackedInt64Array = PackedInt64Array()


## `{"size": Vector2i, "values": PackedByteArray}` of the file, or an empty dictionary (with a warning) on failure.
static func read(path: String) -> Dictionary:
	var file: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if file.size() < 33 or file.slice(0, 8) != SIGNATURE:
		push_warning("HeightmapPng: %s is not a PNG file." % path)
		return {}
	var width: int = 0
	var height: int = 0
	var depth: int = 0
	var color_type: int = 0
	var idat := PackedByteArray()
	var at: int = 8
	while at + 8 <= file.size():
		var length: int = _u32(file, at)
		var kind: String = file.slice(at + 4, at + 8).get_string_from_ascii()
		var body: int = at + 8
		if kind == "IHDR":
			width = _u32(file, body)
			height = _u32(file, body + 4)
			depth = file[body + 8]
			color_type = file[body + 9]
			if file[body + 12] != 0:
				push_warning("HeightmapPng: interlaced PNGs are not supported (%s)." % path)
				return {}
		elif kind == "IDAT":
			idat.append_array(file.slice(body, body + length))
		elif kind == "IEND":
			break
		at = body + length + 4
	var channels: int = {0: 1, 2: 3, 4: 2, 6: 4}.get(color_type, 0)
	if width < 2 or height < 2 or channels == 0 or (depth != 8 and depth != 16):
		push_warning("HeightmapPng: unsupported PNG (%dx%d, type %d, %d bit) in %s." % [width, height, color_type, depth, path])
		return {}
	var pixel_bytes: int = channels * depth / 8
	var stride: int = width * pixel_bytes
	var buf: PackedByteArray = idat.decompress((stride + 1) * height, FileAccess.COMPRESSION_DEFLATE)
	if buf.size() != (stride + 1) * height:
		push_warning("HeightmapPng: damaged image data in %s." % path)
		return {}
	_unfilter(buf, height, stride, pixel_bytes)
	var values := PackedByteArray()
	values.resize(width * height * 2)
	var o: int = 0
	for z: int in height:
		var p: int = z * (stride + 1) + 1
		for x: int in width:
			if depth == 16:
				values[o] = buf[p + 1]
				values[o + 1] = buf[p]
			else:
				values.encode_u16(o, buf[p] * 257)
			o += 2
			p += pixel_bytes
	return {"size": Vector2i(width, height), "values": values}


## Writes `values` (`size.x * size.y` little-endian 16-bit samples) as a 16-bit greyscale PNG.
static func write(path: String, size: Vector2i, values: PackedByteArray) -> Error:
	var raw := PackedByteArray()
	raw.resize((size.x * 2 + 1) * size.y)
	var o: int = 0
	var s: int = 0
	for z: int in size.y:
		raw[o] = 0
		o += 1
		for x: int in size.x:
			raw[o] = values[s + 1]
			raw[o + 1] = values[s]
			o += 2
			s += 2
	var out := StreamPeerBuffer.new()
	out.big_endian = true
	out.put_data(SIGNATURE)
	var header := StreamPeerBuffer.new()
	header.big_endian = true
	header.put_u32(size.x)
	header.put_u32(size.y)
	header.put_u8(16)
	header.put_u8(0)
	header.put_u8(0)
	header.put_u8(0)
	header.put_u8(0)
	_put_chunk(out, "IHDR", header.data_array)
	_put_chunk(out, "IDAT", raw.compress(FileAccess.COMPRESSION_DEFLATE))
	_put_chunk(out, "IEND", PackedByteArray())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(out.data_array)
	return OK


static func _unfilter(buf: PackedByteArray, height: int, stride: int, bpp: int) -> void:
	var row_size: int = stride + 1
	for z: int in height:
		var row: int = z * row_size
		var kind: int = buf[row]
		if kind == 0:
			continue
		var start: int = row + 1
		var above: int = start - row_size
		for i: int in stride:
			var a: int = buf[start + i - bpp] if i >= bpp else 0
			var b: int = buf[above + i] if z > 0 else 0
			var c: int = buf[above + i - bpp] if (z > 0 and i >= bpp) else 0
			var predict: int = 0
			match kind:
				1: predict = a
				2: predict = b
				3: predict = (a + b) >> 1
				4:
					var p: int = a + b - c
					var pa: int = absi(p - a)
					var pb: int = absi(p - b)
					var pc: int = absi(p - c)
					predict = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
			buf[start + i] = (buf[start + i] + predict) & 255


static func _u32(bytes: PackedByteArray, at: int) -> int:
	return (bytes[at] << 24) | (bytes[at + 1] << 16) | (bytes[at + 2] << 8) | bytes[at + 3]


static func _put_chunk(out: StreamPeerBuffer, kind: String, body: PackedByteArray) -> void:
	out.put_u32(body.size())
	var typed: PackedByteArray = kind.to_ascii_buffer()
	typed.append_array(body)
	out.put_data(typed)
	out.put_u32(_crc(typed))


static func _crc(bytes: PackedByteArray) -> int:
	if _crc_table.is_empty():
		_crc_table.resize(256)
		for n: int in 256:
			var c: int = n
			for _k: int in 8:
				c = (0xEDB88320 ^ (c >> 1)) if (c & 1) == 1 else (c >> 1)
			_crc_table[n] = c
	var crc: int = 0xFFFFFFFF
	for b: int in bytes:
		crc = _crc_table[(crc ^ b) & 255] ^ (crc >> 8)
	return crc ^ 0xFFFFFFFF
