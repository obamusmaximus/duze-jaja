# STATUS

Loaded into every session through `CLAUDE.md`, so keep it short: this is an index. Mechanic detail goes in `docs/mechanics/`, not here.

**Playtesting:** the user playtests thoroughly after every feature. If they don't mention a feature, it works as intended. Don't label things "not playtested".

_Last updated: 2026-11-21_

## Current state
| Mechanic | Doc (`docs/mechanics/`) | Where it stands |
|---|---|---|
| Debug tools (tuning panel, pause menu, playtest log, slow time) | `debug_tools.md`, `../playtest_log.md` | Ported from `../first`, plus slow time (`DebugTimeScale` autoload). Tabs: Camera, Units, Map, Controls, Debug; no diagrams yet. Map debug: wall (F3), grid view (F4). |
| Sandbox level | `debug_tools.md` | `levels/sandbox/sandbox.tscn` (main scene): ground with a ramp and plateau, sun, a 2 m scale marker, a debug wall, 6 + 4 units of two teams, the camera rig and player controls, the pause menu. |
| Camera rig (RTS view) | `camera.md` | Built (groundwork step 1): pan (keys, edge with the cursor confined, drag), rotate, zoom with pitch, reset, ground following, map bounds; runs on real time. |
| Units and teams | `units.md` | Built (step 4): registry with stable ids and a spatial hash, swappable brain. |
| Orders | `orders.md` | Built (step 6): `Order` data, `CommandIssuer` (team check, group move, waypoints), per-unit queue. |
| Map grid, pathing, movement | `pathing.md` | Built (step 7): changing map grid, budgeted jump-point paths with sharing, soft-collision steering, crowd arrival, map-change re-paths. 100 units at about 2.8 ms per tick headless. |
| Combat | `combat.md` | Built (step 8): health, weapons (instant or projectile), staggered targeting with return fire and no overkill, behaviour by order with leash, health bars. |
| RTS controls (picking, selection, control groups, order clicks) | `rts_controls.md` | Built (steps 3, 5, 6 view side): left-click scheme, box and double-click select, control groups, attack-move and stop keys, cursor and order markers. |
| Placeholder art, props, space demo level | `props.md`, `../style_guide.md`, `../../assets/README.md` | Kenney Space Kit (CC0) imported in `assets/`; units show models on a team-colour plate; static `Prop` types block the map; `levels/sandbox/space_demo.tscn` is a small two-base test map. Style guide is an outline (palette and UI rules), no UI theme built yet. |

## Current goals
1. **Build the RTS groundwork** in the RA3 / C&C3 style: follow `docs/plans/groundwork.md` step by step (camera rig, slow time, picking, units, selection, orders, map grid and pathing, basic combat, HUD shell). Multiplayer comes later but the groundwork must be ready for a server-authoritative simulation.

## Cross-cutting known issues and gotchas
- Typed `@export var x: Camera3D` loads as null from a `.tscn`. Verify any node export.
- GDScript 4.7: `Array[T]()` doesn't parse (declare a typed local first). A `const` can't hold `PackedVector3Array([...])`. Scalars passed to functions are copies, so return results.

## Next up
1. **The next unticked step in `docs/plans/groundwork.md`** (step 9, HUD shell). Read the plan first, including its rules at the top; the design behind them is in `GAME_DESIGN.md` ("Camera", "Controls", "Views", "Multiplayer and simulation", "Pathing").

## Layout and branches
- Feature folders: `levels/sandbox/`, `assets/` (third-party art), `props/`, `camera/`, `picking/`, `units/`, `selection/`, `orders/`, `player/`, `map/`, `combat/`, `menus/`, `tuning/`, `debug/` (dev-only tools: `debug/tuning/` builds the tuning panel from the stats resources; `debug/playtest_log/`). Each mechanic doc lists its scripts. Headless test notes: `docs/testing.md`.
- Git: local repository only, no remote yet. Work happens on feature branches off `main` (one topic per branch); finished branches are merged and deleted.
