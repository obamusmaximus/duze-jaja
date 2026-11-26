class_name PilotFlight
extends RefCounted
## An inhabited flyer in flight: runs the unit's control type every tick from the pilot's controls (the jet's
## `FlightModel` or the `HoverModel`), puts the result on the unit, keeps it on the map and handles what it hits. A
## type with both starts in the hover and can switch. Takes over from the autopilot's state and hands the same state
## back, so neither end of a flight jumps. Made by `UnitMovement`. Simulation.

const DEFAULT_STATS: FlightStats = preload("res://tuning/flight_default.tres")
## A hover that finds the ground under it rising by more than this in one tick has met a face, not a slope, metres.
const CLIFF_STEP: float = 2.5
## A hover below its least height (taken over on a landing) rises back to it at this rate, metres per second.
const FLOOR_LIFT: float = 12.0
## The unit node turns (yaw only) after the nose at most this fast, radians per second; the airframe takes the rest.
## Near the vertical the nose's heading swings wildly, and the node and airframe are smoothed separately on screen.
const NODE_YAW_RATE: float = TAU

## The control type flying it now: `jet` or `hover`.
var model: PilotModel
var jet: FlightModel
var hover: HoverModel
## What the jet was last asked to do.
var controls := FlightControls.new()

var _unit: Unit
var _input: PilotInput
var _crash: FlightCrash
## The ability key as of the last tick: a use is a press, not the key held.
var _ability_held: bool = false


func _init(unit: Unit, input: PilotInput, autopilot: FlightAutopilot) -> void:
	_unit = unit
	_input = input
	var stats: UnitStats = unit.stats
	if stats.hover_flight != null:
		hover = HoverModel.new(stats.hover_flight)
	if stats.flight_model != null or hover == null:
		jet = FlightModel.new(stats.flight_model if stats.flight_model != null else DEFAULT_STATS)
	model = hover if hover != null else jet
	_start_model(unit.center(), autopilot.velocity, autopilot.orientation())
	_crash = FlightCrash.new(unit)
	_set_reach()
	_crash.start()


func hovering() -> bool:
	return model == hover


## Whether the type has both control types.
func can_switch() -> bool:
	return jet != null and hover != null


## From the hover to the jet or back, carrying on from the same position, velocity and attitude. A slow jet is held
## up by its engine until it has the speed to fly (`FlightModel.transition`).
func switch_mode() -> void:
	if not can_switch():
		return
	var before: PilotModel = model
	model = jet if hovering() else hover
	_start_model(before.position, before.velocity, before.basis)
	controls = FlightControls.new()
	_set_reach()


func step(delta: float) -> void:
	# A targeted ability needs a click on the map; the cockpit has no way to aim one yet.
	if _input.ability and not _ability_held and _unit.ability != null \
			and _unit.ability.stats.targeting() == AbilityStats.Targeting.NONE:
		_unit.ability.use()
	_ability_held = _input.ability
	var from: Vector3 = model.position
	if hovering():
		hover.step(delta, _input)
		_stay_on_map()
		_hover_contact(delta, from)
	else:
		jet.thrust_boost = _unit.thrust_boost
		FlightSteering.fly(jet, _input, controls)
		jet.step(delta, controls)
		_stay_on_map()
	if not _unit.alive:
		return
	_place(delta)
	if not hovering():
		var cause: FlightCrash.Cause = _crash.check(jet.stats, from, jet.position, jet.basis)
		if cause != FlightCrash.Cause.NONE:
			_crash_into(cause, _crash.other)


func _start_model(at: Vector3, velocity: Vector3, facing: Basis) -> void:
	if hovering():
		hover.start(at, velocity, facing)
	else:
		jet.start(at, velocity, facing)


func _set_reach() -> void:
	if hovering():
		_crash.set_reach(hover.stats.crash_body_reach, hover.stats.crash_flyer_reach)
	else:
		_crash.set_reach(jet.stats.crash_body_reach, jet.stats.crash_flyer_reach)


func _crash_into(cause: FlightCrash.Cause, hit: Unit) -> void:
	_unit.crash(cause)
	if hit != null:
		hit.crash(cause)


## A hover meets things: slower than its crash speed it is only stopped, faster it is destroyed.
func _hover_contact(delta: float, from: Vector3) -> void:
	var limit: float = hover.stats.crash_speed
	# Ground and sea: it can't go below its least height over the highest spot under it.
	var floor_height: float = _floor_at(hover.position)
	if hover.position.y < floor_height:
		var flat_speed: float = Vector2(hover.velocity.x, hover.velocity.z).length()
		var face: bool = floor_height - _floor_at(from) > CLIFF_STEP
		if -hover.velocity.y > limit or (face and flat_speed > limit):
			_crash_into(FlightCrash.Cause.GROUND, null)
			return
		if face:
			hover.position.x = from.x
			hover.position.z = from.z
			hover.velocity.x = 0.0
			hover.velocity.z = 0.0
			floor_height = _floor_at(hover.position)
		if hover.position.y < floor_height:
			hover.position.y = minf(floor_height, maxf(hover.position.y, from.y) + FLOOR_LIFT * delta)
			hover.velocity.y = maxf(hover.velocity.y, 0.0)
	# Buildings, props and walls: slide along them (up or over the ground) or stop.
	if _crash.hits_solid(from, hover.position):
		if hover.velocity.length() > limit:
			_crash_into(FlightCrash.Cause.STRUCTURE, null)
			return
		_slide(from)
	var other: Unit = _crash.new_flyer()
	if other != null:
		var theirs: Vector3 = other.movement.autopilot.velocity if other.movement.autopilot != null else Vector3.ZERO
		if (hover.velocity - theirs).length() > limit:
			_crash_into(FlightCrash.Cause.FLYER, other)
		else:
			_crash.ignore_flyer(other)


func _slide(from: Vector3) -> void:
	var to: Vector3 = hover.position
	if not _crash.hits_solid(from, Vector3(from.x, to.y, from.z)):
		hover.position = Vector3(from.x, to.y, from.z)
		hover.velocity.x = 0.0
		hover.velocity.z = 0.0
	elif not _crash.hits_solid(from, Vector3(to.x, from.y, to.z)):
		hover.position = Vector3(to.x, from.y, to.z)
		hover.velocity.y = 0.0
	else:
		hover.position = from
		hover.velocity = Vector3.ZERO


## The lowest the airframe's middle may be at `at`: its underside clear of the ground and sea across its footprint.
func _floor_at(at: Vector3) -> float:
	var air: AirLayer = _unit.registry.map.air
	var out: float = _unit.stats.radius * 0.6
	var ground: float = air.ground_height(at)
	for offset: Vector3 in [Vector3(out, 0.0, 0.0), Vector3(-out, 0.0, 0.0), Vector3(0.0, 0.0, out),
			Vector3(0.0, 0.0, -out)]:
		ground = maxf(ground, air.ground_height(at + offset))
	return ground + _unit.stats.height * 0.5 + hover.stats.ground_gap


## The map's edge stops it, as it does the autopilot's flyers.
func _stay_on_map() -> void:
	var inside: Vector3 = _unit.registry.map.air.clamp_point(model.position)
	if inside.x != model.position.x:
		model.velocity.x = 0.0
	if inside.z != model.position.z:
		model.velocity.z = 0.0
	model.position = inside


func _place(delta: float) -> void:
	var heading: float = model.basis.get_euler(EULER_ORDER_YXZ).y
	_unit.rotation.y = rotate_toward(_unit.rotation.y, heading, NODE_YAW_RATE * delta)
	var at: Vector3 = model.position - Vector3.UP * _unit.stats.height * 0.5
	_unit.global_position = at
	_unit.set_airframe(Basis(Vector3.UP, -_unit.rotation.y) * model.basis)
	_unit.set_hover(at.y - _unit.registry.map.air.ground_height(at))
