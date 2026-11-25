# Heightmap terrain

Natural ground for the battlefield level: heights on a regular sample grid, drawn and collided in chunks, read by the map grid straight from the data (`docs/plans/battlefield.md`, step 2). The tile terrain (`terrain.md`) stays in the code but new levels use this. Tunables: `HeightmapStats` (`tuning/heightmap_default.tres`, Map tab).

**Scripts:** `terrain/terrain_heights.gd` (data), `terrain_chunks.gd` (the node), `terrain_chunk_mesh.gd` (facet mesh), `terrain_light.gd` (baked light), `terrain_test_map.gd` (generators), `heightmap_png.gd` (16-bit PNG codec), `heightmap_import.gd` (PNG <-> `TerrainHeights`), `terrain/terrain_brush.gd` (brush maths), `debug/heightmap_io/` (`heightmap_reloader.gd`, `heightmap_brush.gd`, `height_bands.gd` + shader); `map/map_grid.gd` (`terrain`); test level `levels/heightmap_test/` (`HeightmapTestLevel`, not maintained).

## How it works
- **`TerrainHeights`** (`Resource`, no nodes): `origin`, `spacing` (metres between samples, coarser than the map grid's cell), `samples`, 16-bit heights over `min_height` + `height_range` in a byte array, a painted role byte per sample (0 = pick by slope and height). Seabed is in the same data: below `MapGrid.SEA_LEVEL` is water depth. `height_at(x, z)` blends four samples; `set_sample_height` changes one and emits nothing.
- **`TerrainChunks`** (`setup(data)`): the map cut into chunks of `chunk_cells` cells (corner samples shared). Per chunk a near mesh and a coarse mesh (every `lod_step`-th sample), switched by visibility range at `lod_distance`, and a `HeightMapShape3D` on the World layer (shape node scaled to the spacing), all under one `StaticBody3D`. Meshes are flat-shaded facets, one surface per palette role from `WorldMaterials`; the role is the painted one or picked from slope (stone), height (sand at the shore, soil on the summit, grass between) and depth (seabed: sand shallow, dark stone deep).
- **Changes:** after editing samples, call `changed(area)`. Only the chunks the area touches queue; `chunks_per_tick` rebuild per physics tick; when the queue empties `changed_area(area)` fires. A level connects it to `MapGrid.resample`, which re-reads the data (no wait for physics) and emits `cells_changed`, so units re-path as for any map change.
- **`MapGrid.terrain`:** when set, cells take their height from the data (cells below sea level count as no ground, so the grid stays land only). Unset: rays at colliders, as before (sandbox, Mars, island, atoll blocks).

## Baked light (battlefield step 10b-4)
`TerrainLight` bakes one colour multiplier per sample into the chunk vertex colours (role materials use `vertex_color_use_as_albedo`; white where no light): the sun's horizon shadow (a linear sweep away from the sun over the heights, soft edge, cooled toward `light_shade_tint`), cavity occlusion (neighbours at `light_ao_radius` against the sample) and a low-frequency warm/cool tint (field patchwork). Free per frame in both views. The level gives the sun with `TerrainChunks.set_sun` before `setup`; without it the ground stays white. Tunables: `HeightmapStats` "Baked light". Water-covered samples (below the sea by more than 1 m) are left white.
- **Edits:** `changed(area)` re-bakes `TerrainLight.affected(area)`: the area grown by the cavity radius and swept downwind by the shadow reach, because a new hill shades ground it never touched. Chunks over that area queue (so more than the edited chunks rebuild, within `chunks_per_tick`).
- **Settings:** any change to a light setting re-bakes everything and queues every chunk.
- **Cost:** full bake of the atoll (876 x 501 samples) about 0.7 s on load, headless M1 (GDScript, main thread). An edit bake of a 200 m area is about 30 ms. The brush re-bakes every frame it paints.
- **Not tested:** the look on real relief (the atoll draft is nearly flat); a mid-edit view of the shadows moving.

## Authoring (battlefield step 3a)
Sculpt outside the game (Krita or Blender), save a 16-bit greyscale PNG at `HeightmapStats.source_path` (Import group); the game re-imports it within `reload_poll_seconds` and rebuilds only the chunks whose samples changed.
- **Encoding:** black is `min_height`, white is `min_height + height_range` (defaults -50 m and +150 m, so sea level 0 m is grey 25%). One pixel is one sample, `import_spacing` apart (default 4 m), the map centred on the origin, top row north (-z). Surface roles are not in the image; slope and height pick them.
- **Krita:** new image, greyscale, 16-bit integer, a linear or "no colour conversion" profile (a gamma curve bends the heights), no alpha needed. Export as PNG without interlacing, keeping 16 bits. Our reader takes greyscale, grey + alpha, RGB or RGBA at 8 or 16 bits (first channel); 8-bit works but steps the ground in 0.8 m. Blender: bake the height to a 16-bit PNG, same rules.
- **How to paint** (brush setup, exact heights, ground rules): `docs/terrain_painting.md`.
- **Starter:** the first run of `levels/heightmap_test/` writes a generated atoll (`TerrainTestMap.make_atoll`) to the source path; open it in Krita and paint over it.
- **Keys (`HeightmapReloader`):** `debug_heightmap_reload` (F6) re-imports now; `debug_heightmap_save` (F7) writes the current heights, in-game edits included, back to the PNG.
- **Why our own codec:** `Image.save_png` writes 8 bits and the loader drops to 8 bits. `HeightmapPng` writes greyscale 16-bit (zlib via `PackedByteArray.compress`) and reads all five row filters.
- **Brushes (3b, `HeightmapBrush`, `TerrainBrush`):** # turns the brush on (the left button then paints instead of selecting); + cycles raise, lower, flatten (to the height first clicked) and crater (one dig per click, small rim); `,` and `.` change the radius. Rates, radius and crater depth are in `HeightmapStats` (Brush group). Edits call `TerrainChunks.changed()`, so the grid re-reads heights and units re-path. No undo: F6 re-imports the PNG; F7 saves brush work back.
- **Height bands (3b, `HeightBands`):** 9 overlays height colours, a contour every `contour_interval` metres and an orange waterline (a material overlay on every chunk view through `TerrainChunks.set_overlay`).
- **Tab page:** `ui/keybinds/keybind_page.gd` (autoload `KeybindPage`) lists game keys left and debug / map-design keys right, read from the Input Map; add a row to its two arrays when adding an action.
- **Not yet:** the Krita reference layer, the far camera (3c, 3d in the plan). The atoll level (`levels/atoll/`) uses it since battlefield step 5.

## Reference layer (battlefield step 3d)
`debug_reference_layer` (0, in `HeightmapReloader`) writes `levels/heightmap_test/reference_layer.png` from `ReferenceLayer` (`debug/heightmap_io/reference_layer.gd`): a transparent PNG with one pixel per heightmap sample, to open in Krita as a layer above the painting and never export with it. It holds a labelled grid every 100 m (stronger every 500 m), the heightmap's edge and the battlefield's `map_extent` in red, a 500 m scale bar, the atoll ring radius (orange), the two mothership footprints at their hover position (purple), a one-unit dot and a 100-unit squad block (green), and a ruler of grey patches with their percent and height, sea level marked in blue. Ring, mothership and extent come from `BattlefieldStats`, the ruler from the heightmap's range; regenerate when they change. Its tiny 3 x 5 font draws capitals and digits only. The pixel size is the loaded heightmap's, so match the painting to it.

## Measured
Test level (640 x 640 m, 2 m samples, 321 x 321 samples, 10 x 10 chunks of 32 cells), headless M1: data 301 KB; level load 1.7 s including grid and units; collision ray hits match `height_at` to 0.00 m; 8 units pathed across the island and arrived; raising a 12 m square rebuilt 2 chunks (it straddled a border) and the grid height followed.

Import (headless): a hand-built PNG using all five row filters reads back exactly; a written PNG round-trips and passes CRC checks; a 876 x 501 map (3.5 x 2 km at 4 m) writes in about 40 ms and reads in about 50 ms (flat data, real paintings compress less); reloading an edit of 6 x 6 samples took 6 ms and rebuilt one chunk in one tick.

## Known issues
- Water does not follow the heights (a `WaterBody` is a flat sheet at its node's height; below-sea ground only shows through it in levels that have one; step 4 derives shores). The test level's generator is a stand-in.
- Auto-reload refuses a PNG of a different size or spacing (restart the level); a half-written file is skipped by the next save's modified time.
- Water does not use the heights yet (step 4); the test level has a flat `WaterBody` at 0 m (no shore foam), because without it the sea floor (dark stone and sand) reads as flat grey.
- The mesh's quad split and Jolt's heightmap triangulation may differ on a diagonal, a few centimetres on steep ground.
- Not tested: a path crossing a changed chunk re-pathing (the generic map-change re-path covers it); LOD seams between a near and a far chunk (small cracks possible).
