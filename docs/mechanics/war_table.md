# War table (strategy view)

The strategy view: a tilt-shifted model of the whole map with a token per squad, beside the live RTS view (`docs/plans/battlefield.md`, step 10a; the HUD overlay is 10b). Design: `GAME_DESIGN.md` ("Views"). Tunables: `WarTableStats` (`tuning/war_table_default.tres`, Map tab); its camera is a `CameraStats` preset, `tuning/camera_table.tres`.

**Scripts:** `views/view_switcher.gd`, `views/war_table/war_table.gd`, `war_table_mesh.gd`, `war_table_tokens.gd`, `views/strategy_figures.gd` (the figures, shared with the bird's-eye blips); `camera/camera_rig.gd` (`zoomed`, `set_active`, `follow_ground`, `set_distance`, `focus_point`). Built by `AtollLevel._build_war_table`.

## How it works
- **View only:** reads heights and units, sends no orders. Switching changes cameras and input, never game state.
- **The table** sits `table_height` metres above the live world at the same x, z, on visual layer 20 (`WarTable.LAYER`). The table's camera sees only that layer; `ViewSwitcher` removes it from the RTS camera's cull mask. The camera has its own `Environment` (solid colour), so the level's sky and sun don't reach it.
- **Ground:** `WarTableMesh` samples `TerrainHeights` every `sample_step` samples into flat facets, one mesh per tile of `tile_cells` cells, unshaded with the shading and colour painted into vertex colours (sea by depth, sand, grass, stone from `WorldMaterials` roles). Land is exaggerated by `height_scale`, the seabed flattened by `depth_scale`. `mark_changed(area)` (wired to `TerrainChunks.changed_area`) queues tiles, `tiles_per_frame` rebuild per frame.
- **Tokens (`WarTableTokens`):** one `MultiMesh` of boxes in the team colour, refreshed `token_hz` times a second: a token per carryall, per mothership, per squad (at its members' centre) and per unit with no squad. Size follows the camera distance, so they read at every zoom. No fog exists yet, so both teams show in full.
- **Rig:** a second `CameraRig` with `follow_ground` off and the table preset. The rig that is off has `PROCESS_MODE_DISABLED` (no input, no motion), as does `RtsPlayer` while the table is up, so clicks never reach the live world.
- **Switcher:** `toggle_war_table` (B) flips between the table and the view it was opened from (RTS or bird's-eye, `birds_eye.md`); the new view takes the old one's focus point. Zooming never changes view (no handover to the RTS view; they are separate modes).
- **Tilt-shift:** the table camera's depth-of-field (`CameraAttributesPractical`) far and near blur, bands as shares of the camera distance, applied every frame so edits are live.

## Not done
- Token picking and everything on the HUD (10b). Tokens are plain boxes, not scaled-down models or icons.
- The blur is subtle at the default strength and not judged against a true tilt-shift look; the RTS view has no blur (kept that way: separate modes).
- The table's initial build (all tiles in one frame) is not timed; a map change redraws only touched tiles.

## Known issues
- Both teams show on the table (no fog); a later visibility rule decides what the player sees.
