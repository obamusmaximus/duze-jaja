class_name HoverModel
extends PilotModel
## The hover control type (`docs/mechanics/flight_model.md`): free flight for hovering craft. WASD asks for a speed
## over the ground relative to the heading, up and down for a climb rate, and the craft gains and sheds speed at its
## type's rates, so a heavy one takes longer to stop. The mouse aim is a virtual joystick: the heading and the nose's
## pitch turn toward it. It leans into its acceleration and banks into turns. Never stalls. State in, input in, state
## out: no nodes, nothing read from the world. Simulation.

## Below this (metres per second per second) the easing into a speed still closes the gap.
const MIN_APPROACH: float = 0.4

var stats: HoverStats
## Where the nose is steered, radians: heading, and elevation without the lean.
var yaw: float = 0.0
var pitch: float = 0.0

var _yaw_speed: float = 0.0
var _pitch_speed: float = 0.0
## The extra attitude on top of the steered one, radians: x pitch (up +), y roll (left wing down +).
var _lean := Vector2.ZERO


func _init(hover_stats: HoverStats) -> void:
	stats = hover_stats


## Takes over from any attitude without a jump: what it can't steer to becomes lean, which then eases out.
func start(at: Vector3, with_velocity: Vector3, facing: Basis) -> void:
	position = at
	velocity = with_velocity
	basis = facing.orthonormalized()
	var angles: Vector3 = basis.get_euler(EULER_ORDER_YXZ)
	var limit: float = deg_to_rad(stats.pitch_limit_deg)
	yaw = angles.y
	pitch = clampf(angles.x, -limit, limit)
	_lean = Vector2(angles.x - pitch, angles.z)
	_yaw_speed = 0.0
	_pitch_speed = 0.0


func hover_share() -> float:
	return 1.0


func top_speed() -> float:
	return stats.speed


func neutral_aim() -> Vector3:
	return Basis.from_euler(Vector3(pitch, yaw, 0.0), EULER_ORDER_YXZ) * Vector3.FORWARD


## One tick.
func step(delta: float, input: PilotInput) -> void:
	_turn(delta, input.aim)
	var heading := Basis(Vector3.UP, yaw)
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var ahead: float = input.stick.y * stats.speed * (1.0 if input.stick.y >= 0.0 else stats.reverse_share)
	var wanted: Vector3 = heading * Vector3(input.stick.x * stats.speed * stats.strafe_share, 0.0, -ahead)
	# Slowing down or turning back is braking; anything else is the engine pushing.
	var braking: bool = wanted.length() < flat.length() - 0.05 or wanted.dot(flat) < 0.0
	var moved: Vector3 = _approach(flat, wanted, stats.braking if braking else stats.acceleration, delta)
	var climb: float = clampf(input.lift, -1.0, 1.0) * stats.climb_speed
	var rise: float = _approach(Vector3(0.0, velocity.y, 0.0), Vector3(0.0, climb, 0.0), stats.climb_acceleration,
			delta).y
	_lean_into(delta, heading.inverse() * ((moved - flat) / delta))
	velocity = Vector3(moved.x, rise, moved.z)
	basis = Basis.from_euler(Vector3(pitch + _lean.x, yaw, _lean.y), EULER_ORDER_YXZ)
	position += velocity * delta


## The heading and nose turn toward the aim, the turn rates building and dying with the craft's weight.
func _turn(delta: float, aim: Vector3) -> void:
	var yaw_error: float = 0.0
	var pitch_error: float = 0.0
	if aim.length_squared() > 0.0001:
		var toward: Vector3 = aim.normalized()
		if Vector2(toward.x, toward.z).length() > 0.05:
			yaw_error = angle_difference(yaw, atan2(-toward.x, -toward.z))
		var limit: float = deg_to_rad(stats.pitch_limit_deg)
		pitch_error = clampf(asin(clampf(toward.y, -1.0, 1.0)), -limit, limit) - pitch
	var ease: float = 1.0 - exp(-stats.turn_response * delta)
	var most_yaw: float = deg_to_rad(stats.yaw_rate)
	var most_pitch: float = deg_to_rad(stats.pitch_rate)
	_yaw_speed = lerpf(_yaw_speed, clampf(yaw_error * stats.steer_gain, -most_yaw, most_yaw), ease)
	_pitch_speed = lerpf(_pitch_speed, clampf(pitch_error * stats.steer_gain, -most_pitch, most_pitch), ease)
	yaw = wrapf(yaw + _yaw_speed * delta, -PI, PI)
	pitch += _pitch_speed * delta


## Toward `target` at no more than `limit` per second, easing in over the last of it.
func _approach(from: Vector3, target: Vector3, limit: float, delta: float) -> Vector3:
	var gap: float = from.distance_to(target)
	var rate: float = clampf(gap * stats.settle, MIN_APPROACH, limit)
	return from.move_toward(target, rate * delta)


## Nose down while speeding up, up while braking, rolled into sideways pushes and turns. `push` is in the heading's
## axes (x right, -z ahead).
func _lean_into(delta: float, push: Vector3) -> void:
	var full: float = maxf(maxf(stats.acceleration, stats.braking), 0.01)
	var turning: float = _yaw_speed / maxf(deg_to_rad(stats.yaw_rate), 0.01)
	var pace: float = clampf(Vector2(velocity.x, velocity.z).length() / maxf(stats.speed, 0.01), 0.0, 1.0)
	var target := Vector2(
		clampf(push.z / full, -1.0, 1.0) * deg_to_rad(stats.lean_pitch_deg),
		-clampf(push.x / full, -1.0, 1.0) * deg_to_rad(stats.lean_roll_deg)
			+ clampf(turning, -1.0, 1.0) * pace * deg_to_rad(stats.turn_bank_deg))
	var ease: float = 1.0 - exp(-stats.lean_response * delta)
	_lean = Vector2(lerp_angle(_lean.x, target.x, ease), lerp_angle(_lean.y, target.y, ease))
