class_name FlightCrash
extends RefCounted
## What a flyer under the flight model can hit: the ground and sea (a height sample under its lowest point and under
## its nose), buildings, props and walls (a ball cast along the tick's movement) and other flyers. Whatever it already
## touched when the flight began (the autopilot flies through buildings, and flyers overlap softly) doesn't count
## until it has been clear of it once. `check` is the jet's all-or-nothing rule; a hover uses the parts (`PilotFlight`).
## Simulation.

enum Cause { NONE, GROUND, STRUCTURE, FLYER }

## The World and Building layers.
const SOLID_MASK: int = (1 << 0) | (1 << 2)
## Other flyers are looked for this far beyond the unit's own radius, metres: covers the biggest of them.
const FLYER_SEARCH: float = 12.0

## The other flyer, after a FLYER crash.
var other: Unit

var _unit: Unit
var _body_reach: float = 0.5
var _flyer_reach: float = 0.7
var _sphere := SphereShape3D.new()
var _query := PhysicsShapeQueryParameters3D.new()
var _near: Array[Unit] = []
## Ids of flyers and RIDs of solids touched since the flight began and not yet left.
var _ignored_flyers: Dictionary = {}
var _ignored_solids: Array[RID] = []


func _init(unit: Unit) -> void:
	_unit = unit
	_query.shape = _sphere
	_query.collision_mask = SOLID_MASK


## How much of the unit's radius reaches buildings and other flyers (each control type has its own).
func set_reach(body_reach: float, flyer_reach: float) -> void:
	_body_reach = body_reach
	_flyer_reach = flyer_reach


## Remembers what the unit overlaps now. Call after `set_reach`.
func start() -> void:
	_ignored_flyers.clear()
	_ignored_solids.clear()
	for flyer: Unit in _touching_flyers():
		_ignored_flyers[flyer.id] = true
	for hit: Dictionary in _solids_at(_unit.center()):
		_ignored_solids.append(hit["rid"])


## What a jet hit moving from `from` to `to` (its middle) with the orientation `basis`.
func check(stats: FlightStats, from: Vector3, to: Vector3, basis: Basis) -> Cause:
	other = null
	if _hits_ground(stats, to, basis):
		return Cause.GROUND
	if hits_solid(from, to):
		return Cause.STRUCTURE
	other = new_flyer()
	return Cause.FLYER if other != null else Cause.NONE


## A flyer touched now that wasn't being ignored, or null.
func new_flyer() -> Unit:
	var found: Unit = null
	var still: Dictionary = {}
	for flyer: Unit in _touching_flyers():
		if _ignored_flyers.has(flyer.id):
			still[flyer.id] = true
		elif found == null:
			found = flyer
	_ignored_flyers = still
	return found


## Leaves `flyer` out until the unit has been clear of it (a slow touch, in a hover).
func ignore_flyer(flyer: Unit) -> void:
	_ignored_flyers[flyer.id] = true


## The airframe as a flattened ball (radius by half height): how far it reaches below its middle at this attitude.
func lowest_reach(basis: Basis) -> float:
	var radius: float = _unit.stats.radius
	var half: float = _unit.stats.height * 0.5
	return Vector3(basis.x.y * radius, basis.y.y * half, basis.z.y * radius).length()


func _hits_ground(stats: FlightStats, at: Vector3, basis: Basis) -> bool:
	var air: AirLayer = _unit.registry.map.air
	if at.y - lowest_reach(basis) * stats.crash_ground_reach <= air.ground_height(at):
		return true
	var nose: Vector3 = at - basis.z * _unit.stats.radius * stats.crash_ground_reach
	return nose.y <= air.ground_height(nose)


## Whether moving from `from` to `to` runs into a building, prop or wall.
func hits_solid(from: Vector3, to: Vector3) -> bool:
	# Solids ignored since the start count again once the unit is clear of them.
	if not _ignored_solids.is_empty():
		var inside: Array[RID] = []
		var skip: Array[RID] = _ignored_solids
		_ignored_solids = []
		for hit: Dictionary in _solids_at(to):
			if skip.has(hit["rid"]):
				inside.append(hit["rid"])
		_ignored_solids = inside
	var space: PhysicsDirectSpaceState3D = _unit.get_world_3d().direct_space_state
	_aim_query(from)
	_query.motion = to - from
	if space.cast_motion(_query)[0] < 1.0:
		return true
	_query.motion = Vector3.ZERO
	return not _solids_at(to).is_empty()


func _solids_at(at: Vector3) -> Array[Dictionary]:
	_aim_query(at)
	_query.motion = Vector3.ZERO
	return _unit.get_world_3d().direct_space_state.intersect_shape(_query, 8)


func _aim_query(at: Vector3) -> void:
	_sphere.radius = _unit.stats.radius * _body_reach
	_query.transform = Transform3D(Basis.IDENTITY, at)
	_query.exclude = _ignored_solids


func _touching_flyers() -> Array[Unit]:
	var touching: Array[Unit] = []
	var centre: Vector3 = _unit.center()
	_unit.registry.units_near(centre, _unit.stats.radius + FLYER_SEARCH, _near)
	for flyer: Unit in _near:
		if flyer == _unit or not flyer.alive or not flyer.is_flying():
			continue
		var gap: Vector3 = flyer.center() - centre
		var reach: float = (_unit.stats.radius + flyer.stats.radius) * _flyer_reach
		if Vector2(gap.x, gap.z).length() < reach and absf(gap.y) < (_unit.stats.height + flyer.stats.height) * 0.5:
			touching.append(flyer)
	return touching
