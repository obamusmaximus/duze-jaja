# Water and the island level

A sheet of faceted, stylized sea as a level element, and the green island level that uses it. The shader is ported from the sibling project `first` (where it was a night sea); here it is lit by the level's sun. Tunables: `WaterStats` (`tuning/water_default.tres`, Map tab); the island's tile look is `TerrainStats` (`tuning/terrain_island.tres`). The sea, foam and glitter colours are palette roles (`UiTokens.WORLD_SEA_*`, `WORLD_FOAM`, `WORLD_SUN`; `docs/style_guide.md`), not tunables.

**Scripts:** `water/water_body.gd` (the node), `water/water.gdshader` with `waves`, `shore`, `foam` and `shading` includes; `levels/island/island_level.gd`, `green_island.tscn`, `green_island_terrain.tres`; `bases/carrier.gd`, `carrier.tscn`.

## How it works
- **`WaterBody`** (a `MeshInstance3D`, group `water`): a `PlaneMesh` of `size`, centred on the node and lying at its height, re-subdivided to `quad_size` quads. Every `WaterStats` value goes to the shader live. **Visual only, no collision**: the MapGrid finds no ground under it, so ground units can't enter it and picking passes through (the camera keeps its last height over it).
- **Waves:** a few summed directional sines with analytic normals, moving with `TIME`; flat shading per triangle (`facet_amount`); light in posterized steps; a hard-edged glitter path toward every light. Nothing in it names a light, so any directional light or lamp works.
- **Shore:** `WaterBody.set_shore(rects)` takes up to 48 world rectangles (x, z). The shader measures the distance to the nearest one: foam band, shore bands travelling in, waves damped near it and flat far away (`calm_*`). Without rects the water is flat. The island level builds them from the terrain layout (rows of tiles with the same run, merged) plus each carrier's footprint, so the foam follows the stepped coastline.
- **Island level** (`IslandLevel extends SandboxLevel`): map 800 m long along X (left to right: ally carrier on the left, enemy on the right) and 200 m deep, `camera_bounds`, `map_area` and `camera_yaw` (the home yaw, facing along the island) set on the scene. Island of tile terrain in the middle (`tint_tiles` with `tile_role` grass gives the kit's tiles a flat sage, `cliff_role` sand the cliffs): a coast at height level 1 so cliff walls stand in the water, a hill at level 2 with a ramp at each end, trees (`prop_tree_*`, primitive meshes in `props/models/`). Light is the shared `light_day` preset (`WorldLight`, style guide "In the world").
- **`Carrier`** (`bases/`): placeholder for each team's main base, one in the water at each end. Flat-coloured boxes; the deck is World-layer ground (walkable in the MapGrid, drops at the sides block), the hull is on the Building layer. `SpawnPoints` markers are where units will appear. Group `carriers`.

## Settled
- Water has no collision, so water is impassable by default; boats and ground-picking on water come with the naval units.
- Shore as rectangles instead of a depth texture: no Compatibility risk, exact distances, cheap.
- Trees from primitive meshes: Kenney's site refuses scripted downloads, and flat low-poly trees suit the style anyway.

## Known issues
- Carriers are not connected to the island by land: units on a deck can't reach the island yet (spawning and landing craft come later).
- The coast follows the 8 m tiles, so it is stepped; the foam rectangles match it row by row.
- Shore foam only follows the island and carriers; other things in the water get none.
- Water mosaic is strong from low angles in the far field; `ramp_contrast` and `crest_tint` are the dials (the colours are the palette's).
- No water in the terrain editor yet (F2 paints tiles only); the sea's height is the `Water` node's.
