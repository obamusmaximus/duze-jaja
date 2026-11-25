class_name ViewSwitcher
extends Node
## View side: switches the local player between the RTS view, the bird's-eye view and the war table
## (`docs/mechanics/birds_eye.md`, `war_table.md`). Only cameras and input change hands: every view that is off has
## its rig disabled, and the player controls are on only in the RTS view; the simulation never notices.
## `toggle_strategy_view` (V) flies between the RTS and bird's-eye views; `toggle_war_table` (B) cuts to the table and
## back to the view it was opened from. The views are separate modes: zooming never changes view. `view` is the view being shown or flown to; `flying()` says a flight is under way (input is off then, and
## the same key turns the flight round). A first-person view takes the screen with `hand_over` and gives it back with
## `take_back` (`CockpitView`): in between, every view and key here is off.

enum View { RTS, BIRDS_EYE, WAR_TABLE }

signal view_changed(view: View)

var view: View = View.RTS
## Another view has the screen (`hand_over`).
var held: bool = false

var _table_stats: WarTableStats
var _stats: BirdsEyeStats
var _rts_rig: CameraRig
var _table: WarTable
var _birds: BirdsEye
var _player: RtsPlayer
var _flight: ViewTransition
## The view the table was opened from, and returns to.
var _return_view: View = View.RTS


func setup(table_stats: WarTableStats, stats: BirdsEyeStats, rts_rig: CameraRig, table: WarTable, birds: BirdsEye,
		light: WorldLight, player: RtsPlayer) -> void:
	_table_stats = table_stats
	_stats = stats
	_rts_rig = rts_rig
	_table = table
	_birds = birds
	_player = player
	for rig: CameraRig in [_rts_rig, _birds.rig]:
		rig.get_camera().cull_mask &= ~WarTable.LAYER
	_rts_rig.get_camera().cull_mask &= ~BirdsEyePost.LAYER
	_table.rig.get_camera().cull_mask &= ~BirdsEyePost.LAYER
	_flight = ViewTransition.new()
	_flight.name = "Flight"
	add_child(_flight)
	_flight.duration = _stats.transition_time
	_flight.set_ends(_rts_rig.get_camera(), _birds.rig.get_camera(), light.environment(), _birds.environment)
	_birds.post.attach(_flight.camera)
	_birds.clouds.attach(_flight.camera)
	_flight.blend_changed.connect(_birds.apply_blend)
	_flight.finished.connect(_on_flight_finished)
	_rts_rig.set_active(true) # The other rigs' own cameras took over when they were made.


func _unhandled_input(event: InputEvent) -> void:
	if held or flying():
		return # Another view has the screen, or a flight finishes first.
	if event.is_action_pressed(&"toggle_strategy_view"):
		switch_to(View.RTS if view == View.BIRDS_EYE else View.BIRDS_EYE)
	elif event.is_action_pressed(&"toggle_war_table"):
		switch_to(_return_view if view == View.WAR_TABLE else View.WAR_TABLE)


func flying() -> bool:
	return _flight != null and _flight.flying()


## Gives the screen to another view: every rig and the RTS controls go off, and the state falls back to the RTS view
## (the strategy views' controls close with it). The caller makes its own camera current. The far sea stays up, so
## a view that looks to the horizon never sees past the map.
func hand_over() -> void:
	if flying():
		_flight.settle(1.0 if view == View.BIRDS_EYE else 0.0)
	held = true
	for rig: CameraRig in [_rts_rig, _birds.rig, _table.rig]:
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


## Goes to `next` (flying between the RTS and bird's-eye views, cutting to or from the table), at the current focus or
## at `focus` (x, z).
func switch_to(next: View, focus: Vector2 = Vector2.INF) -> void:
	if held or next == view:
		return
	var previous: View = view
	if flying():
		# A flight in progress: the table cuts straight to where it was heading; the other view turns it round.
		if next == View.WAR_TABLE:
			_flight.settle(1.0 if view == View.BIRDS_EYE else 0.0)
			_arrive(view)
		else:
			view = next
			_flight.fly_to(1.0 if next == View.BIRDS_EYE else 0.0)
			view_changed.emit(view)
			return
	if next == View.WAR_TABLE:
		_return_view = previous
		_cut_to(next, _rig_of(previous).focus_point())
	elif previous == View.WAR_TABLE:
		_cut_to(next, _table.rig.focus_point() if not focus.is_finite() else Vector3(focus.x, 0.0, focus.y))
	else:
		_start_flight(previous, next, focus)
	view = next
	view_changed.emit(view)


func _rig_of(of: View) -> CameraRig:
	match of:
		View.BIRDS_EYE:
			return _birds.rig
		View.WAR_TABLE:
			return _table.rig
	return _rts_rig


## Turns every rig off but `next`'s, which starts at `at`.
func _cut_to(next: View, at: Vector3) -> void:
	for rig: CameraRig in [_rts_rig, _birds.rig, _table.rig]:
		rig.set_active(false)
	var to_rig: CameraRig = _rig_of(next)
	to_rig.focus_on(at, true)
	_flight.settle(1.0 if next == View.BIRDS_EYE else 0.0)
	_arrive(next)


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
	for rig: CameraRig in [_rts_rig, _birds.rig, _table.rig]:
		rig.set_active(false)
	_rig_of(at_view).set_active(true)
	_player.process_mode = Node.PROCESS_MODE_INHERIT if at_view == View.RTS else Node.PROCESS_MODE_DISABLED
	_birds.set_shown(at_view == View.BIRDS_EYE or (at_view == View.WAR_TABLE and _return_view == View.BIRDS_EYE))
	_birds.apply_blend(1.0 if at_view == View.BIRDS_EYE else 0.0)
