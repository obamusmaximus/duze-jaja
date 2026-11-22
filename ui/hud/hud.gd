class_name Hud
extends CanvasLayer
## The in-match HUD: a `HudFrame` laid out by a `HudLayout` (`ui/hud/layouts/`), filled with `HudModule`s. It is a
## view: modules read the selection, units and camera and send nothing but camera jumps. Sizes come from `UiStats`
## (in base units); looks come from the project theme. Swap `layout` to move every module at once.

@export var stats: UiStats
@export var layout: HudLayout

var _frame := HudFrame.new()


## `area` is the part of the ground (x, z) the map covers.
func setup(selection: Selection, team: int, area: Rect2, rig: CameraRig) -> void:
	var context := HudContext.new()
	context.selection = selection
	context.team = team
	context.area = area
	context.rig = rig
	context.stats = stats
	_frame.name = "Frame"
	add_child(_frame)
	_frame.build(layout, context)


## The screen rectangles the framed bands cover, so views can keep clear of them.
func band_rects() -> Array[Rect2]:
	return _frame.band_rects()
