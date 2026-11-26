# Lamps and light pools

The night's lights: navigation lamps on aircraft, markers on ground units, lamps on pads, airfields and motherships, and pools of light under bases. All view code: no lamp is needed to read anything, and light never changes what anyone knows. Tunables: `LampStats` (`tuning/lamp_default.tres`, Map tab); day and night brightness `LightStats` Lamps group; the Explorer's beacon size and periods in `ExplorerStats`.

**Scripts:** `lighting/lamp_set.gd` (data), `lamp_field.gd` + `lamp.gdshader` (drawing), `light_pool.gd` + `light_pool.gdshader`; `units/unit_lamps.gd`, `hull_points.gd`, `explorer_look.gd`; `bases/airfield_look.gd`, `models/mothership_proto.gd`, `mothership.gd` (sea pool); `lighting/world_light.gd` (brightness globals); `levels/atoll/atoll_level.gd` (makes the field).

## How it works
- **`LampSet`** (a `Node3D`, group `lamp_sets`): one owner's lamps in its own space (colour, strength, size, smallest screen size, steady, blink or double strobe). A child of what carries it, so it moves, hides and is freed with it: a hidden unit has no lamps, and a piloted craft's own lamps go with its airframe.
- **`LampField`** (one per level; a level without one shows no lamps): every visible set in one MultiMesh, one draw call. It takes each set's interpolated transform each frame; a set that hasn't moved or changed is copied from a cache. Blinking is in the shader.
- **The glow:** camera-facing, additive, never smaller than `min_px` on screen, drawn a little toward the eye so its own hull doesn't cut it. No fog. `render_priority` 1, so the bird's-eye post pass doesn't paint over it (pools too).
- **What carries what:** aircraft: red port and green starboard wingtips, white tail, white double strobe on top (places read from the model's vertices, cached per shape). Ground units: one dim white marker on the back. Explorer: the same red, green and white tail, team-colour blinkers and white strobes. Pads: white corner lamps and a faint white pool. Airfields: team-colour edge lamps and deck pool. Motherships: red, green, white stern, two strobes, team-colour deck edge lamps, and a team-colour pool on the sea.
- **Light pools** are flat additive shapes that light nothing. The only real lamps are the Explorer's searchlights.
- **Night check:** `LampField.set_blinking(false)` leaves steady lamps only, so its frames compare.

## Measured
M1, 1600x900 windowed, vsync off, atoll at night with 14 flyers, RTS view at the airfield, simulation stopped: about 420 lamps and 38 pools cost 0.1 to 0.6 ms a frame (two runs each). The field's CPU: about 0.07 ms with everything still, 0.26 ms with every unit moving.

**Spot lights:** the Mobile renderer lights a mesh with at most 8 spot lights (tested: 12 over one 128 m terrain chunk show 8). Two Explorers' searchlights over one chunk fit; with a third, that chunk drops some pools.

## Settled
- Wingtips keep aviation's red (port) and green (starboard): they show heading; teams already read from the plates and liveries.
- Orange is kept for warnings, hostile orders and the third team, so the Explorer's blinkers are team colour.
- One lamp field rather than a mesh per owner.

## Tried and passed on
- A small bright core (the old Explorer beacon glow): at distance it shrank to about a pixel and the red and green didn't read.

## Known issues
- A deployed Explorer has no light pool: a flat shape would cut into uneven ground.
- Lamps are on for craft sitting on pads too.
- A third Explorer over one terrain chunk loses searchlight pools there (above).
- Lamp places come from the model's farthest vertices, so an artist's model may want named lamp markers instead.
