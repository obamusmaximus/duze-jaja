# Bird's-eye view

The live strategy view: the camera flies up from the RTS view to a high, steep view of the real map (battlefield step 10b; design and build order in `docs/plans/birds_eye.md`). Tunables: `BirdsEyeStats` (`tuning/birds_eye_default.tres`, Map tab) and the `CameraStats` preset `tuning/camera_birdseye.tres`.

**Scripts:** `views/view_switcher.gd`, `views/view_transition.gd`, `views/strategy_figures.gd`, `views/birds_eye/birds_eye.gd`, `birds_eye_blips.gd`, `birds_eye_post.gd` + `.gdshader`, `birds_eye_clouds.gd`, `cloud.gdshader`, `cloud_shadow.gdshader`, `cloud.gdshaderinc`; `camera/camera_rig.gd` (`yaw`, `set_yaw`, `refresh`), `camera/camera_zoom.gd` (sky guard); `lighting/world_light.gd` (`environment()`, `set_shadows`, `sun()`); `terrain/terrain_chunks.gd` (`set_base_overlay`); `water/water.gdshader` (cloud shade). Built by `AtollLevel._build_war_table`.

## How it works (10b-1: view and edges)
- **View only:** never changes game state. Switching changes cameras and input.
- **Rig:** `BirdsEye` holds a third `CameraRig` (`follow_ground` off, focus at sea level), pan-bounded to the map. Disabled when it isn't the view.
- **Sky guard:** `CameraStats.sky_margin` (degrees, 0 = off) raises the pitch in `CameraZoom.pitch()` so the top screen edge looks at least that far below the horizon. Live, so tuned pitches can't show sky.
- **Views and keys:** `ViewSwitcher.View { RTS, BIRDS_EYE, WAR_TABLE }`. `toggle_strategy_view` (V) flies RTS ↔ bird's-eye. `toggle_war_table` (B) cuts to the table and back to the view it was opened from. Zooming never changes view: the RTS and strategy views are separate modes. `RtsPlayer` is on only in the RTS view.
- **Flight (`ViewTransition`):** a transition `Camera3D` between the RTS camera (blend 0) and the bird's-eye camera (blend 1). `blend` moves at a constant rate on real time (`transition_time`); the pose (position, rotation, FOV, log-blended near and far) is a smoothstep of it, so a second V mid-flight turns round from the current pose without a snap. The focus and yaw are copied to the arriving rig when a flight starts from rest. Input is off during the flight. Pressing B mid-flight settles the flight and cuts to the table.
- **Far sea:** four flat quads (`FarSea`) around the water sheet out to `far_sea_reach`, sharing the sheet's flat material. Visual only, shown only in this view and during flights. With the pan bounds and the sky guard no void is visible at any zoom or edge.
- **Environment:** the bird's-eye camera has a copy of the level's `Environment` with its own haze density (`BirdsEyeStats.haze_density`), contrast, saturation, brightness and glow. During a flight the transition camera blends these from the level's values. Sun shadows (`WorldLight.set_shadows`) go off above `shadows_off_blend` of the flight (the shadow map can't cover kilometres) and come back on below it.

## Switching rules
- A first-person view takes the screen with `hand_over` and returns it with `take_back` (`cockpit.md`); V and B are off in between.
- V and B are ignored during a flight (a HUD change animation will hang on the switch later); switching back waits for the flight to end. Flying up always starts at the rig's default distance.
- The focus is kept inside the map bounds pulled in by `pan_inset` (a share of the half-extent), so panning and RMB drag never show much past the playable area.

## Post pass (10b-2)
`BirdsEyePost`: a full-screen spatial-shader quad on visual layer 21 (`BirdsEyePost.LAYER`), one child on the bird's-eye camera and one on the flight camera; the RTS and table cameras drop the layer. Hidden (no cost) while the flight is near its RTS end. Mobile gives `hint_screen_texture` mipmaps, so the blur is nine taps at a per-pixel mip: tilt-shift band (`band_*`, far blurrier than near) or radial edge blur, whichever is larger; unsharp-mask clarity and saturation/contrast in the sharp area; haze, desaturation and vignette toward the edges. Tunables: `BirdsEyeStats` Tilt-shift and Grade groups. No depth term yet. Frame time not measured.

## Clouds (10b-3)

The cloud materials have `render_priority` 1, so they draw after the post pass: crisp, not blurred or hazed by it. (At priority 0 they sorted before the post quad and its edge blur and haze washed them out to nothing.)
`BirdsEyeClouds`: two 32 km quads (visual layer 22, `BirdsEyeClouds.LAYER`, only the bird's-eye and flight cameras render it) at `cloud_height_low` / `cloud_height_high`, snapped to the focus so only the world-space UVs move (parallax). One seamless 256 px noise (made once) drifts with real-time wind. `cloud.gdshader`: smoothstep coverage, a second tap toward the sun for fake shading, alpha thicker toward the screen edges (`edge_bias`), faded by camera distance to the layer. Shadows: the noise, offset and scale are global shader uniforms (`project.godot`, `cloud.gdshaderinc`); `water.gdshader` multiplies by `cloud_shade`, the land gets a multiply overlay (`cloud_shadow.gdshader`) as `TerrainChunks` base overlay, present only while the view is up (a debug overlay such as the height bands replaces it while shown). Shadow strength is 0 and layers hidden below the flight's first percent. Only the low layer casts shadows. Tunables: `BirdsEyeStats` Clouds group. Frame time not measured.

## Blips (10c-3)
`BirdsEyeBlips`: a `Control` on its own `CanvasLayer` (layer 5, under the HUD) drawing a mark per `StrategyFigures` figure (shared with the table's tokens): squad square with its member count, unit square, carryall triangle, mothership hollow square, team colour with a black edge, fixed pixel size. Figures are re-read `blip_hz` times a second and projected through the viewport's current camera (the flight camera too) every frame, so they stay on their units while panning. They sit above the blur and clouds, like HUD icons. Faded in over the top of the flight (`blip_show_blend`); hidden and not processing otherwise, and on the table (it has its tokens). Tunables: `BirdsEyeStats` Blips group.

## Not done (later steps of `docs/plans/birds_eye.md`)
- 10b-4 is built as baked terrain light in `HeightmapStats` (see `heightmap.md`, "Baked light"), shared by both views; sun tune left to the user.
- Strategy picking, markers, carryall commands and outlines are built (10c-4 to 10c-6, `rts_controls.md`, `ui.md`).

## Known issues
- A flight down to the RTS view ends on the RTS rig's old ground height until its ground follow catches up (a small settle).
- The headless switcher test lives only as a scratch harness; it loads the atoll, flies up, reverses, goes to the table and back, hands over by zoom and spams the key.
