class_name CockpitView
extends Node3D
## View side: the first-person view of the unit the local player inhabits (`docs/mechanics/cockpit.md`). `inhabit`
## (J) asks the `CommandIssuer` for the one selected unit, or to leave. Everything else follows the seat signals, so
## leaving, dying and being removed all end the same way: it flies the camera into the cockpit and back out to the
## RTS view where the unit was, takes the other views and their input away through the `ViewSwitcher`, and starts and
## stops `PilotControls`. The camera sits at the unit's cockpit mount and turns with the airframe.

enum State { OFF, ENTERING, IN, LEAVING }

## The switch toward the cockpit began, or back to the RTS view.
signal entering
signal leaving

const STATS: CockpitStats = preload("res://tuning/cockpit_default.tres")
const HUD_STATS: HelmetHudStats = preload("res://tuning/helmet_hud_default.tres")
const SOUND_STATS: FlightSoundStats = preload("res://tuning/flight_sound_default.tres")

var state: State = State.OFF
var controls := PilotControls.new()
var camera := Camera3D.new()

var _team: int
var _selection: Selection
var _issuer: CommandIssuer
var _views: ViewSwitcher
var _rts_rig: CameraRig
var _light: WorldLight
var _unit: Unit
var hud := HelmetHud.new()
var _feel := CockpitFeel.new()
var _sound := CockpitSound.new()
var _flight := ViewTransition.new()
## A still copy of whatever camera was showing when a switch began: where the flight starts from.
var _anchor := Camera3D.new()
var _listener := AudioListener3D.new()


func setup(team: int, selection: Selection, issuer: CommandIssuer, views: ViewSwitcher, rts_rig: CameraRig,
		light: WorldLight) -> void:
	_team = team
	_selection = selection
	_issuer = issuer
	_views = views
	_rts_rig = rts_rig
	_light = light
	# Posed every frame from interpolated transforms: never interpolated again.
	for own: Camera3D in [camera, _anchor]:
		own.top_level = true
		own.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(own)
	camera.name = "CockpitCamera"
	_anchor.name = "AnchorCamera"
	camera.cull_mask &= ~(WarTable.LAYER | BirdsEyePost.LAYER | BirdsEyeClouds.LAYER)
	camera.add_child(_listener)
	_flight.name = "Switch"
	add_child(_flight)
	_flight.camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_flight.finished.connect(_on_flight_finished)
	_flight.blend_changed.connect(_on_flight_blend)
	controls.name = "PilotControls"
	add_child(controls)
	controls.setup(STATS, issuer)
	_feel.setup(STATS)
	_sound.name = "CockpitSound"
	add_child(_sound)
	_sound.setup(SOUND_STATS, STATS)
	var layer := CanvasLayer.new()
	layer.layer = 8 # Over the world, under the HUD.
	add_child(layer)
	hud.name = "HelmetHud"
	layer.add_child(hud)
	hud.setup(HUD_STATS, SOUND_STATS, controls)
	issuer.seats.inhabited.connect(_on_inhabited)
	issuer.seats.released.connect(_on_released)
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if _issuer == null or not event.is_action_pressed(&"inhabit") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if _issuer.seats.unit_id_of(_team) != 0:
		_issuer.issue(Order.leave(_team))
	elif state == State.OFF and not _views.flying() and _views.view != ViewSwitcher.View.WAR_TABLE:
		var picked: Array[Unit] = _selection.units
		if picked.size() != 1 or not _issuer.issue(Order.inhabit(_team, picked[0].id)):
			Sfx.play_ui(&"ui_error")


func _process(delta: float) -> void:
	if is_instance_valid(_unit):
		_feel.step(delta, _unit.pilot_flight())
	_pose()


func _on_inhabited(team: int, unit: Unit) -> void:
	if team != _team:
		return
	_anchor_here()
	if state == State.OFF:
		_views.hand_over()
	_unit = unit
	state = State.ENTERING
	controls.start(unit)
	_feel.start(unit.pilot_flight())
	_sound.start(unit)
	hud.start(unit)
	set_process(true)
	_pose()
	_fly_to(camera, _light.environment())
	entering.emit()


func _on_released(team: int, unit: Unit, _reason: PilotSeats.Release) -> void:
	if team != _team or unit != _unit:
		return
	if not is_inside_tree():
		controls.stop() # The level is coming down: there is nothing to fly back to.
		return
	_anchor_here()
	state = State.LEAVING
	controls.stop()
	_sound.stop()
	hud.stop()
	set_process(false)
	_listener.clear_current()
	_rts_listener_current()
	unit.set_cockpit_occupied(false)
	_unit = null
	_rts_rig.focus_on(unit.ground_point(), true)
	_rts_rig.refresh()
	_fly_to(_rts_rig.get_camera(), _light.environment())
	leaving.emit()


## Copies the showing camera into the anchor, so a flight starts exactly from what is on screen (mid-flight too).
func _anchor_here() -> void:
	var showing: Camera3D = get_viewport().get_camera_3d()
	_anchor.global_transform = showing.global_transform
	_anchor.fov = showing.fov
	_anchor.near = showing.near
	_anchor.far = showing.far
	_anchor.keep_aspect = showing.keep_aspect
	_anchor.environment = showing.environment.duplicate() if showing.environment != null else _light.environment()


func _fly_to(target: Camera3D, environment: Environment) -> void:
	_flight.duration = STATS.transition_time
	_flight.set_ends(_anchor, target, _anchor.environment, environment)
	_flight.camera.cull_mask = camera.cull_mask
	_flight.settle(0.0)
	_flight.fly_to(1.0)


func _on_flight_blend(blend: float) -> void:
	if state == State.ENTERING and is_instance_valid(_unit):
		_unit.set_cockpit_occupied(blend >= STATS.hide_airframe_blend)
		# The HUD comes on over the last of the flight in, once the camera looks the way it will.
		hud.modulate.a = smoothstep(STATS.hide_airframe_blend, 1.0, blend)


func _on_flight_finished(_reached_end: bool) -> void:
	if state == State.ENTERING:
		state = State.IN
		_unit.set_cockpit_occupied(true)
		hud.modulate.a = 1.0
		camera.make_current()
		_listener.make_current()
	elif state == State.LEAVING:
		state = State.OFF
		_views.take_back()


## The cockpit camera: at the mount, turned with the airframe, then by the pilot's head and the shake.
func _pose() -> void:
	if not is_instance_valid(_unit):
		return
	var mount: Transform3D = _unit.cockpit_mount().get_global_transform_interpolated()
	var head := Basis.from_euler(Vector3(controls.look.x, controls.look.y, 0.0), EULER_ORDER_YXZ)
	camera.global_transform = Transform3D(mount.basis.orthonormalized() * head * _feel.shake, mount.origin)
	camera.fov = STATS.fov + _feel.fov_gain
	camera.near = STATS.near
	camera.far = STATS.far


func _rts_listener_current() -> void:
	for node: Node in _rts_rig.find_children("*", "AudioListener3D", false, false):
		(node as AudioListener3D).make_current()
