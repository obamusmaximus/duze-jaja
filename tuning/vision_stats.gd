class_name VisionStats
extends Resource
## Tunable numbers for detection (`vision/`, `docs/mechanics/vision.md`), shared by every unit and sensor. How far a
## type sees and how easily it is seen are on its `UnitStats` ("Vision").

@export_group("Range")
## No sensor detects anything farther than this, in metres, however big the target.
@export_range(50.0, 3000.0, 10.0) var max_detect_range: float = 700.0
## Extra range an observer gets for standing above its target, as a share of the range (0.5: half as far again).
@export_range(0.0, 2.0, 0.05) var height_bonus: float = 0.4
## Height above the target (metres) at which the observer gets the whole bonus.
@export_range(1.0, 200.0, 1.0) var height_full: float = 40.0

@export_group("Line of sight")
## An observer looks from, and at, the top of the body; this raises both points, in metres.
@export_range(0.0, 5.0, 0.1) var eye_lift: float = 0.5
## Distance between the ground samples along a line of sight, in metres. Smaller catches thinner ridges and costs
## more.
@export_range(1.0, 32.0, 0.5) var sight_step: float = 4.0

@export_group("Coverage")
## Coverage blocks across one terrain chunk (a side): the first, coarse pass and the wireframe's squares. 4 on 128 m
## chunks makes 32 m blocks.
@export_range(1, 8, 1) var coverage_per_chunk: int = 4
## Coverage cells across one block (a side), checked one by one along the edge of watched ground. 4 on 32 m blocks makes
## 8 m cells. Higher is finer and costs more.
@export_range(1, 8, 1) var coverage_detail: int = 4
## Least seconds between the starts of two coverage sweeps (each runs on a background thread; a slower one delays the
## next). Longer costs less and lags more.
@export_range(0.05, 2.0, 0.05) var coverage_interval: float = 0.25
## Longest fade from one sweep's picture to the next, in seconds (0: no fade).
@export_range(0.0, 2.0, 0.05) var coverage_fade: float = 0.5
## How much darker unwatched ground is in the commander views (0: not at all).
@export_range(0.0, 1.0, 0.01) var coverage_dim: float = 0.45
## Hairlines across one coverage block (a side) in the wireframe over unwatched ground. 4 on 32 m blocks: every 8 m.
@export_range(1, 16, 1) var coverage_divisions: int = 4
## Strength of the wireframe's hairlines over unwatched ground in the commander views.
@export_range(0.0, 1.0, 0.01) var coverage_line: float = 0.025
## Strength of the small crosses on the coverage blocks' corners.
@export_range(0.0, 1.0, 0.01) var coverage_tick: float = 0.09
## Strength of the contour along the edge of watched ground.
@export_range(0.0, 1.0, 0.01) var coverage_edge: float = 0.07

@export_group("Last known")
## Seconds a lost unit's last-known record lasts (its heat and cross fade over them). The default is a day: in practice no fade. Simulation.
@export_range(5.0, 3600.0, 5.0, "or_greater") var memory_time: float = 86400.0
## Seconds a big unit's last-known record (its ghost) lasts. The default is a day: in practice no fade. Simulation.
@export_range(5.0, 3600.0, 5.0, "or_greater") var ghost_time: float = 86400.0
## Radius of one lost unit's heat on the ground, metres.
@export_range(4.0, 200.0, 1.0) var heat_radius: float = 48.0
## Side of one texel of the heat picture, metres. Smaller is rounder and costs more to rebuild.
@export_range(2.0, 32.0, 1.0) var heat_cell: float = 8.0
## Heat of one freshly lost unit at its centre (a few together saturate).
@export_range(0.1, 4.0, 0.05) var heat_weight: float = 0.9
## Strength of the heat's fill and contour bands in the commander views.
@export_range(0.0, 2.0, 0.01) var heat_strength: float = 0.8
## Contour bands from cold to saturated heat.
@export_range(1, 8, 1) var heat_bands: int = 4
## Side of the cross at a lost unit's spot, metres.
@export_range(1.0, 40.0, 0.5) var cross_size: float = 9.0
## Strength of a ghost's lines when fresh.
@export_range(0.0, 2.0, 0.01) var ghost_strength: float = 0.8
## Seconds a ghost takes to dissolve once its record is gone.
@export_range(0.05, 3.0, 0.05) var ghost_dissolve: float = 0.6

@export_group("Timing")
## Seconds between checks of whether a unit is detected. The checks are spread over the ticks.
@export_range(0.02, 1.0, 0.01) var check_interval: float = 0.2
## Seconds a unit must stay detected before its enemy knows of it.
@export_range(0.01, 5.0, 0.01) var gain_time: float = 0.25
## Seconds a known unit takes to be lost once nothing detects it.
@export_range(0.05, 20.0, 0.05) var lose_time: float = 1.5
