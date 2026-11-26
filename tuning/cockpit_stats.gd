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

@export_group("Speed view")
## Degrees the field of view widens by at high speed, on top of the base one.
@export_range(0.0, 40.0, 0.5) var speed_fov_gain: float = 12.0
## The speed where the widening starts, as a share of the type's level top speed (`FlightStats.cruise_speed`).
@export_range(0.0, 2.0, 0.05) var speed_fov_from: float = 0.6
## The speed where the widening is full, as a share of the level top speed (above 1 takes a dive).
@export_range(0.1, 3.0, 0.05) var speed_fov_to: float = 1.5
## How quickly the field of view follows the speed (per second).
@export_range(0.5, 20.0, 0.5) var speed_fov_response: float = 3.0

@export_group("Shake")
## Camera shake at high speed, degrees.
@export_range(0.0, 3.0, 0.01) var shake_speed: float = 0.12
## The speed where the shake starts, as a share of the type's level top speed.
@export_range(0.0, 2.0, 0.05) var shake_speed_from: float = 0.85
## The speed where the speed shake is full, as a share of the level top speed.
@export_range(0.1, 3.0, 0.05) var shake_speed_to: float = 1.5
## Camera shake in a stall (the buffet), degrees.
@export_range(0.0, 5.0, 0.05) var shake_stall: float = 0.6
## The buffet starts at this share of the stall angle and is full at the stall.
@export_range(0.3, 1.0, 0.01) var shake_stall_from: float = 0.8
## How fast the camera shakes: higher is a finer, quicker rattle.
@export_range(1.0, 40.0, 0.5) var shake_frequency: float = 14.0
## How quickly the shake comes and goes (per second).
@export_range(0.5, 30.0, 0.5) var shake_response: float = 10.0

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
## How far the mouse's directions roll with the plane. 0: mouse up is always toward the sky. 1: mouse up is always
## toward the top of the screen, whatever the bank.
@export_range(0.0, 1.0, 0.05) var aim_roll_follow: float = 0.0
## How strongly the aim is pulled back to the centre (per second), so the plane levels out without the aim being put
## there by hand. Higher centres sooner, and holding a turn then takes more mouse movement. 0: the aim stays where it
## is left.
@export_range(0.0, 8.0, 0.05) var aim_correction: float = 0.8

@export_group("Stick (WASD, jet)")
## Swaps W and S. Off: W raises the nose, S lowers it. On: S raises it, as pulling a flight stick back does.
@export var stick_invert_pitch: bool = false
## While the stick flies the plane, the aim goes along with its flight path, so letting go holds that course. Off: the
## aim stays put and the plane goes back to it.
@export var aim_follows_stick: bool = true

@export_group("Free look")
## How quickly the mouse stick returns to centre while free look is held (per second), so the craft stops turning.
@export_range(0.5, 40.0, 0.5) var free_look_aim_return: float = 6.0
## How far the head turns to each side while free look is held, degrees.
@export_range(10.0, 175.0, 1.0) var look_yaw_limit: float = 150.0
## How far the head tilts up or down while free look is held, degrees.
@export_range(10.0, 89.0, 1.0) var look_pitch_limit: float = 80.0
## How quickly the head comes back to the front after free look is let go (per second).
@export_range(1.0, 40.0, 0.5) var look_return_rate: float = 10.0
