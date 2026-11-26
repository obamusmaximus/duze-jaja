class_name HeightmapStats
extends Resource
## Tunable numbers for the heightmap terrain (terrain/, tuning/heightmap_default.tres): how the ground is cut into
## chunks, how far each level of detail shows, how the surface roles are picked and how fast changes rebuild.

@export_group("Samples")
## Metres between height samples of a map made by the test generator. Coarser than the map grid's cell: fewer
## numbers to store and draw. (A loaded map keeps its own spacing.)
@export_range(1.0, 16.0, 0.5) var sample_spacing: float = 2.0

@export_group("Import")
## The heightmap PNG (16-bit greyscale) the level loads, watches and saves back to.
@export_file("*.png") var source_path: String = "res://levels/heightmap_test/heightmap.png"
## Height (metres) of a black pixel.
@export_range(-500.0, 0.0, 1.0) var min_height: float = -50.0
## Metres from black to white: a white pixel is `min_height + height_range`. Sea level (0 m) is at grey
## `-min_height / height_range`.
@export_range(10.0, 1000.0, 1.0) var height_range: float = 200.0
## Metres between samples (pixels) of an imported map.
@export_range(1.0, 16.0, 0.5) var import_spacing: float = 4.0
## Seconds between checks of the PNG's modified time for the auto-reload.
@export_range(0.1, 5.0, 0.1) var reload_poll_seconds: float = 0.5

@export_group("Chunks")
## Cells along one side of a chunk (a chunk is the unit of mesh, collision and rebuilding). Must be a multiple of
## `lod_step`.
@export_range(8, 64, 4) var chunk_cells: int = 32
## The far mesh uses every this-many samples (a coarser facet grid). 1 turns the far level off.
@export_range(1, 8, 1) var lod_step: int = 4
## Distance (metres, from the camera) beyond which a chunk shows its coarse mesh.
@export_range(50.0, 4000.0, 10.0) var lod_distance: float = 500.0
## Chunks rebuilt per physics tick after a change; the rest wait for the next tick.
@export_range(1, 32, 1) var chunks_per_tick: int = 4
## Metres under the deepest wave trough a whole chunk must lie to go undrawn (it keeps its collision). Raise it if
## holes ever show in the sea.
@export_range(0.0, 20.0, 0.5) var submerged_depth: float = 1.0

@export_group("Surface")
## Ground this far above the sea (metres) or lower is sand.
@export_range(0.0, 10.0, 0.1) var beach_height: float = 1.5
## Facets steeper than this (degrees) are stone.
@export_range(10.0, 80.0, 1.0) var rock_slope_deg: float = 38.0
## Ground higher than this above the sea (metres) is soil (a bare summit).
@export_range(1.0, 200.0, 1.0) var soil_height: float = 22.0
## Seabed deeper than this below the sea (metres) is dark stone, shallower is sand (it reads lighter through the water).
@export_range(1.0, 60.0, 1.0) var deep_depth: float = 6.0

@export_group("Baked light")
## How strongly the sun's horizon shadow (long raking shadows from hills) darkens and cools the ground, 0 to 1. Baked
## into the chunk colours, so free per frame and in both views.
@export_range(0.0, 1.0, 0.05) var light_shadow: float = 0.6
## Colour the shadowed ground is multiplied toward (cool, like skylight).
@export var light_shade_tint: Color = Color(0.55, 0.62, 0.8)
## Vertical metres over which a shadow's edge fades (soft penumbra).
@export_range(0.1, 10.0, 0.1) var light_shadow_softness: float = 2.5
## Farthest (metres) a shadow is traced from what casts it. Longer is slower to bake and rebuilds more chunks on an edit.
@export_range(50.0, 1500.0, 10.0) var light_reach: float = 400.0
## How strongly hollows darken (cavity occlusion, the Mobile renderer has no SSAO), 0 to 1.
@export_range(0.0, 1.0, 0.05) var light_ao: float = 0.5
## Metres from a sample that its neighbours count for the hollow test.
@export_range(2.0, 60.0, 1.0) var light_ao_radius: float = 12.0
## How much the ground colour varies across the map (field patchwork), 0 off.
@export_range(0.0, 0.3, 0.01) var tint_strength: float = 0.07
## Cycles per metre of that variation (small is broad patches).
@export_range(0.0005, 0.02, 0.0005) var tint_frequency: float = 0.004

@export_group("Brush")
## Radius (metres) of the debug terrain brush.
@export_range(2.0, 150.0, 1.0) var brush_radius: float = 20.0
## Metres the radius changes per press of the smaller / larger keys.
@export_range(1.0, 20.0, 1.0) var brush_radius_step: float = 5.0
## Metres per second the raise and lower brushes move the ground at the centre.
@export_range(1.0, 100.0, 1.0) var brush_rate: float = 15.0
## How fast (per second, 1 = reaches it in a second) the flatten brush pulls the ground to the height first clicked.
@export_range(0.5, 20.0, 0.5) var flatten_rate: float = 4.0
## Metres deep the crater brush digs at its centre (its rim rises a little).
@export_range(0.5, 30.0, 0.5) var crater_depth: float = 5.0

@export_group("Overlay")
## Metres between contour lines of the height-band overlay.
@export_range(1.0, 50.0, 1.0) var contour_interval: float = 10.0
## Height (metres above the sea) at which the overlay's bands reach their top colour.
@export_range(10.0, 400.0, 10.0) var band_top: float = 100.0
