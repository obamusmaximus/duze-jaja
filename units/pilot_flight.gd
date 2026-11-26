class_name PilotFlight
extends RefCounted
## An inhabited flyer in flight: runs the unit's control type every tick from the pilot's controls (the jet's
## `FlightModel` or the `HoverModel`), puts the result on the unit, keeps it on the map and handles what it hits. A
## type with both starts in the hover and can switch. Takes over from the autopilot's state and hands the same state
## back, so neither end of a flight jumps. A jetpack type (the commando) runs its `JetpackModel` instead, on foot or
## in the air, with the seeker shotgun and tracking in place of the pilot's weapon. Made by `UnitMovement`.
## Simulation.

const DEFAULT_STATS: FlightStats = preload("res://tuning/flight_default.tres")
## A hover that finds the ground under it rising by more than this in one tick has met a face, not a slope, metres.
const CLIFF_STEP: float = 2.5
## A hover below its least height (taken over on a landing) rises back to it at this rate, metres per second.
const FLOOR_LIFT: float = 12.0
## The Building layer: what a jetpack body can't pass (it walks over the ground and props by their height).
const BUILDING_MASK: int = 1 << 2
## The unit node turns (yaw only) after the nose at most this fast, radians per second; the airframe takes the rest.
## Near the vertical the nose's heading swings wildly, and the node and airframe are smoothed separately on screen.
const NODE_YAW_RATE: float = TAU

## The control type flying it now: `jet` or `hover`.
var model: PilotModel
var jet: FlightModel
var hover: HoverModel
## A jetpack type's first-person kit, its tracking and its seeker shotgun; null on flyers.
var jetpack: JetpackModel
var tracking: JetTracking
var shotgun: SeekerShotgun
## What the jet was last asked to do.
var controls := FlightControls.new()
## The unit's weapon in the pilot's hand (null for a jetpack type, which has the `shotgun`).
var weapon: PilotWeapon

var _unit: Unit
var _input: PilotInput
var _crash: FlightCrash


func _init(unit: Unit, input: PilotInput, start_velocity: Vector3, facing: Basis) -> void:
	_unit = unit
	_input = input
	var stats: UnitStats = unit.stats
	_crash = FlightCrash.new(unit)
	if stats.jetpack != null:
		jetpack = JetpackModel.new(stats.jetpack)
		model = jetpack
		jetpack.start(unit.center(), start_velocity, facing)
		tracking = JetTracking.new(unit, stats.jetpack.tracking)
		shotgun = SeekerShotgun.new(unit, stats.jetpack.shotgun, tracking)
		return
	weapon = PilotWeapon.new(unit)
	if stats.hover_flight != null:
		hover = HoverModel.new(stats.hover_flight)
	if stats.flight_model != null or hover == null:
		jet = FlightModel.new(stats.flight_model if stats.flight_model != null else DEFAULT_STATS)
	model = hover if hover != null else jet
	_start_model(unit.center(), start_velocity, facing)
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


## A jetpack type on foot or in its kit (no crashes; it walks and lands).
func is_jetpack() -> bool:
	return jetpack != null


## The pilot's eyes in the world (a jetpack type's view and weapons start here).
func eye() -> Vector3:
	return model.position + model.basis * (_unit.stats.cockpit_offset - Vector3.UP * _unit.stats.height * 0.5)


func step(delta: float) -> void:
	if jetpack != null:
		_step_jetpack(delta)
		return
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
	if _unit.alive:
		weapon.step(_input, model)


func _step_jetpack(delta: float) -> void:
	var from: Vector3 = jetpack.position
	jetpack.step(delta, _input)
	_stay_on_map()
	_jetpack_contact(from)
	_unit.rotation.y = jetpack.basis.get_euler(EULER_ORDER_YXZ).y
	var at: Vector3 = jetpack.position - Vector3.UP * _unit.stats.height * 0.5
	_unit.global_position = at
	_unit.set_hover(maxf(at.y - _unit.registry.map.air.ground_height(at), 0.0))
	var view: Basis = jetpack.view_basis()
	tracking.step(delta, eye(), view, jetpack.afterburning())
	shotgun.step(delta, _input, eye(), view, not jetpack.afterburning())


## Buildings stop the body (it slides along them); the ground and sea under it are its floor: it lands on them, and
## a grounded body follows ground that drops away gently instead of taking off.
func _jetpack_contact(from: Vector3) -> void:
	if _building_between(from, jetpack.position):
		var to: Vector3 = jetpack.position
		if not _building_between(from, Vector3(from.x, to.y, from.z)):
			jetpack.position = Vector3(from.x, to.y, from.z)
			jetpack.velocity.x = 0.0
			jetpack.velocity.z = 0.0
		elif not _building_between(from, Vector3(to.x, from.y, to.z)):
			jetpack.position = Vector3(to.x, from.y, to.z)
			jetpack.velocity.y = 0.0
		else:
			jetpack.position = from
			jetpack.velocity = Vector3.ZERO
	var floor_height: float = _unit.registry.map.air.ground_height(jetpack.position) + _unit.stats.height * 0.5
	var above: float = jetpack.position.y - floor_height
	if above <= 0.0:
		jetpack.position.y = floor_height
		jetpack.land()
	elif jetpack.grounded and jetpack.velocity.y <= 0.0 and above <= jetpack.stats.ground_snap:
		jetpack.position.y = floor_height
	elif jetpack.grounded:
		jetpack.leave_ground()


func _building_between(from: Vector3, to: Vector3) -> bool:
	if from.is_equal_approx(to):
		return false
	var query := PhysicsRayQueryParameters3D.create(from, to, BUILDING_MASK, [_unit.get_rid()])
	return not _unit.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


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
