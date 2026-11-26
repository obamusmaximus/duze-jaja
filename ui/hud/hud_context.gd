class_name HudContext
extends RefCounted
## What the HUD's modules may read: the local player's selection and team, the map area, the camera rig and the HUD
## stats. Handed to every module through `HudModule.bind`.

var selection: Selection
var team: int = 0
## The part of the ground (x, z) the map covers.
var area: Rect2
var rig: CameraRig
var stats: UiStats
## What the strategist's next ground click does (the commands panel arms it, `StrategyControl` spends it).
var tools: StrategyTools
## Where command buttons ask the RTS controls to act.
var commands: HudCommands
