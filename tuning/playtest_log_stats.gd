class_name PlaytestLogStats
extends Resource
## Tunable numbers for the playtest log (debug/playtest_log/). One .tres per preset (tuning/playtest_log_default.tres),
## loaded by the PlaytestLog autoload.

@export_group("Recording")
## Record the last few seconds of every physics frame so L (`save_playtest_log`) can save them.
@export var enabled: bool = true
## How many seconds of frames the log keeps and saves.
@export_range(1.0, 30.0, 0.5) var buffer_seconds: float = 5.0
## Also save a screenshot of the moment L was pressed, next to the log.
@export var save_screenshot: bool = true
