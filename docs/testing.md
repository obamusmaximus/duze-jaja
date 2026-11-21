# Headless testing

Read before writing a headless or `--script` test harness. Add a line here when a harness trips on something new.

- New `class_name`s need `godot --headless --import` before headless runs can see them.
- A `--script` harness (`extends SceneTree`) can't name autoloads as globals at compile time: reach them with `root.get_node("PlaytestLog")`.
- Headless runs have no renderer, so `PlaytestLog`'s screenshot logs a harmless "Parameter t is null" error.
- Code that uses `get_tree().current_scene` gets null when a script adds the level to `root`.
- Run one level load per process when comparing several loads.
- A GDScript lambda captures locals by value: assigning to an outer variable inside one (a signal callback collecting results) changes nothing outside. Mutate a container instead (`got[0] = x`).
- For a deterministic run (comparing a trace before and after a refactor), pass `--fixed-fps 60`; without it the physics step count follows wall time.
- A screenshot script on a small window must set `root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED`, or the project's 2560x1440 stretch shrinks everything to a corner.
- Keep harness scripts out of the project folder (or delete them after the run, with their `.uid`).
- Push input with `root.push_input(event, true)` (local coordinates) to use viewport points such as `unproject_position()`; without `true` the event is mapped from the tiny headless window and lands far off.
- Headless reports the mouse at (0, 0), a screen corner: turn off `CameraStats.edge_scroll_enabled` in the test or the camera pans away.
- Measure cost by wall time over many ticks (`Time.get_ticks_usec()` around a loop of `await physics_frame`); `Performance.TIME_PHYSICS_PROCESS` sampled from a harness gives misleading numbers headless.
- The level builds the map and registers units on its first physics tick: wait a few ticks after adding it. A unit that died is freed at the end of the frame: check `is_instance_valid()` before reading one you held.
