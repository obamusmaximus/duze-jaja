# RTS controls: picking, selection, control groups, order clicks

The local player's RTS-view controls (the left-click scheme in `GAME_DESIGN.md`, "Controls"). View side: they change the game only by sending orders (`orders.md`). Tunables: `PlayerControlStats` (`tuning/player_control_default.tres`, Controls tab).

**Scripts:** `picking/ground_pick.gd`; `player/rts_player.gd` (+ `rts_player.tscn`), `player/pointer_input.gd`; `selection/selection.gd`, `selection_control.gd`, `control_groups.gd`, `selection_box.gd`; `orders/order_control.gd`, `order_marker.gd`. Level wiring: `levels/sandbox/sandbox.gd`.

## How it works
- **Ground picking (`GroundPick`, static):** `ground_point(viewport, screen_point)` casts from the viewport's active camera on layer 1 and returns the hit or `GroundPick.NONE` (test `is_finite()`); `object_under()` returns the unit or building (layers 2, 3) under the point, unless ground is in front of it. Call from `_physics_process`. Everything that clicks the world goes through it.
- **`RtsPlayer`** (one per local player, `setup(team, selection, issuer, camera_rig)`) wires the parts. `PointerInput` reports gestures decided on release: a left press moved past `drag_threshold_px` is a box, otherwise a click (with the OS double-click flag); a right press that didn't move that far is a click (farther was a camera drag pan). `RtsPlayer` queues gestures and resolves them on the next physics tick, where picking is safe.
- **What a left click does:** own unit → select it (unless attack-move is armed); else, with a selection: enemy → attack, ground → move (or attack-move when armed); without a selection, an enemy is inspected (probe event; the HUD will show it). Right click: cancel attack-move, else clear the selection.
- **`Selection`** (owned by the level) is the player's list of own units, signal `changed`; it shows and hides the rings and drops units that leave the match.
- **`SelectionControl`:** click replaces the selection; `select_add` (Shift) toggles a clicked unit or adds a box; double-click selects every own unit of the type on screen. A box projects unit centres to the screen (`unproject_position`), no physics, own team only. Probe: `selected` ids; events `select`, `box_select`, `inspect`.
- **`ControlGroups`:** `control_group_set` (Ctrl or Cmd) + `control_group_<n>` stores the selection; the number recalls it; the same number again within `group_double_tap_seconds` (real time) also calls `CameraRig.focus_on` with the group's centre. Events `group_set`, `group_recall`.
- **`OrderControl`:** builds orders from the selection and sends them to the `CommandIssuer`. `order_queue` (Alt) held queues a waypoint; `order_attack_move` (A) arms attack-move for the next left click; `order_stop` (S) stops. Feedback: the cursor (move over ground, cross over enemies or while armed) and an `OrderMarker` ring where an order landed, for `order_marker_seconds` (real time).
- **Health bars** (`HealthBars`, `combat.md`) are drawn in `RtsPlayer`'s `BarLayer`.
- **Actions:** `select` (LMB), `deselect` (RMB), `select_add` (Shift), `control_group_set` (Ctrl, Cmd), `control_group_0..9` (number row), `order_attack_move` (A), `order_stop` (S), `order_queue` (Alt).

## Settled

## Tried and passed on

## Known issues
- Keys for attack-move, stop and the modifiers were picked without checking the RA3 / C&C3 manuals.
- Ctrl+number can be taken by macOS (Mission Control desktop shortcuts); Cmd+number works too.
- Inspecting an enemy has no HUD yet (step 9).
