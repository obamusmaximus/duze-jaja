# Build plan: RTS groundwork

The order for building the basic RTS layer: camera, selection, orders, movement, basic combat. Design is in `GAME_DESIGN.md` ("Camera", "Controls", "Changing maps", "Views", "Multiplayer and simulation", "Pathing"); this file is only the build order. **Work top to bottom, one step per branch.** When a step lands, give it a mechanic doc in `docs/mechanics/` (or extend one), add its row to `STATUS.md`, and tick it here. Delete this file once every step is done; anything left over goes into `STATUS.md` "Next up".

**Rules that shape every step** (from `GAME_DESIGN.md`):
- **Simulation apart from views.** Units, orders, pathing, combat and map changes run on the fixed tick (`_physics_process`) and never read the camera, mouse, selection or HUD. They must run headless, because a server will run them later. Visual-only things (rings, trails, markers) sit apart.
- **Orders are the only way in.** Views and AI change the game only by sending `Order` data through `CommandIssuer`.
- **Maps change.** Nothing assumes a map baked once at load: the map grid (step 7) is the one map model.
- **About 100 units in a battle** is the performance target. Networking itself is not part of the groundwork.

Every step follows `CLAUDE.md`: tunables in a stats class in `tuning/` with a `*_default.tres` and a `TuningPanel.TABS` entry, named input actions only, small scripts, signals up and direct calls down. Each step ends with a headless check (`docs/testing.md`) and a hand-off to the user for a playtest. Where a step says "probe", make the node a playtest-log probe (`docs/playtest_log.md`).

## 1. Camera rig  [x]
**Uses:** `CameraStats` (exists, `tuning/camera_default.tres`, Camera tab).
- `camera/camera_rig.tscn` + scripts. A root `Node3D` at the **focus point** on the ground; yaw turns the root; the `Camera3D` child sits at `distance` along the pitched arm. Pitch comes from the distance: blend `pitch_near` to `pitch_far` by `(distance - min_distance) / (max_distance - min_distance)` raised to `pitch_curve`.
- Keep target values (focus, yaw, distance) apart from the current ones, and ease the current toward the target with the `*_smoothing` rates (frame-rate independent: `1 - exp(-rate * delta)`).
- Split by job: input reading (`CameraInput`), pan, rotate, zoom, ground-height follow (raycast down on layer 1, smoothed by `height_follow_smoothing`), map bounds clamp.
- Input actions to add: `camera_pan_left/right/forward/back` (arrows), `camera_drag` (RMB), `camera_rotate` (MMB), `camera_zoom_in/out` (wheel), `camera_reset` (key to confirm). Edge scrolling uses the mouse position against `edge_margin_px` (scale it from the 1920x1080 base to the real window).
- **Map bounds:** the level hands the rig a `Rect2` (`setup(bounds)`); the focus point is clamped inside it.
- Public API for later steps: `focus_on(position: Vector3)` (control-group jumps, minimap click, alerts), `reset()`.
- Probe: focus point, yaw, distance, pitch.
- The rig is the RTS view only: it owns its camera, input and nothing else, so a view switcher can later turn it off and hand over to the strategy or first-person view.
- Replace the fixed camera in the sandbox with the rig. Give the sandbox some height (a ramp or hill) to check the height following.
- **Done when:** all of pan (keys, edge, drag), rotate, zoom with pitch change, reset and bounds work, and changing the Camera tab live changes the feel.

## 2. Slow time (dev tool)  [x]
- `debug/time_scale/`: actions `debug_time_slower`, `debug_time_faster`, `debug_time_reset` (keys to pick) step `Engine.time_scale` through a few fixed values, with a small label showing the speed when it isn't 1. Debug builds only, as all of `debug/`.
- The camera rig must stay at full speed while time is slowed (scale its smoothing `delta` by `1 / Engine.time_scale`), so the player can watch slowed fights normally.
- **Done when:** the simulation visibly slows and speeds up, the camera doesn't, and reset returns to 1.

## 3. Ground picking  [x]
- One shared helper (`class_name GroundPick`, static): screen point to ground point (ray from the active camera, layer 1), and screen point to the unit or building under the cursor (layers 2 and 3). Everything that clicks the world goes through it.
- **Done when:** a headless test turns known screen points into the expected ground points.

## 4. Units and teams  [x]
- `units/unit.tscn`: `CharacterBody3D` on layer 2 (masks 1, 2, 3), a placeholder mesh, a selection ring (hidden), a `team: int` (owner). `UnitStats` (speed, turn rate, radius, health, sight). A unit type is a stats class or a `.tres`.
- A `Unit` only holds its parts; movement, health, weapon and order queue are child components.
- **Movement takes a wanted velocity from a "brain"**: for now the order queue, later direct control in first person. Keep the brain swappable.
- Each unit has a stable `id` (int, unique per match) so orders, the network and saves can name it.
- Groups: `units`, plus `team_<n>`. Signals: `died`, `selected_changed`.
- Spawn a handful of team 0 and team 1 units in the sandbox.

## 5. Selection  [x]
- `selection/` with a `Selection` node owned by the level (the player's selection: a typed list of units, signal `changed`).
- Controls from `GAME_DESIGN.md`: click select, left-drag box select (project unit positions to the screen and test against the rectangle, don't use physics for the box), Shift add or remove, double-click to select all of a type on screen, right-click to clear. Only own-team units are selectable in a box; clicking an enemy shows its info but doesn't add it to the selection.
- Draw the drag box (a `Control` on a `CanvasLayer`) and the rings.
- **Control groups:** Ctrl+number makes a group, number selects it, number twice calls `CameraRig.focus_on` with the group's centre.
- Left-click is also the order click (step 6). Decide it on release: a drag past a small threshold is a box; otherwise, with a selection and the cursor on ground or an enemy, it's an order; otherwise it's a select.
- Probe: selected unit ids. Events: `select`, `box_select`, `group_set`, `group_recall`.

## 6. Orders  [x]
- An `Order` (move, attack, attack-move, stop; with target position or unit) and an order queue component on each unit. A new order replaces the queue; Alt+click adds a waypoint.
- An `Order` is plain data (kind, unit ids, target position or unit id, queued flag), never node references, so it can be sent over the network later.
- A `CommandIssuer` turns clicks plus the selection into orders. It's the only place orders come from: the strategy and first-person views, the AI and the network will use the same path. It takes the issuing team, and refuses orders for units that aren't that team's.
- **Group move:** don't send every unit to the same point. Spread the destinations into a loose block around the clicked point, facing the travel direction, spaced by unit radius.
- Cursor feedback: a move cursor over ground, an attack cursor over enemies. A short marker where an order landed.
- Events: `order` (kind, target, unit count).

## 7. Map grid, movement and pathing  [x]
- `map/`: a `MapGrid` (the map model from `GAME_DESIGN.md`, "Pathing"): cell size, and per cell the ground height, passable or not, and move cost. The level builds it at load by sampling its ground and marking obstacles. It has `set_blocked(rect, blocked)` and a `cells_changed(rect)` signal for map changes.
- Paths: `AStarGrid2D` over the grid; smooth the cell path (drop corners that a straight line can skip) so units don't zigzag. Slopes above a limit block a cell. Hot code stays in the engine's `AStarGrid2D`; measure before considering flow fields.
- Units follow their path and steer apart from nearby units (separation) on the fixed tick, speed and turn rate from `UnitStats`. Arrival: a unit blocked near its goal by others counts as arrived, so groups don't jostle forever.
- **Changing map test:** a debug key raises and lowers a wall across the sandbox; units whose path crosses it re-path, and ones heading through it go around.
- Stress test: 100 units ordered across the map. Note the frame time in the mechanic doc.
- Probe events: `repath`, `map_change`.

## 8. Basic combat  [x]
- `Health` component (`died` signal), `Weapon` component (range, cooldown, damage, projectile or instant: in a `WeaponStats`), target acquisition (nearest enemy in range, re-checked on a timer, not every frame).
- Behaviour by order: attack chases its target; attack-move fights anything met on the way, then carries on; idle units return fire and hold their ground; stop clears everything.
- Health bars over units (shown when damaged or selected), death removal.
- Probe events: `attack`, `death`.

## 9. HUD shell  [~]  (selection panel, minimap and command grid placeholder built: `docs/mechanics/ui.md`; enemy inspect and camera clearing the bar open)
- Bottom-right panel with the selection (count and type icons, or one unit's health). A placeholder minimap frame with click-to-move-camera and the camera's view cone. No sidebar or production yet: that's after the groundwork (`GAME_DESIGN.md`, "Production").

## After the groundwork (not planned here)
Networking (server-authoritative), the strategy view and guidelines (Leitlinien), first-person control of a unit, the AI commander (enemy and friendly delegate), buildings and placement, the sidebar build queue, the economy (harvesting), fog of war, pause rules in multiplayer, the right-click order scheme option.
