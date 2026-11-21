extends Node
## Debug autoload `PlaytestLog`: keeps the last few seconds of game state and saves them when L (`save_playtest_log`)
## is pressed, for finding out afterwards what went wrong in a playtest.
##
## It knows nothing about gameplay. Any node in the group PROBE_GROUP that has `playtest_snapshot() -> Dictionary` is
## sampled once per physics frame, after every other node has moved. If it also has a
## `playtest_event(event: StringName, data: Dictionary)` signal, those events are logged in between the frames.
## Logs go to `res://playtest_logs/` when run from the editor (gitignored), else `user://playtest_logs/`.

const PROBE_GROUP: StringName = &"playtest_probe"
const STATS_PATH: String = "res://tuning/playtest_log_default.tres"

var _stats: PlaytestLogStats = load(STATS_PATH)
## Frames and events in time order, oldest first. Each has "type" and "t" (real seconds since start).
var _lines: Array[Dictionary] = []
var _frame: int = 0
var _game_time: float = 0.0
var _toast: SavedToast


func _ready() -> void:
	# Runs while paused or dead, so L still saves the frozen moment. Last in the physics order: sees this frame's moves.
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = 1000
	_toast = SavedToast.new()
	add_child(_toast)


func _physics_process(delta: float) -> void:
	if not _stats.enabled or get_tree().paused:
		return
	_frame += 1
	_game_time += delta
	var line: Dictionary = {
		"type": "frame", "f": _frame, "t": _now(), "game_t": _game_time,
		"dt": delta, "time_scale": Engine.time_scale,
	}
	for probe: Node in get_tree().get_nodes_in_group(PROBE_GROUP):
		_connect_events(probe)
		if probe.has_method(&"playtest_snapshot"):
			line[String(probe.name).to_snake_case()] = probe.playtest_snapshot()
	_lines.append(line)
	_trim()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"save_playtest_log") and not event.is_echo():
		save()
		get_viewport().set_input_as_handled()


## Writes the buffered seconds to a new timestamped file (and a screenshot). Returns the log's path, or "" on failure.
func save() -> String:
	var folder: String = _folder()
	DirAccess.make_dir_recursive_absolute(folder)
	_keep_out_of_editor(folder)
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path: String = folder.path_join("%s.jsonl" % stamp)
	var header: Dictionary = {
		"type": "header", "saved_at": stamp, "frames": _frame_count(),
		"scene": get_tree().current_scene.scene_file_path if get_tree().current_scene else "",
		"physics_hz": Engine.physics_ticks_per_second,
	}
	if not PlaytestLogWriter.write(path, header, _lines):
		_toast.show_text("Playtest log FAILED, see the console")
		return ""
	if _stats.save_screenshot:
		_save_screenshot(path.trim_suffix(".jsonl") + ".png")
	print("PlaytestLog: saved %s" % ProjectSettings.globalize_path(path))
	_toast.show_text("Playtest log saved: %s" % path.get_file())
	return path


## No image without a renderer (headless runs), so this can't fail the log itself.
func _save_screenshot(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	if image:
		image.save_png(path)


func _on_probe_event(event: StringName, data: Dictionary) -> void:
	if not _stats.enabled:
		return
	var line: Dictionary = {"type": "event", "event": event, "f": _frame, "t": _now()}
	line.merge(data)
	_lines.append(line)


func _connect_events(probe: Node) -> void:
	if probe.has_signal(&"playtest_event") and not probe.is_connected(&"playtest_event", _on_probe_event):
		probe.connect(&"playtest_event", _on_probe_event)


## Drops lines older than buffer_seconds (real time, so bullet time doesn't stretch the window).
func _trim() -> void:
	var oldest: float = _now() - _stats.buffer_seconds
	var drop: int = 0
	while drop < _lines.size() and _lines[drop]["t"] < oldest:
		drop += 1
	if drop > 0:
		_lines = _lines.slice(drop)


func _frame_count() -> int:
	return _lines.filter(func(line: Dictionary) -> bool: return line["type"] == "frame").size()


func _now() -> float:
	return Time.get_ticks_usec() / 1_000_000.0


func _folder() -> String:
	return "res://playtest_logs" if OS.has_feature("editor") else "user://playtest_logs"


## An empty .gdignore stops the editor importing the screenshots as game assets.
func _keep_out_of_editor(folder: String) -> void:
	var marker: String = folder.path_join(".gdignore")
	if not FileAccess.file_exists(marker):
		FileAccess.open(marker, FileAccess.WRITE)
