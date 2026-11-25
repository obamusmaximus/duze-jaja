# Build plan: battlefield level, motherships, squads, carryalls, war table

The order for building the first full-scale match space: a battlefield-sized level with sculpted heightmap terrain (an atoll, mountains, plains, shores), a hovering **mothership** per side, **squads** built from a flat income in several parallel production lines, **carryalls** that fly them to the islands, and the **strategy view** as a tilt-shift **war table**. Design is in `GAME_DESIGN.md` ("A typical match", "Squads", "Carryalls", "Views", "Economy", "Changing maps", "Pathing"); this file is only the build order. It follows `docs/plans/groundwork.md` (step 9 there, the HUD shell, can finish in parallel).

**Work top to bottom, one step per branch and one session per step**, following `docs/performance.md`, with the groundwork's rules: simulation apart from views, orders as the only way in, maps change, tunables in `tuning/`, a headless check per step, a hand-off for a playtest. Tick a step when it lands, give it a mechanic doc, add its `STATUS.md` row. Steps marked **(parallel)** can run in their own session. **The battlefield level (`levels/atoll/`) is the only maintained level**; the sandbox, Mars and island levels are left as they are.

## Decided (details in `GAME_DESIGN.md`)
- **Map size** is picked on the scale reference level (step 1), not on paper.
- **The mothership hovers.** Later it drops naval units, splits off hovering forward bases and can relocate (BF2142 Titan mode).
- **Economy (leaning):** no harvesting; both sides get the same flat income and spend it on squads (later forward bases).
- **Squads:** fully custom, with presets; one squad per carryall as the rule, bigger squads allowed. A squad has one job; its units can still be micro'd one by one.
- **Carryalls:** infantry and machinery cargo slots, para-drop anywhere, land to pick up, two side gunners, autopilot or pilot.
- **Tilt-shift** is part of the look: heavy in the war table, fading in at far RTS zoom.
- **Strategy view v1:** a war-table model of the map (not the live level) with squad tokens; zooming in hands over to the live battle; its HUD builds squads, assigns landing zones, places map markers and strategy outlines.
- **Tile terrain** stays in the code but the new level is heightmap only.
- **Performance** (`docs/performance.md`): Mobile renderer, units at half the physics rate with interpolated views, kinematic RTS units, land regions refusing unreachable ground moves, carried units as data, terrain authored in Blender or Krita and imported.

## Still open (decide when the step comes up)
- A carryall shot down: does its cargo die (proposal: yes)?
- Income: a bank cap, and whether unspent income carries over.
- The cap on squad size above one carryall.
- Para-drop: can units be shot while descending?

## 0. Performance foundations  [x]
The rules are in `docs/performance.md`; this step puts the existing code on them before the battlefield builds on it.
- **Renderer:** switch to Mobile. Check the water shader, `WorldMaterials`, the light presets and the UI still look right.
- **Tick:** physics interpolation on; the registry steps units at half rate (half the units per tick), the inhabited unit and projectiles every tick; units lose their own `_physics_process`.
- **Kinematic units:** RTS units move without `move_and_slide` (height from the map model, walls from the grid), keeping their collision shape for queries; the brain swap to direct control brings the physics controller back.
- **Ids, not nodes:** selection, control groups, targets and orders hold unit ids.
- **Benchmark scene:** headless, fixed unit count and ticks, one summary line of milliseconds per system.
- **Landed (see `units.md`, `pathing.md` "Measured"):** Mobile renderer, registry loop at half rate with per-tick integration, kinematic ground units, ids in selection/groups/targets, `debug/benchmark/benchmark.gd`. The Mobile look of water, materials, lights and UI is for the user's playtest.
- **Done when:** the benchmark shows the per-unit cost down from today's (`pathing.md`, "Measured"), units still path, fight and look smooth, and the numbers are in the mechanic docs.

## 1. Scale reference level  [x]
`levels/atoll/` starts here and becomes the main scene.
- A flat seabed, primitive island blocks (an atoll ring, a big island, a few small ones), two hovering mothership boxes, 100 units, the sea at full size.
- `BattlefieldStats` (Map tab): map extent, the motherships' standoff distance and altitude, a test flyer speed. Island blocks and motherships follow live edits.
- A debug readout of the travel time from each mothership to the atoll at the test speed.
- Measure: frame time with water and far plane at full size, `MapGrid` memory and build time, depth precision at far zoom, haze and shadows from high up. Write the numbers under "Measured".
- **Done when:** the user picks the map size on it.

## 2. Heightmap terrain  [x]
- `TerrainHeights` resource: heights at their own spacing (a tunable, coarser than the map grid), seabed included (below sea level is water depth), a surface role per sample (grass, sand, stone, soil by slope and height unless painted). Stored compactly, not one float per metre.
- `TerrainChunks`: mesh (flat-shaded facets, palette roles through `WorldMaterials`) and `HeightMapShape3D` collision on layer 1, per chunk; a change rebuilds only its chunks and emits the area; far chunks use a coarser mesh.
- `MapGrid` reads heights from the data instead of a ray per cell.
- **Landed (see `heightmap.md`):** `TerrainHeights`, `TerrainChunks` (two mesh levels, `HeightMapShape3D`, budgeted rebuild queue), `MapGrid.terrain`, test level `levels/heightmap_test/`. Shared chunk index for the grid and regions comes with step 4.
- **Done when:** a test heightmap renders, collides, units path over it, and a scripted change rebuilds one chunk and re-paths the units crossing it.

## 3. Heightmap import, runtime brushes and the far camera  [x]
Sculpting happens in an external tool; we build only what the game needs anyway. **Too big for one session, so split:** **3a** import, auto-reload, save to PNG, starter heightmap `[x]` (a 16-bit PNG codec of our own, since Godot saves 8-bit only; `HeightmapReloader`, keys F6 reload and F7 save, starter at `levels/heightmap_test/heightmap.png`; see `heightmap.md`); **3b** runtime brushes plus the height-band overlay `[x]` (F8 to F10, see `heightmap.md`); **3c** the far camera rig `[x]` (far and near planes follow the zoom; presets with a large `max_distance`; see `camera.md`); **3d** the Krita reference layer script `[x]` (F11, `ReferenceLayer`, see `heightmap.md`). The bullets below are the full list.
- **Authoring outside:** Blender (sculpt a subdivided plane, bake its height to a 16-bit image) or Krita (paint a 16-bit greyscale image). Both are free and run on macOS.
- **Import:** a 16-bit PNG or EXR becomes the level's `TerrainHeights` (heights scaled by a tunable range, sea level a tunable); surface roles come from slope and height. A debug key re-imports the file in game, so edit, save, re-import is the loop.
- **Runtime brushes:** raise, lower, flatten, crater through the same map-change call gameplay uses (landing pads, craters, ground changing during play). No editor UI beyond a debug key and radius; no undo (re-import instead).
- **Height encoding:** black is `min_height`, white is `min_height + height_range` (both tunable, so white is never the scene's highest point by accident). Sea level is 0 m (`MapGrid.SEA_LEVEL`), so its grey is `-min_height / height_range`. Proposed start: black -50 m, white +150 m, sea level at 25% grey. Krita: 16-bit greyscale, no colour-profile conversion (a gamma curve would bend the heights); write the exact settings into `docs/mechanics/heightmap.md` when it lands.
- **Auto-reload:** the game watches the PNG and re-imports on save, no key needed; only the changed chunks rebuild.
- **Save back to PNG:** a debug key writes the current `TerrainHeights`, in-game brush edits included, to a 16-bit PNG, so brush work survives a re-import and can go back into Krita.
- **Height colour bands:** a debug overlay colours the ground by height with a contour line every 10 m, so the waterline and slopes read while painting.
- **Starter heightmap:** a generated rough atoll ring (from the step 2 test map generator) saved as a PNG to open in Krita, so the user edits a working example rather than a blank canvas.
- **Krita reference layer:** a script generates a transparent PNG at the heightmap's pixel size from the same data the game uses (`BattlefieldStats`, mothership data): labelled grid every 100 m, scale bar, map edge, mothership footprints at hover position, atoll ring radius, a unit-sized dot and a 100-unit squad blob, and a grey-value ruler marking sea level. It lives on its own layer above the painting and is never exported with it; regenerate it when the map size or mothership data changes.
- **Far camera rig** (pan, rotate, zoom out to about two thirds of the map); the bird's-eye rig reuses it (step 10).
- Terrain addons (Terrain3D, HTerrain) do in-editor sculpting but bring their own map model to keep in sync with ours; using one needs the user's OK (`CLAUDE.md`, "Dependencies").
- **Not now (revisit on a concrete need):** a measure tool (click two points, distance and unit travel time); a second image for surface-role paint where slope and height pick wrongly. No custom map editor: Krita and Blender paint better, and an editor is only worth it for placing objects (capture points, spawns, props), starting as a simple marker file.
- **Working tip:** block out coarse first (about 875 x 500 px at 4 m spacing, big soft brush), detail after.
- **Done when:** an atoll blocked out in Blender or Krita shows in game within a minute of saving, and a brush changes it during play with units re-pathing.

## 4. Water and pathing at full size  [x]  (parallel with 3)
**Landed (see `water.md`, `pathing.md`):** dense camera patch over a flat far sheet, `ShoreField` baked from the heightmap (distance and depth, settled local re-bake, lighter reef), land regions with order refusal. **Not done:** the grid is not chunked (one array measured fine at 1.26 M cells), and the atoll level's shore is still rectangles until step 5 gives it a heightmap.
- **Water:** a dense grid following the camera plus a flat far plane (or LOD rings). Shore distance and depth baked from the heightmap into a low-resolution texture, re-baked locally on change, replacing `set_shore(rects)` (capped at 48). Shallow water over the reef reads lighter.
- **Map grid:** land only, in the shared chunks (`docs/performance.md`), built and rebuilt alone; a coarse chunk-to-chunk level only if one island is still too big for one search. Measure first.
- **Land regions:** every walkable cell carries a region id (one per connected land mass), refreshed locally on map changes. `CommandIssuer` refuses a ground move to another region (amphibious units excepted), so no search ever crosses the sea.
- **Done when:** the numbers from step 1 are within budget at full size.

## 5. Atoll blockout  [x]
- The sculpted atoll replaces the primitive blocks: reef ring, lagoon, main islands with a mountain, plains and beaches, smaller islands around, open sea to each mothership.
- Capture points as markers only. No props or detail beyond what reads the forms.
- Plants and rocks, when needed: copy them from the Kenney Nature Kit the user already downloaded (`~/Downloads/kenney_nature-kit`) into `assets/kenney_nature_kit/`; don't download anything (`assets/README.md`, "Planned imports").
- **Landed (see `battlefield.md`):** `levels/atoll/` runs on `TerrainChunks` over `levels/atoll/heightmap.png`, generated once by `AtollBlockout` and edited in Krita from then on; shore field, grid and land regions follow the heights; ten capture markers. Plants and rocks not added.
- **Done when:** travel times and lines of sight can be judged with today's units dropped in.

## 6. Hovering mothership  [x]  (parallel from step 2)
- `Carrier` becomes `Mothership` (`bases/`, group `motherships`): in the air, no ground footprint, doesn't block the grid. Its position is simulation state, so relocation can come later.
- Primitive placeholder at true scale, `bases/models/mothership_proto.tscn` (style guide prototyping rules). It's built from primitives, not Kenney parts, because nothing in the Space Kit reads as a hull that size.
  - **Shape:** a long hull with a wedged prow, carryall pads on top, production bays as doors underneath, a naval drop bay at the stern (reserved), and engine pods with downward thrusters. Space Kit turrets and dishes may go on as fittings at plausible sizes.
  - **Showing the hover:** a soft ground shadow (a decal under the hull), since sun shadows are off at far zoom (`docs/performance.md`); thruster glow is an effect. A slow bob is in the view only, never in the simulation.
  - **Cost:** a few meshes, one per palette role, merged when built; collision is a few boxes on the Building layer.
  - **Size** is a `MothershipStats` tunable, set on the scale reference level.
- Sound: a low drone loop from the synth tool (`tools/audio_synth/`).
- Named attachment points: production bays, carryall pads, a naval drop bay (reserved), the forward-base pieces (reserved).
- `MothershipStats`: production lines, pads; later health per part.
- **Landed (see `battlefield.md`):** `Mothership` + `MothershipProto` + `MothershipStats`, long side to the atoll. **Not done:** thruster glow, drone sound, bob, per-part health.
- **Done when:** both motherships hover in the battlefield level and read as huge from near and far.

## 7. Unit cargo classes  [x]
- `UnitStats` gains a cargo class (infantry or machinery) and a slot size (an IFV takes half a carryall's machinery slots, a tank all of them).
- **True scale first:** the trooper and rover are scaled up today (the trooper stands far taller than a person). Bring them back to true scale (style rule 6; the base plate keeps them readable), so cargo sizes look right.
- Placeholder types: infantry (the Space Kit astronaut), and an IFV and a tank as primitive prototypes (`units/models/ifv_proto.tscn`, `tank_proto.tscn`): an IFV on six wheels, a tank on tracks with a long gun, told apart by silhouette. Kenney has no fitting military vehicles.
- **Landed (see `cargo.md`):** `UnitStats` cargo class and slots, `Cargo` hold with `CargoEntry` data, `CargoStats`, unit icons (SVG, `UnitStats.icon`, `UnitIcon`), `CargoView` in the selection module, IFV and tank prototypes, trooper and rover at true scale, a test carryall per team on the atoll. **Not done:** actually loading units (step 9).
- **Done when:** the three types exist with their slots and fight like the others.

## 8. Income and squad production  [x]  (after 6, 7)
- `EconomyStats`: flat income per side, the bank. `UnitStats` gains a cost.
- **Squad spec** (plain data): unit type ids, a job (scout, patrol, guard, covert, assault), a name. Presets are `SquadStats` `.tres` (fireteam, anti-air, motorized division, covert insertion). Cost and build time come from the units. Size capped at one carryall's slots by default; a larger cap is a tunable.
- `ProductionLine` per mothership bay: a queue on the fixed tick; finished squads wait aboard.
- **Orders:** `produce` and `cancel` carry the squad spec through `CommandIssuer`.
- **Squad identity:** `SquadRegistry` (squad id, team, members, job); each unit carries its squad id; members stay selectable one by one.
- **HUD (first pass):** a squad builder (presets, custom pick within the slot rules), the production lines, the bank.
- Probe events: `produce`, `squad_ready`, `income`.
- **Landed (see `economy.md`):** all of it except the anti-air preset (no AA unit yet) and the `income` HUD graph; squads wait aboard as data until step 9.
- **Done when:** several lines build squads at once from the HUD, and a headless test queues and cancels through `CommandIssuer` and checks the bank.

## 9. Carryalls  [x]  (after 5, 8)
- **Placeholder model:** the Space Kit's `craft_cargoA`, scaled in its `.tres` to true size (its cargo hold fits a tank). Flyers don't use the grid, so its size costs nothing there. `craft_cargoB` stays free for a variant. Sound: a synthesized rotor or engine loop.
- A large flyer with a `Cargo` component: infantry and machinery slots. **Carried units are data:** loading stores each unit's id, type, health, squad and controller and removes its node the way death does (no death event); para-drop or landing spawns it again with the same id. Everything already copes with units leaving, and state that holds ids (step 0) gets them back. A richer carried state can come with first-person play.
- Orders:
  - **Pick-up:** lands on a valid landing zone (flat, walkable, big enough) or a mothership pad.
  - **Para-drop:** anywhere; units descend, land spread over walkable cells, snap off blocked ones.
  - **Deliver:** load the squad at the pad, fly, para-drop or land.
- **Side gunners:** two carried units fire their own weapons from mount points on the carryall.
- **Autopilot:** an order-following brain for RTS commands. Piloting is the existing brain swap, built with first person.
- Probe events: `load`, `drop`, `unload`.
- **Landed (see `carryall.md`):** carryall comes free with a squad job and is loaded unit by unit on a mothership pad, takeoff interrupts the job with a partial refund, deliver by landing (returns beside the mothership, never onto a pad), `CarryallFleet` list with states for the strategy view, side gunners (ground only, infantry). **Not done:** para-drop, picking units up again / exfil, pick-up on landing zones, gunner mount points, sound.
- **Done when:** a squad built aboard reaches the atoll from one deliver order, by para-drop or landing, and a carryall picks it up again.

## 10. Strategy views  [x]  (after 2, 8, 9)
Built; the mechanics are in `docs/mechanics/war_table.md`, `birds_eye.md`, `ui.md`, `rts_controls.md`. The views are separate modes: V flies between the RTS and bird's-eye views, B cuts to the table and back, and zooming never changes view.
- **10a War table:** simplified map model in tiles on its own layer, squad tokens, tilt-shift blur.
- **10b Bird's-eye view:** live high view with post shader, clouds and cloud shadows, baked terrain light, far sea ring (design and build order: `docs/plans/birds_eye.md`).
- **10c Strategy HUD:** two HUDs swapped on the view change, RA3-style selection panel, unit blips, picking, map markers, carryall list, SET LZ, EXFIL NEAREST, strategy outlines. Open parts (marker and exfil behaviour, unit pick-up) are in `docs/plans/backlog.md`.

## 11. Full-scale check  [ ]
(The old step 11, tilt-shift at far RTS zoom, was dropped: the RTS view and the strategy views stay clearly separate modes.)
Both motherships producing, several carryalls flying, a 100-unit fight on the atoll, units spread elsewhere. Frame time headless and rendered, noted in the mechanic docs.

## Risks and likely setbacks
- **The map grid at kilometres:** tens of millions of cells at today's cell size; `AStarGrid2D` holds a point per cell; building with a ray per cell takes seconds. Land-only chunks first, a hierarchical search if needed.
- **Renderer switch (step 0):** shaders and materials tuned under Compatibility may look different under Mobile. Sun shadows can't cover kilometres on any renderer.
- **Water at scale:** vertex count, the 48-rectangle shore cap, the low-angle mosaic.
- **Haze tuned for 100 m** will white out a view kilometres across; it needs to follow the view or zoom.
- **Terrain rebuild hitches** during play need a per-tick budget, as paths have.
- **Carried units** leave and re-enter the world; anything still holding a node reference instead of an id will break there.
- **The war table must follow live map changes**, redrawn from the data chunk by chunk.
- **Para-drop on a sculpted coast:** thin land and reef edges leave few walkable cells to land on.
- **Side gunners on a moving flyer:** fire arcs and targeting from a mount that moves and turns (`combat.md`).
- **Heightmap data size:** keep the spacing coarse and storage compact.

## Mechanics that need design before they're built (not in this plan)
- **Capture points** (presence, timers, contesting, what they give).
- **Forward bases** detaching from the mothership, and how income pays for them.
- **Mothership relocation and naval drops.**
- **Fog of war** at this scale, and what the war table reveals.
- **Ground changing under units** (sculpting during play makes it real).
- **The minimap**, drawn from the terrain data.
- **Unreachable orders:** what the player sees when a ground move is refused (another island), and whether the strategist's view offers a carryall instead.
- **Strategy outlines' vocabulary** (the guidelines, Leitlinien): what they can say and how the AI reads them.

## Measured
Step 1, headless, M1: default map 3000 x 2000 m, grid over 1100 x 1100 m at 1 m cells (1.21M cells): **build 1.9 s, about 170 MB static memory** for the whole level load (2.2 s). Gridding the whole map would be 6M cells: roughly 10 s and 850 MB, so the grid stays land-only. 100 units ordered across the island: 2.4 ms per tick, 1.7 ms in the unit loop. Frame time, depth precision and haze from high up need a rendered run: read them off the readout in game and note them here.
