class_name JetpackModel
extends PilotModel
## A jetpack unit (the commando) in first person: the jetpack kit ported from `../first` (`docs/mechanics/
## commando.md`). On foot it walks and jumps. The jet key (`PilotInput.jet`) toggles HOVER on a short press: low
## gravity in the air and WASD strafing at a set speed. Held past `surge_hold_time` with a movement key it SURGEs along
## the keys relative to the view (pitch included), which turns into the AFTERBURNER after `afterburner_delay` of
## forward-only surging. No fuel. `PilotFlight` runs it, keeps it on the ground (`land`, `leave_ground`) and out of
## buildings. Plain state: nothing read from the world. Simulation.

enum Thrust { OFF, SURGE, AFTERBURNER }

var stats: JetpackStats
## Hover is switched on (it only holds the body up in the air).
var hover_on: bool = false
var thrust: Thrust = Thrust.OFF
## Standing or walking on the ground (`PilotFlight` sets it).
var grounded: bool = false

## The jet key is down, and has been for `_held_time` seconds; this press became a hold (no hover toggle on release).
var _held: bool = false
var _held_time: float = 0.0
var _hold_used: bool = false
## Seconds of forward-only surging, toward the afterburner.
var _forward_time: float = 0.0
## The surge started this tick: its speed is set outright.
var _fresh: bool = false
## Afterburner momentum still carried: the hover doesn't brake it down to its strafe speed.
var _carry: bool = false
## The jump key as of the last tick: a jump is a press.
var _lift_held: bool = false
## Where the view looks: a world direction.
var _view := Vector3.FORWARD


func _init(jetpack_stats: JetpackStats) -> void:
	stats = jetpack_stats


func start(at: Vector3, start_velocity: Vector3, facing: Basis) -> void:
	position = at
	velocity = start_velocity
	_view = -facing.z
	_face()
	hover_on = true # It comes out of the RTS hover still hovering.
	thrust = Thrust.OFF
	grounded = false
	_held = false
	_carry = false


func top_speed() -> float:
	return stats.surge_speed


func afterburning() -> bool:
	return thrust == Thrust.AFTERBURNER


## How far a held jet key is toward starting a surge, 0 to 1; 0 while not held or already thrusting.
func hold_ratio() -> float:
	if not _held or thrust != Thrust.OFF:
		return 0.0
	return clampf(_held_time / maxf(stats.surge_hold_time, 0.01), 0.0, 1.0)


## Where the view looks, a world direction (the weapons aim along it).
func view() -> Vector3:
	return _view


## The view's orientation: -z along it, level x.
func view_basis() -> Basis:
	return Basis.looking_at(_view, Vector3.UP if absf(_view.y) < 0.999 else Vector3.BACK)


## One tick: reads the controls and moves `position` by the new velocity. Contact is `PilotFlight`'s.
func step(delta: float, input: PilotInput) -> void:
	if input.view.length_squared() > 0.0001:
		_view = input.view.normalized()
	_face()
	_read_jet(delta, input)
	var wish: Vector3 = _flat_wish(input.stick)
	if thrust != Thrust.OFF:
		_step_thrust(delta, input.stick)
	elif hover_on and not grounded:
		_step_hover(delta, wish)
	elif grounded:
		_step_walk(delta, wish, input)
	else:
		_step_air(delta, wish)
	_lift_held = input.lift > 0.5
	position += velocity * delta


## Touched down: it walks from here, and the afterburner's carry is spent.
func land() -> void:
	grounded = true
	_carry = false
	if velocity.y < 0.0:
		velocity.y = 0.0


func leave_ground() -> void:
	grounded = false


## The body turns (yaw only) with the view.
func _face() -> void:
	var flat := Vector2(_view.x, _view.z)
	if flat.length() > 0.001:
		basis = Basis(Vector3.UP, atan2(-_view.x, -_view.z))


## The jet key: a short press toggles hover; a hold surges while a movement key is held, and lights the afterburner
## after a while of forward-only surging.
func _read_jet(delta: float, input: PilotInput) -> void:
	if input.jet and not _held:
		_held = true
		_held_time = 0.0
		_hold_used = false
	elif not input.jet and _held:
		_held = false
		if not _hold_used:
			hover_on = not hover_on
		_set_thrust(Thrust.OFF)
	if not _held:
		return
	_held_time += delta
	if _held_time < stats.surge_hold_time:
		return
	_hold_used = true
	if input.stick.is_zero_approx():
		_forward_time = 0.0
		_set_thrust(Thrust.OFF)
		return
	if thrust == Thrust.OFF:
		_fresh = true
		_set_thrust(Thrust.SURGE)
	if thrust == Thrust.SURGE:
		_forward_time = _forward_time + delta if input.stick.y > 0.5 else 0.0
		if _forward_time >= stats.afterburner_delay:
			_set_thrust(Thrust.AFTERBURNER)


func _set_thrust(new_thrust: Thrust) -> void:
	if new_thrust == thrust:
		return
	if new_thrust == Thrust.OFF:
		_forward_time = 0.0
		if thrust == Thrust.AFTERBURNER:
			_carry = true
	thrust = new_thrust
	if new_thrust != Thrust.OFF:
		grounded = false


## The movement keys along the view, pitch included: W flies where the view points.
func _thrust_direction(stick: Vector2) -> Vector3:
	if stick.is_zero_approx():
		return Vector3.ZERO
	return (view_basis() * Vector3(stick.x, 0.0, -stick.y)).normalized()


## The movement keys on the level: where walking, air steering and the hover go.
func _flat_wish(stick: Vector2) -> Vector3:
	if stick.is_zero_approx():
		return Vector3.ZERO
	return (basis * Vector3(stick.x, 0.0, -stick.y)).limit_length(1.0)


## Surge holds `surge_speed` along the keys; the afterburner accelerates toward `afterburner_speed` against a drag
## growing with the square of the speed, so it levels off there softly. Both turn with the view; no gravity.
func _step_thrust(delta: float, stick: Vector2) -> void:
	var direction: Vector3 = _thrust_direction(stick)
	if thrust == Thrust.SURGE:
		var target: Vector3 = direction * stats.surge_speed
		velocity = target if _fresh else velocity.move_toward(target, stats.surge_steer_accel * delta)
	else:
		var speed: float = velocity.length()
		var top: float = maxf(stats.afterburner_speed, 1.0)
		speed += stats.afterburner_accel * (1.0 - (speed / top) * (speed / top)) * delta
		velocity = velocity.move_toward(direction * speed, stats.surge_steer_accel * delta)
	_fresh = false


## Low gravity, the vertical speed settling, and WASD driving the flat speed toward `hover_strafe_speed` (braking
## faster momentum down to it), unless afterburner momentum is still carried: then it coasts on as in free flight.
func _step_hover(delta: float, wish: Vector3) -> void:
	velocity.y -= stats.gravity * stats.hover_gravity_scale * delta
	velocity.y /= 1.0 + stats.hover_vertical_damping * delta
	var flat := Vector2(velocity.x, velocity.z)
	if _carry and flat.length() > stats.hover_strafe_speed:
		_steer_air(delta, wish)
		return
	_carry = false
	flat = flat.move_toward(Vector2(wish.x, wish.z) * stats.hover_strafe_speed, stats.hover_strafe_accel * delta)
	velocity.x = flat.x
	velocity.z = flat.y


func _step_walk(delta: float, wish: Vector3, input: PilotInput) -> void:
	var flat := Vector2(velocity.x, velocity.z).move_toward(Vector2(wish.x, wish.z) * stats.walk_speed,
			stats.walk_accel * delta)
	velocity.x = flat.x
	velocity.z = flat.y
	velocity.y = 0.0
	if input.lift > 0.5 and not _lift_held:
		velocity.y = stats.jump_speed
		grounded = false


## Free flight with hover off: gravity, keys steering a little, drag above walking speed.
func _step_air(delta: float, wish: Vector3) -> void:
	velocity.y -= stats.gravity * delta
	_steer_air(delta, wish)


func _steer_air(delta: float, wish: Vector3) -> void:
	var flat := Vector2(velocity.x, velocity.z)
	var speed: float = flat.length()
	flat = flat.move_toward(Vector2(wish.x, wish.z) * maxf(speed, stats.walk_speed), stats.air_accel * delta)
	if flat.length() > stats.walk_speed:
		flat /= 1.0 + stats.air_drag * delta
	velocity.x = flat.x
	velocity.z = flat.y
