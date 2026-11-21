class_name UnitStats
extends Resource
## Tunable numbers for a unit type. A unit type is a stats class or a .tres of this one (tuning/unit_default.tres);
## units sharing a .tres are the same type (double-click selects them together).

@export_group("Identity")
## The type's name, for the HUD and the playtest log.
@export var display_name: String = "Unit"

@export_group("Movement")
## Top speed on the ground, in metres per second.
@export_range(0.5, 40.0, 0.1) var speed: float = 6.0
## How fast the unit turns, in degrees per second. It moves slower while it faces away from where it wants to go.
@export_range(10.0, 1440.0, 5.0) var turn_rate: float = 360.0
## How close (metres) to a move order's point counts as arrived.
@export_range(0.05, 5.0, 0.05) var arrive_distance: float = 0.4

@export_group("Crowds")
## How hard units push apart when they overlap (soft collision between units; they never block each other hard).
@export_range(0.0, 5.0, 0.05) var separation_strength: float = 1.5
## Extra gap (metres) units keep between their bodies.
@export_range(0.0, 2.0, 0.05) var separation_padding: float = 0.15
## Within this distance (metres) of its goal, a unit that touches an already-arrived unit between it and the goal
## counts as arrived, so groups settle instead of jostling for the same spot.
@export_range(0.0, 20.0, 0.1) var crowd_arrive_distance: float = 3.0
## Seconds without progress toward the next waypoint before the unit re-paths (twice at most), then gives up and
## counts as arrived.
@export_range(0.2, 10.0, 0.1) var stuck_seconds: float = 1.5

@export_group("Body")
## Radius of the body, in metres: collision, selection ring and formation spacing.
@export_range(0.1, 5.0, 0.05) var radius: float = 0.6
## Height of the body, in metres.
@export_range(0.2, 10.0, 0.1) var height: float = 1.2

@export_group("Look")
## The imported model (.glb) shown for the unit. None: the placeholder cylinder with a nose.
@export var model: PackedScene
## Uniform scale of the model. Imported kits are not built to one scale, so each type sets its own.
@export_range(0.1, 30.0, 0.05) var model_scale: float = 1.0
## Turns the model about its centre, in degrees, to line its front up with the way the unit faces (-Z).
@export_range(-180.0, 180.0, 15.0) var model_yaw_deg: float = 0.0

@export_group("Combat")
## Hit points when full.
@export_range(1.0, 5000.0, 1.0) var max_health: float = 100.0
## The unit's weapon (a WeaponStats .tres), or none.
@export var weapon: WeaponStats
## How far the unit notices enemies, in metres: attack-move engages anything this close.
@export_range(1.0, 200.0, 0.5) var sight_range: float = 20.0
## How far (metres) an attack-moving unit chases an enemy from where it met it before it gives up and carries on.
@export_range(0.0, 100.0, 0.5) var leash_distance: float = 10.0
## Seconds between searches for targets. Searches are spread over the units, not all on one tick.
@export_range(0.05, 2.0, 0.05) var scan_interval: float = 0.25
