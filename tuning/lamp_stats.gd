class_name LampStats
extends Resource
## Tunable numbers for the lamps (`lighting/lamp_set.gd`, `docs/mechanics/lamps.md`): navigation lamps on aircraft,
## markers on ground units, pad, airfield and mothership lamps, and the pools of light under bases. A lamp is a glow
## `size` metres across that never gets smaller than `min_px` pixels on screen. How bright they all are by day or night
## is `LightStats` (`lamp_brightness`, `pool_brightness`). The Explorer's sizes and periods are `ExplorerStats`.
## One `.tres` (`lamp_default.tres`).

@export_group("Aircraft")
## Red (port) and green (starboard) wingtip lamps: size (m) and smallest size on screen (pixels).
@export_range(0.1, 6.0, 0.05) var nav_size: float = 1.1
@export_range(0.0, 20.0, 0.5) var nav_min_px: float = 9.0
## White tail lamp.
@export_range(0.1, 6.0, 0.05) var tail_size: float = 0.9
@export_range(0.0, 20.0, 0.5) var tail_min_px: float = 7.0
## White double strobe on top, and the seconds between its double flashes.
@export_range(0.1, 8.0, 0.05) var strobe_size: float = 1.8
@export_range(0.0, 30.0, 0.5) var strobe_min_px: float = 13.0
@export_range(0.2, 5.0, 0.05) var strobe_period: float = 1.6

@export_group("Ground units")
## One small white marker on the back of each ground unit.
@export_range(0.05, 3.0, 0.05) var marker_size: float = 0.45
@export_range(0.0, 10.0, 0.5) var marker_min_px: float = 2.5
@export_range(0.0, 1.0, 0.05) var marker_strength: float = 0.45

@export_group("Pads")
## White lamps at the corners of every pad.
@export_range(0.1, 4.0, 0.05) var pad_size: float = 0.8
@export_range(0.0, 10.0, 0.5) var pad_min_px: float = 2.5
@export_range(0.0, 1.0, 0.05) var pad_strength: float = 0.7

@export_group("Bases")
## Team-colour lamps round an airfield's deck and along a mothership's deck edges, and the metres between them.
@export_range(0.1, 6.0, 0.05) var edge_size: float = 1.6
@export_range(0.0, 10.0, 0.5) var edge_min_px: float = 4.0
@export_range(2.0, 60.0, 0.5) var airfield_edge_spacing: float = 9.0
@export_range(4.0, 80.0, 0.5) var ship_edge_spacing: float = 22.0
## A mothership's own red, green, tail and strobe lamps are this much bigger than an aircraft's.
@export_range(1.0, 8.0, 0.1) var ship_nav_scale: float = 3.0

@export_group("Light pools")
## Strength of the white pool on each pad.
@export_range(0.0, 2.0, 0.01) var pad_pool: float = 0.11
## Strength of the team-colour pool on an airfield's deck.
@export_range(0.0, 2.0, 0.01) var airfield_pool: float = 0.12
## Strength of the team-colour pool on the sea under a mothership, and its size as a share of the hull's footprint.
@export_range(0.0, 2.0, 0.01) var ship_pool: float = 0.14
@export_range(0.5, 6.0, 0.05) var ship_pool_scale: float = 2.2
