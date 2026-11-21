# CLAUDE.md

## Project
- **Engine:** Godot 4 (project is on 4.7, GL Compatibility renderer, Jolt physics). Use Godot 4 APIs only. Don't use Godot 3 patterns such as `KinematicBody`, `yield`, or `export var`.
- **Language:** GDScript only.
- **Genre:** Top-down 3D real-time strategy, built along the lines of Red Alert 3 / C&C3 (free camera, left-click control scheme; see `GAME_DESIGN.md`). Groundwork build order: `docs/plans/groundwork.md`.

## Code conventions
- **Use typed GDScript everywhere.** Give types to variables, parameters, return values, and `@export`s (e.g. `var speed: float = 5.0`, `func move() -> void:`). Use `:=` when the type is obvious.
- **Keep scripts small and focused.** Each script should have one responsibility. Split growing logic into child nodes or components. Don't build large "god" scripts.
- Use `class_name` for reusable scripts.
- Prefer signals over hard references between unrelated nodes.
- **Signals up, direct calls down:** a node reports events upward with signals, and calls its own children directly.
- **One scene per object**, and **group files by feature** (e.g. `units/` holds unit scenes and scripts).
- **All tunable numbers live in stats resources in `tuning/`** (one class per owner, each with a `*_default.tres`), never as `@export`s on gameplay scripts. Add a tunable as an `@export` in the right class, inside an `@export_group` (it becomes a sub-label in the tuning panel) and with a `##` doc comment (it becomes the tooltip). Owners hold the resource and hand it to their parts through `setup()`; parts read `stats.x`. Parts that cache a value listen to the resource's `changed` signal so live edits apply. A new stats class needs listing in `TuningPanel.TABS`. A unit type is a stats class; a variant of it is just another `.tres`.
- **The `.tres` files are the source of truth.** The user tunes live and saves them between sessions, so values change between prompts. That is normal: don't be surprised by a changed value, don't "fix", reset or revert it. Never write tunable values into the docs (name the parameter), and treat any number in a doc as possibly stale.
- **Use named input actions** from the Input Map, never raw keys. Current actions: `pause` (Esc), `save_playtest_log` (L); the camera's are listed in `docs/mechanics/camera.md`, selection and order keys in `rts_controls.md`, slow time's in `debug_tools.md`.
- **Movement and raycasts go in `_physics_process`**, not `_process`.
- **Keep the simulation apart from views** (`GAME_DESIGN.md`, "Multiplayer and simulation"). Units, orders, pathing, combat and map changes run on the fixed tick and never read a camera, the mouse, the selection or the HUD, so a headless server can run them. Views, players and AI change the game only by sending `Order` data through `CommandIssuer`. Never assume the map is fixed: it changes during a match.
- **Collision layers:** 1 World, 2 Unit, 3 Building, 4 Projectile. Use these when setting `collision_layer` and `collision_mask`. The names are set in `project.godot`.
- Use `@onready var x: Type = $Path` for node references. Don't call `get_node` repeatedly.
- Follow the official GDScript style guide: `snake_case` for files, functions, and variables; `PascalCase` for classes and nodes.

## Session workflow
- **`STATUS.md` is imported at the end of this file**, so it is already loaded at the start of every session.
- **Working on a mechanic? Read its doc in `docs/mechanics/`** (the glossary below says which) before touching its scripts, and read only the scripts it lists unless the task needs more.
- **Building groundwork?** `docs/plans/groundwork.md` is the build order; tick a step there when it lands.
- **Writing a headless test?** Read `docs/testing.md` first.
- **At the end of a task, update the mechanic's doc, then `STATUS.md`.** Follow the documenting principles in `docs/mechanics/README.md`.
- Several sessions may work in this checkout at once, one per mechanic. Touch only your mechanic's doc, and re-read `STATUS.md` right before editing it.
- `GAME_DESIGN.md` is optional reading for design discussions.
- **Playtest logs** (`playtest_logs/`, saved in game with L): read them only when the user asks, and read `docs/playtest_log.md` first.
- The sibling project `../first` (an FPS) is where these conventions and debug tools came from. Look there for prior art when a tool or pattern is needed again, but don't edit it.

## Glossary
Game-specific terms. Use them consistently in code, comments and conversation. Each is defined in the mechanic doc in brackets (all in `docs/mechanics/`).

- **[`camera.md`]** focus point, yaw, distance, pitch, pan, drag pan, edge scrolling, reset
- **[`units.md`]** unit, unit type, team, unit id, unit registry, brain
- **[`pathing.md`]** map grid (map model), cell, clearance, path service, shared path, navigator, separation (soft collision), crowd arrival, stuck, map change
- **[`combat.md`]** health, weapon, fire arc, targeting, doomed (overkill), shots, return fire, hold ground, leash
- **[`orders.md`]** order, `CommandIssuer`, order queue, group move, waypoint, attack-move
- **[`rts_controls.md`]** ground pick, selection, box select, control group, inspect
- **[`GAME_DESIGN.md`, until each has a doc]** view (RTS, strategy, first-person), inhabit, simulation, guidelines (Leitlinien), AI commander
- **[`debug_tools.md`]** tuning panel, stats resource, tab, diagram (tuning visual), pause menu, sandbox, playtest log, probe, slow time

- **Dev-only tools live in `debug/`** (one subfolder per tool) and their scripts start their doc comment with "Debug:". Gameplay must never depend on them; they hook in through groups and signals.

## Dependencies
- **Ask before adding any addon or plugin** (Asset Library, `addons/` folder, GDExtension). Prefer built-in engine features.

## Notes
- **Levels share principles.** A change to how levels in general work (wiring, what they hand units, conventions) goes into all of them. Level-specific geometry doesn't. Every level instances `menus/pause_menu.tscn`.
- Don't edit files in `.godot/`. It's generated cache.

@STATUS.md
