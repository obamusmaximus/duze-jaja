class_name AudioStats
extends Resource
## Tunable numbers for the audio system (audio/): bus volumes and how sounds fall off with distance from the camera's
## focus point. The cues themselves are `SfxCue` resources.

@export_group("Bus volumes")
## SFX bus (combat, orders, selection), in decibels.
@export_range(-40.0, 6.0, 0.5) var sfx_db: float = 0.0
## UI bus (hover, click, confirm), in decibels.
@export_range(-40.0, 6.0, 0.5) var ui_db: float = -3.0
## Ambient bus (wind and the like), in decibels.
@export_range(-40.0, 6.0, 0.5) var ambient_db: float = -10.0
## Music bus, in decibels.
@export_range(-40.0, 6.0, 0.5) var music_db: float = -8.0

@export_group("Distance")
## Distance (metres from the camera's focus point) within which a world sound is at full volume.
@export_range(1.0, 200.0, 1.0) var full_volume_distance: float = 30.0
## Beyond this distance (metres) a world sound is not played at all.
@export_range(10.0, 500.0, 5.0) var max_distance: float = 140.0
## How strongly sounds pan left and right with the camera's view (0 = none).
@export_range(0.0, 1.0, 0.05) var panning: float = 0.6

@export_group("Voices")
## World sounds that can play at once across all cues.
@export_range(4, 64, 1) var world_voices: int = 32
## UI and flat sounds that can play at once.
@export_range(2, 32, 1) var flat_voices: int = 12
