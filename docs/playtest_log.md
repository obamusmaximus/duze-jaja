# Playtest log (debug tool)

Read this before reading a playtest log or changing what it records. **Read logs only when the user asks.**

**Scripts:** `debug/playtest_log/playtest_log.gd` (autoload `PlaytestLog`: buffer, L key, saving), `playtest_log_writer.gd` (`PlaytestLogWriter`), `saved_toast.gd`. Tunables: `PlaytestLogStats` (tuning panel, Debug tab).

## How it works
- `PlaytestLog` keeps the last `buffer_seconds` (real time) of physics frames. `save_playtest_log` (L) writes them to `playtest_logs/<date>_<time>.jsonl` plus a screenshot `.png` of that moment. The folder is gitignored and has a `.gdignore` so the editor doesn't import it. Exported builds write to `user://playtest_logs/`. L works while paused.
- **Probes:** any node in the group `playtest_probe` with `playtest_snapshot() -> Dictionary` is sampled every physics frame, after all other nodes (`process_physics_priority`). Its data goes under the node's name in snake_case. A probe's `playtest_event(event, data)` signal adds event lines. The recorder knows nothing about gameplay; to log another system, make it a probe.
- **No probes exist yet.** Likely first ones: the camera rig, the selection (selected unit ids, last order), and a per-unit summary (keep it small: hundreds of units every frame makes big files; sample a chosen few or log only events).

## Reading a log
- Line 1 is a header (`frames`, `physics_hz`, `saved_at`, `scene`). Then lines in time order: `type: "frame"` (`f`, `t` real seconds, `game_t`, `dt`, `time_scale`, one object per probe) and `type: "event"` (`event`, `f` = the last frame before it, plus its data). Vectors are `[x, y, z]`, y is up.
- Start from the end of the file (the moment L was pressed) and from the user's description.
