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

## 0. Performance foundations  [ ]
The rules are in `docs/performance.md`; this step puts the existing code on them before the battlefield builds on it.
- **Renderer:** switch to Mobile. Check the water shader, `WorldMaterials`, the light presets and the UI still look right.
- **Tick:** physics interpolation on; the registry steps units at half rate (half the units per tick), the inhabited unit and projectiles every tick; units lose their own `_physics_process`.
- **Kinematic units:** RTS units move without `move_and_slide` (height from the map model, walls from the grid), keeping their collision shape for queries; the brain swap to direct control brings the physics controller back.
- **Ids, not nodes:** selection, control groups, targets and orders hold unit ids.
- **Benchmark scene:** headless, fixed unit count and ticks, one summary line of milliseconds per system.
- **Done when:** the benchmark shows the per-unit cost down from today's (`pathing.md`, "Measured"), units still path, fight and look smooth, and the numbers are in the mechanic docs.

## 1. Scale reference level  [ ]
`levels/atoll/` starts here and becomes the main scene.
- A flat seabed, primitive island blocks (an atoll ring, a big island, a few small ones), two hovering mothership boxes, 100 units, the sea at full size.
- `BattlefieldStats` (Map tab): map extent, the motherships' standoff distance and altitude, a test flyer speed. Island blocks and motherships follow live edits.
- A debug readout of the travel time from each mothership to the atoll at the test speed.
- Measure: frame time with water and far plane at full size, `MapGrid` memory and build time, depth precision at far zoom, haze and shadows from high up. Write the numbers under "Measured".
- **Done when:** the user picks the map size on it.

## 2. Heightmap terrain  [ ]
- `TerrainHeights` resource: heights at their own spacing (a tunable, coarser than the map grid), seabed included (below sea level is water depth), a surface role per sample (grass, sand, stone, soil by slope and height unless painted). Stored compactly, not one float per metre.
- `TerrainChunks`: mesh (flat-shaded facets, palette roles through `WorldMaterials`) and `HeightMapShape3D` collision on layer 1, per chunk; a change rebuilds only its chunks and emits the area; far chunks use a coarser mesh.
- `MapGrid` reads heights from the data instead of a ray per cell.
- **Done when:** a test heightmap renders, collides, units path over it, and a scripted change rebuilds one chunk and re-paths the units crossing it.

## 3. Heightmap import, runtime brushes and the far camera  [ ]
Sculpting happens in an external tool; we build only what the game needs anyway.
- **Authoring outside:** Blender (sculpt a subdivided plane, bake its height to a 16-bit image) or Krita (paint a 16-bit greyscale image). Both are free and run on macOS.
- **Import:** a 16-bit PNG or EXR becomes the level's `TerrainHeights` (heights scaled by a tunable range, sea level a tunable); surface roles come from slope and height. A debug key re-imports the file in game, so edit, save, re-import is the loop.
- **Runtime brushes:** raise, lower, flatten, crater through the same map-change call gameplay uses (landing pads, craters, ground changing during play). No editor UI beyond a debug key and radius; no undo (re-import instead).
- **Far camera rig** (pan, rotate, zoom out to about two thirds of the map); the strategy view's zoom handover reuses it (step 10).
- Terrain addons (Terrain3D, HTerrain) do in-editor sculpting but bring their own map model to keep in sync with ours; using one needs the user's OK (`CLAUDE.md`, "Dependencies").
- **Done when:** an atoll blocked out in Blender or Krita shows in game within a minute of saving, and a brush changes it during play with units re-pathing.

## 4. Water and pathing at full size  [ ]  (parallel with 3)
- **Water:** a dense grid following the camera plus a flat far plane (or LOD rings). Shore distance and depth baked from the heightmap into a low-resolution texture, re-baked locally on change, replacing `set_shore(rects)` (capped at 48). Shallow water over the reef reads lighter.
- **Map grid:** land only, in the shared chunks (`docs/performance.md`), built and rebuilt alone; a coarse chunk-to-chunk level only if one island is still too big for one search. Measure first.
- **Land regions:** every walkable cell carries a region id (one per connected land mass), refreshed locally on map changes. `CommandIssuer` refuses a ground move to another region (amphibious units excepted), so no search ever crosses the sea.
- **Done when:** the numbers from step 1 are within budget at full size.

## 5. Atoll blockout  [ ]
- The sculpted atoll replaces the primitive blocks: reef ring, lagoon, main islands with a mountain, plains and beaches, smaller islands around, open sea to each mothership.
- Capture points as markers only. No props or detail beyond what reads the forms.
- **Done when:** travel times and lines of sight can be judged with today's units dropped in.

## 6. Hovering mothership  [ ]  (parallel from step 2)
- `Carrier` becomes `Mothership` (`bases/`, group `motherships`): in the air, no ground footprint, doesn't block the grid. Its position is simulation state, so relocation can come later.
- Primitive placeholder at true scale (`*_proto.tscn` through the stats' model, style guide prototyping rules).
- Named attachment points: production bays, carryall pads, a naval drop bay (reserved), the forward-base pieces (reserved).
- `MothershipStats`: production lines, pads; later health per part.
- **Done when:** both motherships hover in the battlefield level and read as huge from near and far.

## 7. Unit cargo classes  [ ]
- `UnitStats` gains a cargo class (infantry or machinery) and a slot size (an IFV takes half a carryall's machinery slots, a tank all of them).
- Placeholder types: infantry, IFV, tank.
- **Done when:** the three types exist with their slots and fight like the others.

## 8. Income and squad production  [ ]  (after 6, 7)
- `EconomyStats`: flat income per side, the bank. `UnitStats` gains a cost.
- **Squad spec** (plain data): unit type ids, a job (scout, patrol, guard, covert, assault), a name. Presets are `SquadStats` `.tres` (fireteam, anti-air, motorized division, covert insertion). Cost and build time come from the units. Size capped at one carryall's slots by default; a larger cap is a tunable.
- `ProductionLine` per mothership bay: a queue on the fixed tick; finished squads wait aboard.
- **Orders:** `produce` and `cancel` carry the squad spec through `CommandIssuer`.
- **Squad identity:** `SquadRegistry` (squad id, team, members, job); each unit carries its squad id; members stay selectable one by one.
- **HUD (first pass):** a squad builder (presets, custom pick within the slot rules), the production lines, the bank.
- Probe events: `produce`, `squad_ready`, `income`.
- **Done when:** several lines build squads at once from the HUD, and a headless test queues and cancels through `CommandIssuer` and checks the bank.

## 9. Carryalls  [ ]  (after 5, 8)
- A large flyer with a `Cargo` component: infantry and machinery slots. **Carried units are data:** loading stores each unit's id, type, health, squad and controller and removes its node the way death does (no death event); para-drop or landing spawns it again with the same id. Everything already copes with units leaving, and state that holds ids (step 0) gets them back. A richer carried state can come with first-person play.
- Orders:
  - **Pick-up:** lands on a valid landing zone (flat, walkable, big enough) or a mothership pad.
  - **Para-drop:** anywhere; units descend, land spread over walkable cells, snap off blocked ones.
  - **Deliver:** load the squad at the pad, fly, para-drop or land.
- **Side gunners:** two carried units fire their own weapons from mount points on the carryall.
- **Autopilot:** an order-following brain for RTS commands. Piloting is the existing brain swap, built with first person.
- Probe events: `load`, `drop`, `unload`.
- **Done when:** a squad built aboard reaches the atoll from one deliver order, by para-drop or landing, and a carryall picks it up again.

## 10. Strategy view: the war table  [ ]  (after 2, 8, 9)
- **`ViewSwitcher`** (a named action); switching never changes game state.
- **The table:** a simplified model of the map drawn from `TerrainHeights` in its own scene and visual layer, never the live level, redrawn by chunk on map changes. Squad tokens (low-res scaled-up models or icons, Homeworld style).
- **Tilt-shift:** try the Mobile renderer's camera depth of field first (near and far blur around a focus band); a hand-written post shader only if that doesn't read as tilt-shift. Heavy here.
- **Zoom handover:** zooming in past a threshold switches to the RTS rig at that point.
- **HUD overlay:** squad builder and production, landing zone assignment (deliver orders), team **map markers**, **strategy outlines** (areas or arrows with a label, stored as data the AI will read).
- Markers and outlines are team data through the issuer path, so they can go over the network.
- **Done when:** a match's production, deliveries and markers can be run from the war table, and zooming in drops into the live battle.

## 11. Tilt-shift at far RTS zoom  [ ]
- The same shader in the RTS view, strength following the zoom (`CameraStats`), so the RTS view blends into the war table.

## 12. Full-scale check  [ ]
Both motherships producing, several carryalls flying, a 100-unit fight on the atoll, units spread elsewhere. Frame time headless and rendered, noted in the mechanic docs.

## Risks and likely setbacks
- **The map grid at kilometres:** tens of millions of cells at today's cell size; `AStarGrid2D` holds a point per cell; building with a ray per cell takes seconds. Land-only chunks first, a hierarchical search if needed.
- **Renderer switch (step 0):** shaders and materials tuned under Compatibility may look different under Mobile. Sun shadows can't cover kilometres on any renderer.
- **Water at scale:** vertex count, the 48-rectangle shore cap, the low-angle mosaic.
- **Haze tuned for 100 m** will white out a view kilometres across; it needs to follow the view or zoom.
- **Terrain rebuild hitches** during play need a per-tick budget, as paths have.
- **Carried units** leave and re-enter the world; anything still holding a node reference instead of an id will break there.
- **The war table must follow live map changes**, redrawn from the data chunk by chunk.
- **The zoom handover** between two cameras must feel like one continuous zoom.
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
(Filled in by step 1.)
