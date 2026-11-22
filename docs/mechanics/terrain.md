# Terrain tiles

Tile-based ground for a level: Kenney Space Kit terrain pieces on a grid, stacked in height levels with ramps, roads and generated cliff walls. Painted in the running game, saved as a data file. A heightmap terrain is meant to come later and replace this for natural ground. Tunables: `TerrainStats` (`tuning/terrain_default.tres`, tile size and the cliffs' palette role; Map tab).

**Scripts:** `terrain/terrain_layout.gd` (data), `terrain_pieces.gd` (the kit's models), `terrain_cliffs.gd` (walls), `terrain_map.gd` (the node); `debug/terrain_editor/terrain_editor.gd` (painting). Example levels: `levels/mars/mars_outpost.tscn` with `mars_outpost_terrain.tres`, and the green island (`water.md`). `TerrainStats` can tint the tiles flat in a palette role (`tint_tiles`, `tile_role`) instead of the kit's texture; the tint is the shared `WorldMaterials` material, and the cliffs take `cliff_role`'s colour.

## How it works
- **`TerrainLayout`** (`.tres`): per cell a kind (flat, ramp, road straight / corner / cross / split / end), a turn (quarter turns clockwise from above) and a height level. Stored as five ints per cell (`data`); `commit()` before saving. Cells with no entry are the level's open ground.
- **Heights:** a level is half a tile above the one below. A flat or road tile sits at its level; a ramp's low edge is at its level and its high edge one level up, its high side facing north at turn 0. Roads are flat, so they only sit beside ramps and at their own level.
- **`TerrainMap`** (group `terrain_map`): a MultiMesh per kind for the tiles (a few draw calls), one `StaticBody3D` on layer 1 holding a trimesh per tile plus the cliff mesh. `paint` / `erase` change a cell, rebuild the views and cliffs and emit `changed_area`; the level then re-reads the map grid there after two physics frames (`sandbox.gd`), so units re-path. The MapGrid blocks steep faces by itself (cliffs block, ramps at 26 degrees pass), nothing else is told about the terrain.
- **`TerrainCliffs`:** builds a wall wherever two neighbouring tiles' edges differ in height (also for the slanted side of a ramp) and a skirt to the ground from the open edges of raised tiles. Any painted shape gets walls; no wall pieces from the kit are used.
- **`TerrainPieces`:** measures each kit model once: re-centres it on its own bounds (the kit's meshes sit off their origin), finds a ramp's high side from its vertices, builds the collision.
- **Editor (F2, `debug_terrain_editor`):** left button paints, Shift + left erases, 1-7 pick the tile, R turns it, Page Up / Down change the level, Ctrl+S (Cmd+S) saves the layout `.tres`. It takes the mouse and these keys from the RTS controls while on. A level opts in with `Terrain` (a `TerrainMap` with a layout and stats) and `TerrainEditor` nodes; `sandbox.gd` wires them.

## Settled
- Cliffs are generated, not the kit's side pieces: the kit's wedge pieces do not autotile cleanly and a generated wall fits any shape.
- RMB stays the camera's drag, so erasing is Shift + left.

## Tried and passed on
- An editor plugin (`addons/`): rejected, painting in the running game needs no plugin and shows the real map and pathing.
- A Mars asset pack: Kenney has none; the Space Kit terrain is used, its salmon palette suits a Mars map.

## Known issues
- No undo; a mistake is Shift-click or Reset from disk by reloading the level.
- The kit's large ramp (2 tiles) and the detailed ramp are not offered; ramps are one tile.
- Props and units are placed by hand in the scene at their level's height (`y`); painting does not move them.
- Cliffs are one flat palette colour; no ground texture on the open ground yet (the ground shader is the debug grid in a Mars colour).
- Only checked on the example level and one live paint test (a raised tile's edge cells blocked, then reopened on erase); odd shapes such as ramps meeting at corners are untested.
