class_name DayNightToggle
extends Node
## Debug: `debug_day_night` (N) swaps the level's light between the day and night presets (`WorldLight.use_preset`).
## The terrain shadow is traced again for the new sun, so the swap hitches. Nothing in the simulation reads light.

const DAY: LightStats = preload("res://tuning/light_day.tres")
const NIGHT: LightStats = preload("res://tuning/light_night.tres")

var _light: WorldLight


func setup(light: WorldLight) -> void:
	_light = light


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_day_night"):
		get_viewport().set_input_as_handled()
		_light.use_preset(DAY if _light.stats.night else NIGHT)
