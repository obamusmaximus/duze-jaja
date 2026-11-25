class_name PilotControls
extends Node
## View side: the local player's hands on an inhabited unit. Captures the mouse, turns its motion into a mouse-aim
## direction (or, while `free_look` is held, into turning the pilot's head, with the aim held), reads the stick,
## air brake and ability keys, and streams them every physics tick as a `PilotInput` through `CommandIssuer.pilot()`.
## Off until `start`.

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


## Mouse movement in screen pixels: moves the aim, or the head while free look is held.
func move_mouse(pixels: Vector2) -> void:
	var turn: Vector2 = pixels * deg_to_rad(_stats.aim_sensitivity)
	var up: float = turn.y if _stats.invert_y else -turn.y
	if Input.is_action_pressed(&"free_look"):
		var yaw_limit: float = deg_to_rad(_stats.look_yaw_limit)
		var pitch_limit: float = deg_to_rad(_stats.look_pitch_limit)
		look.x = clampf(look.x + up, -pitch_limit, pitch_limit)
		look.y = clampf(look.y - turn.x, -yaw_limit, yaw_limit)
		return
	_aim_yaw = wrapf(_aim_yaw - turn.x, -PI, PI)
	_aim_pitch += up
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


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_unit) or not _unit.alive:
		return
	_limit_aim() # The nose moves under a still mouse too.
	_input.aim = aim()
	_input.stick = Input.get_vector(&"pilot_roll_left", &"pilot_roll_right", &"pilot_pitch_down", &"pilot_pitch_up")
	_input.air_brake = Input.is_action_pressed(&"air_brake")
	_input.ability = Input.is_action_pressed(&"unit_ability")
	_issuer.pilot(_input)


## Keeps the aim within reach of the nose and short of straight up or down.
func _limit_aim() -> void:
	var pitch_limit: float = deg_to_rad(_stats.aim_pitch_limit)
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
