# Battlefield level (scale reference)

`levels/atoll/atoll.tscn`, the main scene: a full-size sea with a primitive atoll, a hovering mothership box per team and test units, built to measure what a battlefield costs and to pick the map size (`docs/plans/battlefield.md`, step 1). Tunables: `BattlefieldStats` (`tuning/battlefield_default.tres`, Map tab); the camera uses its own `tuning/camera_atoll.tres` (far zoom).

**Scripts:** `levels/atoll/atoll_level.gd` (extends `SandboxLevel`), `atoll_land.gd`, `mothership_box.gd`; `debug/battlefield/battlefield_readout.gd`.

## How it works
- **`AtollLevel`** sizes everything from the stats: map area (camera bounds, minimap), sea (`WaterBody.set_size`, shore from the land's rectangles), motherships, camera far plane. The **map grid covers only `grid_size`** around the atoll (`SandboxLevel._grid_area()` hook): the sea has no ground, so the grid is land only. A stats edit rebuilds the land, sea and motherships at once and the grid two physics ticks later.
- **`AtollLand`**: one `StaticBody3D` on the World layer: a reef ring of box segments, a big island, six small islands (fractions of the map extent), and a seabed picture with no collision (units can't walk it). Blockout only.
- **`MothershipBox`** (group `mothership_boxes`): hull box and team stripe at `mothership_standoff` from the atoll centre along x (team 0 west, 1 east), no collision, no grid footprint. Replaced by `Mothership` in step 6.
- **`BattlefieldReadout`** (debug): fps, draw calls, map and grid size, grid build time, test-flyer travel time from each mothership to the ring and the big island.
- Test units: `unit_count` troopers and rovers, half per team, on the big island.

## Known issues
- The sea's shore foam uses bounding rectangles of the ring segments, so it is coarse.
- The sea is one dense plane (about 375k vertices at the default extent): step 4 replaces it. GPU cost is read from the readout in game.
