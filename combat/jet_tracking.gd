class_name JetTracking
extends RefCounted
## The commando's first-person tracking (`docs/mechanics/commando.md`): which enemies are tracked, for the seeker
## shotgun to home on. The scanner is a pyramid along the view (`scanner_half_width_deg` by `scanner_half_height_deg`):
## an enemy that stays in it, within `scanner_range` and in sight, for `scanner_pickup_time` is tracked for `track_time`
## (up to `max_tracks`); being in it refreshes the track. While the afterburner burns, scouting tracks every enemy in
## sight within `scout_range` at once, for `scout_track_time`. Only enemies the commando knows of (awareness,
## `vision.md`) are picked up. Tracks are held by unit id. Held by `PilotFlight`,
## stepped every tick. Simulation.

## The World and Building layers: what hides an enemy.
const SIGHT_MASK: int = (1 << 0) | (1 << 2)
## A sight line stops this far short of the enemy, so the ground under it doesn't hide it, metres.
const SIGHT_SLACK: float = 0.5

var stats: TrackingStats

var _unit: Unit
## Tracked unit id to the seconds its track has left, in pickup order (a refresh keeps the place).
var _tracks: Dictionary = {}
## Unit id in the scanner but not tracked yet, to the seconds it has been in it.
var _dwell: Dictionary = {}
var _near: Array[Unit] = []


func _init(unit: Unit, tracking_stats: TrackingStats) -> void:
	_unit = unit
	stats = tracking_stats


## The living tracked units in the order they were picked up, oldest first.
func targets() -> Array[Unit]:
	var found: Array[Unit] = []
	for id: int in _tracks:
		var other: Unit = _unit.registry.get_unit(id)
		if other != null:
			found.append(other)
	return found


## Seconds left on the track of unit `id` (0 if it isn't tracked).
func time_left(id: int) -> float:
	return _tracks.get(id, 0.0)


## Whether a world point lies in the scanner of a view at `eye` looking along `view` (-z of the basis).
static func in_scanner(view: Basis, eye: Vector3, point: Vector3, tracking_stats: TrackingStats) -> bool:
	var local: Vector3 = view.inverse() * (point - eye)
	if local.z >= -0.01:
		return false
	return absf(local.x / -local.z) <= tan(deg_to_rad(tracking_stats.scanner_half_width_deg)) \
		and absf(local.y / -local.z) <= tan(deg_to_rad(tracking_stats.scanner_half_height_deg))


## Nothing of the ground or buildings between `from` and `to` (stopping just short of `to`).
static func clear_between(unit: Unit, from: Vector3, to: Vector3) -> bool:
	var length: float = from.distance_to(to)
	if length <= SIGHT_SLACK:
		return true
	var query := PhysicsRayQueryParameters3D.create(from, from.lerp(to, 1.0 - SIGHT_SLACK / length), SIGHT_MASK,
		[unit.get_rid()])
	return unit.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func step(delta: float, eye: Vector3, view: Basis, scouting: bool) -> void:
	_count_down(delta)
	var reach: float = maxf(stats.scanner_range, stats.scout_range if scouting else 0.0)
	_unit.registry.units_near(eye, reach, _near)
	var in_view: Dictionary = {}
	for other: Unit in _near:
		if not other.alive or not other.is_enemy_of(_unit.team):
			continue
		var center: Vector3 = other.center()
		var distance: float = eye.distance_to(center)
		var scanned: bool = distance <= stats.scanner_range and in_scanner(view, eye, center, stats)
		var scouted: bool = scouting and distance <= stats.scout_range
		if not (scanned or scouted) or (not _tracks.has(other.id) and not _unit.knows(other)) \
				or not clear_between(_unit, eye, center):
			continue
		if scouted:
			_tracks[other.id] = maxf(_tracks.get(other.id, 0.0), stats.scout_track_time)
		if not scanned:
			continue
		if _tracks.has(other.id):
			_tracks[other.id] = maxf(_tracks[other.id], stats.track_time)
			continue
		in_view[other.id] = true
		_dwell[other.id] = _dwell.get(other.id, 0.0) + delta
		if _dwell[other.id] >= stats.scanner_pickup_time and _tracks.size() < stats.max_tracks:
			_tracks[other.id] = stats.track_time
	# Leaving the scanner (or being tracked) starts the pickup over.
	for id: int in _dwell.keys():
		if not in_view.has(id):
			_dwell.erase(id)


func clear() -> void:
	_tracks.clear()
	_dwell.clear()


## Runs the tracks' time down and drops those that ran out or whose unit is gone.
func _count_down(delta: float) -> void:
	for id: int in _tracks.keys():
		var left: float = _tracks[id] - delta
		if left <= 0.0 or _unit.registry.get_unit(id) == null:
			_tracks.erase(id)
		else:
			_tracks[id] = left
