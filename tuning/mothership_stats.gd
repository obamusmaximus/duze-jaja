class_name MothershipStats
extends Resource
## Tunable numbers for a hovering mothership (`bases/mothership.gd`, tuning/mothership_default.tres): its size, how many
## production bays and carryall pads it shows, and the model scene that draws it. Where it hovers is
## `BattlefieldStats` (Motherships group).

@export_group("Size")
## Length of the main hull along the ship's z axis, in metres, not counting the prow.
@export_range(60.0, 800.0, 5.0) var hull_length: float = 320.0
## Width of the hull (beam), in metres.
@export_range(20.0, 300.0, 1.0) var beam: float = 90.0
## Height of the main hull, in metres.
@export_range(10.0, 200.0, 1.0) var hull_height: float = 50.0
## Length of the wedged prow in front of the hull, as a share of the beam.
@export_range(0.2, 2.0, 0.05) var prow_ratio: float = 0.8

@export_group("Fittings")
## Carryall landing pads on the top deck.
@export_range(0, 8, 1) var carryall_pads: int = 4
## Production bays (doors) under the hull; one per production line later.
@export_range(0, 8, 1) var production_bays: int = 4

## Helipads for fighters and VTOLs on the top deck, aft of the carryall pads, in two rows.
@export_range(0, 6, 1) var helipads: int = 6

@export_group("Vision")
## How far the mothership detects a target of signature 1, in metres. It looks from its underside.
@export_range(0.0, 1500.0, 10.0) var sensor_range: float = 250.0

@export_group("Pads")
## How carryalls land on and leave their deck pads. Read at level load, like the rest of this group.
@export var carryall_pad: PadStats
## How fighters and VTOLs land on and leave the deck's helipads.
@export var helipad: PadStats
## How a new Explorer leaves the pad it was built on.
@export var explorer_pad: PadStats
## How far (metres) beyond the hull's side a craft climbs to before it slides in over the deck, and leaves by.
@export_range(5.0, 200.0, 1.0) var gate_margin: float = 25.0
## How far (metres) round the outer deck pads a click still counts as the mothership's pads.
@export_range(2.0, 40.0, 0.5) var pad_pick_margin: float = 8.0

@export_group("Shadow")
## How dark the soft ground shadow under the hull is (sun shadows are off at far zoom).
@export_range(0.0, 1.0, 0.05) var shadow_strength: float = 0.45

@export_group("Model")
## The scene that draws the hull (must follow `MothershipProto`'s attachment point names).
@export var model: PackedScene
