class_name JetpackStats
extends Resource
## Tunable numbers for a jetpack unit type (the commando, `docs/mechanics/commando.md`): how it hovers and surges as
## an RTS unit, and the first-person kit (walk, hover, surge, afterburner) while a player inhabits it. Its weapons'
## numbers are their own resources (`shotgun`, `tracking`). `UnitStats.jetpack` points at one
## (tuning/jetpack_default.tres). The RTS surge speed is the type's `UnitStats.speed`.

@export_group("RTS view")
## How high the body hovers above the ground under it, metres (a grunt's height).
@export_range(0.0, 6.0, 0.05) var rts_hover_height: float = 1.8
## Seconds of moving in one direction before the afterburner lights.
@export_range(0.1, 10.0, 0.05) var rts_afterburner_delay: float = 2.0
## Turning further than this (degrees) from the way a straight run began starts the run over (and ends the
## afterburner).
@export_range(1.0, 90.0, 1.0) var rts_straight_deg: float = 15.0
## Top speed under the afterburner, metres per second. It can't fire while it burns.
@export_range(1.0, 80.0, 0.5) var rts_afterburner_speed: float = 26.0
## How fast it gains (and loses) the afterburner's extra speed, metres per second per second.
@export_range(1.0, 200.0, 1.0) var rts_afterburner_accel: float = 20.0
## How far the body leans forward at full surge speed, degrees (more under the afterburner). Look only.
@export_range(0.0, 60.0, 1.0) var rts_lean_deg: float = 20.0

@export_group("First person: input")
## Holding the jet key at least this long (seconds) with a movement key starts a surge. A shorter press toggles hover.
@export_range(0.05, 2.0, 0.01) var surge_hold_time: float = 0.5
## The view turns at most this far above or below level, degrees.
@export_range(10.0, 89.0, 1.0) var view_pitch_limit_deg: float = 85.0

@export_group("First person: on foot")
## Downward pull, metres per second per second.
@export_range(1.0, 60.0, 0.5) var gravity: float = 22.0
## Walking speed on the ground, metres per second.
@export_range(0.5, 40.0, 0.5) var walk_speed: float = 8.0
## How fast walking reaches its speed or stops, metres per second per second.
@export_range(1.0, 200.0, 1.0) var walk_accel: float = 60.0
## Upward speed of a jump (Space on the ground), metres per second. A jump rises into the hover if it is on.
@export_range(0.0, 40.0, 0.5) var jump_speed: float = 9.0
## In the air with hover off: how fast the keys steer the flat velocity, metres per second per second.
@export_range(0.0, 100.0, 1.0) var air_accel: float = 10.0
## In the air with hover off: share of the flat speed above walking speed lost per second.
@export_range(0.0, 2.0, 0.01) var air_drag: float = 0.1
## A grounded body follows ground that drops away by up to this much in one tick instead of taking off, metres.
@export_range(0.0, 2.0, 0.05) var ground_snap: float = 0.6

@export_group("First person: hover")
## Share of gravity while hovering in the air.
@export_range(0.0, 1.0, 0.01) var hover_gravity_scale: float = 0.19
## Horizontal speed WASD drives it toward while hovering, metres per second. Momentum doesn't carry into a hover,
## except the afterburner's.
@export_range(0.5, 80.0, 0.5) var hover_strafe_speed: float = 20.0
## How fast the hover reaches the strafe speed, or brakes down to it, metres per second per second.
@export_range(1.0, 200.0, 1.0) var hover_strafe_accel: float = 40.0
## Share of the vertical speed lost per second while hovering, so a fall or a jump settles instead of floating far.
@export_range(0.0, 10.0, 0.05) var hover_vertical_damping: float = 0.95

@export_group("First person: surge")
## Speed a surge sets at once, along the movement keys relative to the view (pitch included), metres per second.
@export_range(1.0, 150.0, 0.5) var surge_speed: float = 50.0
## How fast a surge's velocity follows the view and the keys, metres per second per second. High is a near-instant
## turn.
@export_range(1.0, 500.0, 1.0) var surge_steer_accel: float = 120.0

@export_group("First person: afterburner")
## Seconds of surging with only forward held (W, not S) before the afterburner lights.
@export_range(0.1, 10.0, 0.05) var afterburner_delay: float = 2.0
## Speed the afterburner levels off at: a drag balances its thrust there, metres per second.
@export_range(1.0, 200.0, 0.5) var afterburner_speed: float = 69.0
## Thrust of the afterburner, metres per second per second. Higher reaches `afterburner_speed` sooner.
@export_range(1.0, 200.0, 1.0) var afterburner_accel: float = 20.0

@export_group("First person: weapons")
## The seeker shotgun fired by hand (a `SeekerShotgunStats`).
@export var shotgun: SeekerShotgunStats
## The scanner and tracks it aims at (a `TrackingStats`).
@export var tracking: TrackingStats
