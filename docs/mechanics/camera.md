# Camera rig (RTS view)

The RTS view's camera in the RA3 / C&C3 style. Design: `GAME_DESIGN.md` ("Camera", "Controls", "Views"). Tunables: `CameraStats` (`tuning/camera_default.tres`, Camera tab).

**Scripts:** `camera/camera_rig.gd` (+ `camera_rig.tscn`), `camera_input.gd`, `camera_pan.gd`, `camera_rotate.gd`, `camera_zoom.gd`, `camera_ground_follow.gd`, `camera_ease.gd`.

## How it works
- **`CameraRig`** (root `Node3D`) sits at the **focus point** on the ground and turns with the **yaw**; its `Camera` child sits `distance` along the arm, pitched down by the **pitch**. It owns no state itself: each part owns a target and a current value and eases the current toward the target with `CameraEase.weight(rate, delta)` (`1 - exp(-rate * delta)`, rate 0 = instant). The rig wires the parts in `_ready` and places the camera each frame.
- **Parts:** `CameraInput` reads the actions and mouse and sends signals up (`drag_moved`, `rotate_moved`, `zoom_notches`, `reset_pressed`); the rig polls `pan_direction()` and `rotate_direction()` for held keys and the screen edge. `CameraPan` owns the focus (x, z) and the map bounds clamp; `CameraRotate` the yaw (degrees, unwrapped, so reset turns the short way); `CameraZoom` the distance and `pitch()`; `CameraGroundFollow` the focus height (a ray down on layer 1 in `_physics_process`, eased in `_process`).
- **Pitch** blends `pitch_near` to `pitch_far` by `(distance - min_distance) / (max_distance - min_distance)` raised to `pitch_curve`.
- **Pan** by keys and the edge goes in screen directions turned by the yaw, at `pan_speed`, times `distance / min_distance` when `pan_scales_with_zoom`. **Drag pan** grabs the ground (it follows the mouse) unless `drag_pan_inverted`. **Edge scrolling** compares the mouse with the viewport's visible rect, in viewport units (the 1920x1080 base under the project's canvas_items stretch, which `edge_margin_px` is given in); an unfocused window doesn't scroll, nor does the edge while dragging or rotating. Once the cursor leaves the window (`NOTIFICATION_WM_MOUSE_EXIT`) the edge scrolls by its last position inside, until it re-enters. `confine_mouse` is off by default now: on macOS confinement made the cursor choppy and dropped motion (playtested). With it on, `CameraInput` keeps the cursor inside the window while the game runs (so the edge is reachable in a window) and frees it while paused or when the rig leaves.
- **Mouse-free fallback:** on a trackpad two-finger scroll (`InputEventPanGesture`, scaled by `trackpad_zoom_notches`) and pinch (`InputEventMagnifyGesture`, `trackpad_pinch_notches`) zoom; arrows pan, comma/period rotate, Page Up/Down zoom.
- **Zoom:** each wheel notch multiplies the distance by `1 + zoom_step` (the event's `factor` makes smooth-scrolling devices fractional), clamped to the limits every frame so live edits apply.
- **Real time:** the rig divides `delta` by `Engine.time_scale`, so it keeps full speed while the game is slowed (debug slow time, `debug_tools.md`).
- **API:** the level calls `setup(bounds: Rect2, home_yaw)` (x, z; degrees) after the rig is ready, and the home yaw is what reset returns to (`SandboxLevel.camera_yaw`); `focus_on(point)` jumps the focus (control groups, minimap, alerts); `reset()` returns yaw and zoom to the defaults; `get_camera()`.
- **Actions:** `camera_pan_left/right/forward/back` (arrows), `camera_rotate_left/right` (comma, period), `camera_drag` (RMB drag; a right click without moving is an order), `camera_rotate` (MMB), `camera_zoom_in/out` (wheel, Page Up / Page Down), `camera_reset` (Home).
- **Probe:** the rig is a playtest probe (`camera_rig`: `focus`, `yaw`, `distance`, `pitch`).
- **View only:** nothing in the simulation reads the rig. A later view switcher turns it off and makes another view's camera current.

## Settled
- Edge scrolling needs the cursor confined: a window doesn't capture it by itself, so the mouse left the window instead of resting on the edge.
- Positive yaw swings the camera right around the focus point; MMB drag right and the rotate-right key both do that.

## Tried and passed on
- Edge scrolling in real window pixels from `DisplayServer` (mouse minus window position): replaced by viewport coordinates, which match input events and the stretch without conversion.

## Known issues
- Keys for rotation and reset were picked without checking the RA3 / C&C3 manuals (`GAME_DESIGN.md`, "Controls").
- The camera can dip into a steep hill in front of the focus point: there is no camera collision.
