class_name PropStats
extends Resource
## Tunable numbers for a prop type: a static object placed in a level, scenery or a building shell (props/). A prop
## type is a .tres of this class (tuning/prop_hangar_large.tres); every placement of it in a level is one Prop node.

@export_group("Identity")
## The type's name, for the HUD and the playtest log.
@export var display_name: String = "Prop"

@export_group("Look")
## The imported model (.glb) shown for the prop.
@export var model: PackedScene
## Uniform scale of the model. Imported kits are not built to one scale, so each type sets its own.
@export_range(0.1, 30.0, 0.05) var model_scale: float = 4.0
## Turns the model about its centre, in degrees, to line its front up with the prop's own forward (-Z).
@export_range(-180.0, 180.0, 15.0) var model_yaw_deg: float = 0.0

@export_group("Footprint")
## On: units collide with the prop and the map grid blocks its footprint, so paths go around it. Off: scenery only.
@export var blocks: bool = true
## Footprint width (metres, along the prop's x axis).
@export_range(0.5, 40.0, 0.1) var footprint_x: float = 4.0
## Footprint depth (metres, along the prop's z axis).
@export_range(0.5, 40.0, 0.1) var footprint_z: float = 4.0
## Collision height in metres (units cannot climb on it; it only matters to picking and shots).
@export_range(0.2, 20.0, 0.1) var height: float = 3.0
