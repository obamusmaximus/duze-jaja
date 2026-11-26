class_name PilotControls
extends Node
## View side: the local player's hands on an inhabited unit. Captures the mouse, turns its motion into a mouse-aim
## direction, the virtual joystick (or, while `free_look` is held, into turning the pilot's head, while the joystick
## goes back to centre), reads the WASD, up and down, air brake, ability, fire and lock keys, and streams them every physics tick
## as a `PilotInput` through `CommandIssuer.pilot()`. A jetpack type (the commando) is a first-person shooter instead:
## the mouse turns the view itself, Space jumps, the jet key surges and hovers. Off until `start`.

## The pilot's head turned from straight ahead, radians: x up, y left.
var look := Vector2.ZERO

var _stats: CockpitStats
var _issuer: CommandIssuer
var _unit: Unit
var _input := PilotInput.new()
## The aim, radians in the world: heading and elevation.
var _aim_yaw: float = 0.0
var _aim_pitch: float = 0.0


func setup(stats: CockpitStats, issuer: CommandIssuer) -> void:
	_stats = stats
	_issuer = issuer
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)


## Takes the controls of `unit`, aiming where its nose points.
func start(unit: Unit) -> void:
	_unit = unit
	_input.team = unit.team
	_input.unit_id = unit.id
	_aim_yaw = unit.rotation.y
	_aim_pitch = 0.0
	look = Vector2.ZERO
	set_process(true)
	set_physics_process(true)
	set_process_unhandled_input(true)
	_capture(true)


## Lets go: the mouse is free again and nothing more is sent.
func stop() -> void:
	if _unit == null:
		return
	_unit = null
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)
	_capture(false)


func is_active() -> bool:
	return _unit != null


## Where the player aims: a world direction of unit length.
func aim() -> Vector3:
	return Basis.from_euler(Vector3(_aim_pitch, _aim_yaw, 0.0), EULER_ORDER_YXZ) * Vector3.FORWARD


## The aim as an orientation (-z along it, level x): a jetpack type's view.
func aim_basis() -> Basis:
	return Basis.from_euler(Vector3(_aim_pitch, _aim_yaw, 0.0), EULER_ORDER_YXZ)


## Where the pilot's head looks: a world direction of unit length (the nose, with the head straight).
func view() -> Vector3:
	if _unit == null or _unit.movement.flight == null or _jetpack():
		return aim()
	var head := Basis.from_euler(Vector3(look.x, look.y, 0.0), EULER_ORDER_YXZ)
	return (_unit.movement.flight.model.basis * head * Vector3.FORWARD).normalized()


## Mouse movement in screen pixels: moves the aim, or the head while free look is held.
func move_mouse(pixels: Vector2) -> void:
	var turn: Vector2 = pixels * deg_to_rad(_stats.aim_sensitivity)
	var up: float = turn.y if _stats.invert_y else -turn.y
	if _jetpack():
		_aim_yaw = wrapf(_aim_yaw - turn.x, -PI, PI)
		_aim_pitch += up
		_limit_aim()
		return
	if Input.is_action_pressed(&"free_look"):
		var yaw_limit: float = deg_to_rad(_stats.look_yaw_limit)
		var pitch_limit: float = deg_to_rad(_stats.look_pitch_limit)
		look.x = clampf(look.x + up, -pitch_limit, pitch_limit)
		look.y = clampf(look.y - turn.x, -yaw_limit, yaw_limit)
		return
	var moved: Vector2 = Vector2(turn.x, up).rotated(_bank() * _stats.aim_roll_follow)
	_aim_yaw = wrapf(_aim_yaw - moved.x, -PI, PI)
	_aim_pitch += moved.y
	_limit_aim()


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		move_mouse(motion.screen_relative)


func _process(delta: float) -> void:
	if Input.is_action_pressed(&"free_look"):
		return
	var real_delta: float = delta if Engine.time_scale <= 0.0 else delta / Engine.time_scale
	look = look.lerp(Vector2.ZERO, CameraEase.weight(_stats.look_return_rate, real_delta))


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_unit) or not _unit.alive:
		return
	if _unit.movement.flight == null:
		# On the autopilot: only the ability key counts (an Explorer packs up with it), and the aim rides the nose so
		# the hand-back starts straight.
		_aim_yaw = _unit.rotation.y
		_aim_pitch = 0.0
		_send_idle()
		return
	if _jetpack():
		_send_jetpack()
		return
	var hovering: bool = _hovering()
	var stick: Vector2 = Input.get_vector(&"pilot_roll_left", &"pilot_roll_right", &"pilot_pitch_down", &"pilot_pitch_up")
	if _stats.stick_invert_pitch and not hovering:
		stick.y = -stick.y
	# In a jet WASD flies the plane and takes over from the mouse; a hover moves by it and steers by the mouse.
	var jet_stick: bool = not hovering and not stick.is_zero_approx()
	if Input.is_action_pressed(&"free_look"):
		if jet_stick and _stats.aim_follows_stick:
			_aim_along_course()
		else:
			_centre_aim(_stats.free_look_aim_return, delta)
	elif jet_stick:
		if _stats.aim_follows_stick:
			_aim_along_course()
	else:
		_centre_aim(_stats.aim_correction, delta)
	_limit_aim() # The nose moves under a still mouse too.
	_input.aim = aim()
	_input.stick = stick
	_input.lift = Input.get_axis(&"pilot_down", &"pilot_up") if hovering else 0.0
	_input.air_brake = not hovering and Input.is_action_pressed(&"air_brake")
	_input.ability = Input.is_action_pressed(&"unit_ability")
	_input.view = view()
	_input.fire = Input.is_action_pressed(&"pilot_fire")
	_input.lock = Input.is_action_pressed(&"pilot_lock")
	_issuer.pilot(_input)


## A jetpack type: WASD walks, strafes and surges, Space jumps, the jet key hovers and surges, the view aims.
func _send_jetpack() -> void:
	_input.aim = aim()
	_input.stick = Input.get_vector(&"pilot_roll_left", &"pilot_roll_right", &"pilot_pitch_down", &"pilot_pitch_up")
	_input.lift = Input.get_action_strength(&"pilot_up")
	_input.jet = Input.is_action_pressed(&"pilot_jet")
	_input.air_brake = false
	_input.ability = Input.is_action_pressed(&"unit_ability")
	_input.view = aim()
	_input.fire = Input.is_action_pressed(&"pilot_fire")
	_input.lock = false
	_issuer.pilot(_input)


func _send_idle() -> void:
	_input.aim = aim()
	_input.stick = Vector2.ZERO
	_input.lift = 0.0
	_input.air_brake = false
	_input.ability = Input.is_action_pressed(&"unit_ability")
	_input.view = view()
	_input.fire = false
	_input.lock = false
	_input.jet = false
	_issuer.pilot(_input)


## Puts the aim where the jet is going (held up in a transition, where its nose points).
func _aim_along_course() -> void:
	var flight: PilotFlight = _unit.movement.flight
	if flight == null or flight.hovering():
		return
	var model: FlightModel = flight.jet
	var slow: bool = model.support > 0.5 or model.velocity.length() < FlightModel.MIN_AIR_SPEED
	var course: Vector3 = model.forward() if slow else model.velocity.normalized()
	_set_aim(course)


## Pulls the aim toward the mouse stick's centre at `rate` per second (`CockpitStats.aim_correction`, or the faster
## `free_look_aim_return` while looking around).
func _centre_aim(rate: float, delta: float) -> void:
	if rate <= 0.0 or _unit.movement.flight == null:
		return
	var from: Vector3 = aim()
	var centre: Vector3 = _unit.movement.flight.model.neutral_aim()
	var weight: float = CameraEase.weight(rate, delta)
	var axis: Vector3 = from.cross(centre)
	if axis.length_squared() < 0.00000001:
		return
	_set_aim(from.rotated(axis.normalized(), from.angle_to(centre) * weight))


func _jetpack() -> bool:
	return _unit != null and _unit.movement.flight != null and _unit.movement.flight.is_jetpack()


func _hovering() -> bool:
	return _unit.movement.flight != null and _unit.movement.flight.hovering()


## Aims along a world direction of unit length. Near the vertical there is no heading to take.
func _set_aim(direction: Vector3) -> void:
	_aim_pitch = asin(clampf(direction.y, -1.0, 1.0))
	if Vector2(direction.x, direction.z).length() > 0.1:
		_aim_yaw = atan2(-direction.x, -direction.z)


## The plane's bank, radians: negative with the right wing down.
func _bank() -> float:
	if _unit == null or _unit.movement.flight == null:
		return 0.0
	var basis: Basis = _unit.movement.flight.model.basis
	return atan2(basis.x.y, basis.y.y)


## Keeps the aim within reach of the nose and short of straight up or down.
func _limit_aim() -> void:
	if _jetpack():
		var view_limit: float = deg_to_rad(_unit.stats.jetpack.view_pitch_limit_deg)
		_aim_pitch = clampf(_aim_pitch, -view_limit, view_limit)
		return
	var pitch_limit: float = deg_to_rad(_stats.aim_pitch_limit)
	if _hovering():
		pitch_limit = minf(pitch_limit, deg_to_rad(_unit.movement.flight.hover.stats.pitch_limit_deg))
	_aim_pitch = clampf(_aim_pitch, -pitch_limit, pitch_limit)
	var reach: float = deg_to_rad(_stats.aim_max_off_nose)
	var nose: float = _unit.rotation.y
	_aim_yaw = nose + clampf(angle_difference(nose, _aim_yaw), -reach, reach)


## The mouse is free while the game is paused and captured again after.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			if is_active():
				_capture(false)
		NOTIFICATION_UNPAUSED:
			if is_active():
				_capture(true)
		NOTIFICATION_EXIT_TREE:
			stop()


func _capture(on: bool) -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE
