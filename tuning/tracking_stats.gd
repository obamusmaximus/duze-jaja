class_name TrackingStats
extends Resource
## Tunable numbers for the commando's first-person tracking: the scanner (a pyramid in front of the view that picks
## enemies up), the afterburner's scouting and how long tracks last (`docs/mechanics/commando.md`). How the scanner
## frame and track markers look is `JetHudStats`. `JetpackStats.tracking` points at one (tuning/tracking_default.tres).

@export_group("Scanner")
## Half the scanner's width either side of the view, degrees. The HUD frame shows it.
@export_range(1.0, 80.0, 0.5) var scanner_half_width_deg: float = 22.0
## Half the scanner's height above and below the view, degrees.
@export_range(1.0, 80.0, 0.5) var scanner_half_height_deg: float = 14.0
## How far the scanner reaches, metres.
@export_range(5.0, 1000.0, 5.0) var scanner_range: float = 150.0
## Seconds an enemy must stay in the scanner (and in sight) to be picked up.
@export_range(0.0, 10.0, 0.01) var scanner_pickup_time: float = 1.49
## Seconds a track lasts. Being in the scanner again refreshes it.
@export_range(0.5, 60.0, 0.5) var track_time: float = 5.0
## Most enemies the scanner holds at once. Scouting isn't limited by it.
@export_range(1, 40, 1) var max_tracks: int = 5

@export_group("Scouting")
## While the afterburner burns, every enemy in sight within this distance in any direction is tracked at once, metres.
@export_range(0.0, 500.0, 5.0) var scout_range: float = 50.0
## Seconds a track from scouting lasts.
@export_range(0.5, 60.0, 0.5) var scout_track_time: float = 8.0
