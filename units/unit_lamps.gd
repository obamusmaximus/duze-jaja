class_name UnitLamps
extends RefCounted
## Visual only: which lamps a unit carries (`docs/mechanics/lamps.md`). Aircraft: red on the port wingtip, green on
## the starboard one, white on the tail and a white double strobe on top. Ground units: one small white marker on the
## back. The Explorer's are its own (`ExplorerLook`). The places come from the model's vertices, read once per shape.

## Not a `const`: GDScript folds a const resource's properties at compile time, and live edits would not show.
## Read from outside through `lamp_stats()`: a direct read of another script's `static var` breaks the engine's cleanup at exit.
static var _lamp_stats: LampStats = preload("res://tuning/lamp_default.tres")
## How much of a hull's size counts as one tip (see `HullPoints.tip`).
const TIP_SLACK: float = 0.04

## Shape key to its lamp places in the airframe's space: port, starboard, tail, top, back.
static var _places: Dictionary = {}


static func lamp_stats() -> LampStats:
	return _lamp_stats



## Fills `lamps` (a child of the airframe) for a unit of `stats` showing `model` (null for the placeholder).
static func fill(lamps: LampSet, stats: UnitStats, frame: Node3D, model: Node3D, unit_id: int) -> void:
	lamps.clear()
	var places: PackedVector3Array = _places_of(stats, frame, model)
	if places.is_empty():
		return
	if not stats.flying:
		lamps.add(places[4], UiTokens.WORLD_LAMP_WHITE, _lamp_stats.marker_size, _lamp_stats.marker_min_px, _lamp_stats.marker_strength)
		return
	lamps.add(places[0], UiTokens.WORLD_LAMP_PORT, _lamp_stats.nav_size, _lamp_stats.nav_min_px)
	lamps.add(places[1], UiTokens.WORLD_LAMP_STARBOARD, _lamp_stats.nav_size, _lamp_stats.nav_min_px)
	lamps.add(places[2], UiTokens.WORLD_LAMP_WHITE, _lamp_stats.tail_size, _lamp_stats.tail_min_px)
	# Each aircraft's strobe keeps its own time.
	lamps.add(places[3], UiTokens.WORLD_LAMP_WHITE, _lamp_stats.strobe_size, _lamp_stats.strobe_min_px, 1.0,
		LampSet.Pattern.STROBE, _lamp_stats.strobe_period, fposmod(unit_id * 0.618, 1.0))


static func _places_of(stats: UnitStats, frame: Node3D, model: Node3D) -> PackedVector3Array:
	if not frame.is_inside_tree():
		return PackedVector3Array()
	var key: Array = [stats.model, stats.model_scale, stats.model_yaw_deg, stats.radius, stats.height, stats.flying]
	if _places.has(key):
		return _places[key]
	var half := Vector3(stats.radius, stats.height * 0.5, stats.radius)
	var hull := HullPoints.new(frame, model, half)
	var slack: float = maxf(stats.radius, 0.3) * TIP_SLACK
	var port: Vector3 = hull.tip(Vector3.LEFT, slack)
	var starboard: Vector3 = hull.tip(Vector3.RIGHT, slack)
	var tail: Vector3 = hull.tip(Vector3.BACK, slack)
	tail.x = 0.0
	var top: Vector3 = hull.tip(Vector3.UP, slack)
	top.x = 0.0
	var back: Vector3 = hull.support(Vector3(0.0, 0.6, 1.0))
	back.x = 0.0
	var out := PackedVector3Array([port, starboard, tail, top, back])
	_places[key] = out
	return out
