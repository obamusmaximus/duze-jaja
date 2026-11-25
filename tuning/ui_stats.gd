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
## Width of one cargo slot in the selected carrier's hold view, in base units.
@export_range(2, 8, 1) var cargo_slot_units: int = 4
## Side of one card in the selection grid (a type, or a unit when one type is selected), in base units.
@export_range(8, 24, 1) var selection_card_units: int = 9
## Columns of the selection card grid.
@export_range(1, 8, 1) var selection_columns: int = 4
## Rows of the selection card grid; more cards than fit end in a "+N" card.
@export_range(1, 6, 1) var selection_rows: int = 3

@export_group("Command grid")
## Columns of the command and build grid.
@export_range(1, 8, 1) var command_columns: int = 4
## Rows of the command and build grid.
@export_range(1, 6, 1) var command_rows: int = 3
## Side of one grid cell, in base units.
@export_range(6, 20, 1) var command_cell_units: int = 8

@export_group("Strategy HUD")
## Width of the strategy HUD's right column (resource counter, production), in base units.
@export_range(30, 80, 1) var strategy_panel_units: int = 46
## Width of the strategy HUD's left column (commands), in base units.
@export_range(20, 80, 1) var command_panel_units: int = 34
## Side of one commander ability slot, in base units.
@export_range(6, 20, 1) var ability_slot_units: int = 10

@export_group("HUD swap")
## Seconds one module takes to trace in or out when the RTS and strategy HUDs swap.
@export_range(0.05, 2.0, 0.05) var swap_time: float = 0.45
## Seconds between one module starting and the next.
@export_range(0.0, 0.5, 0.01) var swap_stagger: float = 0.06
## Seconds after the outgoing HUD starts before the incoming one does.
@export_range(0.0, 2.0, 0.05) var swap_delay: float = 0.3
## Size of a glitch block in pixels: along the trace, then across it.
@export var glitch_cell: Vector2 = Vector2(24.0, 8.0)
## Width of the flickering band behind the trace front, as a fraction of the module.
@export_range(0.0, 1.0, 0.05) var glitch_band: float = 0.3
## How far the block streaks lag each other, as a fraction of the module.
@export_range(0.0, 1.0, 0.05) var glitch_jitter: float = 0.35
## Width of the solid acid-green head at the trace front, in pixels.
@export_range(0.0, 24.0, 1.0) var glitch_head: float = 6.0
## Flickers per second in the band.
@export_range(5.0, 60.0, 1.0) var glitch_flicker_rate: float = 30.0

@export_group("Readouts")
## How often the force and clock readouts refresh, per second.
@export_range(1.0, 30.0, 1.0) var readout_rate: float = 4.0
