# Battlefield level (scale reference)

`levels/atoll/atoll.tscn`, the main scene: a full-size sea with a sculpted heightmap atoll, a hovering mothership box per team and test units, built to measure what a battlefield costs and to pick the map size (`docs/plans/battlefield.md`, step 1). Tunables: `BattlefieldStats` (`tuning/battlefield_default.tres`, Map tab); the camera uses its own `tuning/camera_atoll.tres` (far zoom).

**Scripts:** `levels/atoll/atoll_level.gd` (extends `SandboxLevel`), `atoll_blockout.gd`, `capture_marker.gd`, `bases/mothership.gd`, `bases/models/mothership_proto.gd`; `debug/battlefield/battlefield_readout.gd`.

## How it works
- **`AtollLevel`** loads the heightmap like `HeightmapTestLevel` (`heightmap.md`): `TerrainChunks`, `MapGrid.terrain`, `ShoreField` for the sea, reloader (F6, F7, 0), brush (#) and bands (9). The grid uses `tuning/map_atoll.tres` (2 m cells). Tunables for the terrain are `tuning/heightmap_atoll.tres` (`source_path` is `levels/atoll/heightmap.png`). Map area, camera bounds, sea size, motherships and camera far plane follow `BattlefieldStats` (a debounced `_apply_size`). The **map grid covers the dry land's bounding box** plus a margin (`_grid_area()`).
- **`AtollBlockout`** (`make(stats, heightmap)`): the first draft, written to the PNG only when it is missing (delete the PNG to regenerate). A reef ring with two passes (angles `PASS_ANGLES`) round a shallow lagoon, a big island (plain at its top height, a mountain north of centre, beaches), six small islands between the ring and the motherships, a seabed dropping to open sea. The Atoll group of `BattlefieldStats` shapes it; sizes are approximate. Then the PNG is the source of truth: paint over it in Krita.
- **`CaptureMarker`**: ten markers (big island plain and summit, six islets, ring north and south crests), from `AtollBlockout.capture_points`; markers only, no mechanic.
- **`Mothership`** (`bases/`, group `motherships`, `MothershipStats` in `tuning/mothership_default.tres`, Map tab): hovers at `mothership_standoff` from the atoll centre along x (team 0 west, 1 east) at `mothership_altitude`, set by the level through `place()`. Hull length runs along z with the bow at -z for both, so the **long side faces the atoll** (starboard for the west ship, port for the east). The hull is the stats' `model` scene (`MothershipProto`, primitives at true scale, palette roles, team livery stripes) with named attachment points `CarryallPad0..n`, `ProductionBay0..n`, `NavalDropBay`. Collision: two boxes on the Building layer; no grid footprint. A top-level radial-fade quad on the sea is the ground shadow.
- **`BattlefieldReadout`** (debug): fps, draw calls, map and grid size, grid build time, test-flyer travel time from each mothership to the ring and the big island.
- Test units: `unit_count` troopers and rovers, half per team, on the big island's plain; `test_fighters` and `test_vtols` per team in a row beside each block.

## Measured (headless M1, 3500 x 2000 m, 4 m samples = 876 x 501)
Level load 5.4 s, of which the map grid 1.9 s for 1072 x 834 cells at 2 m (`tuning/map_atoll.tres`, 0.9 M cells, the islets spread wide); ten land regions. At 1 m cells (3.6 M) the grid took 7.4 s and the load 14 s. Paths on 2 m cells are coarser: judge them in play.

## Known issues
- Mothership: no thruster glow, drone sound, bob or per-part health yet; shadow is a plain quad.
- Plants, rocks and detail are not added; the first draft is a blockout to repaint.
- Editing the Atoll group of `BattlefieldStats` no longer reshapes the land (the PNG is the source); only a missing PNG regenerates.
