class_name BirdsEyeStats
extends Resource
## Tunable numbers for the bird's-eye view, the live high view of the map (`docs/mechanics/birds_eye.md`): the fly
## transition, the far sea round the map and the haze. Camera limits are the `CameraStats` preset
## `camera_birdseye.tres`. One `.tres` (`birds_eye_default.tres`).

@export_group("Camera")
## Share of the map's half-width and half-depth the camera focus stays out of from each edge, so panning never
## shows much past the playable area.
@export_range(0.0, 0.9, 0.01) var pan_inset: float = 0.25

@export_group("Transition")
## Seconds to fly between the RTS view and this one (real time).
@export_range(0.2, 6.0, 0.05) var transition_time: float = 1.6

@export_group("Tilt-shift")
## Turns the whole post pass off (compare with the plain view).
@export var post_enabled: bool = true
## Screen row (0 top, 1 bottom) of the middle of the sharp band.
@export_range(0.0, 1.0, 0.01) var band_center: float = 0.55
## Height of the sharp band, share of the screen.
@export_range(0.0, 1.0, 0.01) var band_width: float = 0.35
## How softly the blur grows beyond the band, share of the screen.
@export_range(0.05, 1.0, 0.01) var band_falloff: float = 0.35
## Blur at the top of the screen (the far side) and at the bottom (near), 0 to 1 of the blur range.
@export_range(0.0, 1.0, 0.01) var far_blur: float = 0.9
@export_range(0.0, 1.0, 0.01) var near_blur: float = 0.6
## Blur toward the screen corners, 0 to 1.
@export_range(0.0, 1.0, 0.01) var edge_blur: float = 0.7
## Largest mip level the blur reads (the blur range), higher is blurrier.
@export_range(1.0, 8.0, 0.1) var max_blur_lod: float = 4.5

@export_group("Grade")
## Unsharp mask in the sharp area: 0 off, 1 doubles the local contrast.
@export_range(0.0, 2.0, 0.05) var clarity: float = 0.6
## Saturation and contrast multipliers inside the sharp area.
@export_range(0.5, 2.0, 0.01) var focus_saturation: float = 1.2
@export_range(0.5, 2.0, 0.01) var focus_contrast: float = 1.1
## Colour the blurred edges lift toward, and how strongly (0 to 1).
@export var haze_color: Color = Color(0.72, 0.8, 0.88)
@export_range(0.0, 1.0, 0.01) var edge_haze: float = 0.35
## Share the blurred edges lose of their colour.
@export_range(0.0, 1.0, 0.01) var edge_desaturation: float = 0.4
## Darkening toward the corners.
@export_range(0.0, 1.0, 0.01) var vignette: float = 0.25

@export_group("Clouds")
## Turns both cloud layers (and their shadows) off.
@export var clouds_enabled: bool = true
## A second, higher layer (parallax between the two).
@export var second_layer: bool = true
## Heights of the two layers above sea level, metres. Keep them under the camera's closest height.
@export_range(50.0, 600.0, 5.0) var cloud_height_low: float = 220.0
@export_range(50.0, 800.0, 5.0) var cloud_height_high: float = 380.0
## Metres one tile of the noise covers (the size of the cloud features).
@export_range(500.0, 12000.0, 100.0) var cloud_size: float = 4500.0
## Wind: compass-style direction (degrees on the map plane) and speed (m/s).
@export_range(0.0, 360.0, 1.0) var wind_direction: float = 35.0
@export_range(0.0, 200.0, 1.0) var wind_speed: float = 14.0
## Share of the sky the noise fills with cloud, and how soft its edges are.
@export_range(0.0, 1.0, 0.01) var coverage: float = 0.5
@export_range(0.02, 1.0, 0.01) var softness: float = 0.2
## Cloud opacity, 0 to 1.
@export_range(0.0, 1.0, 0.01) var cloud_opacity: float = 0.9
## How much thinner the clouds are over the screen centre than at the edges (0 even, 1 none in the middle), and the
## distance from the centre (share of the corner distance) where they start to thicken.
@export_range(0.0, 1.0, 0.01) var edge_bias: float = 0.95
@export_range(0.0, 1.0, 0.01) var edge_start: float = 0.3
## Lit and shaded cloud colours.
@export var cloud_color: Color = Color(1.0, 1.0, 1.0)
@export var cloud_shade_color: Color = Color(0.45, 0.52, 0.65)
## Fake lighting: how far toward the sun (noise tile share) the second tap reaches, and how strongly it shades.
@export_range(0.0, 0.1, 0.002) var light_reach: float = 0.02
@export_range(0.0, 20.0, 0.1) var light_gain: float = 6.0
## Clouds fade out within this camera distance (m) of a layer, over `fade_range` more, so the flight doesn't whiteout.
@export_range(0.0, 400.0, 5.0) var fade_near: float = 40.0
@export_range(10.0, 1000.0, 5.0) var fade_range: float = 200.0
## How dark the clouds' shadows make the sea and land (0 none, 1 black).
@export_range(0.0, 1.0, 0.01) var shadow_strength: float = 0.5

@export_group("Sea")
## How far (m) from the map's centre the far sea reaches, so no void shows past the map at any zoom.
@export_range(2000.0, 40000.0, 500.0) var far_sea_reach: float = 12000.0

@export_group("Light")
## Haze density in this view (the RTS view's is `LightStats.haze_density`), tuned for kilometres.
@export_range(0.0, 0.002, 0.00005) var haze_density: float = 0.00012
## Colour adjustment: contrast, saturation and brightness of the whole view.
@export_range(0.5, 1.5, 0.01) var contrast: float = 1.1
@export_range(0.5, 1.5, 0.01) var saturation: float = 1.12
@export_range(0.5, 1.5, 0.01) var brightness: float = 1.0
## Soft glow on bright highlights (foam, sun glitter).
@export var glow: bool = true
## The sun's shadows switch off above this share of the flight (the shadow map can't cover kilometres).
@export_range(0.0, 1.0, 0.05) var shadows_off_blend: float = 0.3

@export_group("Blips")
## Side of a unit's blip on screen, in pixels (squads, carryalls and motherships scale from it).
@export_range(2.0, 24.0, 0.5) var blip_size: float = 7.0
## Squad blip size, times `blip_size`.
@export_range(1.0, 4.0, 0.1) var squad_blip_scale: float = 1.8
## Carryall blip size, times `blip_size`.
@export_range(1.0, 4.0, 0.1) var carryall_blip_scale: float = 1.6
## Mothership blip size, times `blip_size`.
@export_range(1.0, 8.0, 0.1) var ship_blip_scale: float = 3.5
## How often the blips re-read the units, per second (they are re-projected every frame).
@export_range(1.0, 60.0, 1.0) var blip_hz: float = 10.0
## Share of the flight up at which the blips start to fade in (fully shown at the top).
@export_range(0.0, 1.0, 0.05) var blip_show_blend: float = 0.5
