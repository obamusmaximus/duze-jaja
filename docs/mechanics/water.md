# Water

A sheet of faceted, stylized sea as a level element. The shader is ported from the sibling project `first` (where it was a night sea); here it is lit by the level's sun. Tunables: `WaterStats` (`tuning/water_battlefield.tres`, Map tab). The sea, foam and glitter colours are palette roles (`UiTokens.WORLD_SEA_*`, `WORLD_FOAM`, `WORLD_SUN`; `docs/style_guide.md`), not tunables.

**Scripts:** `water/water_body.gd` (the node), `water/shore_field.gd`, `water/water.gdshader` with `waves`, `shore`, `foam` and `shading` includes.

## How it works
- **`WaterBody`** (a `MeshInstance3D`, group `water`): a `PlaneMesh` of `size`, centred on the node and lying at its height, re-subdivided to `quad_size` quads. Every `WaterStats` value goes to the shader live. **Visual only, no collision**: the MapGrid finds no ground under it, so ground units can't enter it and picking passes through (the camera keeps its last height over it).
- **Night:** `WaterBody.set_light(LightStats)` (the atoll calls it on every `WorldLight.applied`): night sea, foam and moon-glitter colours, and the preset's scales on the body's glow, foam glow and the directional glitter (lamps' glitter is not scaled). A level that never calls it keeps the day look.
- **Waves:** a few summed directional sines with analytic normals, moving with `TIME`; flat shading per triangle (`facet_amount`); light in posterized steps; a hard-edged glitter path toward every light. Nothing in it names a light, so any directional light or lamp works.
- **Terrain shadow:** on a heightmap level the sea takes the sun or moon shadow mask (`heightmap.md`, "Terrain shadow"): it blocks the directional light and glitter and darkens the body colour, never a lamp's.
- **Shore:** from the baked `ShoreField` (below). `WaterBody.set_shore(rects)` (up to 48 world rectangles) is left from the removed island level and has no caller. Without a shore the water is flat.

## Level of detail and shore field (battlefield step 4)
- **Dense patch over a flat sheet** (`WaterStats.near_size` above 0, `tuning/water_battlefield.tres`; 0 keeps a single sheet): a patch of `quad_size` quads follows the ground the camera looks at (`WaterBody._follow_camera`, snapped to whole quads so the facets hold still); this node's own sheet of `far_quad_size` quads lies under it, flat and dropped by the deepest possible trough. Waves fade out at the patch's edge (`patch_fade` in `water.gdshader`), so they meet without a step. For a low camera (cockpit) the patch stays round it: its centre is at most `LOW_REACH` of its side ahead, a limit that opens with height, and the rule is continuous from looking down to level so the patch never jumps.
- **`ShoreField`** (`water/shore_field.gd`, a node): bakes the heightmap into an RG float texture, one texel per `field_texel` metres: red the signed distance to the shore (negative on land, kept to `field_reach`), green the depth below the sea. Distances are a two-pass chamfer (about 8 % error at worst, fine for foam). `WaterBody.set_shore_field(field)` makes the shader read it instead of the 48 rectangles (`use_field`), so any number of islands cost the same. `mark_changed(area)` collects ground changes and re-bakes the texels within `field_reach` of them once nothing changed for `field_settle` seconds (a brush stroke is one re-bake). Shallow water over the reef reads lighter (`reef_depth`, `reef_strength`, `reef_amount` in `shore.gdshaderinc`).
- **Measured** (headless M1, 3500 x 2000 m at 4 m texels, 876 x 501): full bake about 0.8 s at level load (`compute()` can run on a worker); a re-bake of a 20 m area about 0.7 s (the window is the area plus twice the reach), which is why it waits for the ground to settle. The numbers on the atoll are for the user's playtest.

## Settled
- Water has no collision, so water is impassable by default; boats and ground-picking on water come with the naval units.

## Known issues
- Water mosaic is strong from low angles in the far field; `ramp_contrast` and `crest_tint` are the dials (the colours are the palette's).
