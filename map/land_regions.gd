class_name LandRegions
extends RefCounted
## Land regions (`docs/mechanics/pathing.md`, "Land regions"): every walkable cell carries the id of its connected land
## mass (4-connected, like the path search's straight steps; 0 for a cell that isn't walkable). An order to another
## region is refused at once instead of searching across the sea. `label_all` labels a whole grid now (the build);
## after a map change `restart` + `step` relabel the grid in budgeted slices off a snapshot of the walkable bytes, and
## swap the labels in when done, so the live labels are stale (never half-built) meanwhile. Simulation.

## Region id per cell, row by row; 0 where nothing walkable is. Ids are only comparable within one labelling.
var labels := PackedInt32Array()
## Number of regions in `labels`.
var count: int = 0
## Whether a relabel is in progress.
var running: bool = false

var _size: Vector2i = Vector2i.ZERO
var _walkable := PackedByteArray()
var _next := PackedInt32Array()
var _stack := PackedInt32Array()
var _scan: int = 0
var _next_id: int = 0


## The region of `cell` (0 for none or out of range).
func region_at(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= _size.x or cell.y >= _size.y or labels.is_empty():
		return 0
	return labels[cell.y * _size.x + cell.x]


## Labels the whole grid now.
func label_all(walkable: PackedByteArray, size: Vector2i) -> void:
	restart(walkable, size)
	while running:
		step(1 << 30)


## Starts a relabel from a snapshot of `walkable` (any pass in progress is dropped).
func restart(walkable: PackedByteArray, size: Vector2i) -> void:
	_size = size
	_walkable = walkable
	_next = PackedInt32Array()
	_next.resize(size.x * size.y)
	_stack = PackedInt32Array()
	_scan = 0
	_next_id = 0
	running = true


## Visits up to `budget` cells. When every cell is done the new labels replace the old ones.
func step(budget: int) -> void:
	if not running:
		return
	var total: int = _size.x * _size.y
	var width: int = _size.x
	var visited: int = 0
	while visited < budget:
		if _stack.is_empty():
			while _scan < total and (_walkable[_scan] == 0 or _next[_scan] != 0):
				_scan += 1
				visited += 1
			if _scan >= total:
				labels = _next
				count = _next_id
				_walkable = PackedByteArray()
				running = false
				return
			_next_id += 1
			_next[_scan] = _next_id
			_stack.append(_scan)
			if visited >= budget:
				return
		var index: int = _stack[_stack.size() - 1]
		_stack.resize(_stack.size() - 1)
		visited += 1
		var x: int = index % width
		if x > 0 and _walkable[index - 1] == 1 and _next[index - 1] == 0:
			_next[index - 1] = _next_id
			_stack.append(index - 1)
		if x < width - 1 and _walkable[index + 1] == 1 and _next[index + 1] == 0:
			_next[index + 1] = _next_id
			_stack.append(index + 1)
		if index >= width and _walkable[index - width] == 1 and _next[index - width] == 0:
			_next[index - width] = _next_id
			_stack.append(index - width)
		if index + width < total and _walkable[index + width] == 1 and _next[index + width] == 0:
			_next[index + width] = _next_id
			_stack.append(index + width)
