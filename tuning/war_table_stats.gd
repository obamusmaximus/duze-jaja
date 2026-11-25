class_name WarTableStats
extends Resource
## Tunable numbers for the war table, the strategy view (`docs/mechanics/war_table.md`): the simplified map model, its
## tilt-shift blur, the squad tokens. One `.tres` (`war_table_default.tres`).

@export_group("Table")
## Ground samples per table cell. The table is a coarse copy of the heightmap, so higher is cheaper and blockier.
@export_range(1, 16, 1) var sample_step: int = 4
## Table cells per tile; a map change redraws only the tiles it touches.
@export_range(4, 64, 1) var tile_cells: int = 16
## Tiles redrawn per frame after a map change.
@export_range(1, 16, 1) var tiles_per_frame: int = 2
## Multiplier on land heights, so low islands still read as relief.
@export_range(0.5, 6.0, 0.1) var height_scale: float = 2.0
## Multiplier on depths below sea level (the seabed is drawn nearly flat).
@export_range(0.0, 1.0, 0.05) var depth_scale: float = 0.15
## Height of the table above the live world, metres, so the two never overlap. Only the camera's visual layer decides what shows.
@export_range(500.0, 20000.0, 100.0) var table_height: float = 4000.0
## Direction the table's fake sun comes from (shading is painted into the vertex colours).
@export var light_direction: Vector3 = Vector3(-0.5, 0.8, -0.35)
## Strength of that shading: 0 is flat colour.
@export_range(0.0, 1.0, 0.05) var shade_strength: float = 0.5

@export_group("Tilt-shift")
## Blur far from the focus band, on or off.
@export var blur_enabled: bool = true
## Distance from the camera (as a share of the camera's distance to its focus) where far blur starts.
@export_range(0.5, 3.0, 0.05) var far_start: float = 1.15
## Length over which the far blur ramps up, as a share of the camera distance.
@export_range(0.05, 3.0, 0.05) var far_transition: float = 0.8
## Distance (share of camera distance) where near blur ends.
@export_range(0.0, 1.5, 0.05) var near_end: float = 0.8
## Length over which the near blur ramps up, as a share of the camera distance.
@export_range(0.05, 3.0, 0.05) var near_transition: float = 0.5
## Blur strength.
@export_range(0.0, 1.0, 0.01) var blur_amount: float = 0.12

@export_group("Tokens")
## Token size as a share of the camera distance (so tokens stay readable at every zoom).
@export_range(0.002, 0.05, 0.001) var token_size: float = 0.012
## Carryall token size, times `token_size`.
@export_range(1.0, 4.0, 0.1) var carryall_scale: float = 1.6
## Mothership token size, times `token_size`.
@export_range(1.0, 8.0, 0.1) var ship_scale: float = 3.5
## Token refreshes per second.
@export_range(1.0, 60.0, 1.0) var token_hz: float = 10.0
## Height of a token above the ground, metres.
@export_range(0.0, 100.0, 1.0) var token_lift: float = 12.0
