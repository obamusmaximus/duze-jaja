class_name BattlefieldStats
extends Resource
## Tunable numbers for the battlefield level (`levels/atoll/`, tuning/battlefield_default.tres): the map's size,
## the shape of the atoll's first-draft heightmap, and where the hovering motherships sit. The Atoll group only shapes
## the draft `AtollBlockout` writes when `levels/atoll/heightmap.png` is missing; after that the PNG is the land.

@export_group("Map")
## Size of the whole map in metres (x, z), centred on the origin. The sea, the seabed and the camera bounds follow it.
@export var map_extent: Vector2 = Vector2(3000.0, 2000.0)

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

@export_group("Motherships")
## How far each mothership hovers from the middle of the atoll, along x, in metres. Its long side faces the atoll.
@export_range(200.0, 2000.0, 10.0) var mothership_standoff: float = 1100.0
## Height of the motherships' underside above the sea, in metres.
@export_range(10.0, 600.0, 5.0) var mothership_altitude: float = 140.0

@export_group("Test flyer")
## Speed of the test flyer used for the travel-time readout, in metres per second.
@export_range(5.0, 300.0, 1.0) var flyer_speed: float = 50.0

@export_group("Test units")
## Units placed on the big island at the start, split between the two teams.
@export_range(0, 400, 1) var unit_count: int = 100
## Test fighters (fixed wing) per team, placed over its block at the start.
@export_range(0, 20, 1) var test_fighters: int = 2
## Test VTOLs (hovering) per team, placed over its block at the start.
@export_range(0, 20, 1) var test_vtols: int = 2
