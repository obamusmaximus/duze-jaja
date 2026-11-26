class_name ViewSwitcher
extends Node
## View side: switches the local player between the RTS view and the bird's-eye view (`docs/mechanics/birds_eye.md`).
## Only cameras and input change hands: the view that is off has its rig disabled, and the player controls are on only
## in the RTS view; the simulation never notices. `toggle_strategy_view` (V) flies between the two. The views are
## separate modes: zooming never changes view. `view` is the view being shown or flown to; `flying()` says a flight
## is under way (input is off then, and the same key turns the flight round). A first-person view takes the screen
## with `hand_over` and gives it back with `take_back` (`CockpitView`): in between, every view and key here is off.

enum View { RTS, BIRDS_EYE }

signal view_changed(view: View)

var view: View = View.RTS
## Another view has the screen (`hand_over`).
var held: bool = false

var _stats: BirdsEyeStats
var _rts_rig: CameraRig
var _birds: BirdsEye
var _player: RtsPlayer
var _flight: ViewTransition


func setup(stats: BirdsEyeStats, rts_rig: CameraRig, birds: BirdsEye, light: WorldLight, player: RtsPlayer) -> void:
	_stats = stats
	_rts_rig = rts_rig
	_birds = birds
	_player = player
	_rts_rig.get_camera().cull_mask &= ~BirdsEyePost.LAYER
	_flight = ViewTransition.new()
	_flight.name = "Flight"
	add_child(_flight)
	_flight.duration = _stats.transition_time
	_flight.set_ends(_rts_rig.get_camera(), _birds.rig.get_camera(), light.environment(), _birds.environment)
	_birds.post.attach(_flight.camera)
	_birds.clouds.attach(_flight.camera)
	_flight.blend_changed.connect(_birds.apply_blend)
	_flight.finished.connect(_on_flight_finished)
	_rts_rig.set_active(true) # The other rig's own camera took over when it was made.


func _unhandled_input(event: InputEvent) -> void:
	if held or flying():
		return # Another view has the screen, or a flight finishes first.
	if event.is_action_pressed(&"toggle_strategy_view"):
		switch_to(View.RTS if view == View.BIRDS_EYE else View.BIRDS_EYE)


func flying() -> bool:
	return _flight != null and _flight.flying()


## Gives the screen to another view: every rig and the RTS controls go off, and the state falls back to the RTS view
## (the strategy view's controls close with it). The caller makes its own camera current. The far sea stays up, so
## a view that looks to the horizon never sees past the map.
func hand_over() -> void:
	if flying():
		_flight.settle(1.0 if view == View.BIRDS_EYE else 0.0)
	held = true
	for rig: CameraRig in [_rts_rig, _birds.rig]:
		rig.set_active(false)
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_birds.apply_blend(0.0)
	_birds.set_shown(true)
	if view != View.RTS:
		view = View.RTS
		view_changed.emit(view)


## Takes the screen back, into the RTS view at its rig's focus.
func take_back() -> void:
	held = false
	view = View.RTS
	_arrive(View.RTS)
	view_changed.emit(view)


## Flies to `next`, arriving at the current focus or at `focus` (x, z). A flight in progress turns round.
func switch_to(next: View, focus: Vector2 = Vector2.INF) -> void:
	if held or next == view:
		return
	if flying():
		_flight.fly_to(1.0 if next == View.BIRDS_EYE else 0.0)
	else:
		_start_flight(view, next, focus)
	view = next
	view_changed.emit(view)


func _rig_of(of: View) -> CameraRig:
	return _birds.rig if of == View.BIRDS_EYE else _rts_rig


func _start_flight(from: View, to: View, focus: Vector2) -> void:
	var from_rig: CameraRig = _rig_of(from)
	var to_rig: CameraRig = _rig_of(to)
	var at: Vector3 = from_rig.focus_point() if not focus.is_finite() else Vector3(focus.x, 0.0, focus.y)
	to_rig.focus_on(at, true)
	to_rig.set_yaw(from_rig.yaw())
	if to == View.BIRDS_EYE:
		to_rig.set_distance(to_rig.stats.default_distance)
	from_rig.refresh()
	to_rig.refresh()
	from_rig.set_active(false)
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_birds.set_shown(true)
	_flight.fly_to(1.0 if to == View.BIRDS_EYE else 0.0)


## A flight ended (or was settled) at `reached`'s end: that rig takes over.
func _on_flight_finished(reached_end: bool) -> void:
	_arrive(View.BIRDS_EYE if reached_end else View.RTS)


func _arrive(at_view: View) -> void:
	for rig: CameraRig in [_rts_rig, _birds.rig]:
		rig.set_active(false)
	_rig_of(at_view).set_active(true)
	_player.process_mode = Node.PROCESS_MODE_INHERIT if at_view == View.RTS else Node.PROCESS_MODE_DISABLED
	_birds.set_shown(at_view == View.BIRDS_EYE)
	_birds.apply_blend(1.0 if at_view == View.BIRDS_EYE else 0.0)
