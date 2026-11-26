class_name SfxLoop
extends AudioStreamPlayer
## One looping cue that its owner can drive live (volume and pitch). Made by `Sfx` (`make_loop`, `start_ambient`).
## View side.

## Below this share of the cue's volume the loop is silent (decibels have no zero).
const SILENT_GAIN: float = 0.0001

var cue: SfxCue


func _init(loop_cue: SfxCue, looped_stream: AudioStream) -> void:
	cue = loop_cue
	stream = looped_stream
	bus = cue.bus
	volume_db = cue.volume_db


## `gain` is a share of the cue's volume (0 silent, 1 as set on the cue); `pitch` multiplies the recorded one.
func drive(gain: float, pitch: float = 1.0) -> void:
	volume_db = cue.volume_db + linear_to_db(maxf(gain, SILENT_GAIN))
	pitch_scale = maxf(pitch, 0.01)
