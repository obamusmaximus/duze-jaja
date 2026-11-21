class_name UnitSpatialHash
extends RefCounted
## Finds units near a point fast: units bucketed by a coarse square grid, rebuilt once per physics tick. Queries fill
## a caller-owned array, so the hot path allocates nothing.

var _cell: float
## Vector2i bucket to Array[Unit].
var _buckets: Dictionary = {}


func _init(cell_size: float) -> void:
	_cell = cell_size


func rebuild(units: Array[Unit]) -> void:
	for bucket: Array in _buckets.values():
		bucket.clear()
	for unit: Unit in units:
		if not unit.alive:
			continue
		var key: Vector2i = _key(unit.global_position)
		var bucket: Variant = _buckets.get(key)
		if bucket == null:
			bucket = []
			_buckets[key] = bucket
		(bucket as Array).append(unit)


## Fills `out` with the living units whose centre (x, z) lies within `radius` of `point`.
func query(point: Vector3, radius: float, out: Array[Unit]) -> void:
	out.clear()
	var low: Vector2i = _key(point - Vector3(radius, 0.0, radius))
	var high: Vector2i = _key(point + Vector3(radius, 0.0, radius))
	var limit: float = radius * radius
	for y: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			var bucket: Variant = _buckets.get(Vector2i(x, y))
			if bucket == null:
				continue
			for unit: Unit in bucket:
				var dx: float = unit.global_position.x - point.x
				var dz: float = unit.global_position.z - point.z
				if dx * dx + dz * dz <= limit:
					out.append(unit)


func _key(point: Vector3) -> Vector2i:
	return Vector2i(floori(point.x / _cell), floori(point.z / _cell))
