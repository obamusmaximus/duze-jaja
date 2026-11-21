# STATUS

Loaded into every session through `CLAUDE.md`, so keep it short: this is an index. Mechanic detail goes in `docs/mechanics/`, not here.

**Playtesting:** the user playtests thoroughly after every feature. If they don't mention a feature, it works as intended. Don't label things "not playtested".

_Last updated: 2026-11-21_

## Current state
| Mechanic | Doc (`docs/mechanics/`) | Where it stands |
|---|---|---|
| Debug tools (tuning panel, pause menu, playtest log) | `debug_tools.md`, `../playtest_log.md` | Ported from `../first`. Tuning panel has one tab (Debug); no diagrams yet. Playtest log has no probes yet. |
| Sandbox level | `debug_tools.md` | `levels/sandbox/sandbox.tscn` (main scene): flat ground, sun, a 2 m scale marker, a fixed placeholder camera, the pause menu. |

## Current goals
1. **Decide the camera model** (`GAME_DESIGN.md`, "Camera"), then build the RTS camera rig.
2. **First playable loop:** select units, order them to move.

## Cross-cutting known issues and gotchas
- Typed `@export var x: Camera3D` loads as null from a `.tscn`. Verify any node export.
- GDScript 4.7: `Array[T]()` doesn't parse (declare a typed local first). A `const` can't hold `PackedVector3Array([...])`. Scalars passed to functions are copies, so return results.

## Next up
1. Camera rig (pan, zoom, rotate as decided) with its own stats class and tuning tab.
2. Unit selection (click, box select) and move orders on the ground plane.
3. Pathfinding and group movement (NavigationServer3D vs flow fields: open).

## Layout and branches
- Feature folders: `levels/sandbox/`, `menus/`, `tuning/`, `debug/` (dev-only tools: `debug/tuning/` builds the tuning panel from the stats resources; `debug/playtest_log/`). Each mechanic doc lists its scripts. Headless test notes: `docs/testing.md`.
- Git: local repository only, no remote yet. Work happens on feature branches off `main` (one topic per branch); finished branches are merged and deleted.
