class_name HelmetHudStats
extends Resource
## Tunable numbers for the helmet HUD of an inhabited flyer (views/cockpit/hud/, tuning/helmet_hud_default.tres).
## Sizes are pixels at the 1920x1080 base size. The stall warning's threshold is the sound's
## (`FlightSoundStats.warning_load`), so the two always agree.

@export_group("Horizon and ladder")
## Degrees of pitch between two rungs of the ladder.
@export_range(5.0, 30.0, 5.0) var ladder_step: float = 10.0
## Rungs show up to this many degrees above and below where the nose points.
@export_range(5.0, 60.0, 1.0) var ladder_span: float = 22.0
## Half the width of a rung, degrees of view.
@export_range(1.0, 20.0, 0.5) var rung_half_width: float = 7.0
## Half the gap in the middle of a rung and of the horizon, degrees of view.
@export_range(0.5, 10.0, 0.5) var rung_gap: float = 3.0
## Half the width of the horizon line, degrees of view.
@export_range(5.0, 70.0, 1.0) var horizon_half_width: float = 28.0

@export_group("Markers")
## Radius of the mouse-aim ring.
@export_range(4.0, 60.0, 1.0) var aim_radius: float = 16.0
## Size of the boresight (where the nose points).
@export_range(6.0, 60.0, 1.0) var boresight_size: float = 22.0
## Radius of the flight path marker's circle; its wings scale with it.
@export_range(4.0, 40.0, 1.0) var path_radius: float = 11.0
## Below this speed (metres per second) there is no flight path to show.
@export_range(0.5, 20.0, 0.5) var path_min_speed: float = 3.0
## How close to the screen's edge the flight path marker is held when the path leaves the view.
@export_range(0.0, 400.0, 5.0) var path_edge_inset: float = 120.0

## Half the width of the weapon crosshair.
@export_range(4.0, 60.0, 1.0) var crosshair_size: float = 18.0
## Half the width of the box on a locked target.
@export_range(8.0, 120.0, 1.0) var lock_size: float = 26.0

@export_group("Angle of attack")
## The top of the angle-of-attack gauge, as a share of the stall angle.
@export_range(1.1, 2.0, 0.05) var gauge_top: float = 1.4
## How far ahead (seconds) the gauge's trend caret looks: where the angle of attack is heading.
@export_range(0.0, 1.5, 0.05) var trend_time: float = 0.35
## How quickly the trend settles (per second): lower is calmer, higher reacts sooner.
@export_range(1.0, 40.0, 0.5) var trend_response: float = 12.0
## The stall limit bar by the flight path marker shows from this share of the stall angle, current or heading there.
@export_range(0.0, 1.0, 0.05) var limit_from: float = 0.5

@export_group("Tapes")
## How far the speed and altitude tapes stand to the sides of the middle.
@export_range(200.0, 900.0, 10.0) var tape_offset: float = 520.0
## Height of the speed and altitude tapes.
@export_range(150.0, 800.0, 10.0) var tape_height: float = 420.0
## Speed shown from one end of its tape to the other, km/h.
@export_range(20.0, 600.0, 10.0) var speed_window: float = 100.0
## Altitude shown from one end of its tape to the other, metres.
@export_range(20.0, 1000.0, 10.0) var altitude_window: float = 100.0
## Width of the heading tape.
@export_range(200.0, 1200.0, 10.0) var heading_width: float = 520.0
## Degrees of heading shown from one end of the tape to the other.
@export_range(30.0, 180.0, 5.0) var heading_window: float = 70.0
## Distance of the heading tape's line from the top of the screen.
@export_range(40.0, 300.0, 5.0) var heading_top: float = 90.0

@export_group("Warnings")
## "Pull up" comes on when a level or gently falling flight path meets the ground within this many seconds. 0: off.
@export_range(0.0, 6.0, 0.1) var pull_up_time: float = 1.6
## Seconds added to that warning time in a straight dive (shares of it in shallower ones): steep dives take longer to
## pull out of.
@export_range(0.0, 6.0, 0.1) var pull_up_dive_time: float = 2.0
## The height over ground and sea, under the airframe, that counts as meeting it, metres.
@export_range(0.0, 20.0, 0.5) var pull_up_clearance: float = 3.0
## How often the warnings flash, per second.
@export_range(0.5, 10.0, 0.5) var flash_rate: float = 3.0
## How far below the middle of the screen the warning words stand.
@export_range(50.0, 450.0, 5.0) var warning_drop: float = 230.0
