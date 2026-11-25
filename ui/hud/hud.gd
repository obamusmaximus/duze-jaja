class_name Hud
extends CanvasLayer
## The in-match HUD: a `HudFrame` laid out by a `HudLayout` (`ui/hud/layouts/`), filled with `HudModule`s. It is a
## view: modules read the selection, units and camera and send nothing but camera jumps and orders through the
## issuer. Sizes come from `UiStats` (in base units); looks come from the project theme. Swap `layout` to move every
## module at once. A `strategy_layout` and a `flight_layout` make further HUDs for the strategy views and the first
## person; `show_mode` swaps between them with a glitch trace (`HudSwap`).

enum Mode { RTS, STRATEGY, FLIGHT }

@export var stats: UiStats
@export var layout: HudLayout
## The HUD of the strategy views (bird's-eye and war table). None: the RTS HUD stays up in every view.
@export var strategy_layout: HudLayout
## The first-person HUD of an inhabited flyer. None: the RTS HUD stays up there too.
@export var flight_layout: HudLayout

## Mode to its HudFrame; modes without a layout have none and use the RTS one.
var _frames: Dictionary = {}
var _swap := HudSwap.new()
var _mode: Mode = Mode.RTS
## The armed map marker or landing zone; shared with the strategy views' controls.
var tools := StrategyTools.new()


## `area` is the part of the ground (x, z) the map covers.
func setup(selection: Selection, team: int, area: Rect2, rig: CameraRig) -> void:
	var context := HudContext.new()
	context.selection = selection
	context.team = team
	context.area = area
	context.rig = rig
	context.stats = stats
	context.tools = tools
	_swap.name = "Swap"
	add_child(_swap)
	_swap.setup(stats)
	_build_frame(Mode.RTS, "Frame", layout, context)
	_build_frame(Mode.STRATEGY, "StrategyFrame", strategy_layout, context)
	_build_frame(Mode.FLIGHT, "FlightFrame", flight_layout, context)


## Swaps to the HUD of `mode`, tracing the outgoing modules out and the incoming ones in.
func show_mode(mode: Mode) -> void:
	var next: Mode = mode if _frames.has(mode) else Mode.RTS
	if next == _mode or not _frames.has(next):
		return
	_swap.run(_frames[_mode], 0.0)
	_swap.run(_frames[next], 1.0, stats.swap_delay)
	_mode = next


## The screen rectangles the framed bands cover, so views can keep clear of them.
func band_rects() -> Array[Rect2]:
	return (_frames[_mode] as HudFrame).band_rects()


func _build_frame(mode: Mode, frame_name: String, frame_layout: HudLayout, context: HudContext) -> void:
	if frame_layout == null:
		return
	var frame := HudFrame.new()
	frame.name = frame_name
	add_child(frame)
	frame.build(frame_layout, context)
	_frames[mode] = frame
	if mode != Mode.RTS:
		_swap.snap(frame, false)
