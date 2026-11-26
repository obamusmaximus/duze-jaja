class_name CoverageMap
extends Node
## Coverage (`docs/mechanics/vision.md`, "Coverage"): which ground one team's units and sensors watch. A grid of cells
## that cuts each terrain chunk into `coverage_per_chunk` blocks a side, each into `coverage_detail` cells a side; a cell
## is watched when a unit or sensor of the team would detect a standing target of signature 1 at its centre (`Vision.sees_point`). It only describes the ground:
## detection never reads it. Simulation: it reads positions, sensors and terrain and changes nothing.
## A sweep runs on a worker thread, at most one per `coverage_interval`, into its own buffer, and is published on the
## main thread when done, so a view never reads half a sweep. It checks each block's centre first, then cell by cell only
## in blocks whose answer differs from a neighbour's (the edge of watched ground); the rest take their block's answer.
## A sweep's observers are copied as data at its start (units may die during it) and listed per chunk, so a point only
## asks those that could reach its chunk.

## A new sweep was published, or the grid was remade (then `texture` is null until its first sweep ends).
signal changed

## Which team's coverage this is.
var team: int = 0
## Side of one cell, metres.
var cell: float = 0.0
## Side of one block (the first, coarse pass; the drawn wireframe's squares), metres.
var block: float = 0.0
## Cells across x and z.
var cells: Vector2i = Vector2i.ZERO
## The grid's corner (world x, z): the terrain's, so cells line up with its chunks.
var origin: Vector2 = Vector2.ZERO
## The last complete sweep, one R8 texel per cell (1 watched, 0 not), or null before the first.
var texture: ImageTexture
## The same sweep as bytes (255 watched), row by row.
var watched: PackedByteArray = PackedByteArray()
## Complete sweeps so far, total microseconds spent on the main thread and on the worker (tests and measuring read
## them).
var sweeps: int = 0
var step_usec: int = 0
var sweep_usec: int = 0

## The texture of the sweep before the last, reused for the next one.
var _spare: ImageTexture
var _vision: Vision
var _registry: UnitRegistry
var _heights: TerrainHeights
var _chunk_cells: int = 32
var _stats: VisionStats
var _per_chunk: int = 0
var _detail: int = 0
var _blocks: Vector2i = Vector2i.ZERO
var _chunks: Vector2i = Vector2i.ZERO
## The running sweep's task (-1: none). While it runs, only the worker touches the sweep's data below.
var _task: int = -1
var _building: PackedByteArray = PackedByteArray()
## Seconds until the next sweep may start.
var _wait: float = 0.0
## This sweep's observers, by index: where each looks from and its range against signature 1.
var _eyes: PackedVector3Array = PackedVector3Array()
var _reaches: PackedFloat32Array = PackedFloat32Array()
## Per chunk (row by row), the indices of the observers whose range can touch it.
var _near: Array[Array] = []
## The observer that watched the last watched point: neighbours are mostly its too, so it is asked first.
var _last: int = -1


## Makes the grid of `heights` for team `owner`, cut from chunks of `chunk_cells` terrain cells a side.
func setup(vision: Vision, registry: UnitRegistry, heights: TerrainHeights, chunk_cells: int, stats: VisionStats,
		owner: int) -> void:
	_vision = vision
	_registry = registry
	_heights = heights
	_chunk_cells = chunk_cells
	_stats = stats
	team = owner
	process_physics_priority = -80 # After vision has checked this tick.
	_stats.changed.connect(_on_stats_changed)
	_rebuild()


## Whether the last complete sweep watched the ground at `point` (world x, z). False off the grid.
func is_watched(point: Vector2) -> bool:
	var at := Vector2i(((point - origin) / cell).floor())
	if watched.is_empty() or at.x < 0 or at.y < 0 or at.x >= cells.x or at.y >= cells.y:
		return false
	return watched[at.y * cells.x + at.x] != 0


func _physics_process(delta: float) -> void:
	if _heights == null:
		return
	var started: int = Time.get_ticks_usec()
	_wait -= delta
	if _task >= 0:
		if WorkerThreadPool.is_task_completed(_task):
			_finish_task()
			_publish()
	elif _wait <= 0.0:
		_wait = _stats.coverage_interval
		_begin_sweep()
		# Heights decode on their first read, which isn't thread-safe: read once here.
		_heights.height_at(origin.x, origin.y)
		_task = WorkerThreadPool.add_task(_sweep, false, "coverage sweep")
	step_usec += Time.get_ticks_usec() - started


func _exit_tree() -> void:
	_finish_task()


## Waits for the running sweep, if any (every task must be waited for once).
func _finish_task() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _on_stats_changed() -> void:
	if _stats.coverage_per_chunk != _per_chunk or _stats.coverage_detail != _detail:
		_rebuild()


## Makes the grid from the terrain and the settings; the next tick starts its first sweep.
func _rebuild() -> void:
	if _heights == null:
		return
	_finish_task()
	_per_chunk = _stats.coverage_per_chunk
	_detail = _stats.coverage_detail
	block = _heights.spacing * float(_chunk_cells) / float(_per_chunk)
	cell = block / float(_detail)
	origin = _heights.origin
	var span: Vector2 = _heights.bounds().size
	_blocks = Vector2i(maxi(ceili(span.x / block), 1), maxi(ceili(span.y / block), 1))
	cells = _blocks * _detail
	_chunks = Vector2i(ceili(float(_blocks.x) / _per_chunk), ceili(float(_blocks.y) / _per_chunk))
	_building = PackedByteArray()
	_building.resize(cells.x * cells.y)
	_wait = 0.0
	watched = PackedByteArray()
	texture = null
	_spare = null
	changed.emit()


## Copies this sweep's observers (the team's living units and its sensors) and lists them by chunk.
func _begin_sweep() -> void:
	_eyes.clear()
	_reaches.clear()
	_near.resize(_chunks.x * _chunks.y)
	for i: int in _near.size():
		_near[i] = []
	_last = -1
	for sensor: VisionSensor in _vision.sensors():
		if sensor.team == team:
			_add_observer(sensor.eye(), sensor.reach())
	for unit: Unit in _registry.all_units():
		if unit.alive and unit.team == team:
			_add_observer(_vision.eye_of(unit), _vision.reach_of(unit))


func _add_observer(eye: Vector3, reach: float) -> void:
	var index: int = _eyes.size()
	_eyes.append(eye)
	_reaches.append(reach)
	# The farthest it can see a signature-1 target: with the whole height bonus, up to the cap.
	var radius: float = minf(reach * (1.0 + _stats.height_bonus), _stats.max_detect_range)
	var at := Vector2(eye.x, eye.z)
	var side: float = block * _per_chunk
	var low := Vector2i(((at - Vector2(radius, radius) - origin) / side).floor())
	var high := Vector2i(((at + Vector2(radius, radius) - origin) / side).floor())
	for cz: int in range(maxi(low.y, 0), mini(high.y, _chunks.y - 1) + 1):
		for cx: int in range(maxi(low.x, 0), mini(high.x, _chunks.x - 1) + 1):
			var corner: Vector2 = origin + Vector2(cx, cz) * side
			if at.distance_squared_to(at.clamp(corner, corner + Vector2(side, side))) <= radius * radius:
				_near[cz * _chunks.x + cx].append(index)


## Worker thread: fills `_building`, the blocks first, then the cells of the blocks on the edge of watched ground.
func _sweep() -> void:
	var started: int = Time.get_ticks_usec()
	var coarse := PackedByteArray()
	coarse.resize(_blocks.x * _blocks.y)
	for row: int in _blocks.y:
		for column: int in _blocks.x:
			var centre: Vector2 = origin + Vector2(column + 0.5, row + 0.5) * block
			coarse[row * _blocks.x + column] = 255 if _watches(centre, column, row) else 0
	for row: int in _blocks.y:
		for column: int in _blocks.x:
			var value: int = coarse[row * _blocks.x + column]
			var refine: bool = _detail > 1 and _on_edge(coarse, column, row)
			for z: int in range(row * _detail, (row + 1) * _detail):
				for x: int in range(column * _detail, (column + 1) * _detail):
					if refine:
						value = 255 if _watches(origin + Vector2(x + 0.5, z + 0.5) * cell, column, row) else 0
					_building[z * cells.x + x] = value
	sweep_usec += Time.get_ticks_usec() - started


## Whether any of the eight blocks around block (`column`, `row`) answered differently from it.
func _on_edge(coarse: PackedByteArray, column: int, row: int) -> bool:
	var value: int = coarse[row * _blocks.x + column]
	for z: int in range(maxi(row - 1, 0), mini(row + 2, _blocks.y)):
		for x: int in range(maxi(column - 1, 0), mini(column + 2, _blocks.x)):
			if coarse[z * _blocks.x + x] != value:
				return true
	return false


## Whether any of this sweep's observers watches the ground at `point` (world x, z), in block (`column`, `row`).
func _watches(point: Vector2, column: int, row: int) -> bool:
	var near: Array = _near[(row / _per_chunk) * _chunks.x + column / _per_chunk]
	if near.is_empty():
		return false
	# The sea hides the seabed: watch its surface.
	var look := Vector3(point.x, maxf(_heights.height_at(point.x, point.y), MapGrid.SEA_LEVEL) + _stats.eye_lift,
			point.y)
	if _last >= 0 and _vision.sees_point(_reaches[_last], _eyes[_last], look, 1.0):
		return true
	for index: int in near:
		if index != _last and _vision.sees_point(_reaches[index], _eyes[index], look, 1.0):
			_last = index
			return true
	return false


func _publish() -> void:
	watched = _building.duplicate()
	var image := Image.create_from_data(cells.x, cells.y, false, Image.FORMAT_R8, watched)
	# Two textures take turns, so the view can fade from the last sweep to this one.
	var next: ImageTexture = _spare
	if next == null:
		next = ImageTexture.create_from_image(image)
	else:
		next.update(image)
	_spare = texture
	texture = next
	sweeps += 1
	changed.emit()
