class_name MapGrid
extends Node
## The map model (GAME_DESIGN.md, "Pathing"): the map area cut into square cells, each with its ground height and
## whether it is passable. For paths, blocked cells grow by `path_clearance`, so paths keep off walls and every path
## check is a plain cell lookup. Built at load by sampling the ground (rays down on the World layer). The map changes
## during a match through `set_blocked()` (obstacles) and `resample()` (terrain height); each rebuilds only the cells
## it touches and emits `cells_changed`. Paths run on `astar` (the engine's AStarGrid2D, jump-point search).
## Simulation. A playtest probe (event `map_change`).

## Cells inside `area` (world x, z) changed. `opened` when ground may have become passable (shorter paths possible).
signal cells_changed(area: Rect2, opened: bool)
signal playtest_event(event: StringName, data: Dictionary)

const WORLD_MASK: int = 1 << 0
const RAY_TOP: float = 1000.0
const RAY_BOTTOM: float = -1000.0

@export var stats: MapStats

## The open air over the whole map: where flyers move (no cells, paths or regions).
var air := AirLayer.new(self)

## One point per cell, solid where paths may not go (clearance included). Read-only outside this class.
var astar := AStarGrid2D.new()
## The map area (world x, z).
var bounds: Rect2
## Cells across x and z.
var size: Vector2i = Vector2i.ZERO
var cell_size: float = 1.0

## Heightmap data to read the ground from instead of casting rays at colliders (null: rays). Heights below the sea level
## are no ground, so the grid stays land only.
var terrain: TerrainHeights
var _heights := PackedFloat32Array()
## 1 where the ground is too steep (or missing), or an obstacle covers the cell.
var _blocked := PackedByteArray()
## 1 where paths may go: not blocked and clear of blocked cells by the clearance. Mirrors `astar`'s solids for fast
## reads.
var _walkable := PackedByteArray()
## How many cells blocked cells grow by for paths.
var _clearance_cells: int = 1
## Obstacle areas (world x, z) blocking the cells they cover. Kept as areas so a rebuild can re-apply them.
var _obstacles: Array[Rect2] = []
var _built: bool = false
## How many obstacles `compute()` had.
var _computed_obstacles: int = 0
## The settings the grid was built with: cell size, slope limit, clearance.
var _built_shape := Vector3.ZERO
var _rebuild_pending: bool = false
## The connected land masses (`LandRegions`): relabelled after every map change.
var regions := LandRegions.new()


func _ready() -> void:
	add_to_group(&"map_grid")
	add_to_group(&"playtest_probe")
	stats.changed.connect(_on_stats_changed)


func is_built() -> bool:
	return _built


## Builds the whole grid over `area` from the ground under it. Call on a physics tick (the level does, after load).
func build(area: Rect2) -> void:
	compute(area)
	publish()


## The first part of `build()`: samples the ground and labels the regions. With `terrain` set it uses no physics, so it
## may run on a worker thread (after `TerrainHeights.prepare()`); then nothing else may touch the grid until it returns.
## The grid stays unbuilt until `publish()`.
func compute(area: Rect2) -> void:
	_built = false
	bounds = area
	cell_size = stats.cell_size
	_built_shape = Vector3(stats.cell_size, stats.max_slope_deg, stats.path_clearance)
	size = Vector2i(ceili(area.size.x / cell_size), ceili(area.size.y / cell_size))
	var count: int = size.x * size.y
	_heights.resize(count)
	_blocked.resize(count)
	_walkable.resize(count)
	_clearance_cells = ceili(stats.path_clearance / cell_size - 0.001)
	astar.region = Rect2i(Vector2i.ZERO, size)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.jumping_enabled = true
	astar.update()
	var all := Rect2i(Vector2i.ZERO, size)
	_computed_obstacles = _obstacles.size()
	_sample(all)
	_refresh(all)
	regions.label_all(_walkable, size)


## The second part, on the main thread: the grid is now built and says so.
func publish() -> void:
	# An obstacle or a shape setting may have changed since `compute()`.
	if _obstacles.size() != _computed_obstacles:
		_refresh(Rect2i(Vector2i.ZERO, size))
		regions.label_all(_walkable, size)
	_built = true
	_on_stats_changed()
	cells_changed.emit(bounds, true)


## Blocks (or unblocks) the cells under `area` (world x, z): walls, buildings, closing gates. Unblocking removes one
## earlier block of exactly that area.
func set_blocked(area: Rect2, blocked: bool) -> void:
	if blocked:
		_obstacles.append(area)
	else:
		_obstacles.erase(area)
	if not _built:
		return
	_refresh(_cells_in(area))
	regions.restart(_walkable, size)
	cells_changed.emit(area, not blocked)
	playtest_event.emit(&"map_change", {"area": [area.position, area.end], "blocked": blocked})


## Re-reads the ground height under `area` (world x, z) after the terrain changed there.
func resample(area: Rect2) -> void:
	if not _built:
		return
	var cells: Rect2i = _cells_in(area).grow(1).intersection(astar.region)
	_sample(cells)
	_refresh(cells)
	regions.restart(_walkable, size)
	cells_changed.emit(area, true)
	playtest_event.emit(&"map_change", {"area": [area.position, area.end], "resampled": true})


func cell_of(point: Vector3) -> Vector2i:
	return _cell_of_2d(Vector2(point.x, point.z)).clamp(Vector2i.ZERO, size - Vector2i.ONE)


## The middle of `cell` on the ground.
func cell_center(cell: Vector2i) -> Vector3:
	var height: float = _heights[_index(cell)]
	return Vector3(
		bounds.position.x + (cell.x + 0.5) * cell_size, height if is_finite(height) else 0.0,
		bounds.position.y + (cell.y + 0.5) * cell_size)


## Height of the sea (world y). Ground under the sea is lower, so flyers measure from here instead.
const SEA_LEVEL: float = 0.0


## The ground height under `point` (its cell's height, at least the sea level). Flyers use it for altitude.
func ground_height(point: Vector3) -> float:
	if not _built:
		return SEA_LEVEL
	var cell: Vector2i = cell_of(point)
	var height: float = _heights[_index(cell)]
	return maxf(height, SEA_LEVEL) if is_finite(height) else SEA_LEVEL


## The ground height under `point`, blended between the neighbouring cell centres so a walking unit rides ramps
## smoothly (cells without ground are skipped). Unlike `ground_height` it is not raised to sea level.
func surface_height(point: Vector3) -> float:
	if not _built:
		return point.y
	var fx: float = (point.x - bounds.position.x) / cell_size - 0.5
	var fz: float = (point.z - bounds.position.y) / cell_size - 0.5
	var x0: int = floori(fx)
	var z0: int = floori(fz)
	var tx: float = fx - x0
	var tz: float = fz - z0
	var centre: float = _heights[_index(cell_of(point))]
	if not is_finite(centre):
		return 0.0
	var sum: float = 0.0
	var weight: float = 0.0
	for dz: int in 2:
		for dx: int in 2:
			var cell := Vector2i(clampi(x0 + dx, 0, size.x - 1), clampi(z0 + dz, 0, size.y - 1))
			var height: float = _heights[_index(cell)]
			if is_finite(height):
				var w: float = (tx if dx == 1 else 1.0 - tx) * (tz if dz == 1 else 1.0 - tz)
				sum += height * w
				weight += w
	return sum / weight if weight > 0.0 else centre


## The land region of the walkable cell nearest `point`, looking up to `rings` cells out; 0 when none is there.
func region_at_point(point: Vector3, rings: int = 6) -> int:
	if not _built:
		return 0
	var cell: Vector2i = nearest_walkable(cell_of(point), rings)
	return regions.region_at(cell) if cell.x >= 0 else 0


func is_walkable(cell: Vector2i) -> bool:
	return _built and cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y \
		and _walkable[cell.y * size.x + cell.x] == 1


## Whether the cell itself is blocked (ignoring clearance).
func is_blocked(cell: Vector2i) -> bool:
	return _built and astar.is_in_boundsv(cell) and _blocked[_index(cell)] == 1


## `cell` if walkable, else the nearest walkable cell within `max_rings` rings, else Vector2i(-1, -1).
func nearest_walkable(cell: Vector2i, max_rings: int = 24) -> Vector2i:
	if is_walkable(cell):
		return cell
	for ring: int in range(1, max_rings + 1):
		var best := Vector2i(-1, -1)
		var best_distance: int = 1 << 30
		for i: int in range(-ring, ring + 1):
			for other: Vector2i in [cell + Vector2i(i, -ring), cell + Vector2i(i, ring), cell + Vector2i(-ring, i),
					cell + Vector2i(ring, i)]:
				var distance: int = (other - cell).length_squared()
				if distance < best_distance and is_walkable(other):
					best = other
					best_distance = distance
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)


## Whether a unit can go straight from `from` to `to`: every cell the line passes through is walkable (clearance is
## built into the cells). Visits each cell once (grid traversal), so long lines stay cheap.
func line_walkable(from: Vector3, to: Vector3) -> bool:
	if not _built:
		return true
	var start := Vector2((from.x - bounds.position.x) / cell_size, (from.z - bounds.position.y) / cell_size)
	var end := Vector2((to.x - bounds.position.x) / cell_size, (to.z - bounds.position.y) / cell_size)
	var cell := Vector2i(floori(start.x), floori(start.y))
	var last := Vector2i(floori(end.x), floori(end.y))
	var line: Vector2 = end - start
	var step := Vector2i(1 if line.x > 0.0 else -1, 1 if line.y > 0.0 else -1)
	var t_delta := Vector2(absf(1.0 / line.x) if line.x != 0.0 else INF, absf(1.0 / line.y) if line.y != 0.0 else INF)
	var t_max := Vector2(
		((cell.x + (1 if step.x > 0 else 0)) - start.x) / line.x if line.x != 0.0 else INF,
		((cell.y + (1 if step.y > 0 else 0)) - start.y) / line.y if line.y != 0.0 else INF)
	var guard: int = absi(last.x - cell.x) + absi(last.y - cell.y) + 2
	while guard > 0:
		guard -= 1
		if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y or _walkable[cell.y * size.x + cell.x] == 0:
			return false
		if cell == last:
			return true
		if t_max.x < t_max.y:
			t_max.x += t_delta.x
			cell.x += step.x
		else:
			t_max.y += t_delta.y
			cell.y += step.y
	return true


## Whether the segment `a`-`b` (x, z) touches `area`.
static func segment_hits_rect(a: Vector2, b: Vector2, area: Rect2) -> bool:
	if area.has_point(a) or area.has_point(b):
		return true
	var corners: Array[Vector2] = [area.position, Vector2(area.end.x, area.position.y), area.end,
		Vector2(area.position.x, area.end.y)]
	for i: int in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false


func _sample(cells: Rect2i) -> void:
	if terrain != null:
		_sample_data(cells)
		return
	var space: PhysicsDirectSpaceState3D = get_viewport().world_3d.direct_space_state
	var query := PhysicsRayQueryParameters3D.new()
	query.collision_mask = WORLD_MASK
	for y: int in range(cells.position.y, cells.end.y):
		for x: int in range(cells.position.x, cells.end.x):
			var centre := Vector2(bounds.position.x + (x + 0.5) * cell_size, bounds.position.y + (y + 0.5) * cell_size)
			query.from = Vector3(centre.x, RAY_TOP, centre.y)
			query.to = Vector3(centre.x, RAY_BOTTOM, centre.y)
			var hit: Dictionary = space.intersect_ray(query)
			_heights[y * size.x + x] = (hit["position"] as Vector3).y if not hit.is_empty() else NAN


## Reads the ground height of `cells` from the heightmap data: no ray, no wait for physics.
func _sample_data(cells: Rect2i) -> void:
	for y: int in range(cells.position.y, cells.end.y):
		var z: float = bounds.position.y + (y + 0.5) * cell_size
		for x: int in range(cells.position.x, cells.end.x):
			var height: float = terrain.height_at(bounds.position.x + (x + 0.5) * cell_size, z)
			_heights[y * size.x + x] = height if height >= SEA_LEVEL else NAN


## Recomputes what is blocked in `cells` (and their rim, whose slope depends on them), then path walkability
## (blocked grown by the clearance) around them.
func _refresh(cells: Rect2i) -> void:
	var near: Rect2i = cells.grow(1).intersection(astar.region)
	_mark_blocked(near)
	_mark_walkable(near.grow(_clearance_cells).intersection(astar.region))


## A cell is blocked with no ground, a step to a neighbour steeper than the slope limit, or an obstacle over it. A
## neighbour with no ground (NAN) never counts as steep: no comparison with NAN is true.
func _mark_blocked(cells: Rect2i) -> void:
	var max_step: float = cell_size * tan(deg_to_rad(stats.max_slope_deg))
	var width: int = size.x
	var last: Vector2i = size - Vector2i.ONE
	var has_obstacles: bool = not _obstacles.is_empty()
	for y: int in range(cells.position.y, cells.end.y):
		for x: int in range(cells.position.x, cells.end.x):
			var i: int = y * width + x
			var height: float = _heights[i]
			var blocked: bool = not is_finite(height) \
					or (x > 0 and absf(height - _heights[i - 1]) > max_step) \
					or (x < last.x and absf(height - _heights[i + 1]) > max_step) \
					or (y > 0 and absf(height - _heights[i - width]) > max_step) \
					or (y < last.y and absf(height - _heights[i + width]) > max_step)
			if not blocked and has_obstacles:
				blocked = _is_covered(Vector2i(x, y))
			_blocked[i] = 1 if blocked else 0


## Sets walkability in `cells`: a cell is not walkable with a blocked cell within the clearance (a square). Two
## passes, along rows and then along columns, each remembering the last blocked cell it met, so the cost does not grow
## with the clearance. `astar` takes each row in runs of equal cells, far fewer calls than one per cell.
func _mark_walkable(cells: Rect2i) -> void:
	if not cells.has_area():
		return
	var k: int = _clearance_cells
	var reach: int = k * 2
	var width: int = size.x
	# Rows the column pass reads: `cells` and the clearance above and below.
	var top: int = maxi(cells.position.y - k, 0)
	var bottom: int = mini(cells.end.y + k, size.y)
	# Per cell of those rows, over the columns of `cells`: 1 with a blocked cell within `k` along its row.
	var near_in_row := PackedByteArray()
	near_in_row.resize(cells.size.x * (bottom - top))
	for y: int in range(top, bottom):
		var row: int = y * width
		var out: int = (y - top) * cells.size.x - cells.position.x
		var last: int = -width - reach
		for x: int in range(maxi(cells.position.x - k, 0), mini(cells.position.x + k, width)):
			if _blocked[row + x] == 1:
				last = x
		for x: int in range(cells.position.x, cells.end.x):
			var ahead: int = x + k
			if ahead < width and _blocked[row + ahead] == 1:
				last = ahead
			near_in_row[out + x] = 1 if last >= x - k else 0
	# The same down the columns, walked row by row: `seen` is the last row with a hit, per column.
	var seen := PackedInt32Array()
	seen.resize(cells.size.x)
	seen.fill(-size.y - reach)
	for y: int in range(top, mini(cells.position.y + k, bottom)):
		var from: int = (y - top) * cells.size.x
		for c: int in cells.size.x:
			if near_in_row[from + c] == 1:
				seen[c] = y
	for y: int in range(cells.position.y, cells.end.y):
		var ahead: int = y + k
		if ahead < bottom:
			var from: int = (ahead - top) * cells.size.x
			for c: int in cells.size.x:
				if near_in_row[from + c] == 1:
					seen[c] = ahead
		var row: int = y * width
		var run_start: int = cells.position.x
		var run_clear: bool = seen[0] < y - k
		for c: int in cells.size.x:
			var x: int = cells.position.x + c
			var clear: bool = seen[c] < y - k
			_walkable[row + x] = 1 if clear else 0
			if clear != run_clear:
				astar.fill_solid_region(Rect2i(run_start, y, x - run_start, 1), not run_clear)
				run_start = x
				run_clear = clear
		astar.fill_solid_region(Rect2i(run_start, y, cells.end.x - run_start, 1), not run_clear)


func _is_covered(cell: Vector2i) -> bool:
	if _obstacles.is_empty():
		return false
	var square := Rect2(bounds.position + Vector2(cell) * cell_size, Vector2.ONE * cell_size)
	for area: Rect2 in _obstacles:
		if square.intersects(area):
			return true
	return false


func _cells_in(area: Rect2) -> Rect2i:
	var first: Vector2i = _cell_of_2d(area.position)
	var last: Vector2i = _cell_of_2d(area.end)
	return Rect2i(first, last - first + Vector2i.ONE).intersection(astar.region)


func _cell_of_2d(point: Vector2) -> Vector2i:
	return Vector2i(floori((point.x - bounds.position.x) / cell_size), floori((point.y - bounds.position.y) / cell_size))


func _index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


## A changed cell size, slope limit or clearance needs a full rebuild, done on the next physics tick.
func _on_stats_changed() -> void:
	var shape := Vector3(stats.cell_size, stats.max_slope_deg, stats.path_clearance)
	if _built and shape != _built_shape:
		_rebuild_pending = true


func _physics_process(_delta: float) -> void:
	if regions.running:
		regions.step(stats.region_cells_per_tick)
	if _rebuild_pending:
		_rebuild_pending = false
		build(bounds)
