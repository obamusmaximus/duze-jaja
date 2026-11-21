# STATUS

Loaded into every session through `CLAUDE.md`, so keep it short: this is an index. Mechanic detail goes in `docs/mechanics/`, not here.

**Playtesting:** the user playtests thoroughly after every feature. If they don't mention a feature, it works as intended. Don't label things "not playtested".

_Last updated: 2026-11-21_

## Current state
| Mechanic | Doc (`docs/mechanics/`) | Where it stands |
|---|---|---|
| Debug tools (tuning panel, pause menu, playtest log) | `debug_tools.md`, `../playtest_log.md` | Ported from `../first`. Tuning panel has one tab (Debug); no diagrams yet. Playtest log has no probes yet. |
| Sandbox level | `debug_tools.md` | `levels/sandbox/sandbox.tscn` (main scene): flat ground, sun, a 2 m scale marker, a fixed placeholder camera, the pause menu. |
| Camera | (doc comes with the rig) | Design decided (`GAME_DESIGN.md`, "Camera"). `CameraStats` and `camera_default.tres` exist (Camera tab); no rig uses them yet. |

## Current goals
1. **Build the RTS groundwork** in the RA3 / C&C3 style: follow `docs/plans/groundwork.md` step by step (camera rig, slow time, picking, units, selection, orders, map grid and pathing, basic combat, HUD shell). Multiplayer comes later but the groundwork must be ready for a server-authoritative simulation.

## Cross-cutting known issues and gotchas
- Typed `@export var x: Camera3D` loads as null from a `.tscn`. Verify any node export.
- GDScript 4.7: `Array[T]()` doesn't parse (declare a typed local first). A `const` can't hold `PackedVector3Array([...])`. Scalars passed to functions are copies, so return results.

## Next up
1. **The next unticked step in `docs/plans/groundwork.md`** (step 1, the camera rig, to start). Read the plan first, including its rules at the top; the design behind them is in `GAME_DESIGN.md` ("Camera", "Controls", "Views", "Multiplayer and simulation", "Pathing").

## Layout and branches
- Feature folders: `levels/sandbox/`, `camera/` (planned), `menus/`, `tuning/`, `debug/` (dev-only tools: `debug/tuning/` builds the tuning panel from the stats resources; `debug/playtest_log/`). Each mechanic doc lists its scripts. Headless test notes: `docs/testing.md`.
- Git: local repository only, no remote yet. Work happens on feature branches off `main` (one topic per branch); finished branches are merged and deleted.
