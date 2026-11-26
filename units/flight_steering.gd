class_name FlightSteering
extends RefCounted
## Turns the pilot's controls into control inputs for the `FlightModel`.
## Mouse aim (`steer`): it banks to where the wing has to push, which is the wanted turn plus holding the weight, so a
## small correction takes a shallow bank and only a hard turn goes near the vertical. Far off the aim it pulls; close
## to it pitch and rudder point the nose and the wings come level by themselves. In a hover it turns flat. The nose is
## held above the aim by the angle of attack the speed needs, so the flight path goes where the player aims. It asks
## for all the aim does: a slow aircraft can be pulled into a stall.
## Stick (`fly_stick`): while held it flies the aircraft directly and the aim is ignored. Simulation.

## Below this push (metres per second per second) the wanted bank fades out: there is hardly a direction to bank to
## (a vertical nose with nothing to turn).
const MIN_BANK_PUSH: float = 2.0


## One tick of controls: the stick while it is held, else the mouse aim.
static func fly(model: FlightModel, input: PilotInput, out: FlightControls) -> void:
	if input.stick.is_zero_approx():
		steer(model, input.aim, input.air_brake, out)
	else:
		fly_stick(input.stick, input.air_brake, out)


## Direct control: y pitches, x rolls, the rudder is left to the airframe's own stability. Nothing levels the wings.
static func fly_stick(stick: Vector2, air_brake: bool, out: FlightControls) -> void:
	out.air_brake = air_brake
	out.pitch = clampf(stick.y, -1.0, 1.0)
	out.roll = clampf(stick.x, -1.0, 1.0)
	out.yaw = 0.0


static func steer(model: FlightModel, aim: Vector3, air_brake: bool, out: FlightControls) -> void:
	out.air_brake = air_brake
	var stats: FlightStats = model.stats
	var wings_level: float = atan2(model.basis.x.y, model.basis.y.y)
	if aim.length_squared() < 0.0001:
		out.pitch = 0.0
		out.yaw = 0.0
		out.roll = _control(wings_level, model.rates.z, stats.steer_roll_gain, stats)
		return
	var target: Vector3 = aim.normalized()
	# Point the nose that much above the aim as the wing needs to hold the path there.
	target = _pitched(target, _lead(model))
	var local: Vector3 = target * model.basis
	var off: float = Vector3.FORWARD.angle_to(local)
	var pitch_error: float = atan2(local.y, Vector2(local.x, local.z).length())
	var yaw_error: float = atan2(local.x, -local.z)
	var pulling: float = smoothstep(deg_to_rad(stats.steer_level_angle_deg), deg_to_rad(stats.steer_bank_angle_deg), off)
	pulling *= 1.0 - model.support
	if model.stalled:
		# Only a hard pull may hold a wing stalled: a small correction lets the nose down until it flies again.
		pitch_error = lerpf(minf(pitch_error, model.trim_alpha() - model.alpha), pitch_error, pulling)

	# Where the wing has to push: toward the aim as hard as the turn asks, and up against the weight.
	var nose: Vector3 = model.forward()
	var toward: Vector3 = target - nose * target.dot(nose)
	toward = toward.normalized() if toward.length_squared() > 0.000001 else model.basis.y # Dead behind: pull.
	var turn_rate: float = minf(off * stats.steer_turn_response, deg_to_rad(stats.pitch_rate))
	var needed: Vector3 = toward * turn_rate * model.velocity.length() \
		+ (Vector3.UP - nose * nose.y) * stats.gravity
	# A little below the nose: push, instead of rolling upside down to pull.
	var push: bool = needed.y < 0.0 and off < deg_to_rad(stats.steer_push_angle_deg)
	if push:
		needed = -needed
	var across := Vector2(needed.dot(model.basis.x), needed.dot(model.basis.y))
	var roll_error: float = atan2(across.x, across.y) * minf(across.length() / MIN_BANK_PUSH, 1.0)
	roll_error = lerpf(roll_error, wings_level, model.support)

	# Pull once rolled into the wanted bank; the aim's side of the airframe says whether that is a pull or a push.
	var aim_side: float = local.y / maxf(Vector2(local.x, local.y).length(), 0.0001)
	if local.z > 0.0 and absf(local.y) < 0.01:
		aim_side = 1.0 # Dead behind.
	var bank_pitch: float = off * aim_side * maxf(cos(roll_error), 0.0)
	out.pitch = _control(lerpf(pitch_error, bank_pitch, pulling), model.rates.x, stats.steer_gain, stats)
	out.yaw = _control(yaw_error * (1.0 - pulling), model.rates.y * (1.0 - pulling), stats.steer_gain, stats)
	out.roll = _control(roll_error, model.rates.z, stats.steer_roll_gain, stats)


## The aim that asks for nothing: the mouse stick's centre. It is the nose, less the lead `steer` holds it above the
## aim by, so at cruise it is the nose itself, and slower it sits a little under. Aiming at the bare nose instead would
## creep upward when slow.
static func neutral_aim(model: FlightModel) -> Vector3:
	return _pitched(model.forward(), -_lead(model))


## How far (radians) the nose is held above the aim: what the wing needs to hold the path there.
static func _lead(model: FlightModel) -> float:
	return model.trim_alpha() * clampf(model.basis.y.y, 0.0, 1.0) * (1.0 - model.support)


## `direction` raised by `angle` (radians) toward straight up. Left alone near the vertical, where there is no "up".
static func _pitched(direction: Vector3, angle: float) -> Vector3:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length() <= 0.1:
		return direction
	return direction.rotated(flat.normalized().cross(Vector3.UP), angle)


## A control input for an angle still to go (radians), eased off by the turn rate already there.
static func _control(error: float, rate: float, gain: float, stats: FlightStats) -> float:
	return clampf((error - rate * stats.steer_damping) * gain, -1.0, 1.0)
