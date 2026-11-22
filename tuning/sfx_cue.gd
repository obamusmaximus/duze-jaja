class_name SfxCue
extends Resource
## Tunable numbers for one sound: a named cue with a few variations (audio/). The `Sfx` autoload picks a random
## variation and pitch each time it plays. Every cue is a .tres (tuning/sfx_*.tres) listed in `tuning/sfx_library.tres`.

@export_group("Sound")
## The name the game plays it by (e.g. `ui_hover`, `laser_small`).
@export var id: StringName = &""
## Variations; one is picked at random each time.
@export var streams: Array[AudioStream] = []
## Loudness in decibels, before the bus volume.
@export_range(-40.0, 12.0, 0.5) var volume_db: float = 0.0
## Lowest pitch multiplier of the random pitch (1 is as recorded).
@export_range(0.5, 2.0, 0.01) var pitch_min: float = 0.95
## Highest pitch multiplier of the random pitch.
@export_range(0.5, 2.0, 0.01) var pitch_max: float = 1.05
## Repeat the sound until stopped (ambient beds).
@export var loop: bool = false

@export_group("Routing")
## The audio bus it plays on: SFX, UI, Ambient or Music.
@export var bus: StringName = &"SFX"
## On: it comes from a place in the world (quieter with distance, panned to the camera). Off: plays flat.
@export var positional: bool = true

@export_group("Limits")
## At most this many copies of this cue sound at once; more are dropped. A battle of 50 units must not be 50 lasers.
@export_range(1, 32, 1) var max_voices: int = 6
## Minimum seconds between two plays of this cue.
@export_range(0.0, 1.0, 0.005) var min_interval: float = 0.0
