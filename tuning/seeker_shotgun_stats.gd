class_name SeekerShotgunStats
extends Resource
## Tunable numbers for the commando's first-person seeker shotgun: a spread of pellets that each home in on one of the
## tracked enemies (`docs/mechanics/commando.md`). `JetpackStats.shotgun` points at one
## (tuning/seeker_shotgun_default.tres).

@export_group("Pellets")
## Pellets per shot. They are dealt out to the tracked enemies newest pickup first, round and round.
@export_range(1, 40, 1) var pellet_count: int = 8
## What one pellet does to each armor type, its sound cues and spark size (a `WeaponStats` with a damage profile).
@export var weapon: WeaponStats
## Pellet speed, metres per second.
@export_range(5.0, 400.0, 1.0) var speed: float = 119.0
## Half-angle of the cone the pellets leave in, degrees.
@export_range(0.0, 30.0, 0.1) var spread_degrees: float = 3.9
## Radius a pellet hits with, metres.
@export_range(0.02, 2.0, 0.01) var pellet_radius: float = 0.25
## Seconds a pellet flies before it is gone.
@export_range(0.1, 10.0, 0.01) var lifetime: float = 2.01
## Where the pellets leave from, relative to the view (metres; x right, y up, -z forward).
@export var muzzle_offset := Vector3(0.25, -0.2, -0.5)
## The pellets are aimed at what the crosshair points at within this distance, or at that distance, metres.
@export_range(10.0, 2000.0, 5.0) var aim_range: float = 300.0
## Shortest time between two shots, seconds (0: as fast as the trigger is pressed).
@export_range(0.0, 3.0, 0.01) var refire_time: float = 0.0

@export_group("Homing")
## Seconds a pellet flies straight before it starts turning toward its enemy.
@export_range(0.0, 2.0, 0.01) var homing_delay: float = 0.12
## How fast a homing pellet turns toward its enemy, degrees per second.
@export_range(10.0, 2000.0, 10.0) var turn_rate: float = 600.0
## Off: a pellet whose enemy is inside its turning circle (out of reach at its speed) gives up homing and flies
## straight on until `lifetime`. On: it brakes into the turn instead, just enough to make it, so it nearly always lands.
@export var brake_into_turns: bool = false
## With `brake_into_turns`: the slowest a braking pellet goes, as a share of `speed`.
@export_range(0.01, 1.0, 0.01) var min_speed_share: float = 0.1
## With `brake_into_turns`: how fast a braked pellet speeds back up to `speed`, metres per second per second.
@export_range(1.0, 2000.0, 10.0) var speed_recovery: float = 300.0

@export_group("Tracers")
## Seconds a point of a tracer lasts: the tracer is the pellet's path over this long, fading toward its tail. Look only.
@export_range(0.01, 1.0, 0.01) var tracer_time: float = 0.12
## Width of a tracer at the pellet, metres. It narrows toward the tail. Look only.
@export_range(0.005, 0.5, 0.005) var tracer_width: float = 0.15
