class_name BattlefieldStats
extends Resource
## Tunable numbers for the battlefield level (`levels/atoll/`, tuning/battlefield_default.tres): the map's size,
## the shape of the atoll's first-draft heightmap, and where the hovering motherships sit. The Atoll group only shapes
## the draft `AtollBlockout` writes when `levels/atoll/heightmap.png` is missing; after that the PNG is the land.

@export_group("Map")
## Size of the whole map in metres (x, z), centred on the origin. The sea, the seabed and the camera bounds follow it.
@export var map_extent: Vector2 = Vector2(3000.0, 2000.0)

@export_group("Loading")
## Builds the ground, shore and map grid side by side on worker threads while loading. Off: one after another, for
## comparing. Read at level load.
@export var threaded_load: bool = true

@export_group("Atoll")
## Radius of the reef ring around the lagoon, in metres.
@export_range(100.0, 1200.0, 5.0) var ring_radius: float = 520.0
## Width of the reef ring, in metres.
@export_range(10.0, 200.0, 1.0) var ring_width: float = 40.0
## Height of the reef ring above the sea, in metres.
@export_range(0.5, 20.0, 0.5) var ring_height: float = 3.0
## Size of the big island (x, z) in the lagoon, in metres.
@export var big_island_size: Vector2 = Vector2(340.0, 240.0)
## Height of the big island's top above the sea, in metres.
@export_range(1.0, 40.0, 0.5) var island_height: float = 6.0
## Size of each small island around the atoll, in metres (x, z). They sit outside the ring, between it and the motherships.
@export var small_island_size: Vector2 = Vector2(90.0, 70.0)
## Height of the small islands above the sea, in metres.
@export_range(1.0, 40.0, 0.5) var small_island_height: float = 4.0

@export_group("Airfields")
## Where the middle of team 0's airfield stands (x, z), in metres: on flat high ground on its side. Read at level load.
@export var airfield_west := Vector2(-360.0, -5.0)
## Where the middle of team 1's airfield stands (x, z), in metres. Read at level load.
@export var airfield_east := Vector2(440.0, 5.0)

@export_group("Starting flyers")
## Where team 0's test fighters and VTOLs start (x, z): keep it well clear of high ground, so taking one over at once
## is safe (over the sea off its island). Read at level load.
@export var flyers_west := Vector2(-780.0, -40.0)
## Where team 1's test fighters and VTOLs start (x, z). Read at level load.
@export var flyers_east := Vector2(900.0, -40.0)
## Where team 0's first starting carryall hovers (x, z), over its island; further ones line up along z. Read at level
## load.
@export var carryalls_west := Vector2(-300.0, -150.0)
## Where team 1's first starting carryall hovers (x, z). Read at level load.
@export var carryalls_east := Vector2(520.0, -90.0)
## Where team 0's first test Explorer starts (x, z): flat ground on its island; further ones line up along z.
@export var explorer_west := Vector2(-430.0, -130.0)
## Where team 1's first test Explorer starts (x, z).
@export var explorer_east := Vector2(560.0, -170.0)

@export_group("Motherships")
## How far each mothership hovers from the middle of the atoll, along x, in metres. Its long side faces the atoll.
@export_range(200.0, 2000.0, 10.0) var mothership_standoff: float = 1100.0
## Height of the motherships' underside above the sea, in metres.
@export_range(10.0, 600.0, 5.0) var mothership_altitude: float = 140.0

@export_group("Test flyer")
## Speed of the test flyer used for the travel-time readout, in metres per second.
@export_range(5.0, 300.0, 1.0) var flyer_speed: float = 50.0

@export_group("Test units")
## Ground units placed at the start, split between the two teams.
@export_range(0, 400, 1) var unit_count: int = 100
## The test units are spread over their team's island (the one its airfield is on), on ground no steeper than this,
## in degrees.
@export_range(1.0, 35.0, 0.5) var spawn_max_slope_deg: float = 12.0
## Carryalls per team hovering over its island at the start, each with a hold full of troopers.
@export_range(0, 4, 1) var test_carryalls: int = 2
## Test fighters (fixed wing) per team at the start.
@export_range(0, 20, 1) var test_fighters: int = 2
## Test VTOLs (hovering) per team at the start.
@export_range(0, 20, 1) var test_vtols: int = 2
## Test commandos (jetpack infantry) per team at the start, beside the test flyers.
@export_range(0, 20, 1) var test_commandos: int = 2
## Explorers per team, each with a demo hold (troopers, IFVs, a tank, a VTOL), parked on its island.
@export_range(0, 4, 1) var test_explorers: int = 1
