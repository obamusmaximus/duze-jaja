class_name FlightAutopilot
extends RefCounted
## The cheap, always-safe flight model of RTS and AI flyers (`docs/mechanics/units.md`, "Flyers"): kinematic flight
## on the air layer, with a speed band, a turn rate and an altitude over the ground. It keeps a real `velocity` and
## orientation, so another flight model can take over from it and hand back without a jump.
## - Hover types (`UnitStats.FlightStyle.HOVER`) turn toward where they want to go, speed up and slow down, and stop
##   and hover.
## - Fixed-wing types only fly where the nose points, never slower than `flight_min_speed`, so they turn in arcs. With
##   nothing to do they orbit a point (anticlockwise seen from above, all of them, so they never meet head on).
## `UnitMovement` feeds it a decision (`command`) at the unit's rate and moves it every tick (`step`). Simulation.

const GRAVITY: float = 9.8
## How far inside its tightest turn circle a point must be before a fixed wing flies on to come round again.
const EXTEND_SLACK: float = 0.5
## The orbit is never tighter than the turn circle at orbit speed times this, so the plane can hold it.
const ORBIT_SLACK: float = 1.3
## How hard an orbiting plane steers back onto its circle (radians of correction at one radius off).
const ORBIT_PULL: float = 1.2
## Looking ahead for hills: a ground sample about every so many metres, and no more than this many.
const LOOK_SPACING: float = 12.0
const LOOK_SAMPLES: int = 24
## The least share of its speed a hover type keeps while climbing first.
const CREEP: float = 0.1
## The emergency pull-up: when the ground here or this many seconds ahead comes within half the minimum clearance,
## a flyer may climb this steeply (metres up per metre flown), whatever its climb rate.
const PULL_UP_SECONDS: float = 0.75
const PULL_UP_SLOPE: float = 1.5
## The share of the climb rate the look-ahead counts on.
const CLIMB_MARGIN: float = 0.8
## Flyers never get closer to the ground than this, whatever the climb rate (metres). Not for landings.
const HARD_FLOOR: float = 0.5
## Hover types lean this share of the angle their acceleration would ask for (look only).
const HOVER_LEAN: float = 0.6

## Metres per second, all three axes.
var velocity := Vector3.ZERO
## Nose up (+) or down, and roll with the left wing down (+), in radians. Yaw is the unit's own rotation.
var pitch: float = 0.0
var bank: float = 0.0

var _body: Unit
var _stats: UnitStats
var _air: AirLayer
## Airspeed along the nose (fixed wing).
var _speed: float = 0.0
## Hover types: the flat velocity being built up or braked.
var _drive := Vector3.ZERO
## Flat push from separation, outside the momentum.
var _nudge := Vector3.ZERO
var _target_velocity := Vector3.ZERO
var _target_yaw: float = NAN
## How fast the nose swung in the last tick (radians per second).
var _yaw_rate: float = 0.0
## The height to be at now to clear the ground under and ahead of the flyer, as of the last decision.
var _cruise: float = 0.0
## The ground is about to be too close (as of the last decision).
var _pull_up: bool = false
## What an idle fixed wing orbits, once it has one.
var _orbit_centre := Vector3.ZERO
var _orbiting: bool = false


func _init(body: Unit, stats: UnitStats, air: AirLayer) -> void:
	_body = body
	_stats = stats
	_air = air
	if is_fixed_wing():
		_speed = stats.flight_min_speed
		velocity = _forward() * _speed
	_cruise = altitude_for(_air.ground_height(body.global_position))


func is_fixed_wing() -> bool:
	return _stats.flight_style == UnitStats.FlightStyle.FIXED_WING


## The airframe's orientation: what the unit node's yaw lacks is pitch and bank.
func orientation() -> Basis:
	return Basis.from_euler(Vector3(pitch, _body.rotation.y, bank), EULER_ORDER_YXZ)


## One decision: the flat velocity the brain wants (zero: nothing to do), where to face while hovering, and the push
## from other flyers.
func command(wanted: Vector3, facing: Vector3, nudge: Vector3) -> void:
	_nudge = nudge
	if is_fixed_wing():
		_command_wing(wanted)
	else:
		_command_hover(wanted, facing)
	_cruise = _cruise_height()
	var soon: Vector3 = _body.global_position + Vector3(velocity.x, 0.0, velocity.z) * PULL_UP_SECONDS
	var near: float = maxf(_air.ground_height(_body.global_position), _air.ground_height(soon))
	_pull_up = _body.global_position.y < near + _stats.flight_min_clearance * 0.5


## One physics tick. `altitude_override` is a fixed height to hold (pads and landings), NAN for the usual altitude.
func step(delta: float, altitude_override: float) -> void:
	var yaw: float = _body.rotation.y
	if not is_nan(_target_yaw):
		_body.rotation.y = rotate_toward(yaw, _target_yaw, deg_to_rad(_stats.turn_rate) * delta)
	_yaw_rate = angle_difference(yaw, _body.rotation.y) / delta
	var acceleration: float = 0.0
	var flat: Vector3
	if is_fixed_wing():
		var before: float = _speed
		var wanted_speed: float = clampf(_target_velocity.length(), _stats.flight_min_speed, _stats.speed)
		_speed = move_toward(_speed, wanted_speed, _stats.flight_acceleration * delta)
		acceleration = (_speed - before) / delta
		flat = _forward() * _speed
	else:
		var before: float = _drive.dot(_forward())
		_drive = _drive.move_toward(_target_velocity, _stats.flight_acceleration * delta)
		acceleration = (_drive.dot(_forward()) - before) / delta
		flat = _drive
		if is_nan(altitude_override):
			flat *= _climb_first()
	flat += _nudge
	var position: Vector3 = _body.global_position
	var wanted_height: float = _cruise if is_nan(altitude_override) else altitude_override
	var climb_limit: float = _stats.flight_climb_rate
	if _pull_up and is_nan(altitude_override):
		climb_limit = maxf(climb_limit, Vector2(flat.x, flat.z).length() * PULL_UP_SLOPE)
	var climb: float = clampf((wanted_height - position.y) / delta, -_stats.flight_climb_rate, climb_limit)
	var moved: Vector3 = _air.clamp_point(position + Vector3(flat.x, climb, flat.z) * delta)
	var ground: float = _air.ground_height(moved)
	if is_nan(altitude_override):
		moved.y = maxf(moved.y, ground + HARD_FLOOR)
	velocity = (moved - position) / delta
	_body.global_position = moved
	_body.set_hover(moved.y - ground)
	_lean(delta, _yaw_rate, acceleration)


## The height above sea level kept over ground at `ground`: `flight_height` plus a share of the ground's rise, but
## never less than `flight_min_clearance` above the ground itself.
func altitude_for(ground: float) -> float:
	return maxf(ground + _stats.flight_min_clearance, _stats.flight_height + _stats.flight_terrain_follow * ground)


## Puts the flyer at its altitude at once (it is placed on the ground in the level).
func snap_to_altitude(altitude_override: float) -> void:
	var ground: float = _air.ground_height(_body.global_position)
	_target_velocity = velocity
	_cruise = _cruise_height() # A fixed wing is moving already: clear of the hills ahead from the start.
	_body.global_position.y = _cruise if is_nan(altitude_override) else altitude_override
	_body.set_hover(_body.global_position.y - ground)


## The velocity that takes a fixed wing over `point`: straight at it, or, when it lies inside the tightest turn the
## plane can make, straight ahead until there is room to come round.
func approach(point: Vector3) -> Vector3:
	var to := Vector3(point.x - _body.global_position.x, 0.0, point.z - _body.global_position.z)
	var forward: Vector3 = _forward()
	var radius: float = turn_radius(_speed)
	var side: Vector3 = forward.cross(Vector3.UP) * radius
	var tight: float = radius - EXTEND_SLACK
	if to.distance_to(side) < tight or to.distance_to(-side) < tight:
		return forward * _stats.speed
	return to.normalized() * _stats.speed


## A fixed wing with nothing to do orbits `point` from now on (until it is given somewhere to go).
func orbit(point: Vector3) -> void:
	_orbit_centre = _air.clamp_point(point, orbit_radius())
	_orbiting = true


## Forgets the orbit: the next time there is nothing to do, a fixed wing circles from where it is then.
func end_orbit() -> void:
	_orbiting = false


func is_orbiting() -> bool:
	return _orbiting


func orbit_centre() -> Vector3:
	return _orbit_centre


func orbit_radius() -> float:
	return maxf(_stats.flight_orbit_radius, turn_radius(_stats.flight_min_speed) * ORBIT_SLACK)


## The radius of the tightest turn at `speed`.
func turn_radius(speed: float) -> float:
	return speed / maxf(deg_to_rad(_stats.turn_rate), 0.01)


## How far inside the map edge a destination must lie, so the flyer can stay on the map there.
func edge_margin() -> float:
	return orbit_radius() + turn_radius(_stats.flight_min_speed) if is_fixed_wing() else _stats.radius


## The usual altitude here, raised for hills ahead: each point ahead asks for its altitude less what can still be
## climbed on the way, so the climb starts just early enough and no earlier.
func _cruise_height() -> float:
	var from: Vector3 = _body.global_position
	var height: float = altitude_for(_air.ground_height(from))
	# Where it is about to go: its motion, or from a standstill where it is setting off to.
	var course := Vector3(velocity.x, 0.0, velocity.z)
	var wanted := Vector3(_target_velocity.x, 0.0, _target_velocity.z)
	if course.length_squared() < 1.0:
		course = wanted
	var speed: float = maxf(course.length(), wanted.length())
	if speed < 0.5:
		return height
	course = course.normalized()
	var reach: float = speed * _stats.flight_look_ahead
	var count: int = clampi(ceili(reach / LOOK_SPACING), 1, LOOK_SAMPLES)
	var spacing: float = reach / count
	# A turning flyer looks along its curve (at most half a circle of it).
	var swing: float = _yaw_rate * spacing / speed
	var turned: float = 0.0
	var point: Vector3 = from
	for i: int in range(1, count + 1):
		if absf(turned + swing) <= PI:
			turned += swing
		point += course.rotated(Vector3.UP, turned) * spacing
		var climbable: float = _stats.flight_climb_rate * CLIMB_MARGIN * spacing * i / speed
		height = maxf(height, altitude_for(_air.ground_height(point)) - climbable)
	return height


## Hover types well below the height they need slow down and climb before going on (a hill rising from close by).
func _climb_first() -> float:
	var short: float = _cruise - _body.global_position.y - _stats.flight_min_clearance * 0.5
	return clampf(1.0 - short / maxf(_stats.flight_min_clearance, 1.0), CREEP, 1.0)


func _command_wing(wanted: Vector3) -> void:
	if wanted.length_squared() > 0.0001:
		_orbiting = false
		_target_velocity = wanted
	else:
		if not _orbiting:
			# Nothing asked for a point: circle to the left, starting where the plane is.
			var left: Vector3 = _forward().cross(Vector3.UP) * -orbit_radius()
			orbit(_body.global_position + left)
		_target_velocity = _orbit_direction() * _stats.flight_min_speed
	_target_yaw = _yaw_of(_target_velocity)


func _command_hover(wanted: Vector3, facing: Vector3) -> void:
	_orbiting = false
	_target_velocity = Vector3.ZERO
	if wanted.length_squared() > 0.0001:
		facing = wanted
		_target_velocity = wanted.limit_length(_stats.speed) * clampf(_forward().dot(wanted.normalized()), 0.0, 1.0)
	_target_yaw = _yaw_of(facing) if facing.length_squared() > 0.0001 else NAN


## Along the circle anticlockwise (seen from above), bent back toward it by how far off it the plane is.
func _orbit_direction() -> Vector3:
	var out := Vector3(_body.global_position.x - _orbit_centre.x, 0.0, _body.global_position.z - _orbit_centre.z)
	var distance: float = out.length()
	if distance < 0.01:
		return _forward()
	out /= distance
	var radius: float = orbit_radius()
	var along: Vector3 = Vector3.UP.cross(out)
	var correction: float = clampf((distance - radius) / radius * ORBIT_PULL, -PI * 0.5, PI * 0.5)
	# Lead the circle by the angle flown while the nose catches up, or the orbit settles wide.
	return along.rotated(Vector3.UP, correction)


## Pitch and bank from the flight: banked into turns; a fixed wing noses along its climb, a hover type leans into its
## acceleration.
func _lean(delta: float, yaw_rate: float, acceleration: float) -> void:
	var limit: float = deg_to_rad(_stats.flight_max_bank_deg)
	var flat_speed: float = Vector2(velocity.x, velocity.z).length()
	var wanted_bank: float = clampf(atan(flat_speed * yaw_rate / GRAVITY), -limit, limit)
	var wanted_pitch: float
	if is_fixed_wing():
		wanted_pitch = atan2(velocity.y, maxf(flat_speed, 1.0))
	else:
		wanted_pitch = clampf(-atan(acceleration / GRAVITY) * HOVER_LEAN, -limit, limit)
	var blend: float = 1.0 - exp(-_stats.flight_lean_rate * delta)
	bank = lerpf(bank, wanted_bank, blend)
	pitch = lerpf(pitch, wanted_pitch, blend)
	_body.set_attitude(pitch, bank)


func _forward() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, _body.rotation.y)


func _yaw_of(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)
