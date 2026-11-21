# Map grid, pathing and unit movement

How units get around a map that changes. Design: `GAME_DESIGN.md` ("Pathing", "Changing maps"). Tunables: `MapStats` (`tuning/map_default.tres`, Map tab); `UnitStats` "Movement" and "Crowds" (Units tab).

**Scripts:** `map/map_grid.gd`, `map/path_service.gd`; `props/prop.gd` (blocks its footprint, see `props.md`); `units/unit_navigator.gd`, `unit_movement.gd`, `unit_spatial_hash.gd` (in `unit_registry.gd`); debug: `debug/map_wall/map_wall.gd`, `debug/map_view/map_grid_view.gd`.

## How it works
- **`MapGrid`** (the map model): the map area in cells of `cell_size`, each with a ground height and blocked or not. The level builds it on its first physics tick (`build(area)`, rays down on layer 1). A cell is blocked when the height step to a side neighbour is steeper than `max_slope_deg` (both sides of a cliff), or when an obstacle covers it. For paths, blocked cells grow by `path_clearance`, so paths keep off walls and every path check is a cell lookup. One clearance serves every unit size for now.
- **Map changes:** `set_blocked(area, blocked)` (obstacles, kept as areas so a rebuild re-applies them) and `resample(area)` (terrain height) rebuild only the touched cells plus a rim, then emit `cells_changed(area, opened)`. Changing a grid setting in the Map tab rebuilds the whole grid on the next tick.
- **`PathService`:** units ask with `request(from, to, callback)`; answers come on later ticks within `path_budget_ms` per tick. A search is the engine's `AStarGrid2D` with jump-point search and diagonals only past free corners; the path keeps only its turns, then drops every turn a straight line can skip (`line_walkable`, a cell-by-cell grid walk). A blocked goal snaps to the nearest walkable cell; a cut-off goal gets a partial path to the nearest reachable cell. **Shared paths:** a request starting and ending in the same `path_share_size` areas as a recent path reuses its middle when its own ends connect straight, so a group order mostly costs one search. Map changes clear them.
- **`UnitNavigator`** (per unit) follows the path's waypoints and brakes into the final point. **Arrival:** within reach of the goal; or, within `crowd_arrive_distance`, touching a stopped friendly unit between it and the goal (groups settle instead of jostling); or at the end of a partial path. **Stuck:** no progress toward the next waypoint for `stuck_seconds` re-paths, at most twice, then it gives up and counts as arrived. **Map changes:** re-paths when the change touches the rest of its path, or when the map opened up and it is on a detour (path longer than 1.3 times the straight line). `follow(point, reach)` chases a moving target and re-paths at most twice a second.
- **`UnitMovement`:** turns toward the brain's velocity (or wanted facing while standing) at `turn_rate`; speed scales with how far it already faces that way. **Soft collision:** units don't collide with each other (masks 1 and 3 only); they add a separation push from overlapping neighbours (`separation_strength`, `separation_padding`), so moving units nudge idle ones aside and crowds never lock up. Walls and buildings block hard (`move_and_slide`). A unit standing still on the ground skips physics, except every 30th tick to notice ground going away.
- **Neighbour queries:** `UnitRegistry.units_near(point, radius, out)` reads a spatial hash (4 m buckets) rebuilt once per tick before the units move. Callers own `out`, so nothing allocates.
- **Debug:** `debug_toggle_wall` (F3) raises and lowers a 90 m wall across the sandbox (`MapGrid.set_blocked`, World-layer collision). Units caught inside when it rises are pushed out by physics. `debug_show_map_grid` (F4) shows blocked-for-paths cells and the selected units' paths.
- **Probe events:** `map_change` (MapGrid), `repath` (PathService: unit, reason `map_change`, `map_opened`, `stuck`).

## Settled
- Measured headless, 100 units ordered across the map: about 2.8 ms per tick wall time, of which Jolt `move_and_slide` is about 1 ms and separation about 0.7 ms. The order made 42 searches and 139 shared paths, nothing waited in the queue, and all units arrived. A long path onto the plateau costs about 0.16 ms.
- 12 units sent to one point settle in a few seconds, without overlap.

## Tried and passed on
- Path checks sampling half-cells with the unit's radius either side: about 0.4 ms per long line, and the reason long paths cost 2 ms; replaced by clearance built into the cells and a cell-by-cell grid walk.
- Move costs near walls (`AStarGrid2D` weights): jump-point search ignores weights and was worth more (A* about 0.6 ms down to a fraction); clearance does the job of keeping off walls.
- Hard collision between units (layer 2 in the units' mask): crowds jam and push each other around corners; soft separation instead.

## Known issues
- No flow fields: groups use shared paths and formation slots. Revisit only if measurements call for it.
- Wide units (more than about `path_clearance` plus half a cell) can clip walls and corners: one clearance for all sizes.
- Units standing on ground that vanishes or rises: only "pushed out by physics" so far (the debug wall).
