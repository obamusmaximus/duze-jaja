class_name HoverStats
extends Resource
## Tunable numbers of the hover control type (`HoverModel`), per hovering craft: `UnitStats.hover_flight` points at
## one. Heavier craft get lower rates. RTS and AI flight (the autopilot) uses `UnitStats` "Flight".

@export_group("Moving")
## Top speed forward, metres per second.
@export_range(1.0, 80.0, 0.5) var speed: float = 20.0
## Top speed sideways, as a share of the speed forward.
@export_range(0.0, 1.0, 0.05) var strafe_share: float = 0.7
## Top speed backward, as a share of the speed forward.
@export_range(0.0, 1.0, 0.05) var reverse_share: float = 0.5
## How fast it gains speed, metres per second per second.
@export_range(0.5, 60.0, 0.5) var acceleration: float = 16.0
## How fast it sheds speed with the keys let go or reversed, metres per second per second: lower drifts further.
@export_range(0.5, 60.0, 0.5) var braking: float = 18.0
## How sharply it eases into the speed asked for (per second): lower has a longer, softer end.
@export_range(0.5, 20.0, 0.1) var settle: float = 4.0

@export_group("Climbing")
## Climb and descent rate with up or down held, metres per second.
@export_range(0.5, 40.0, 0.5) var climb_speed: float = 10.0
## How fast the climb rate builds and dies, metres per second per second.
@export_range(0.5, 60.0, 0.5) var climb_acceleration: float = 20.0

@export_group("Turning")
## Fastest turn of the heading, degrees per second.
@export_range(1.0, 360.0, 1.0) var yaw_rate: float = 120.0
## Fastest tilt of the nose, degrees per second.
@export_range(1.0, 360.0, 1.0) var pitch_rate: float = 90.0
## How far above or below level the nose can be steered, degrees.
@export_range(0.0, 80.0, 1.0) var pitch_limit_deg: float = 45.0
## Turn rate per radian the nose is off the aim (per second).
@export_range(0.2, 10.0, 0.1) var steer_gain: float = 3.0
## How quickly the turn rates build and die (per second): lower feels heavier. Keep it a few times `steer_gain`, or
## the nose overshoots.
@export_range(0.5, 40.0, 0.5) var turn_response: float = 12.0

@export_group("Lean")
## Nose-down tilt at full acceleration (nose-up when braking), degrees.
@export_range(0.0, 30.0, 0.5) var lean_pitch_deg: float = 6.0
## Roll at full sideways acceleration, degrees.
@export_range(0.0, 45.0, 0.5) var lean_roll_deg: float = 10.0
## Bank in the fastest turn at full speed, degrees.
@export_range(0.0, 45.0, 0.5) var turn_bank_deg: float = 12.0
## How quickly the airframe leans and levels (per second).
@export_range(0.2, 20.0, 0.1) var lean_response: float = 5.0

@export_group("Contact")
## The least height of the airframe's underside over the ground or sea, metres.
@export_range(0.0, 10.0, 0.1) var ground_gap: float = 0.4
## Hitting ground, a building or a flyer faster than this (metres per second) destroys it; slower only stops it.
@export_range(1.0, 80.0, 0.5) var crash_speed: float = 15.0
## Size of the ball cast against buildings, props and walls, as a share of the unit's radius.
@export_range(0.1, 1.5, 0.05) var crash_body_reach: float = 0.5
## Two flyers touch when closer than this share of their two radii (flat) and half their two heights.
@export_range(0.1, 1.5, 0.05) var crash_flyer_reach: float = 0.7
