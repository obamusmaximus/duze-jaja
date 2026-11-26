class_name HelmetHud
extends Control
## Visual only: the head-up display of an inhabited flyer, thin lines in one colour, drawn in screen space. It reads
## the flight once a frame into the values below, and its parts (`HelmetPart`) draw from them: the horizon and pitch
## ladder, the markers, the tapes, the warnings, the ability and the weapon. A jetpack type (the commando) shows its
## own parts instead: crosshair, scanner frame, track markers and the hover and surge indicators (`JetHudStats`). Marks that belong to the world are projected through whatever
## camera is showing, so they stay on it in free look too. Off until `start`.

## As of this frame.
var camera: Camera3D
## Where the nose points, and the airframe's right and up: from the cockpit mount as it is drawn.
var nose := Vector3.FORWARD
var right := Vector3.RIGHT
var up := Vector3.UP
## The flight's velocity, smoothed between ticks like the airframe is.
var velocity := Vector3.ZERO
## Metres above the sea, and from the underside of the airframe to the ground or sea below.
var altitude: float = 0.0
var clearance: float = 0.0
## Share of the stall angle in use, and where it is heading (`HelmetHudStats.trend_time` ahead).
var load_now: float = 0.0
var load_ahead: float = 0.0
var stall_warning: bool = false
var pull_up: bool = false
## Flashing warnings are lit.
var flash_on: bool = true

var stats: HelmetHudStats
## The jetpack parts' sizes (a var, so live tuning shows).
var jet_stats: JetHudStats = load("res://tuning/jet_hud_default.tres")
var sound_stats: FlightSoundStats
var controls: PilotControls
var unit: Unit
var flight: PilotFlight

var _parts: Array[HelmetPart] = []
var _autopilot := HelmetAutopilot.new()
var _velocity_before := Vector3.ZERO
var _velocity_after := Vector3.ZERO
var _load_rate: float = 0.0
var _flash_time: float = 0.0


func setup(hud_stats: HelmetHudStats, warning_stats: FlightSoundStats, pilot_controls: PilotControls) -> void:
	stats = hud_stats
	sound_stats = warning_stats
	controls = pilot_controls
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for part: HelmetPart in [HelmetLadder.new(), HelmetMarkers.new(), HelmetTapes.new(), HelmetWarnings.new(),
			HelmetAbility.new(), HelmetWeapon.new(), JetScanner.new(), JetTracks.new(), JetCrosshair.new(),
			JetStatus.new()]:
		add_child(part)
		part.setup(self)
		_parts.append(part)
	add_child(_autopilot)
	_autopilot.setup(self)
	stop()


func start(flown: Unit) -> void:
	unit = flown
	_follow(flown.pilot_flight())
	modulate.a = 0.0
	visible = true
	set_process(true)
	set_physics_process(true)


## Takes up `new_flight` (null while the autopilot has the unit), starting its smoothed values afresh.
func _follow(new_flight: PilotFlight) -> void:
	flight = new_flight
	_velocity_before = flight.model.velocity if flight != null else Vector3.ZERO
	_velocity_after = _velocity_before
	load_now = flight.model.stall_load() if flight != null else 0.0
	load_ahead = load_now
	_load_rate = 0.0
	stall_warning = false
	pull_up = false
	for part: HelmetPart in _parts:
		part.visible = flight != null and part.shows(flight)
		part.queue_redraw()
	_autopilot.queue_redraw()


func stop() -> void:
	unit = null
	flight = null
	visible = false
	set_process(false)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not _flying():
		return
	var model: PilotModel = flight.model
	_velocity_before = _velocity_after
	_velocity_after = model.velocity
	var load_new: float = model.stall_load()
	_load_rate = lerpf(_load_rate, (load_new - load_now) / delta, 1.0 - exp(-stats.trend_response * delta))
	load_now = load_new
	load_ahead = maxf(load_now + _load_rate * stats.trend_time, 0.0)
	stall_warning = FlightWarnings.stall(model, stall_warning, sound_stats)
	var half_height: float = unit.stats.height * 0.5
	# A hover lands on purpose, so only a jet is told to pull up.
	pull_up = not flight.hovering() and not flight.is_jetpack() and FlightWarnings.ground(model, unit.registry.map.air, half_height, stats)


func _process(delta: float) -> void:
	if is_instance_valid(unit) and unit.pilot_flight() != flight:
		_follow(unit.pilot_flight()) # The autopilot took over, or gave the controls back.
	if flight == null:
		_autopilot.queue_redraw()
	camera = get_viewport().get_camera_3d()
	if not _flying() or camera == null:
		return
	var mount: Basis = unit.cockpit_mount().get_global_transform_interpolated().basis.orthonormalized()
	nose = -mount.z
	right = mount.x
	up = mount.y
	velocity = _velocity_before.lerp(_velocity_after, Engine.get_physics_interpolation_fraction())
	var at: Vector3 = flight.model.position
	altitude = at.y - MapGrid.SEA_LEVEL
	clearance = maxf(at.y - unit.stats.height * 0.5 - unit.registry.map.air.ground_height(at), 0.0)
	_flash_time = fmod(_flash_time + delta * stats.flash_rate, 1.0)
	flash_on = _flash_time < 0.65
	for part: HelmetPart in _parts:
		part.queue_redraw()


func _flying() -> bool:
	return flight != null and is_instance_valid(unit) and unit.alive
