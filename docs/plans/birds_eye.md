# Bird's-eye view (battlefield step 10b)

**Built (10b-1 to 10b-4; the sun tune is open).** What exists is described in `docs/mechanics/birds_eye.md`; this doc keeps the design reasoning. The zoom-in handover to the RTS view was dropped: the views are separate modes.

The design and build order for the live strategy view. A fresh session should be able to start from this doc alone. Read `docs/mechanics/war_table.md` (view switching, the table rig), `camera.md`, `water.md` and `docs/performance.md` first.

## Goal
V pulls the camera up from the RTS view to a high, steep view of the **live** map. It should read like a tilt-shift photo of a miniature battlefield seen from above the clouds. The references the user gave are the Battlefield V / 2042 deploy maps and a stylised aerial city render: a sharp, contrasty, sunlit centre, with soft clouds and blur framing the edges.

The war table (10a) stays as a second, simplified strategy view. This view is what the HUD overlay (10c: squad builder, LZs, markers, outlines) sits on.

**Scope:** the look and feel is in scope. Photoreal detail is not. Spending effort on the effect is allowed, but every part must stay cheap, fixed-cost per pixel, and off entirely outside this view.

## What makes the references work
Most of the effect comes from these, roughly in order of weight:
1. **A clear key light.** A low, warm sun with long shadows and cooler shade makes the relief read at altitude. Flat lighting looks like a map; raking light looks like a model.
2. **Contrast and clarity in the centre, softness at the edges.** The centre has crisp local contrast and full saturation. Toward the edges everything is lifted toward a pale haze, desaturated and blurred. The eye goes to the middle.
3. **Tilt-shift blur.** A sharp band through the focus, blurring toward the top and bottom. The far side blurs more, as with a real shallow focus plane.
4. **Clouds between the camera and the ground.** These give a parallax layer, a sense of altitude, and a natural frame. They are thicker at the screen edges and thin over the centre.
5. **Cloud shadows** drifting over the ground. These are cheap and very effective at selling scale and life.
6. **Atmospheric perspective.** The far top of the screen is hazier and bluer than the near bottom.
7. **Readable figures.** Units are specks at this height, so markers or tokens carry the information (in the references these are HUD icons). Unit blips belong to 10c.
8. **Miniature grading.** Slightly raised saturation and contrast, a gentle vignette, and soft bloom on bright highlights (foam, sun glitter).

## Design

### View, camera, transition
- **Bird's-eye rig:** a third `CameraRig` with its own `CameraStats` preset (`camera_birdseye.tres`) and `follow_ground = false` (focus at sea level). It needs a narrow zoom range and a steep pitch range.
- **Pitch guard:** the pitch minus half the vertical FOV must stay well below the horizon, so the sky is never seen. Clamp this when the preset loads, rather than trusting the tuned values.
- **Pan bounds:** the map bounds, so the footprint stays over the far sea (below).
- **`ViewSwitcher`** grows to `View { RTS, BIRDS_EYE, WAR_TABLE }`:
  - V toggles RTS ↔ bird's-eye.
  - The war table moves to a new key (default B, action `toggle_war_table`; V becomes `toggle_strategy_view`). Update the keybind page.
  - Zooming never changes view.
- **Fly transition:** a `ViewTransition` node owns a transition `Camera3D`. It eases the global transform, FOV, near and far planes from the outgoing camera to the incoming one over `transition_time`, on real time like the rigs.
  - Effects read a single `blend` value (0 for RTS, 1 for bird's-eye) that it drives.
  - Input is off during the flight. A second V mid-flight reverses from the current pose and does not snap.
  - The war table still cuts; flying 4 km up to the table would look wrong.
- `RtsPlayer` is disabled in the bird's-eye view, as it is for the table, until 10c adds strategy picking.

### Post shader: tilt-shift, edge blur, clarity, grading
- **Setup:** one full-screen pass, implemented as a quad in front of the bird's-eye and transition cameras. It is a spatial shader with `POSITION = vec4(VERTEX.xy, 1.0, 1.0)`, a large `extra_cull_margin`, and its own visual layer that only those cameras render. The HUD (canvas) stays sharp on top. It reads `hint_screen_texture` with mipmaps and `hint_depth_texture`.
- **Blur:** about 9 taps at a mip level chosen per pixel. The blur amount is the larger of:
  - the tilt-shift band term, from the screen row against `band_center` and `band_width`, with `far_blur` stronger than `near_blur`;
  - the radial vignette term (`edge_blur`).
- **Depth:** optionally mix the band with a depth term, so mountains in the band don't blur on their tops.
- **Clarity:** the centre gets `centre - blurred × clarity`, an unsharp mask that comes free with the blurred samples. This is the "sharp contrast in the middle".
- **Grading:**
  - saturation and contrast up inside the focus mask;
  - toward the edges, lift to `edge_haze_color` (a `UiTokens` world colour) and desaturate;
  - a gentle darkening vignette;
  - optional warm-highlight / cool-shadow split toning.
- **Spike first:** confirm that the Mobile renderer gives the screen texture mipmaps in a spatial shader. If it doesn't, fall back to a half-resolution blur: a `SubViewport` copy, or a two-pass separable blur via a `CompositorEffect` if Mobile supports one. Record what works in the doc.
- **Tunables:** all in a new `BirdsEyeStats` (groups: Camera, Transition, Tilt-shift, Grade, Clouds, Sea, Light), listed in `TuningPanel.TABS` under Map.

### Clouds
- **Layers:** two large planes at `cloud_height_low` and `cloud_height_high` above sea level, between the camera's minimum height and the ground. They follow the camera's focus, snapped so that only the UVs (world-space x, z) move, so panning shows parallax between the two.
- **Shader:**
  - unshaded and alpha-blended, casting no shadow;
  - two samples of one shared, seamless, tiling noise texture (made once at load), scrolled by `wind_direction` and `wind_speed`;
  - coverage is a smoothstep on the noise, with `coverage` and `softness`.
- **Fake lighting:** sample the noise again, offset toward the sun, to darken the side away from the light. This is cheap and gives volume.
- **Framing:** alpha is multiplied by a screen-space edge mask (`cloud_edge_bias`), so clouds gather at the edges and thin over the centre.
- **Fade with height:** alpha also fades by camera distance from the layer, so clouds never fill the screen when the camera passes through them during the fly transition.
- **Off outside this view:** the layers are hidden and not processed below a small `blend`. The RTS view pays nothing.
- **Cloud shadows:** a global shader uniform set (`cloud_noise`, `cloud_offset`, `cloud_scale`, `cloud_shadow_strength`) in `project.godot` shader globals. The terrain and water shaders sample the same noise at world x, z and darken the lit colour, so shadows match the clouds exactly.
  - Strength comes from `blend`, so it is optional in the RTS view; a little might look good there too.
  - This touches the terrain material and `water.gdshader`; coordinate with those docs.

### Far sea (no void)
- **Ring:** a ring of a few large flat quads around the current water sheet, out to `far_sea_reach`. It uses the far-sheet water material with waves off, so it is one material and a handful of triangles.
- **Visual only:** no collision, no grid cells, no heightmap samples, nothing simulated. The terrain and map stay their current size.
- **Fill:** the ring's colour fades to the deep-sea colour and to the haze. With the pitch guard and pan bounds, the footprint never leaves it.
- **Far plane:** follows the bird's-eye distance (the rig already does this through `far_per_distance`).

### Light and atmosphere
- **Haze:** the bird's-eye camera gets its own `Environment` (`Camera3D.environment`), a copy of the level's built from `LightStats` plus bird's-eye overrides: haze density for kilometres, adjustments (contrast, saturation), and glow on for highlights. This handles the plan's "haze tuned for 100 m" risk.
- **Sun:** keep one sun for both views; changing it per view would move the shadows on switching. Tune the shared `light_day` sun lower and warmer if the RTS view agrees. The sun shadow map can't cover kilometres, so turn sun shadows off in this view (blend-driven) and rely on the baked terrain light.
- **Baked terrain light:** when a chunk is built, bake a horizon shadow (march along the sun direction over `TerrainHeights`) and a cavity / AO term into the terrain's vertex colour, or a second channel the terrain material multiplies by.
  - This is computed once per chunk, rebuilt with the chunk on map changes (it already has a budget), and costs nothing per frame.
  - It gives the long raking shadows and the relief at any distance, and helps the RTS view too.
  - The Mobile renderer has no SSAO, so this is the AO.
  - Check how the terrain material reads colour first (`heightmap.md`).
- **Large-scale tint variation:** low-frequency world-space noise varying the ground colour slightly (field patchwork), so land isn't a flat fill from 2 km. This is one texture sample in the terrain shader.

## Cheap, robust, optimised: rules for this view
- **Zero cost when off:** every node (post quad, clouds, far ring, transition camera) is hidden and `PROCESS_MODE_DISABLED` outside the view or the transition. The global cloud-shadow strength is 0 then, so shaders skip the work behind one uniform branch.
- **Fixed per-pixel cost:** independent of units and map size. Quality knobs in `BirdsEyeStats` (blur taps, second cloud layer, cloud lighting sample, clarity) allow a cheaper tier on the M1 target.
- **One noise texture** shared by the clouds, the cloud shadows and the ground tint, generated once at load. No per-frame allocations, no per-frame `set_shader_parameter` except the uniforms that actually move (cloud offset, blend).
- **Baked light on chunk build only,** inside the existing chunk rebuild budget; on a worker thread if it shows in the hitch readout.
- **Real time:** the transition and cloud drift run on real time (like the rigs), unaffected by slow time and pause.
- **Robustness:**
  - V spammed mid-flight;
  - switching while paused;
  - window resize (the screen-space maths uses `SCREEN_UV` only);
  - the table opened from the bird's-eye view and closed again (returns to the bird's-eye view);
  - level reload.
- **Headless test:** the `ViewSwitcher` state machine and transition (states, reversals) with no rendering. Visuals are checked with screenshots and the rendered frame time is noted.

## Build order (one session each)
1. **10b-1 View and edges (done):**
   - the bird's-eye rig and preset, the pitch guard, `ViewSwitcher` with three views and the key change, `ViewTransition`;
   - the far sea ring, the bird's-eye `Environment` (haze, adjustments), sun shadows off in view;
   - the headless switcher test.
   - **Done when:** V flies up and back, and no void or sky shows at any zoom or edge.
2. **10b-2 Post shader (done):**
   - the Mobile mipmap spike;
   - tilt-shift band, edge blur, clarity, grading, vignette;
   - `BirdsEyeStats`.
   - **Done when:** screenshots read as tilt-shift with a crisp centre.
3. **10b-3 Clouds (done):**
   - two layers with fake lighting, edge framing and height fade;
   - global cloud uniforms and cloud shadows in the terrain and water shaders.
   - **Done when:** clouds frame the view, drift, show parallax on pan, and their shadows cross the ground.
4. **10b-4 Light (done, except the sun tune):**
   - baked horizon shadow and AO in the terrain chunks, the ground tint noise, the sun tune;
   - frame time noted.
   - **Done when:** the relief reads from the highest zoom, and the RTS view looks at least as good as before.

After 10b: the HUD overlay (10c) sits on this view; unit blips (team-coloured tokens scaled with distance, as the table's) are its first piece.
