# Plan: build the level on more CPU cores

Goal: a shorter atoll load by running the map's build stages in parallel with `WorkerThreadPool`. One step per session. Delete this file once built.

**Read:** `docs/mechanics/heightmap.md`, `pathing.md` (MapGrid, land regions), `water.md` (shore field); `levels/atoll/atoll_level.gd`, `levels/sandbox/sandbox.gd`, `terrain/terrain_chunks.gd`, `terrain_chunk_mesh.gd`, `terrain_light.gd`, `terrain_heights.gd`, `map/map_grid.gd`, `water/shore_field.gd`.

## Starting point
The cheaper work is done: decoded heights are cached in `TerrainHeights`, wholly submerged chunks get no meshes, and the grid and shore loops are tightened. Check `git status` first: if that work is still uncommitted, work in the main checkout, because a fresh worktree won't have it.

Headless M1 with the editor open and other work running, so treat these as rough. Level added to playable: about 4.9 s (three runs), 5.7 s in the run that timed the stages below on their own.

| Stage | Time | Needs |
|---|---|---|
| Heightmap PNG decode | 0.9 s | nothing; everything else needs it |
| Terrain light bake | 0.9 s | heights |
| Chunk meshes (drawn chunks) | 0.9 s | heights, light |
| Shore field | 0.8 s | heights |
| Map grid (area scan, sample, walkability, regions) | 1.1 s | heights |
| War table | 0.2 s | heights |

After the decode, three chains don't depend on each other: **light then meshes**, **shore**, **grid**. If they overlap well, the load should drop by roughly 1.5 to 2.5 s. This is an estimate, which step 1 tests.

## Hazards
- **Height cache:** `TerrainHeights` decodes on the first read, which isn't thread-safe. Decode on the main thread before starting any task (add a `prepare()` for it). Nothing may write heights while tasks run: set up the brush and the reloader after they finish.
- **Don't split the light bake.** A partial `bake(area)` only looks `light_reach` upstream (and pads the other axis to match), while the full bake carries shadows from the map's edge, so bands would change the shadows and could leave seams. Run it as one task. It also writes a member array, so nothing may read `color_at` until it has finished.
- **`WorldMaterials.role()`** fills a static dictionary on first use. Workers must not call it, which affects `TerrainChunkMesh.build` and `WarTableMesh`.
- **Engine objects:** have workers return plain data (packed arrays, bytes). Make `ArrayMesh`, `ImageTexture`, `HeightMapShape3D` and nodes, assign materials and emit signals on the main thread.
- **`MapGrid.build`** sets `_built` before sampling and emits `cells_changed` at the end. While it runs on a worker, nothing else may touch the grid or its `astar`; `is_built()` must stay false until the main thread publishes the result. Only the heightmap path (`terrain` set) can leave the main thread: the ray path uses the physics space.
- **No nested waits:** don't wait for a group task from inside a pool task. Start tasks and groups from the main thread and wait there.
- **Tunables** are read by workers. Nothing may change a stats resource during the build.
- **Edits stay as they are.** The budgeted chunk rebuild, grid resample and shore re-bake during a match are out of scope.

## Steps
- [x] **1. Measure the speed-up first.** Done; **the mesh gate failed**, so step 2 was built without a mesh group (the user agreed). The split is in (`TerrainChunkMesh.arrays()` pure, `make_mesh()` main thread), chunk output unchanged.

### Step 1 results
Headless M1 (8 cores, 4 of them performance), editor open, load average 4 to 5. Medians of 10 runs on the loaded atoll: 120 drawn chunks, 240 meshes. Every threaded result (arrays, light, shore, grid) matched the serial one, 0 mismatches.

| Chunk meshes, pure part (the `ArrayMesh` step adds 19 ms) | Time | Speed-up |
|---|---|---|
| serial | 789 ms | |
| group, 2 / 3 tasks | 690 / 595 ms | 1.1x / 1.3x |
| group, 4 tasks (best) | 552 ms | 1.4x |
| group, 5 / 6 / 8 tasks (8 is the default) | 692 / 729 / 773 ms | 1.0x to 1.1x |
| control, pure arithmetic: serial, 4, 8 tasks | 391, 112, 87 ms | 3.5x, 4.5x |

The machine and pool scale; this code doesn't. Likely cause (not tested): the temporary arrays each triangle allocates.

| Chains | Time |
|---|---|
| shore alone, grid alone | 795, 1099 ms |
| shore and grid side by side (**overlaps well**) | 1192 ms (shore 877, grid 1192 inside it) |
| light, meshes, shore, grid, all serial | 3358 ms |
| step 2 shape, mesh group at 8 tasks | 1745 ms |
| three tasks (light then serial meshes; shore; grid), `make_mesh` on main | 1740 ms |

So without any mesh group, running the three chains side by side saves about 1.6 s of these stages. A whole level load was not timed. Step 2 uses that shape.

**Priority:** pass `high_priority = true` to `add_task`; low-priority tasks only get a share of the pool's threads (`low_priority_thread_ratio`), so the chains might not all run at once.

- [x] **2. Parallel build, still blocking.** Built: `LevelBuild` (`levels/atoll/level_build.gd`) runs three tasks (ground light then chunk arrays; shore; grid), each stage split into a main-thread start, a worker-safe `compute()` and a main-thread finish. `_ready` still blocks; the grid is published on the first physics tick. `BattlefieldStats.threaded_load` off (or one core) runs the chains in turn.

### Step 2 results
Same machine and session, one load per process, medians of 10. Before the change (load average 4.5 to 6.8): level added to playable 4881 ms. After, serial and threaded runs alternating (load average 4.5 to 8):

| | serial | threaded |
|---|---|---|
| level added to playable | 4730 ms | 3115 ms (**1.6 s shorter**) |
| of which blocked in `add_child` | 4505 ms | 2890 ms |
| readout's grid time (compute and publish) | 1075 ms | 1330 ms |

20 threaded and 3 serial loads matched the pre-change output exactly: grid cells, heights, solids, region labels, shore image and texture, light, chunk mesh arrays, collision shapes, unit count; no script or thread errors. A windowed run drew the terrain with no errors or warnings.

- [ ] **3. Loading screen (ask the user first).** Await task completion across frames instead of blocking, and show progress. This is the riskier step: the level, HUD, camera, views and debug tools assume everything exists after `_ready`. The simulation must not tick until the whole load is done, so it starts from the same state every time. Add a `loaded` signal, make headless harnesses wait for it, and note that in `docs/testing.md`. UI follows `docs/mechanics/ui.md`.

## Checks (for changes to the build)
Keep harnesses out of the project (`docs/testing.md`). Before changing code, save from a loaded atoll: the grid's `_walkable`, `_blocked`, `_heights`, `astar` solids and region labels; the shore image bytes; and each chunk's vertex and colour arrays. After the change they must be identical, since only the order of work changes. Compare repeated runs (at least 10), because races show up only sometimes. Time before and after in the same session, with `uptime` noted, since other sessions' tests can make timings several times slower. Run the game in a window and check for errors and missing terrain.

## Not in this plan
- **PNG decode:** row filters depend on the row above, so it stays serial. Removing it means caching the decoded map on disk.
- **A disk cache** of baked results: a separate decision, with invalidation to design while the map is still being painted and tuned.
