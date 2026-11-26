class_name FlightSoundStats
extends Resource
## Tunable numbers for the sound of an inhabited flight (views/cockpit/cockpit_sound.gd,
## tuning/flight_sound_default.tres). Each loop's own loudness is on its cue (flight_engine, flight_wind,
## stall_warning). "Top speed" is the type's level top speed (`FlightStats.cruise_speed`).

@export_group("Engine")
## The engine's pitch standing still (1 is as recorded).
@export_range(0.3, 2.0, 0.01) var engine_pitch_slow: float = 0.8
## The engine's pitch at top speed; it goes on rising a little in a dive.
@export_range(0.3, 2.5, 0.01) var engine_pitch_fast: float = 1.2
## Pitch added while the engine holds a hover type up (it works harder).
@export_range(0.0, 1.0, 0.01) var engine_pitch_hover: float = 0.15

@export_group("Wind")
## The speed where the wind starts to be heard, as a share of top speed.
@export_range(0.0, 2.0, 0.05) var wind_from: float = 0.25
## The speed where the wind is at its cue's full loudness, as a share of top speed.
@export_range(0.1, 3.0, 0.05) var wind_to: float = 1.4
## The wind's pitch standing still.
@export_range(0.3, 2.0, 0.01) var wind_pitch_slow: float = 0.7
## The wind's pitch at top speed.
@export_range(0.3, 2.5, 0.01) var wind_pitch_fast: float = 1.15
## Extra wind as the wing nears its stall angle (hard turns roar).
@export_range(0.0, 1.5, 0.05) var wind_stall_load: float = 0.35
## Extra wind while the air brake is held, at top speed.
@export_range(0.0, 1.5, 0.05) var wind_air_brake: float = 0.4

@export_group("Stall warning")
## The warning sounds from this share of the stall angle.
@export_range(0.3, 1.0, 0.01) var warning_load: float = 0.85
## It stops only this far below the warning share, so it doesn't chatter at the edge.
@export_range(0.0, 0.3, 0.01) var warning_release: float = 0.05
## In the stall itself the warning plays this much faster and higher.
@export_range(1.0, 2.5, 0.05) var warning_stall_pitch: float = 1.35

@export_group("Response")
## How quickly the engine and wind follow the flight (per second).
@export_range(0.5, 30.0, 0.5) var response: float = 6.0
