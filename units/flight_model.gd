class_name FlightModel
extends PilotModel
## The jet control type's flight model (`docs/mechanics/flight_model.md`): our own cheap aerodynamics, integrated on the
## simulation tick. Fixed thrust; lift from speed squared and angle of attack up to a stall; drag from speed squared,
## angle of attack, the stall and the air brake; gravity. Sideslip is pulled back to the nose. A type with a transition
## speed that comes here out of a hover (the VTOL) is held up by its engine until it first outruns it. State in,
## controls in, state out: no nodes, nothing read from the world.
## Simulation.

## Below this speed (metres per second) the air gives no direction: no angle of attack, no stability.
const MIN_AIR_SPEED: float = 0.5
## The engine's support in a transition fades out between the transition speed and this multiple of it.
const HOVER_FADE: float = 1.5
## Drag from the angle of attack stops growing at this many stall angles.
const MAX_DRAG_ALPHA: float = 2.0
## The most the settling angle of attack uses of the stall angle, so hands off never stalls.
const TRIM_LIMIT: float = 0.9

var stats: FlightStats
## Turn rates about the airframe, radians per second: x pitch (up +), y yaw (right +), z roll (right +).
var rates := Vector3.ZERO
## The thrust as a multiple of the type's own (an ability's boost).
var thrust_boost: float = 1.0

## As of the last step, for views (HUD, sound) and the steering.
## Angle between the nose and the flight path, radians (+: the nose is above where it goes).
var alpha: float = 0.0
## How much of its weight the engine carries in a transition, 0 to 1.
var support: float = 0.0
## Out of a hover and not yet fast enough to fly on the wing alone.
var transition: bool = false


func _init(flight_stats: FlightStats) -> void:
	stats = flight_stats


func start(at: Vector3, with_velocity: Vector3, facing: Basis) -> void:
	position = at
	velocity = with_velocity
	basis = facing.orthonormalized()
	rates = Vector3.ZERO
	alpha = angle_of_attack()
	transition = stats.hover_speed > 0.0 and _airspeed() < stats.hover_speed * HOVER_FADE
	support = _support()
	stalled = false


func hover_share() -> float:
	return support


func top_speed() -> float:
	return stats.cruise_speed


func neutral_aim() -> Vector3:
	return FlightSteering.neutral_aim(self)


func angle_of_attack() -> float:
	if velocity.length() < MIN_AIR_SPEED:
		return 0.0
	var local: Vector3 = velocity * basis # Into the airframe's axes.
	return atan2(-local.y, -local.z)


## The angle of attack (radians) at which the wing stalls. The wing is set a little above the nose line (its
## incidence), so at cruise speed the nose points along the flight path.
func stall_alpha() -> float:
	return deg_to_rad(stats.stall_angle_deg) - incidence()


func incidence() -> float:
	var share: float = stats.stall_speed / maxf(stats.cruise_speed, stats.stall_speed)
	return deg_to_rad(stats.stall_angle_deg) * share * share


## The angle of attack that holds the flight path at this speed and attitude, kept short of the stall.
func trim_alpha() -> float:
	var stall: float = deg_to_rad(stats.stall_angle_deg)
	var most: float = _lift_factor() * maxf(velocity.length_squared(), 1.0)
	var needed: float = stats.gravity * basis.y.y / most
	return clampf(needed * stall, -stall * 0.5, stall * TRIM_LIMIT) - incidence()


## One tick.
func step(delta: float, controls: FlightControls) -> void:
	var speed: float = velocity.length()
	support = _support()
	_turn(delta, controls, speed)
	_push(delta, controls)
	position += velocity * delta


## Control surfaces and the airframe's own stability turn it.
func _turn(delta: float, controls: FlightControls, speed: float) -> void:
	var authority: float = lerpf(stats.min_control, 1.0, clampf(speed / stats.full_control_speed, 0.0, 1.0))
	authority = maxf(authority, support)
	var wanted := Vector3(
		clampf(controls.pitch, -1.0, 1.0) * deg_to_rad(stats.pitch_rate),
		clampf(controls.yaw, -1.0, 1.0) * deg_to_rad(stats.yaw_rate),
		clampf(controls.roll, -1.0, 1.0) * deg_to_rad(stats.roll_rate)) * authority
	rates = rates.lerp(wanted, 1.0 - exp(-stats.control_response * delta))
	var turn: Vector3 = rates
	alpha = angle_of_attack()
	if speed >= MIN_AIR_SPEED:
		var wing: float = 1.0 - support
		# Hands off the pitch, settle to the angle of attack that holds the flight path.
		var hands_off: float = 1.0 - clampf(absf(controls.pitch), 0.0, 1.0)
		var settle: float = wrapf(trim_alpha() - alpha, -PI, PI) * stats.pitch_stability * hands_off * wing
		turn.x += clampf(settle, -deg_to_rad(stats.pitch_rate), deg_to_rad(stats.pitch_rate))
		var slip: float = asin(clampf(velocity.dot(basis.x) / speed, -1.0, 1.0))
		turn.y += slip * stats.yaw_stability * wing
	var spin := Vector3(turn.x, -turn.y, -turn.z)
	var angle: float = spin.length() * delta
	if angle > 0.000001:
		basis = basis * Basis(spin.normalized(), angle)
	if stalled and speed >= MIN_AIR_SPEED:
		_drop_nose(delta, speed)
	basis = basis.orthonormalized()


## A stalled nose falls toward where the aircraft is going, which is what makes the stall recover.
func _drop_nose(delta: float, speed: float) -> void:
	var nose: Vector3 = forward()
	var course: Vector3 = velocity / speed
	var axis: Vector3 = nose.cross(course)
	if axis.length_squared() < 0.000001:
		axis = basis.x # Dead backwards (a tail slide): any way round will do.
	var past: float = absf(alpha + incidence()) - deg_to_rad(stats.stall_angle_deg)
	var share: float = clampf(past / deg_to_rad(stats.stall_falloff_deg), 0.0, 1.0)
	var angle: float = minf(deg_to_rad(stats.stall_nose_drop) * share * delta, nose.angle_to(course))
	basis = Basis(axis.normalized(), angle) * basis


## Thrust, lift, drag and gravity move it.
func _push(delta: float, controls: FlightControls) -> void:
	var speed: float = velocity.length()
	var wing: float = 1.0 - support
	var thrust: float = 0.0 if transition and controls.air_brake else stats.thrust * thrust_boost
	var push: Vector3 = forward() * thrust + Vector3.DOWN * stats.gravity * wing
	alpha = angle_of_attack()
	var stall: float = deg_to_rad(stats.stall_angle_deg)
	var effective: float = alpha + incidence() if speed >= MIN_AIR_SPEED else 0.0
	var past: float = clampf((absf(effective) - stall) / deg_to_rad(stats.stall_falloff_deg), 0.0, 1.0)
	stalled = support < 0.5 and absf(effective) > stall
	var drag: float = 0.0
	if speed >= MIN_AIR_SPEED:
		var course: Vector3 = velocity / speed
		var most: float = _lift_factor() * speed * speed
		var up: Vector3 = basis.y - course * basis.y.dot(course)
		if up.length_squared() > 0.000001:
			push += up.normalized() * most * lift_coefficient(effective) * wing
		var pace: float = speed / stats.cruise_speed
		var bite: float = minf(absf(effective) / stall, MAX_DRAG_ALPHA)
		drag = _parasite_factor() * speed * speed + stats.induced_drag * most * bite * bite * wing \
			+ stats.stall_drag * past * pace * pace * wing
		if controls.air_brake:
			drag += stats.brake_drag * pace * pace
	velocity += push * delta
	# Drag only slows: it never turns the aircraft round.
	velocity = velocity.limit_length(maxf(velocity.length() - drag * delta, 0.0))
	_grip(delta)
	if support > 0.0:
		_hover(delta, controls)


## How much of the stall angle the wing is using: 1 and above is past the stall. 0 while the engine holds it up in a
## transition. For views (buffet, warning, HUD).
func stall_load() -> float:
	if velocity.length() < MIN_AIR_SPEED:
		return 0.0
	var wing: float = clampf(1.0 - support * 2.0, 0.0, 1.0) # Gone by half support, where the stall is too.
	return absf(alpha + incidence()) / deg_to_rad(stats.stall_angle_deg) * wing


## Lift as a share of the most the wing makes, for an angle (radians) from the zero-lift line.
func lift_coefficient(effective: float) -> float:
	var stall: float = deg_to_rad(stats.stall_angle_deg)
	var size: float = absf(effective)
	if size <= stall:
		return effective / stall
	var past: float = clampf((size - stall) / deg_to_rad(stats.stall_falloff_deg), 0.0, 1.0)
	# Flying sideways or backwards, the wing makes nothing.
	var fade: float = clampf(cos(size) / cos(stall), 0.0, 1.0)
	return signf(effective) * lerpf(1.0, stats.post_stall_lift, past) * fade


## Turns sideways drift back along the nose without losing speed.
func _grip(delta: float) -> void:
	var speed: float = velocity.length()
	var slid: Vector3 = velocity - basis.x * velocity.dot(basis.x) * (1.0 - exp(-stats.side_grip * delta))
	if slid.length() >= MIN_AIR_SPEED:
		velocity = slid.normalized() * speed


## The engine's own flying: the climb follows the nose, and the air brake brings it to a stop.
func _hover(delta: float, controls: FlightControls) -> void:
	var settle: float = (1.0 - exp(-stats.hover_damping * delta)) * support
	velocity.y = lerpf(velocity.y, forward().y * stats.hover_climb_speed, settle)
	if controls.air_brake:
		velocity.x = lerpf(velocity.x, 0.0, settle)
		velocity.z = lerpf(velocity.z, 0.0, settle)


## The engine's share of the weight. The transition ends for good once the wing has the speed to take it all over.
func _support() -> float:
	if not transition:
		return 0.0
	var speed: float = _airspeed()
	if speed >= stats.hover_speed * HOVER_FADE:
		transition = false
		return 0.0
	return 1.0 - smoothstep(stats.hover_speed, stats.hover_speed * HOVER_FADE, speed)


## Speed along the nose: sliding or falling doesn't count toward flying on the wing.
func _airspeed() -> float:
	return maxf(velocity.dot(forward()), 0.0)


## Lift at the stall angle is this times speed squared: gravity at the stall speed.
func _lift_factor() -> float:
	return stats.gravity / (stats.stall_speed * stats.stall_speed)


## The drag that comes with speed alone, set so that in level flight all drag equals the thrust at cruise speed.
func _parasite_factor() -> float:
	var share: float = stats.stall_speed / maxf(stats.cruise_speed, stats.stall_speed)
	var induced: float = stats.induced_drag * stats.gravity * share * share
	return maxf(stats.thrust - induced, 0.1) / (stats.cruise_speed * stats.cruise_speed)
