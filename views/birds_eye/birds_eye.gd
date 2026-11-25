class_name BirdsEye
extends Node3D
## Visual only: the bird's-eye view (`docs/mechanics/birds_eye.md`), the live map seen from high above. Holds its own
## `CameraRig` (a `CameraStats` preset with the sky guard on, no ground following), the far sea that keeps the void
## out of sight, and the haze `Environment` of its camera. Off outside the view: the rig is disabled and the sea ring
## hidden. It never changes game state.

const RIG_SCENE: PackedScene = preload("res://camera/camera_rig.tscn")
const CAMERA_STATS: CameraStats = preload("res://tuning/camera_birdseye.tres")

@export var stats: BirdsEyeStats

var rig: CameraRig
## The environment of the bird's-eye camera (and the flight's end state).
var environment: Environment
var _sea: Node3D
var post: BirdsEyePost
var clouds: BirdsEyeClouds
var blips: BirdsEyeBlips
var _light: WorldLight
var _bounds: Rect2
var _home_yaw: float = 0.0


## `bounds` limits the camera focus, `home_yaw` is the rig's reset yaw, `water` supplies the sea material and level,
## `light` the level's environment and sun, `chunks` the terrain that takes the cloud shadows.
func setup(bounds: Rect2, home_yaw: float, water: WaterBody, light: WorldLight, chunks: TerrainChunks) -> void:
	_light = light
	rig = RIG_SCENE.instantiate()
	rig.stats = CAMERA_STATS
	rig.follow_ground = false
	add_child(rig)
	_bounds = bounds
	_home_yaw = home_yaw
	rig.setup(_inset_bounds(), home_yaw)
	stats.changed.connect(func() -> void: rig.setup(_inset_bounds(), _home_yaw))
	rig.process_mode = Node.PROCESS_MODE_DISABLED
	_build_sea(water)
	environment = light.environment().duplicate()
	stats.changed.connect(_apply_environment)
	_apply_environment()
	rig.get_camera().environment = environment
	post = BirdsEyePost.new()
	post.name = "Post"
	add_child(post)
	post.setup(stats)
	post.attach(rig.get_camera())
	clouds = BirdsEyeClouds.new()
	clouds.name = "Clouds"
	add_child(clouds)
	clouds.setup(stats, rig, chunks, light.sun())
	clouds.attach(rig.get_camera())
	# Below the HUD (layer 10), above the world.
	var blip_layer := CanvasLayer.new()
	blip_layer.name = "BlipLayer"
	blip_layer.layer = 5
	add_child(blip_layer)
	blips = BirdsEyeBlips.new()
	blips.name = "Blips"
	blip_layer.add_child(blips)
	blips.setup(stats)
	set_shown(false)


## The map's bounds pulled in by `pan_inset` of the half-extent on every side.
func _inset_bounds() -> Rect2:
	var inset: Vector2 = _bounds.size * 0.5 * stats.pan_inset
	return Rect2(_bounds.position + inset, _bounds.size - inset * 2.0)


## The sea ring and the sun shadows follow whether the view is up (or flying toward it).
func set_shown(shown: bool) -> void:
	_sea.visible = shown


## Sun shadows are on in the RTS view and off once the flight is `blend` of the way up.
func apply_blend(blend: float) -> void:
	_light.set_shadows(blend < stats.shadows_off_blend)
	post.apply_blend(blend)
	clouds.apply_blend(blend)
	blips.apply_blend(blend)


## Four flat quads round the water's sheet, out to `far_sea_reach`, on the sheet's own flat material (waves off, so
## they cost a handful of triangles). No collision, no grid, nothing simulated.
func _build_sea(water: WaterBody) -> void:
	_sea = Node3D.new()
	_sea.name = "FarSea"
	_sea.top_level = true
	add_child(_sea)
	var half: Vector2 = water.size * 0.5
	var reach: float = maxf(stats.far_sea_reach, maxf(half.x, half.y) + 1000.0)
	var y: float = water.global_position.y
	# Overlap the sheet a little so no seam shows.
	var inner: Vector2 = half - Vector2(8.0, 8.0)
	var strips: Array[Rect2] = [
		Rect2(-reach, -reach, reach - inner.x, reach * 2.0),
		Rect2(inner.x, -reach, reach - inner.x, reach * 2.0),
		Rect2(-inner.x, -reach, inner.x * 2.0, reach - inner.y),
		Rect2(-inner.x, inner.y, inner.x * 2.0, reach - inner.y),
	]
	for strip: Rect2 in strips:
		var plane := PlaneMesh.new()
		plane.size = strip.size
		var instance := MeshInstance3D.new()
		instance.mesh = plane
		instance.material_override = water.material_override
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.layers = 1
		instance.position = Vector3(strip.get_center().x, y, strip.get_center().y)
		_sea.add_child(instance)


## Haze for kilometres, colour adjustment and glow, over a copy of the level's environment.
func _apply_environment() -> void:
	environment.fog_enabled = stats.haze_density > 0.0
	environment.fog_density = stats.haze_density
	environment.adjustment_enabled = true
	environment.adjustment_contrast = stats.contrast
	environment.adjustment_saturation = stats.saturation
	environment.adjustment_brightness = stats.brightness
	environment.glow_enabled = stats.glow
