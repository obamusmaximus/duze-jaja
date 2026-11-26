class_name Vision
extends Node
## Detection (`docs/mechanics/vision.md`): which enemy units each team knows of. An observer detects a target when the
## flat distance is within the observer's sensor range times the target's signature (plus a bonus for height) and the
## terrain doesn't block the line between them. Observers are units and the added `VisionSensor`s. Every unit is
## checked against its enemies every `check_interval`, spread over the ticks, trying whoever saw it last first.
## Light plays no part. Simulation: add it to the tree, then call `setup`. Group: `vision`.

## `team` now knows of the enemy unit.
signal contact_gained(team: int, unit_id: int)
## `team` no longer knows of it: lost, or gone from the match while watched.
signal contact_lost(team: int, unit_id: int)
## `team`'s last-known records changed this tick (made, expired, cleared by sight or by finding the unit again).
signal memory_changed(team: int)

## Side of an observer bucket, metres: sensor searches are wide.
const OBSERVER_CELL: float = 96.0

var stats: VisionStats
## Seconds of simulation since `setup`.
var time: float = 0.0
## Total microseconds spent detecting (the benchmark reads it).
var step_usec: int = 0

var _registry: UnitRegistry
var _terrain: TerrainHeights
var _sensors: Array[VisionSensor] = []
## Team to TeamVision.
var _teams: Dictionary = {}
## Team to UnitSpatialHash of its units, and to the longest sensor range among them; rebuilt every tick.
var _observers: Dictionary = {}
var _longest: Dictionary = {}
## Team to Array[Unit] of its deployed Explorers (open base areas); rebuilt every tick.
var _bases: Dictionary = {}
var _awareness: Awareness
var _tick: int = 0
var _units: Array[Unit] = []
var _near: Array[Unit] = []


func setup(registry: UnitRegistry, terrain: TerrainHeights, vision_stats: VisionStats) -> void:
	_registry = registry
	_terrain = terrain
	stats = vision_stats
	add_to_group(&"vision")
	process_physics_priority = -90 # After the unit loop has moved everything.
	registry.unit_removed.connect(_on_unit_removed)
	_awareness = Awareness.new(self, registry)


func add_sensor(sensor: VisionSensor) -> void:
	_sensors.append(sensor)
	of_team(sensor.team)


## The picture of `team` (made on first use).
func of_team(team: int) -> TeamVision:
	var picture: TeamVision = _teams.get(team)
	if picture == null:
		picture = TeamVision.new(team)
		_teams[team] = picture
	return picture


func sensors() -> Array[VisionSensor]:
	return _sensors


## A unit's sensor range against signature 1: its type's, or a deployed Explorer's base range.
func reach_of(observer: Unit) -> float:
	if observer.explorer != null and observer.explorer.is_base():
		return observer.explorer.stats.base_sensor_range
	return observer.stats.sensor_range


## How far a sensor of range `reach` at height `eye_y` detects a target of `signature` whose top is at `target_y`.
func detect_range(reach: float, signature: float, eye_y: float, target_y: float) -> float:
	var above: float = clampf((eye_y - target_y) / stats.height_full, 0.0, 1.0)
	return minf(reach * signature * (1.0 + stats.height_bonus * above), stats.max_detect_range)


## Where a unit looks from, and is looked at: the top of its body.
func eye_of(unit: Unit) -> Vector3:
	return unit.global_position + Vector3.UP * (unit.stats.height + stats.eye_lift)


## Whether `observer` itself detects `target` right now (no memory, no sharing).
func detects(observer: Unit, target: Unit) -> bool:
	return _sees(reach_of(observer), eye_of(observer), target)


## Awareness: whether `unit` knows of the enemy `target` (its own detection, its squad's, its base's; `Awareness`).
func unit_knows(unit: Unit, target: Unit) -> bool:
	return _awareness.knows(unit, target)


## The same question for a view: answers it without recording who saw the enemy, so it changes nothing.
func unit_has(unit: Unit, target: Unit) -> bool:
	return _awareness.knows(unit, target, false)


## The deployed Explorers of `team` (as of this tick).
func bases_of(team: int) -> Array[Unit]:
	var none: Array[Unit] = []
	return _bases.get(team, none)


## The units of `team` that might detect `target`, by place (as of this tick), into `out`.
func observers_near(team: int, target: Unit, out: Array[Unit]) -> void:
	observers_around(team, target.global_position, target.stats.signature, out)


## The units of `team` that might detect a target of `signature` at `at` (as of this tick), into `out`.
func observers_around(team: int, at: Vector3, signature: float, out: Array[Unit]) -> void:
	out.clear()
	var widest: float = minf(float(_longest.get(team, 0.0)) * signature * (1.0 + stats.height_bonus),
			stats.max_detect_range)
	if widest > 0.0 and _observers.has(team):
		(_observers[team] as UnitSpatialHash).query(at, widest, out)


func _physics_process(delta: float) -> void:
	if _registry == null:
		return
	var started: int = Time.get_ticks_usec()
	time += delta
	_tick += 1
	_rebuild_observers()
	var every: int = maxi(roundi(stats.check_interval / delta), 1)
	for unit: Unit in _units:
		if unit.alive and unit.id % every == _tick % every:
			_check(unit)
	for team: int in _teams:
		var picture: TeamVision = _teams[team]
		_advance(picture, delta)
		_review_memory(picture, every)
		if picture.memory_dirty:
			picture.memory_dirty = false
			memory_changed.emit(team)
	step_usec += Time.get_ticks_usec() - started


func _rebuild_observers() -> void:
	_units = _registry.all_units()
	var by_team: Dictionary = {}
	_longest.clear()
	_bases.clear()
	for unit: Unit in _units:
		if not unit.alive:
			continue
		if unit.explorer != null and unit.explorer.is_base():
			if not _bases.has(unit.team):
				var bases: Array[Unit] = []
				_bases[unit.team] = bases
			(_bases[unit.team] as Array[Unit]).append(unit)
		if not by_team.has(unit.team):
			var list: Array[Unit] = []
			by_team[unit.team] = list
			of_team(unit.team)
		(by_team[unit.team] as Array[Unit]).append(unit)
		_longest[unit.team] = maxf(_longest.get(unit.team, 0.0), reach_of(unit))
	for team: int in _teams:
		if not _observers.has(team):
			_observers[team] = UnitSpatialHash.new(OBSERVER_CELL)
		var empty: Array[Unit] = []
		(_observers[team] as UnitSpatialHash).rebuild(by_team.get(team, empty))


## Updates `seen` for `target` in every other team's picture.
func _check(target: Unit) -> void:
	for team: int in _teams:
		if team == target.team:
			continue
		var picture: TeamVision = _teams[team]
		var contact: VisionContact = picture.contacts.get(target.id)
		if contact != null and _still_sees(contact, target):
			_saw(contact, target)
			continue
		var observer: Unit = null
		var sensor: VisionSensor = _sensor_seeing(team, target)
		if sensor == null:
			observer = _unit_seeing(team, target)
		if sensor == null and observer == null:
			if contact != null:
				contact.seen = false
			continue
		if contact == null:
			contact = VisionContact.new()
			contact.type = target.stats
			contact.team = target.team
			picture.contacts[target.id] = contact
		_saw(contact, target)
		contact.sensor = sensor
		contact.observer_id = observer.id if observer != null else 0


func _saw(contact: VisionContact, target: Unit) -> void:
	contact.seen = true
	contact.position = target.global_position
	contact.yaw = target.global_rotation.y


func _still_sees(contact: VisionContact, target: Unit) -> bool:
	if contact.sensor != null:
		return _sees(contact.sensor.reach(), contact.sensor.eye(), target)
	var observer: Unit = _registry.get_unit(contact.observer_id) if contact.observer_id != 0 else null
	return observer != null and detects(observer, target)


func _sensor_seeing(team: int, target: Unit) -> VisionSensor:
	for sensor: VisionSensor in _sensors:
		if sensor.team == team and _sees(sensor.reach(), sensor.eye(), target):
			return sensor
	return null


func _unit_seeing(team: int, target: Unit) -> Unit:
	observers_near(team, target, _near)
	for observer: Unit in _near:
		if detects(observer, target):
			return observer
	return null


func _sees(reach: float, eye: Vector3, target: Unit) -> bool:
	return sees_point(reach, eye, eye_of(target), target.stats.signature)


## Whether a sensor of range `reach` at `eye` detects a target of `signature` whose look-at point is `at` (range,
## height bonus and line of sight; no unit needed). The coverage grid asks it for bare ground.
func sees_point(reach: float, eye: Vector3, at: Vector3, signature: float) -> bool:
	var limit: float = detect_range(reach, signature, eye.y, at.y)
	var dx: float = at.x - eye.x
	var dz: float = at.z - eye.z
	if dx * dx + dz * dz > limit * limit:
		return false
	return LineOfSight.clear(_terrain, eye, at, stats.sight_step)


## Moves every contact's level toward seen or lost.
func _advance(picture: TeamVision, delta: float) -> void:
	var dropped: Array[int] = []
	for id: int in picture.contacts:
		var contact: VisionContact = picture.contacts[id]
		if contact.seen:
			contact.level = minf(contact.level + delta / stats.gain_time, 1.0)
			if contact.level >= 1.0 and not contact.known:
				contact.known = true
				if picture.memory.erase(id):
					picture.memory_dirty = true
				contact_gained.emit(picture.team, id)
		else:
			contact.level -= delta / stats.lose_time
			if contact.level <= 0.0:
				dropped.append(id)
	for id: int in dropped:
		var contact: VisionContact = picture.contacts[id]
		picture.contacts.erase(id)
		if contact.known:
			picture.memory[id] = LastKnown.new(id, contact, time)
			picture.memory_dirty = true
			contact_lost.emit(picture.team, id)


## Ends the team's records that are too old, and those whose spot the team watches again (after it went unwatched)
## with the unit not there. Each record is looked at once a `check_interval` (spread by id, like the checks), at the
## unit's own signature: had it stayed, it would have been seen.
func _review_memory(picture: TeamVision, every: int) -> void:
	var ended: Array[int] = []
	for id: int in picture.memory:
		var record: LastKnown = picture.memory[id]
		if time - record.time >= (stats.ghost_time if record.ghost else stats.memory_time):
			ended.append(id)
		elif id % every == _tick % every and not picture.contacts.has(id):
			if not _spot_watched(picture.team, record):
				record.hidden = true
			elif record.hidden:
				ended.append(id)
	for id: int in ended:
		picture.memory.erase(id)
	if not ended.is_empty():
		picture.memory_dirty = true


## Whether a sensor or unit of `team` would detect the record's unit if it were still at its last-known spot.
func _spot_watched(team: int, record: LastKnown) -> bool:
	var height: float = record.type.height if record.type != null else 0.0
	var signature: float = record.type.signature if record.type != null else 1.0
	var at: Vector3 = record.position + Vector3.UP * (height + stats.eye_lift)
	for sensor: VisionSensor in _sensors:
		if sensor.team == team and sees_point(sensor.reach(), sensor.eye(), at, signature):
			return true
	observers_around(team, record.position, signature, _near)
	for observer: Unit in _near:
		if sees_point(reach_of(observer), eye_of(observer), at, signature):
			return true
	return false


## A unit died or was loaded into a hold. A team that was watching knows it is gone; one that had lost sight of it
## keeps its last-known record.
func _on_unit_removed(unit: Unit) -> void:
	for team: int in _teams:
		var picture: TeamVision = _teams[team]
		var contact: VisionContact = picture.contacts.get(unit.id)
		if contact == null:
			continue
		picture.contacts.erase(unit.id)
		if not contact.known:
			continue
		if not contact.seen:
			picture.memory[unit.id] = LastKnown.new(unit.id, contact, time)
			picture.memory_dirty = true
		contact_lost.emit(team, unit.id)
