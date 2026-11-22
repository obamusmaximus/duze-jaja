# STATUS

Loaded into every session through `CLAUDE.md`, so keep it short: this is an index. Mechanic detail goes in `docs/mechanics/`, not here.

**Playtesting:** the user playtests thoroughly after every feature. If they don't mention a feature, it works as intended. Don't label things "not playtested".

_Last updated: 2026-11-22_

## Current state
| Mechanic | Doc (`docs/mechanics/`) | Where it stands |
|---|---|---|
| Debug tools (tuning panel, pause menu, playtest log, slow time) | `debug_tools.md`, `../playtest_log.md` | Ported from `../first`, plus slow time (`DebugTimeScale` autoload). Tabs: Camera, Units, Map, Controls, Debug; no diagrams yet. Panel has its own tool theme (IBM Plex Sans, `TuningThemeBuilder`). Map debug: wall (F3), grid view (F4). |
| Sandbox level | `debug_tools.md` | `levels/sandbox/sandbox.tscn` (main scene): ground with a ramp and plateau, sun, a 2 m scale marker, a debug wall, 6 + 4 units of two teams, the camera rig and player controls, the pause menu. |
| Camera rig (RTS view) | `camera.md` | Built (groundwork step 1): pan (keys, edge with the cursor confined, drag), rotate, zoom with pitch, reset, ground following, map bounds; runs on real time. |
| Units and teams | `units.md` | Built (step 4): registry with stable ids and a spatial hash, swappable brain; Mobile renderer, half-rate decisions, kinematic movement, ids in selection and targets (battlefield step 0). Flyers (Hornet, `tuning/unit_hornet.tres`): altitude over the ground, straight flight, anti-air flag. |
| Orders | `orders.md` | Built (step 6): `Order` data, `CommandIssuer` (team check, group move, waypoints), per-unit queue. |
| Map grid, pathing, movement | `pathing.md` | Built (step 7): changing map grid, budgeted jump-point paths with sharing, soft-collision steering, crowd arrival, map-change re-paths. 100 units at about 2.8 ms per tick headless. |
| Combat | `combat.md` | Built (step 8): health, weapons (instant or projectile), staggered targeting with return fire and no overkill, behaviour by order with leash, health bars. |
| RTS controls (picking, selection, control groups, order clicks) | `rts_controls.md` | Built (steps 3, 5, 6 view side): left-click scheme, box and double-click select, control groups, attack-move and stop keys, cursor and order markers. |
| UI layer (tokens, theme, components, HUD) | `ui.md`, `../style_guide.md` | `UiTokens` holds palette, scales and faces (Anybody variable font); generated `game_theme.tres` with hatching; HUD modules placed by swappable layouts in nine screen sections with optional framed bands (`generals.tres`, `sidebar.tres`): minimap, selection (portrait, stats, type cards), empty command grid, match clock, forces. |
| Audio and combat effects | `audio.md` | Sound (UI hover/click, orders, selection, combat, ambient) from Kenney CC0 packs plus synthesized placeholders, and pooled combat particles (flash, sparks, death burst). Cues are `SfxCue` resources (Audio tab). |
| Terrain tiles, Mars level | `terrain.md` | Kenney terrain tiles in height levels with ramps, roads and generated cliffs, painted in game with F2 and saved to a layout `.tres`; `levels/mars/mars_outpost.tscn` is the example. Heightmap terrain comes later. |
| Water, green island level, carriers | `water.md` | `WaterBody` (faceted sea ported from `first`, shore foam and calm from rectangles), `levels/island/green_island.tscn` (800 m long, island in the middle, a placeholder carrier base at each end), terrain tiles tinted in palette roles, tree props. Carriers aren't linked to the island by land yet. |
| Placeholder art, props, space demo level | `props.md`, `../style_guide.md`, `../../assets/README.md` | Kenney Space Kit (CC0) imported in `assets/`; units show models on a team-colour plate; static `Prop` types block the map; `levels/sandbox/space_demo.tscn` is a small two-base test map. World palette: `WorldMaterials` shares one material per palette role and recolours imported models (team livery toggle in `WorldLookStats`); nature (sea, plants, sand, soil) is muted palette roles too. Every level instances `WorldLight` with a shared `LightStats` preset (`light_day`, `light_void`: sun, sky or void, haze, exposure). Style guide has a Marathon reference, prototyping rules and an artist-pass list. |
| Battlefield scale level | `battlefield.md` | `levels/atoll/` is the main scene (battlefield step 1): sea at full size, primitive atoll, mothership boxes, 100 units, `BattlefieldStats` (Map tab), readout. Map size picked by the user; step 1 done. |

## Current goals
1. **Build the RTS groundwork** in the RA3 / C&C3 style: follow `docs/plans/groundwork.md` step by step (camera rig, slow time, picking, units, selection, orders, map grid and pathing, basic combat, HUD shell). Multiplayer comes later but the groundwork must be ready for a server-authoritative simulation.

## Cross-cutting known issues and gotchas
- Typed `@export var x: Camera3D` loads as null from a `.tscn`. Verify any node export.
- GDScript 4.7: `Array[T]()` doesn't parse (declare a typed local first). A `const` can't hold `PackedVector3Array([...])`. Scalars passed to functions are copies, so return results.

## Next up
1. **The next unticked step in `docs/plans/groundwork.md`** (step 9, HUD shell: selection panel and minimap exist, enemy inspect and the camera clearing the bar remain). Read the plan first, including its rules at the top; the design behind them is in `GAME_DESIGN.md` ("Camera", "Controls", "Views", "Multiplayer and simulation", "Pathing").
2. **Battlefield plan** (`docs/plans/battlefield.md`): a full-scale level with sculpted heightmap terrain (atoll, mountains, plains, shores), hovering motherships, flat income and custom squads in production lines, carryalls (para-drop, side gunners), the war-table strategy view with tilt-shift. Decisions are made (`GAME_DESIGN.md`); step 0 (performance foundations) is done, so step 1 (scale reference level, `levels/atoll/`) is done; start at step 2.

**Levels:** once `levels/atoll/` exists it's the main scene and the only maintained level; sandbox, Mars and island are frozen unless the user asks.

## Layout and branches
- Feature folders: `levels/sandbox/`, `assets/` (third-party art), `props/`, `camera/`, `picking/`, `units/`, `selection/`, `orders/`, `player/`, `map/`, `combat/`, `menus/`, `tuning/`, `debug/` (dev-only tools: `debug/tuning/` builds the tuning panel from the stats resources; `debug/playtest_log/`). Each mechanic doc lists its scripts. Headless test notes: `docs/testing.md`.
- Git: local repository only, no remote yet. Work happens on feature branches off `main` (one topic per branch); finished branches are merged and deleted.
