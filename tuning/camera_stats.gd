class_name CameraStats
extends Resource
## Tunable numbers for the RTS camera rig (free pan, rotation and zoom in the style of Red Alert 3 / C&C3, see
## GAME_DESIGN.md "Camera"). One .tres per preset (tuning/camera_default.tres), held by the camera rig.
##
## The rig is a focus point on the ground that the camera orbits: yaw turns around it, `distance` is how far the
## camera sits from it, and pitch follows from the zoom (flatter when close, steeper when far).

enum DragMode { GRAB, FLY }

@export_group("Pan")
## Pan speed from keys and edge scrolling, in metres per second at the closest zoom. Scaled up with the distance
## when `pan_scales_with_zoom` is on, so the screen crosses at a similar rate at every zoom.
@export_range(1.0, 200.0, 0.5) var pan_speed: float = 25.0
## Multiply pan speed by distance / min_distance, so zoomed out pans cover more ground.
@export var pan_scales_with_zoom: bool = true
## Scroll when the mouse is at the screen edge.
@export var edge_scroll_enabled: bool = true
## Keep the cursor inside the game window while playing (freed while paused), so the edge can be reached in a
## window too.
@export var confine_mouse: bool = false
## How close to the screen edge (pixels, at the 1920x1080 base size) the mouse must be to scroll.
@export_range(1.0, 100.0, 1.0) var edge_margin_px: float = 12.0
## Grab drag pan (hold the drag button and move): ground metres moved per pixel of mouse movement, at the closest zoom.
## Scales with the distance like `pan_speed`.
@export_range(0.001, 1.0, 0.001) var drag_pan_per_px: float = 0.05
## Off: the ground follows the mouse while drag panning (grab the map). On: the camera moves the way the mouse moves.
@export var drag_pan_inverted: bool = false
## What holding the drag button (right mouse) does. Grab: the ground follows the mouse (the strategy views). Fly: the
## view flies away from the point the button went down on, faster the farther the cursor is pulled (C&C style, the
## RTS view); a click without a pull is still an order.
@export_enum("Grab", "Fly") var drag_mode: int = 1
## Fly: how far (pixels, 1920x1080 base) the cursor must be pulled from the anchor before the view starts to move.
@export_range(0.0, 60.0, 1.0) var fly_deadzone_px: float = 10.0
## Fly: ground metres per second for each pixel of pull beyond the dead zone, at the closest zoom. Scales with the
## distance like `pan_speed`.
@export_range(0.01, 5.0, 0.01) var fly_speed_per_px: float = 0.25
## Fly: the pull (pixels) beyond which the speed stops rising.
@export_range(50.0, 1000.0, 10.0) var fly_max_px: float = 400.0
## Zoom toward the point under the cursor instead of the screen centre (the strategy views).
@export var zoom_to_cursor: bool = false
## How quickly the focus point catches up with its target (per second). Higher is snappier; 0 means instant.
@export_range(0.0, 40.0, 0.5) var pan_smoothing: float = 14.0

@export_group("Rotation")
## Degrees of yaw per pixel of mouse movement while the rotate button is held.
@export_range(0.01, 2.0, 0.01) var rotate_per_px: float = 0.3
## Degrees of yaw per second from the rotate keys.
@export_range(10.0, 360.0, 1.0) var rotate_key_speed: float = 90.0
## How quickly the yaw catches up with its target (per second). 0 means instant.
@export_range(0.0, 40.0, 0.5) var rotate_smoothing: float = 16.0
## The yaw (degrees) the camera starts at, until a level sets its own home yaw: 0 looks toward -Z, the map's "north".
@export_range(-180.0, 180.0, 1.0) var default_yaw: float = 0.0

@export_group("Zoom")
## Closest camera distance from the focus point, in metres.
@export_range(2.0, 100.0, 0.5) var min_distance: float = 12.0
## Farthest camera distance from the focus point, in metres.
@export_range(10.0, 4000.0, 1.0) var max_distance: float = 70.0
## Zoom notches per unit of two-finger trackpad scroll (fallback without a mouse wheel).
@export_range(0.05, 5.0, 0.05) var trackpad_zoom_notches: float = 0.5
## Pixels of mouse-rotate per unit of sideways two-finger scroll while Option (Alt) is held, so `rotate_per_px`
## applies: higher turns faster.
@export_range(1.0, 100.0, 1.0) var trackpad_rotate_px: float = 20.0
## Zoom notches per unit of log pinch scale on a trackpad: higher zooms more for the same pinch.
@export_range(1.0, 40.0, 0.5) var trackpad_pinch_notches: float = 8.0
## The distance a level starts at and the reset action returns to.
@export_range(2.0, 4000.0, 0.5) var default_distance: float = 40.0
## Fraction of the current distance one mouse-wheel notch zooms by, so each notch feels the same at every zoom.
@export_range(0.01, 0.5, 0.01) var zoom_step: float = 0.12
## How quickly the distance catches up with its target (per second). 0 means instant.
@export_range(0.0, 40.0, 0.5) var zoom_smoothing: float = 10.0
## Pitch (degrees down from the horizon) at `min_distance`. Lower is flatter, more cinematic.
@export_range(5.0, 89.0, 0.5) var pitch_near: float = 35.0
## Pitch (degrees down from the horizon) at `max_distance`. Higher is closer to straight down.
@export_range(5.0, 89.0, 0.5) var pitch_far: float = 60.0
## Shape of the pitch blend between near and far: 1 is linear, above 1 keeps the camera flat for longer as it
## zooms out.
@export_range(0.2, 5.0, 0.05) var pitch_curve: float = 1.0
## Vertical field of view of the camera, in degrees.
@export_range(10.0, 90.0, 0.5) var fov: float = 40.0

@export_group("Far view")
## The far plane is at least this many times the camera's distance from the focus point, so a zoomed-out view
## (kilometres across) still sees the whole map. A level's own larger far plane is kept.
@export_range(1.0, 5.0, 0.1) var far_per_distance: float = 2.5
## The near plane is this fraction of the distance (never below 0.1 m), which keeps depth precision when zoomed out.
@export_range(0.0, 0.2, 0.005) var near_per_distance: float = 0.03

## Keeps the sky out of the view: the top screen edge looks at least this many degrees below the horizon, so the
## pitch is raised to half the field of view plus this. 0 turns the guard off. The bird's-eye preset uses it.
@export_range(0.0, 60.0, 0.5) var sky_margin: float = 0.0

@export_group("Terrain")
## How quickly the focus point's height follows the ground under it (per second), so the camera rides over hills
## without jolting. 0 means instant.
@export_range(0.0, 40.0, 0.5) var height_follow_smoothing: float = 6.0
