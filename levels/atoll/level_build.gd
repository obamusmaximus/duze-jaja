class_name LevelBuild
extends RefCounted
## The heavy part of a heightmap level's load, run as three chains that don't depend on each other: the ground (light,
## then chunk mesh arrays), the shore field and the map grid. Each chain is one `WorkerThreadPool` task; engine objects
## are made on the main thread. Blocks until all three are done, and nothing may write the heights or a stats resource
## meanwhile. The grid is left unpublished (`MapGrid.publish()`).

## How long the grid chain took, microseconds (for the readout).
var grid_usec: int = 0

var _grid: MapGrid
var _grid_area: Callable


## `chunks` has its sun set, `shore` and `grid` are in the tree and `grid.terrain` is `heights`. `grid_area` returns
## the area the grid covers and must only read. Without `threaded` (or on one core) the chains run in turn.
func run(heights: TerrainHeights, chunks: TerrainChunks, shore: ShoreField, water: WaterStats, grid: MapGrid,
		grid_area: Callable, threaded: bool) -> void:
	_grid = grid
	_grid_area = grid_area
	heights.prepare()
	chunks.begin(heights)
	shore.prepare(heights, water.field_texel, water.field_reach, water.field_settle)
	if not threaded or OS.get_processor_count() < 2:
		chunks.compute()
		chunks.finish()
		shore.compute()
		shore.finish()
		_build_grid()
		return
	# High priority: low-priority tasks only get a share of the pool's threads, so the chains could queue.
	var ground_task: int = WorkerThreadPool.add_task(chunks.compute, true, "Level ground")
	var shore_task: int = WorkerThreadPool.add_task(shore.compute, true, "Level shore")
	var grid_task: int = WorkerThreadPool.add_task(_build_grid, true, "Level map grid")
	WorkerThreadPool.wait_for_task_completion(ground_task)
	chunks.finish()
	WorkerThreadPool.wait_for_task_completion(shore_task)
	shore.finish()
	WorkerThreadPool.wait_for_task_completion(grid_task)


func _build_grid() -> void:
	var started: int = Time.get_ticks_usec()
	_grid.compute(_grid_area.call())
	grid_usec = Time.get_ticks_usec() - started
