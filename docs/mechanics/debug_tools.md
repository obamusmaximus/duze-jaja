# Debug tools and the sandbox

Dev-only tooling, ported from `../first`. Gameplay never depends on any of it.

**Scripts:** `debug/tuning/tuning_panel.gd` (+ `.tscn`), `tuning_fields.gd`, `tuning_preview.gd`, `debug/tuning/visuals/tuning_visual.gd` (diagram base), `tuning_visuals.gd` (diagram registry); `menus/pause_menu.gd` (+ `.tscn`), `menus/game_settings.gd`; `debug/time_scale/time_scale_control.gd` (autoload `DebugTimeScale`); `levels/sandbox/sandbox.tscn` (+ `sandbox.gd`). Playtest log: `docs/playtest_log.md`.

## How it works
- **Pause menu** (`pause`, Esc): pauses the tree; Resume, Options (volume, fullscreen, saved to `user://settings.cfg` by `GameSettings`), Tuning (debug builds only), Quit. Every level instances it.
- **Tuning panel:** each tab in `TuningPanel.TABS` lists stats classes; every `.tres` in `tuning/` of those classes is shown. `TuningFields` reflects on the exported properties: each `@export_group` is a foldable section, each property a row (slider and number box, checkbox, colour button, or one box per float-array element). `@export_range` sets the slider range; otherwise it spans 0 to three times the value (`_db` names get a decibel range). Edits apply live and emit `changed`. "Save tab to .tres" writes the current tab back to disk; "Reset tab" reloads from disk. The `##` doc comment above each export is its tooltip and its description in the preview column.
- **Diagrams (tuning visuals):** hovering a row shows an animated diagram drawn from the live values, when one exists. A diagram extends `TuningVisual`, declares `static func covers() -> Dictionary` (stats class to property names) and overrides `setup()` and `paint()`; list it in `TuningVisuals.SCRIPTS`. Shared style and helpers (scale constants, `w()` top-down metres to pixels, `iso()`, arrows, rings, graphs) live in the base. None exist yet.
- **Slow time:** `debug_time_slower` / `debug_time_faster` (`[`, `]`) step `Engine.time_scale` through `TimeScaleStats.steps` (Debug tab) from the listed speed nearest the current one; `debug_time_reset` (`\`) returns to 1. A label at the top shows the speed while it isn't 1. Debug builds only. Views that should keep real speed divide their `delta` by `Engine.time_scale` (the camera rig does).
- **Map debug:** `debug_toggle_wall` (F3) raises and lowers a wall across the sandbox; `debug_show_map_grid` (F4) shows impassable cells and selected units' paths (`pathing.md`).
- **Sandbox:** the main scene for now. Flat ground on layer 1 with a ramp up to a plateau (for the camera's height following), a sun, a 2 m box at the origin for scale, the debug wall, the camera rig and player controls, the match nodes (`MapGrid`, `PathService`, `Shots`, `Units`, `CommandIssuer`); `sandbox.gd` wires them and builds the map on the first physics tick. The pause menu.

## Settled
- Tuning panel and playtest log carried over unchanged in behaviour from `../first`. Mouse capture and mouse sensitivity were dropped (an RTS keeps the cursor).

## Tried and passed on

## Known issues
- `hud_scale` scaling of the menus (in `../first`) isn't ported: there is no HUD stats class yet.
