class_name PlayerControlStats
extends Resource
## Tunable numbers for the RTS view's mouse and keyboard controls (player/, selection/, orders/ view side), held by
## the RtsPlayer (tuning/player_control_default.tres).

@export_group("Mouse")
## How far (pixels, at the 1920x1080 base size) the mouse must move with a button held before it counts as a drag
## (a box with the left button, a camera pan with the right) instead of a click.
@export_range(1.0, 60.0, 1.0) var drag_threshold_px: float = 10.0

## A flyer is clickable within at least this many pixels (at the 1920x1080 base size) of its body or its ground plate,
## however small it is on screen.
@export_range(4.0, 80.0, 1.0) var flyer_pick_min_px: float = 18.0

@export_group("Control groups")
## Two presses of the same group number within this many seconds centre the camera on the group.
@export_range(0.1, 1.5, 0.05) var group_double_tap_seconds: float = 0.4

@export_group("Feedback")
## How long the marker where an order landed stays, in seconds.
@export_range(0.1, 3.0, 0.05) var order_marker_seconds: float = 0.6
