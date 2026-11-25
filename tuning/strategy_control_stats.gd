class_name StrategyControlStats
extends Resource
## Tunable numbers for the strategist's controls in the bird's-eye view and the war table (`views/strategy/`,
## `docs/mechanics/rts_controls.md`): picking figures, the outlines and the map markers drawn on screen.
## One `.tres` (`strategy_control_default.tres`).

@export_group("Picking")
## How near (pixels) a click must be to a figure's centre to pick it.
@export_range(4.0, 80.0, 1.0) var pick_radius_px: float = 22.0
## Mothership pick radius, times `pick_radius_px`.
@export_range(1.0, 6.0, 0.1) var ship_pick_scale: float = 2.0
## A press that moves farther than this (pixels) before release was a camera drag, not a click.
@export_range(1.0, 30.0, 1.0) var click_slop_px: float = 6.0
## Times a second the figures are re-read for hovering.
@export_range(1.0, 60.0, 1.0) var hover_hz: float = 15.0

@export_group("Outlines")
## Smallest side of an outline, pixels.
@export_range(8.0, 120.0, 1.0) var outline_min_px: float = 30.0
## Margin from a squad's members to its outline, pixels.
@export_range(0.0, 60.0, 1.0) var outline_pad_px: float = 14.0
## Line width of the outline, pixels.
@export_range(1.0, 8.0, 0.5) var outline_width: float = 3.0
## Length of each corner bracket, share of the outline's side.
@export_range(0.1, 0.5, 0.01) var bracket_share: float = 0.3

@export_group("Markers")
## Radius of a marker's glyph, pixels.
@export_range(6.0, 60.0, 1.0) var marker_radius_px: float = 18.0
## Smallest distance (pixels) from a right click to a marker that takes the marker away.
@export_range(4.0, 80.0, 1.0) var marker_clear_px: float = 24.0
