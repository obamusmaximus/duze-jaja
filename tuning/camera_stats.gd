class_name CameraStats
extends Resource
## Tunable numbers for the RTS camera rig (free pan, rotation and zoom in the style of Red Alert 3 / C&C3, see
## GAME_DESIGN.md "Camera"). One .tres per preset (tuning/camera_default.tres), held by the camera rig.
##
## The rig is a focus point on the ground that the camera orbits: yaw turns around it, `distance` is how far the
## camera sits from it, and pitch follows from the zoom (flatter when close, steeper when far).

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
## How close to the screen edge (pixels, at the 2560x1440 base size) the mouse must be to scroll.
@export_range(1.0, 100.0, 1.0) var edge_margin_px: float = 12.0
## Drag pan (hold the drag button and move): ground metres moved per pixel of mouse movement, at the closest zoom.
## Scales with the distance like `pan_speed`.
@export_range(0.001, 1.0, 0.001) var drag_pan_per_px: float = 0.05
## Off: the ground follows the mouse while drag panning (grab the map). On: the camera moves the way the mouse moves.
@export var drag_pan_inverted: bool = false
## How quickly the focus point catches up with its target (per second). Higher is snappier; 0 means instant.
@export_range(0.0, 40.0, 0.5) var pan_smoothing: float = 14.0

@export_group("Rotation")
## Degrees of yaw per pixel of mouse movement while the rotate button is held.
@export_range(0.01, 2.0, 0.01) var rotate_per_px: float = 0.3
## Degrees of yaw per second from the rotate keys.
@export_range(10.0, 360.0, 1.0) var rotate_key_speed: float = 90.0
## How quickly the yaw catches up with its target (per second). 0 means instant.
@export_range(0.0, 40.0, 0.5) var rotate_smoothing: float = 16.0
## The yaw (degrees) the reset action returns to: 0 looks toward -Z, the map's "north".
@export_range(-180.0, 180.0, 1.0) var default_yaw: float = 0.0

@export_group("Zoom")
## Closest camera distance from the focus point, in metres.
@export_range(2.0, 100.0, 0.5) var min_distance: float = 12.0
## Farthest camera distance from the focus point, in metres.
@export_range(10.0, 400.0, 1.0) var max_distance: float = 70.0
## The distance a level starts at and the reset action returns to.
@export_range(2.0, 400.0, 0.5) var default_distance: float = 40.0
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

@export_group("Terrain")
## How quickly the focus point's height follows the ground under it (per second), so the camera rides over hills
## without jolting. 0 means instant.
@export_range(0.0, 40.0, 0.5) var height_follow_smoothing: float = 6.0
