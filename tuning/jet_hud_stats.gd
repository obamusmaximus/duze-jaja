class_name JetHudStats
extends Resource
## Tunable sizes of the commando's first-person HUD: crosshair, scanner frame, track markers and their health bars,
## and the hover and surge indicators (`docs/mechanics/commando.md`). Colours come from `UiTokens`. Read by the
## `HelmetHud`'s jet parts (tuning/jet_hud_default.tres).

@export_group("Crosshair")
## Radius of the crosshair ring, pixels.
@export_range(2.0, 60.0, 0.5) var crosshair_radius: float = 14.0

@export_group("Scanner frame")
## Length of the brighter corner marks on the scanner frame, as a share of its shorter side.
@export_range(0.0, 0.5, 0.01) var frame_corner_share: float = 0.12

@export_group("Track markers")
## Size of a track marker around the enemy, in world metres (it shrinks with distance).
@export_range(0.2, 20.0, 0.1) var marker_world_size: float = 2.5
## Smallest a track marker gets on screen, pixels.
@export_range(4.0, 80.0, 1.0) var marker_min_px: float = 28.0
## A marker blinks for this many seconds before its track runs out.
@export_range(0.0, 10.0, 0.01) var marker_blink_time: float = 1.49
## Blinks per second.
@export_range(0.5, 20.0, 0.5) var marker_blink_rate: float = 4.0

@export_group("Health bar")
## Hit points per segment of the bar above a track marker: max health / this many segments (rounded up).
@export_range(1.0, 500.0, 1.0) var health_segment_hp: float = 25.0
## Height of the bar, pixels.
@export_range(1.0, 12.0, 0.5) var health_bar_height: float = 6.0
## Gap between the segments, pixels.
@export_range(0.0, 10.0, 0.5) var health_bar_gap: float = 4.0
## Gap between the bar and the top of the marker, pixels.
@export_range(0.0, 20.0, 0.5) var health_bar_offset: float = 8.0
## Narrowest the bar gets, pixels. It is as wide as the marker otherwise, centred on it.
@export_range(4.0, 200.0, 1.0) var health_bar_min_width: float = 64.0

@export_group("Indicators")
## Side of the hover (H) and surge (S) boxes, pixels.
@export_range(8.0, 120.0, 1.0) var indicator_size: float = 44.0
## Gap between the boxes and the speed readout, pixels.
@export_range(0.0, 40.0, 1.0) var indicator_gap: float = 12.0
## Height of the indicator row's middle, as a share of the screen from the top.
@export_range(0.5, 0.98, 0.01) var indicator_row_share: float = 0.82
