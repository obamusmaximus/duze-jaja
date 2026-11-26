class_name FlightStats
extends Resource
## Tunable numbers of the jet control type's flight model (`FlightModel`), per aircraft type: `UnitStats.flight_model`
## points at one (none: tuning/flight_default.tres). RTS and AI flight (the autopilot) uses `UnitStats` "Flight".

@export_group("Engine and drag")
## The engine's fixed push, metres per second per second. Below gravity, so a long climb costs speed.
@export_range(0.5, 40.0, 0.1) var thrust: float = 8.0
## The level speed where drag eats all the thrust, metres per second: the top speed in level flight.
@export_range(5.0, 150.0, 0.5) var cruise_speed: float = 38.0
## Extra drag from the angle of attack, as a share of the lift made at the stall angle: how much hard turns bleed speed.
@export_range(0.0, 1.0, 0.01) var induced_drag: float = 0.22
## Extra drag once fully stalled, metres per second per second at cruise speed.
@export_range(0.0, 60.0, 0.5) var stall_drag: float = 8.0
## Extra drag of the air brake at cruise speed, metres per second per second (it grows with speed squared).
@export_range(0.0, 80.0, 0.5) var brake_drag: float = 14.0
## Gravity on this aircraft, metres per second per second.
@export_range(1.0, 30.0, 0.1) var gravity: float = 9.8

@export_group("Lift and stall")
## The slowest speed at which the wing can still hold the aircraft up, metres per second (lift grows with speed
## squared, so this also sets how tight it can turn).
@export_range(1.0, 80.0, 0.5) var stall_speed: float = 14.0
## The angle of attack where the wing gives its most lift; past it the wing stalls, degrees.
@export_range(5.0, 40.0, 0.5) var stall_angle_deg: float = 18.0
## How far past the stall angle (degrees) the lift takes to fall to its stalled level: wider is a softer stall.
@export_range(1.0, 40.0, 0.5) var stall_falloff_deg: float = 10.0
## The lift left in a full stall, as a share of the most.
@export_range(0.0, 1.0, 0.01) var post_stall_lift: float = 0.35
## How fast a stalled nose drops toward where the aircraft is going, degrees per second.
@export_range(0.0, 180.0, 1.0) var stall_nose_drop: float = 35.0

@export_group("Handling")
## Fastest pitch, degrees per second, with full control authority.
@export_range(10.0, 360.0, 1.0) var pitch_rate: float = 90.0
## Fastest roll, degrees per second.
@export_range(10.0, 720.0, 5.0) var roll_rate: float = 180.0
## Fastest yaw (rudder), degrees per second.
@export_range(1.0, 360.0, 1.0) var yaw_rate: float = 30.0
## How quickly the turn rates follow the controls (per second): lower feels heavier.
@export_range(1.0, 30.0, 0.5) var control_response: float = 8.0
## The speed from which the controls work fully, metres per second; slower, they get weaker.
@export_range(1.0, 80.0, 0.5) var full_control_speed: float = 22.0
## The share of control left when barely moving.
@export_range(0.0, 1.0, 0.01) var min_control: float = 0.25
## How strongly the aircraft settles, hands off, to the angle of attack that holds its flight path (per second).
@export_range(0.0, 12.0, 0.1) var pitch_stability: float = 3.0
## How strongly the nose swings into any sideslip (per second).
@export_range(0.0, 12.0, 0.1) var yaw_stability: float = 2.0
## How quickly sideways drift is turned back along the nose (per second): high never feels slippery.
@export_range(0.0, 20.0, 0.1) var side_grip: float = 2.5

@export_group("Transition (VTOL)")
## For a type switching here out of a hover: below this speed the engine still holds it up and it cannot stall, fading
## out by one and a half times this. Once past that, it flies on the wing alone. 0: no help. Until then the air brake
## also cuts thrust.
@export_range(0.0, 60.0, 0.5) var hover_speed: float = 0.0
## Climb or descent rate in the transition with the nose straight up or down, metres per second.
@export_range(0.0, 40.0, 0.5) var hover_climb_speed: float = 14.0
## How quickly the transition settles its climb, and with the air brake comes to a stop (per second).
@export_range(0.1, 10.0, 0.1) var hover_damping: float = 1.5

@export_group("Aim steering")
## Pitch and rudder input per radian the nose is off the aim: higher turns onto it harder (and can stall a slow aircraft).
@export_range(0.5, 20.0, 0.1) var steer_gain: float = 4.0
## Roll input per radian the wings are off the wanted bank: higher snaps into and out of turns.
@export_range(0.5, 20.0, 0.1) var steer_roll_gain: float = 3.0
## Eases the controls off before the target by the turn rate already there, seconds of turn: higher settles without
## overshooting, lower is livelier.
@export_range(0.0, 0.5, 0.005) var steer_damping: float = 0.08
## The turn the bank is chosen for, as turn rate per radian off the aim (per second): higher banks steeper for the
## same correction.
@export_range(0.1, 6.0, 0.05) var steer_turn_response: float = 1.5
## Closer to the aim than this (degrees) the nose is pointed with pitch and rudder.
@export_range(0.0, 45.0, 0.5) var steer_level_angle_deg: float = 4.0
## Further from the aim than this (degrees) it only pulls, once rolled into the turn; between the two it blends.
@export_range(1.0, 90.0, 0.5) var steer_bank_angle_deg: float = 20.0
## An aim below the nose by less than this (degrees) is pushed to, instead of rolling upside down to pull.
@export_range(0.0, 90.0, 1.0) var steer_push_angle_deg: float = 25.0

@export_group("Crashes")
## How much of the airframe's size reaches the ground and water: 1 is its full radius and height.
@export_range(0.1, 1.5, 0.05) var crash_ground_reach: float = 0.8
## Size of the ball cast against buildings, props and walls, as a share of the unit's radius.
@export_range(0.1, 1.5, 0.05) var crash_body_reach: float = 0.5
## Two flyers collide when closer than this share of their two radii (flat) and half their two heights.
@export_range(0.1, 1.5, 0.05) var crash_flyer_reach: float = 0.7
