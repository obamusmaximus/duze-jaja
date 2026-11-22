class_name LightStats
extends Resource
## Tunable numbers for a level's light and air (`WorldLight`): the sun, the ambient light, the haze that distance
## fades into, and the exposure. One .tres per preset (`light_day.tres`, `light_void.tres`); levels share presets
## instead of setting up their own light. Colours are palette roles (`UiTokens.WORLD_SKY`, `WORLD_HAZE`, `WORLD_SUN`,
## `WORLD_VOID`), not tunables.

@export_group("Sun")
## Sun height above the horizon (degrees). Lower gives longer shadows, which help big things read as big.
@export_range(5.0, 90.0, 1.0) var sun_elevation: float = 38.0
## Compass direction the sunlight comes from (degrees).
@export_range(-180.0, 180.0, 1.0) var sun_direction: float = -125.0
## Strength of the sunlight.
@export_range(0.0, 3.0, 0.05) var sun_energy: float = 1.0
## Softening of shadow edges (0 is hard, as the style guide wants).
@export_range(0.0, 2.0, 0.05) var shadow_blur: float = 0.4

@export_group("Sky")
## On: a sky from the sky colour overhead to the haze colour at the horizon. Off: the black void (space, test maps).
@export var sky: bool = true
## Strength of the ambient light (haze-coloured), which fills the shadows.
@export_range(0.0, 2.0, 0.05) var ambient_energy: float = 0.5

@export_group("Haze")
## How fast distance fades into the haze (exponential fog density per metre; 0 is off). Haze is the main cue that
## something far away is far away, so big things read as big.
@export_range(0.0, 0.01, 0.0001) var haze_density: float = 0.0006
## How much the haze also covers the sky (0 leaves the sky clear, 1 fades it fully).
@export_range(0.0, 1.0, 0.05) var haze_sky_affect: float = 0.0

@export_group("Exposure")
## Overall brightness before tonemapping. Lower it if light hulls blow out to white.
@export_range(0.2, 3.0, 0.05) var exposure: float = 0.75
## The brightness that maps to pure white (filmic tonemap). Higher keeps more detail in bright surfaces.
@export_range(1.0, 16.0, 0.5) var white: float = 4.0
