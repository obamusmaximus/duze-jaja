class_name TerrainStats
extends Resource
## Tunable numbers for the tile terrain (terrain/): how big one tile is and how the cliff faces look. The tiles are
## Kenney Space Kit pieces (1 model unit wide); one height step is half a tile.

@export_group("Tiles")
## Side of one tile, in metres. A height step is half of it (a ramp climbs one step over one tile).
@export_range(2.0, 24.0, 0.5) var tile_size: float = 8.0

@export_group("Cliffs")
## Palette role of the generated cliff faces between tiles of different height.
@export var cliff_role: WorldMaterials.Role = WorldMaterials.Role.SOIL

@export_group("Look")
## On: every tile is drawn in `tile_role` (flat, lit) instead of the kit's own texture. Off: the kit's colours.
@export var tint_tiles: bool = false
## Palette role of the tiles when `tint_tiles` is on (grass for an island).
@export var tile_role: WorldMaterials.Role = WorldMaterials.Role.GRASS
