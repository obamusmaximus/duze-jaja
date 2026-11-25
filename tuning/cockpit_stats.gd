class_name CockpitStats
extends Resource
## Tunable numbers for the first-person view of an inhabited unit (views/cockpit/, tuning/cockpit_default.tres).
## Where each type's pilot sits is on the type itself (`UnitStats.cockpit_offset`).

@export_group("Camera")
## Vertical field of view in the cockpit, degrees.
@export_range(40.0, 110.0, 1.0) var fov: float = 75.0
## Nearest distance the cockpit camera draws, metres.
@export_range(0.02, 1.0, 0.01) var near: float = 0.15
## Farthest distance the cockpit camera draws, metres: it looks to the horizon.
@export_range(1000.0, 40000.0, 500.0) var far: float = 12000.0

@export_group("Switch")
## Seconds the camera takes to fly into the cockpit, and back out to the RTS view.
@export_range(0.05, 3.0, 0.05) var transition_time: float = 0.9
## Share of the flight in after which the unit's own airframe is hidden (before that you see what you fly into).
@export_range(0.0, 1.0, 0.01) var hide_airframe_blend: float = 0.8

@export_group("Mouse aim")
## Degrees the aim turns per pixel of mouse movement.
@export_range(0.01, 1.0, 0.005) var aim_sensitivity: float = 0.1
## Mouse forward looks down instead of up (aim and free look).
@export var invert_y: bool = false
## How far (degrees, to the side) the aim may lead the nose, so it never gets lost behind the plane.
@export_range(5.0, 175.0, 1.0) var aim_max_off_nose: float = 35.0
## How far above or below level the aim may point, degrees.
@export_range(5.0, 89.0, 1.0) var aim_pitch_limit: float = 60.0
## Radius of the placeholder aim mark, pixels at the 1920x1080 base size.
@export_range(2.0, 40.0, 1.0) var aim_mark_radius: float = 10.0

@export_group("Free look")
## How far the head turns to each side while free look is held, degrees.
@export_range(10.0, 175.0, 1.0) var look_yaw_limit: float = 150.0
## How far the head tilts up or down while free look is held, degrees.
@export_range(10.0, 89.0, 1.0) var look_pitch_limit: float = 80.0
## How quickly the head comes back to the front after free look is let go (per second).
@export_range(1.0, 40.0, 0.5) var look_return_rate: float = 10.0
