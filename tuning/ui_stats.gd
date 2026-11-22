class_name UiStats
extends Resource
## Tunable sizes of the HUD (ui/hud/), held by the Hud (tuning/ui_default.tres) and read by its frame and modules.
## Sizes are in base units (`UiTokens.UNIT` pixels at the 1920x1080 base size), so everything stays on the grid.
## Colours, the unit, the border weight and the type scale are the style guide's and live in `UiTokens`. Where
## modules sit is the HUD layout's (`HudLayout`), not a number.

@export_group("Frame")
## Gap between modules, and from them to the screen edge or band edge, in base units.
@export_range(1, 4, 1) var gap_units: int = 2
## Least thickness of a framed band (the bottom bar, a sidebar), in base units.
@export_range(10, 60, 1) var band_units: int = 24

@export_group("Minimap")
## Side of the square minimap, in base units.
@export_range(16, 60, 1) var minimap_units: int = 27
## Radius of a unit's blip on the minimap, in pixels.
@export_range(2.0, 12.0, 0.5) var blip_radius: float = 4.0

@export_group("Selection panel")
## Width of the selection panel, in base units.
@export_range(30, 120, 1) var selection_width_units: int = 48
## Side of the square unit portrait when one unit is selected, in base units.
@export_range(12, 40, 1) var portrait_units: int = 16
## Side of one unit-type card when several types are selected, in base units.
@export_range(8, 24, 1) var selection_card_units: int = 9

@export_group("Command grid")
## Columns of the command and build grid.
@export_range(1, 8, 1) var command_columns: int = 4
## Rows of the command and build grid.
@export_range(1, 6, 1) var command_rows: int = 3
## Side of one grid cell, in base units.
@export_range(6, 20, 1) var command_cell_units: int = 8

@export_group("Readouts")
## How often the force and clock readouts refresh, per second.
@export_range(1.0, 30.0, 1.0) var readout_rate: float = 4.0
