class_name PlaytestLogWriter
extends RefCounted
## Debug: writes recorded frames to a JSON Lines file (one JSON object per line). The first line is a header, the rest
## are frames and events in time order. Vectors become [x, y, z] rounded to millimetres to keep files small.

const DECIMALS: float = 0.001


## Writes the lines to `path`. Returns false if the file can't be opened.
static func write(path: String, header: Dictionary, lines: Array[Dictionary]) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PlaytestLog: can't write %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_line(JSON.stringify(to_plain(header)))
	for line: Dictionary in lines:
		file.store_line(JSON.stringify(to_plain(line)))
	return true


## Turns vectors, StringNames and nested containers into JSON-friendly values.
static func to_plain(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			return snappedf(value, DECIMALS)
		TYPE_VECTOR2:
			return [snappedf(value.x, DECIMALS), snappedf(value.y, DECIMALS)]
		TYPE_VECTOR3:
			return [snappedf(value.x, DECIMALS), snappedf(value.y, DECIMALS), snappedf(value.z, DECIMALS)]
		TYPE_STRING_NAME:
			return String(value)
		TYPE_DICTIONARY:
			var plain: Dictionary = {}
			for key: Variant in value:
				plain[String(key)] = to_plain(value[key])
			return plain
		TYPE_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_FLOAT32_ARRAY:
			var items: Array = []
			for item: Variant in value:
				items.append(to_plain(item))
			return items
		TYPE_OBJECT:
			return str(value)
	return value
