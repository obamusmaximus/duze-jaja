class_name PadStats
extends Resource
## Tunable numbers for how a flyer lands on and leaves a pad (`Pad`, `Landing`). Shared by every pad that uses the
## .tres (tuning/pad_default.tres, pad_carryall.tres, pad_explorer.tres).

@export_group("Landing")
## Height of the hover point above the pad, in metres: a craft comes down from here and climbs back to it. Keep it
## above the hangars.
@export_range(2.0, 40.0, 0.5) var hover_height: float = 9.0
## How fast a craft drops from the hover point to the pad, in metres per second (it eases off just above the deck).
@export_range(1.0, 40.0, 0.5) var descent_rate: float = 10.0
## The slowest the eased drop gets, in metres per second.
@export_range(0.2, 10.0, 0.1) var touchdown_speed: float = 1.5
## Gap between a landed craft's underside and the deck, in metres.
@export_range(0.0, 2.0, 0.05) var landed_clearance: float = 0.15

@export_group("Approach")
## Flat distance (metres) from the pad at which a craft stops flying and slides into place over it.
@export_range(0.5, 20.0, 0.5) var align_radius: float = 4.0
## Top speed of that slide, in metres per second.
@export_range(0.5, 30.0, 0.5) var align_speed: float = 7.0
## A fixed wing turns to hovering flight this far (metres) beyond the distance it needs to brake from its top speed.
@export_range(0.0, 200.0, 1.0) var wing_brake_margin: float = 20.0
