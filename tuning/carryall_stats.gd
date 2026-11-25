class_name CarryallStats
extends Resource
## Tunable numbers for a carryall's behaviour (`units/carryall.gd`, `tuning/carryall_default.tres`): leaving the
## mothership's pad, landing to deliver, and the side gunners. A unit type points at one from `UnitStats.carryall`;
## its hold is `UnitStats.cargo`, its flight (cruise height, climb rate) the usual `UnitStats` flight group.

@export_group("Pad and mothership")
## Height (metres) of the carryall's body above the pad while it sits on it.
@export_range(0.0, 10.0, 0.1) var deck_clearance: float = 1.0
## How far (metres) beyond the hull's side a carryall flies level, off the pad, before it descends to cruise height.
@export_range(0.0, 200.0, 1.0) var exit_margin: float = 25.0
## How far (metres) beyond the hull's side a carryall hovers when it returns from a delivery. It never lands on a pad.
@export_range(0.0, 400.0, 1.0) var home_margin: float = 60.0

@export_group("Delivery")
## Height (metres) of the carryall's body above the ground while it sits landed to unload.
@export_range(0.0, 10.0, 0.1) var landed_clearance: float = 1.0
## How close (metres) to the landing point the carryall gets before it starts to descend.
@export_range(0.5, 30.0, 0.5) var land_arrive_radius: float = 4.0
## Seconds between one unit leaving the hold and the next.
@export_range(0.1, 5.0, 0.1) var unload_interval: float = 0.7
## Gap (metres) between the carryall's body and the units standing round it.
@export_range(0.0, 10.0, 0.1) var unload_gap: float = 1.5
## Seconds the carryall waits on the ground after the last unit left, before it lifts off.
@export_range(0.0, 10.0, 0.1) var liftoff_delay: float = 1.0

@export_group("Side gunners")
## How many infantry in the hold fire their own weapons at ground enemies from the carryall's sides. A carryall with
## no infantry aboard has no guns. They never fire at flyers.
@export_range(0, 8, 1) var side_gunners: int = 2
