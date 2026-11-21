class_name GameSettings
extends RefCounted
## Player settings that persist between runs (user://settings.cfg): master volume and fullscreen. Plain static data: anything can read it, and the pause menu edits it.

const PATH: String = "user://settings.cfg"
const MASTER_BUS: int = 0

## Master volume, linear 0-1.
static var master_volume: float = 1.0
static var fullscreen: bool = false


static func load_and_apply() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		master_volume = config.get_value("audio", "master_volume", master_volume)
		fullscreen = config.get_value("display", "fullscreen", fullscreen)
	apply()


static func save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.save(PATH)


## Pushes the volume and fullscreen settings to the engine.
static func apply() -> void:
	AudioServer.set_bus_mute(MASTER_BUS, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(maxf(master_volume, 0.001)))
	var is_fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if fullscreen and not is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
