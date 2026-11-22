class_name TerrainLayout
extends Resource
## The terrain of a level as data: which tile (kind, turn, height level) sits in which grid cell. Saved as a flat list
## of five numbers per cell (x, z, kind, turn, level) so the .tres stays small and diff-able. Painted in the game by
## the TerrainEditor (debug/terrain_editor/) and shown by a TerrainMap. Cells with no entry are open ground.

## What a tile is. Roads are flat tiles with a road drawn on them; a ramp climbs one level toward its high side.
enum Kind { FLAT, RAMP, ROAD_STRAIGHT, ROAD_CORNER, ROAD_CROSS, ROAD_SPLIT, ROAD_END }

## Returned by `get_cell` for an empty cell.
const NONE: Vector3i = Vector3i(-1, 0, 0)

## Flat list: x, z, kind, turn, level for each cell (see the class comment).
@export var data: PackedInt32Array = PackedInt32Array():
	set(value):
		data = value
		_cells.clear()
		_loaded = false

var _cells: Dictionary = {}
var _loaded: bool = false


## (kind, turn, level) of `cell`, or `NONE`. Turn is quarter turns clockwise seen from above; for a ramp, 0 has its
## high side to the north (-Z).
func get_cell(cell: Vector2i) -> Vector3i:
	_load()
	return _cells.get(cell, NONE)


func has_cell(cell: Vector2i) -> bool:
	_load()
	return _cells.has(cell)


func set_cell(cell: Vector2i, kind: Kind, turn: int, level: int) -> void:
	_load()
	_cells[cell] = Vector3i(kind, posmod(turn, 4), level)


func erase_cell(cell: Vector2i) -> void:
	_load()
	_cells.erase(cell)


func cells() -> Array[Vector2i]:
	_load()
	var out: Array[Vector2i] = []
	out.assign(_cells.keys())
	return out


func is_empty() -> bool:
	_load()
	return _cells.is_empty()


## Writes the cells back into `data`; call before saving the resource.
func commit() -> void:
	_load()
	var list := PackedInt32Array()
	var keys: Array[Vector2i] = cells()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for cell: Vector2i in keys:
		var tile: Vector3i = _cells[cell]
		list.append_array(PackedInt32Array([cell.x, cell.y, tile.x, tile.y, tile.z]))
	var saved: Dictionary = _cells.duplicate()
	data = list
	_cells = saved
	_loaded = true


func _load() -> void:
	if _loaded:
		return
	_loaded = true
	_cells.clear()
	for i: int in range(0, data.size() - 4, 5):
		_cells[Vector2i(data[i], data[i + 1])] = Vector3i(data[i + 2], data[i + 3], data[i + 4])
