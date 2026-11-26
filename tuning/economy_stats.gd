class_name EconomyStats
extends Resource
## Tunable numbers for the flat income and squad production (`economy/`, `tuning/economy_default.tres`). Both sides
## get the same income; it is spent on squads built in the mothership's production lines.

@export_group("Income")
## Credits each team earns per second, flat (no harvesting).
@export_range(0.0, 500.0, 0.5) var income_per_second: float = 10.0
## Credits each team starts with.
@export_range(0, 100000, 50) var starting_bank: int = 1000
## The most credits a bank holds; income above it is lost. 0 means no cap.
@export_range(0, 100000, 50) var bank_cap: int = 0

@export_group("Production")
## Squads a line holds at once, the one being built included.
@export_range(1, 16, 1) var queue_length: int = 4
## Multiplies every build time (the sum of a squad's unit build times).
@export_range(0.05, 10.0, 0.05) var build_time_scale: float = 1.0
## Share of a squad's cost handed back when it is cancelled (the units already built are scrapped).
@export_range(0.0, 1.0, 0.05) var cancel_refund: float = 1.0
## Share of the price of the units not yet built that is handed back when a carryall takes off with its squad only
## partly built (the rest of the squad is dropped).
@export_range(0.0, 1.0, 0.05) var takeoff_refund: float = 0.5

@export_group("Squads")
## The hold a squad must fit (one carryall's volume by default).
@export var squad_hold: CargoStats
## How many carryall holds one squad may fill; above 1 the squad needs several carryalls.
@export_range(1, 8, 1) var squad_carryalls: int = 1
