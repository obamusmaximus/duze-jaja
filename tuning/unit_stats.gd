class_name UnitStats
extends Resource
## Tunable numbers for a unit type. A unit type is a stats class or a .tres of this one (tuning/unit_default.tres);
## units sharing a .tres are the same type (double-click selects them together).

## What kind of cargo a unit is (`Cargo`): which units side gunners can be, how it leaves a hold. None: can't be
## carried (boats, the Explorer).
enum CargoClass { NONE, INFANTRY, MACHINERY, AIR }
## How the autopilot flies a flyer. Hover: slows, stops and hovers. Fixed wing: never stops, turns in arcs.
enum FlightStyle { HOVER, FIXED_WING }
## What a unit is made of, for damage (`DamageProfile`).
enum ArmorType { INFANTRY, VEHICLE, TANK, AIRCRAFT, CARRYALL, EXPLORER, LIGHT_VEHICLE }

@export_group("Identity")
## The type's name, for the HUD and the playtest log.
@export var display_name: String = "Unit"
## Flat white-on-clear symbol of the type, for the HUD's cargo view and the production queue. The HUD tints it.
## None: the HUD shows the type's initial instead.
@export var icon: Texture2D

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
@export_range(0.1, 40.0, 0.05) var radius: float = 0.6
## Height of the body, in metres.
@export_range(0.2, 40.0, 0.1) var height: float = 1.2

@export_group("Movement")
## Crosses water: its ground moves are not refused for lying on another land mass (the land regions of `pathing.md`).
## A flag for later naval and amphibious units; no unit sets it yet.
@export var amphibious: bool = false

@export_group("Flight")
## Flies: the unit keeps to the air above the ground (see `flight_height`), moves straight to its goal over anything,
## and is hit only by weapons and units that can attack air (`anti_air`).
@export var flying: bool = false
## Hover types can stop in the air (VTOLs, carryalls). Fixed wings only fly forward and orbit when idle.
@export var flight_style: FlightStyle = FlightStyle.HOVER
## How fast a flyer gains and loses speed, in metres per second per second.
@export_range(0.5, 100.0, 0.5) var flight_acceleration: float = 14.0
## Fixed wing: the slowest it can fly, in metres per second (it orbits at this speed). Top speed is `speed`.
@export_range(1.0, 100.0, 0.5) var flight_min_speed: float = 12.0
## Fixed wing: passing this close (metres, flat) to a move order's point counts as arrived.
@export_range(1.0, 50.0, 0.5) var flight_arrive_radius: float = 8.0
## Fixed wing: radius of the circle it flies while idle, in metres (never tighter than it can turn).
@export_range(5.0, 200.0, 1.0) var flight_orbit_radius: float = 30.0
## Seconds of flight a flyer looks ahead for rising ground, to start climbing early.
@export_range(0.0, 40.0, 0.5) var flight_look_ahead: float = 16.0
## Flyers further apart in height than this (metres) pass over each other instead of pushing apart.
@export_range(0.5, 20.0, 0.5) var flight_separation_height: float = 3.0
## Steepest bank in a turn, and lean of a hover type, in degrees. Look only.
@export_range(0.0, 85.0, 1.0) var flight_max_bank_deg: float = 55.0
## How quickly the airframe rolls and pitches into a new attitude (per second). Look only.
@export_range(0.5, 20.0, 0.5) var flight_lean_rate: float = 5.0
## Width of the line from a flyer's ground plate up to its body, in metres. Look only.
@export_range(0.0, 1.0, 0.01) var height_line_width: float = 0.12
## Size of the round shadow straight under a flyer, as a multiple of its radius. Look only.
@export_range(0.0, 4.0, 0.05) var shadow_scale: float = 1.5
## How dark that shadow is at its middle. Look only.
@export_range(0.0, 1.0, 0.05) var shadow_opacity: float = 0.45
## How far a flyer's plate, ring and shadow are raised over open sea, to clear the waves, in metres. Look only.
@export_range(0.0, 3.0, 0.05) var sea_mark_lift: float = 0.8
## Fixed wing attack pass: it breaks off when this close (metres, flat) to a ground target, or once it is behind it.
@export_range(0.0, 100.0, 0.5) var flight_pass_break_distance: float = 10.0
## Fixed wing attack pass: after breaking off it flies on until this far (metres, flat) from the target, then turns
## back for the next run.
@export_range(5.0, 300.0, 1.0) var flight_pass_distance: float = 55.0
## Height above sea level over flat ground, in metres, for a flyer.
@export_range(0.0, 200.0, 0.5) var flight_height: float = 10.0
## Metres a flyer rises per metre the ground rises beneath it. Below 1, so it sits closer to the ground over high
## terrain than over the sea.
@export_range(0.0, 1.0, 0.05) var flight_terrain_follow: float = 0.4
## The least gap (metres) between a flyer and the ground under it, however high the terrain.
@export_range(0.0, 50.0, 0.5) var flight_min_clearance: float = 3.0
## How fast a flyer climbs or descends, in metres per second.
@export_range(0.5, 50.0, 0.5) var flight_climb_rate: float = 6.0

## The jet control type's numbers while a player flies it (`FlightStats`). None, with no `hover_flight` either:
## tuning/flight_default.tres.
@export var flight_model: FlightStats
## The hover control type's numbers while a player flies it (`HoverStats`). A type with them starts in a hover; with
## `flight_model` too it can switch (a `FlightModeStats` ability). None: a jet.
@export var hover_flight: HoverStats

@export_group("Jetpack")
## A jetpack type (the commando): a ground unit that hovers, surges and afterburns (`JetpackStats`), and can be
## inhabited on foot. None: not a jetpack type.
@export var jetpack: JetpackStats

@export_group("Ability")
## The type's ability (F), an `AbilityStats` .tres. None: no ability.
@export var ability: AbilityStats

@export_group("Cockpit")
## Where the pilot's eyes are in first person, from the unit's bottom middle (metres; y up, -z toward the nose).
## It pitches and banks with the airframe. Only types a player can inhabit use it.
@export var cockpit_offset := Vector3(0.0, 1.2, -0.4)

@export_group("Cargo")
## What kind of cargo this unit is (infantry, machinery, air). None: it can't be carried.
@export var cargo_class: CargoClass = CargoClass.NONE
## Room it takes in a hold, counted in infantry (a trooper 1, an IFV 2.5, a tank 5). Every hold is one shared volume.
@export_range(0.5, 40.0, 0.5) var cargo_size: float = 1.0
## This unit's own hold, if it carries others (a carryall, the Explorer). None: carries nothing.
@export var cargo: CargoStats
## How this unit behaves as a carryall (pad, landing, side gunners). None: not a carryall.
@export var carryall: CarryallStats
## How this unit behaves as an Explorer (deploy, bubble, base area, searchlights). None: not an Explorer.
@export var explorer: ExplorerStats

@export_group("Production")
## Credits a squad pays for one of this type (`Economy`).
@export_range(0, 5000, 5) var cost: int = 100
## Seconds a production line spends on one of this type (a squad takes the sum of its units, scaled by
## `EconomyStats.build_time_scale`).
@export_range(0.5, 300.0, 0.5) var build_time: float = 10.0

@export_group("Look")
## The imported model (.glb) shown for the unit. None: the placeholder cylinder with a nose.
@export var model: PackedScene
## Uniform scale of the model. Imported kits are not built to one scale, so each type sets its own.
@export_range(0.1, 60.0, 0.05) var model_scale: float = 1.0
## Turns the model about its centre, in degrees, to line its front up with the way the unit faces (-Z).
@export_range(-180.0, 180.0, 15.0) var model_yaw_deg: float = 0.0

@export_group("Vision")
## How far this type detects a target of signature 1, in metres, with a clear line over the terrain. It sees a target
## of signature 2 twice as far. The longest ranges cost the most.
@export_range(0.0, 1000.0, 5.0) var sensor_range: float = 45.0
## How easily the type is detected: it multiplies every observer's sensor range. Infantry below 1, big things above.
@export_range(0.05, 20.0, 0.05) var signature: float = 1.0
## Big units leave a wireframe ghost of themselves where the enemy last saw them; the rest leave heat on the ground.
@export var leaves_ghost: bool = false

@export_group("Combat")
## Hit points when full. Every type has the same; how tough it is comes from `armor`.
@export_range(1.0, 5000.0, 1.0) var max_health: float = 100.0
## Which of a weapon's damage numbers hits this type.
@export var armor: ArmorType = ArmorType.INFANTRY
## Flyers: the nose of a standing hover type tilts onto the target it fights if that is at most this far above or below
## level, degrees. 0: it never tilts. Look only.
@export_range(0.0, 85.0, 1.0) var aim_tilt_deg: float = 0.0
## First person: the weapon follows the pilot's view (free look aims it). Off: it is fixed to the boresight.
@export var pilot_turret: bool = false
## Can target flying units. Units without it never pick a flyer as a target, on their own initiative or by order.
@export var anti_air: bool = false
## The unit's weapon (a WeaponStats .tres), or none.
@export var weapon: WeaponStats
## How far the unit notices enemies, in metres: attack-move engages anything this close.
@export_range(1.0, 200.0, 0.5) var sight_range: float = 20.0
## How far (metres) an attack-moving unit chases an enemy from where it met it before it gives up and carries on.
@export_range(0.0, 100.0, 0.5) var leash_distance: float = 10.0
## Seconds between searches for targets. Searches are spread over the units, not all on one tick.
@export_range(0.05, 2.0, 0.05) var scan_interval: float = 0.25

@export_group("Sound and effects")
## Sound cue played to the player when the unit is selected (a `SfxCue` id).
@export var select_cue: StringName = &"select_unit"
## Sound cue played where the unit dies.
@export var death_cue: StringName = &"death_small"
## Size of the death explosion, as a multiple of the normal size (big units: more than 1).
@export_range(0.2, 4.0, 0.05) var death_effect_scale: float = 1.0
