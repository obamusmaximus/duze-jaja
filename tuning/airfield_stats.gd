class_name AirfieldStats
extends Resource
## Tunable numbers for an airfield (`Airfield`): a flat deck with six helipads in two rows of three, each with a hangar
## behind it, where flyers land to repair. Read at level load: the layout is built once. Where each team's airfield
## stands is in `BattlefieldStats`.

@export_group("Repair")
## Hit points per second a craft regains while it sits on a pad.
@export_range(0.0, 200.0, 0.5) var repair_rate: float = 10.0
## How landing and takeoff go on these pads.
@export var pad: PadStats

@export_group("Vision")
## How far the airfield detects a target of signature 1, in metres.
@export_range(0.0, 1000.0, 5.0) var sensor_range: float = 150.0
## It looks from this high above its deck, in metres.
@export_range(0.0, 100.0, 1.0) var sensor_height: float = 15.0

@export_group("Waiting")
## With every pad taken, a craft waits over a point this far (metres) from the airfield's middle, toward the middle of
## the map.
@export_range(10.0, 300.0, 1.0) var holding_distance: float = 60.0

@export_group("Layout")
## Distance between neighbouring pads in a row, in metres.
@export_range(6.0, 40.0, 0.5) var pad_spacing: float = 13.0
## Distance of each row of pads from the airfield's middle line, in metres.
@export_range(4.0, 30.0, 0.5) var row_offset: float = 8.0
## Side of the square helipad marking, in metres.
@export_range(3.0, 20.0, 0.5) var pad_size: float = 8.0
## From a pad's middle back to its hangar's middle, in metres.
@export_range(4.0, 30.0, 0.5) var hangar_offset: float = 9.0
## A hangar's size, in metres: depth (away from its pad), height, width (along the row).
@export var hangar_size := Vector3(7.0, 5.0, 10.0)
## Bare deck left round the pads and hangars, in metres.
@export_range(0.0, 10.0, 0.5) var deck_margin: float = 2.0
## The deck stands this far above the highest ground under it, in metres.
@export_range(0.05, 3.0, 0.05) var deck_lift: float = 0.3
