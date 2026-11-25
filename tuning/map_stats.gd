class_name MapStats
extends Resource
## Tunable numbers for the map model and pathing (map/), held by the MapGrid and the PathService
## (tuning/map_default.tres). Changing the cell size or slope limit live rebuilds the grid.

@export_group("Grid")
## Side of one map cell, in metres. Smaller is finer paths but more cells to build and search.
@export_range(0.25, 4.0, 0.05) var cell_size: float = 1.0
## Steepest ground a unit can climb, in degrees. Steeper steps between cells block both cells.
@export_range(5.0, 80.0, 1.0) var max_slope_deg: float = 35.0
## How far (metres) paths keep from walls and cliff edges: blocked cells grow by this much for pathing, so units
## don't scrape along walls or cut corners. Gaps narrower than twice this become impassable.
@export_range(0.0, 4.0, 0.05) var path_clearance: float = 0.6

@export_group("Paths")
## Time per physics tick the path service may spend answering requests, in milliseconds. Requests past it wait for
## the next tick, so a big order spreads over a few ticks instead of stalling one.
@export_range(0.1, 10.0, 0.1) var path_budget_ms: float = 2.0
## Requests that start and end in the same areas this wide (metres) as a recent path reuse its middle part instead
## of searching again (a group order mostly shares one search). 0 turns sharing off.
@export_range(0.0, 32.0, 0.5) var path_share_size: float = 8.0

@export_group("Regions")
## Cells per physics tick the land-region relabel after a map change may visit. The labels are stale (an order may
## be let through or refused wrongly) until it finishes: a 1000 x 1000 grid takes about 1.2 M cells, so 60000 is 20 ticks.
@export_range(1000, 1000000, 1000) var region_cells_per_tick: int = 60000
