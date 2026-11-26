class_name OrderControl
extends Node
## Turns the player's order clicks and keys into `Order`s for the selection and sends them through the
## CommandIssuer. Holding `order_queue` (Alt) queues a waypoint; `order_attack_move` (A) arms attack-move for the next
## left click (orders themselves are right clicks); `order_stop` (S) stops; `unit_ability` (F, or the HUD's
## ability button) fires the main type's ability, or arms a targeted one for the next left click; a click on an own
## airfield or mothership pads with flyers selected lands them there, and `order_seek_airfield` (H) sends them to the nearest. Also the feedback: the cursor and a short marker where an order landed.
## View side: it only reads the selection and sends orders.

## Confirm is acid green; hostile orders are safety orange (`UiTokens`).
const MOVE_COLOR: Color = UiTokens.GREEN
const ATTACK_COLOR: Color = UiTokens.ORANGE
const ATTACK_MOVE_COLOR: Color = UiTokens.ORANGE
const ABILITY_COLOR: Color = UiTokens.GREEN

signal ability_armed_changed(armed: bool)

## The next left click aims the main type's targeted ability.
var ability_armed: bool = false:
	set(value):
		if value != ability_armed:
			ability_armed = value
			ability_armed_changed.emit(value)
## The next left click gives an attack-move.
var attack_move_armed: bool = false

var _team: int
var _selection: Selection
var _issuer: CommandIssuer
var _stats: PlayerControlStats
var _markers: Node3D
var _cursor: Input.CursorShape = Input.CURSOR_ARROW


func setup(team: int, selection: Selection, issuer: CommandIssuer, stats: PlayerControlStats, markers: Node3D) -> void:
	_team = team
	_selection = selection
	_issuer = issuer
	_stats = stats
	_markers = markers
	_selection.changed.connect(_on_selection_changed)
	_selection.main_changed.connect(func() -> void: ability_armed = false)


## Switched off with the RTS controls: nothing stays armed and the cursor goes back to the arrow.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED and _selection != null:
		disarm()
		_cursor = Input.CURSOR_ARROW
		Input.set_default_cursor_shape(_cursor)


func _unhandled_input(event: InputEvent) -> void:
	if _selection == null or _selection.is_empty(): # Input can arrive before `setup` (the level loads for a while).
		return
	if event.is_action_pressed(&"order_attack_move"):
		ability_armed = false
		attack_move_armed = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"unit_ability"):
		use_ability()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"order_seek_airfield"):
		seek_airfield()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"order_stop"):
		_issuer.issue(Order.stop(_team, _selection.ids()))
		disarm()
		get_viewport().set_input_as_handled()


## F: the selection's main type uses its ability (`Order.ability`; units without a ready one are skipped). A
## targeted ability is armed instead, if any of them is ready; F again puts it away.
func use_ability() -> void:
	if _selection == null or _selection.is_empty():
		return
	var able: AbilityStatus = AbilityStatus.of(_selection.main_units())
	attack_move_armed = false
	if ability_armed or able == null:
		ability_armed = false
	elif able.stats.targeting() != AbilityStats.Targeting.NONE:
		ability_armed = able.state == AbilityStatus.State.READY
	else:
		_issuer.issue(Order.ability(_team, _main_ids()))


## The armed ability's click: `hovered` is the unit under it (or null), `ground` the ground point (or
## `GroundPick.NONE`). A click it can't take (no unit, no ground, refused) leaves it armed.
func target_ability(hovered: Unit, ground: Vector3) -> void:
	var able: AbilityStatus = AbilityStatus.of(_selection.main_units())
	if able == null:
		ability_armed = false
		return
	var order: Order
	var marker_point: Vector3 = ground
	if able.stats.targeting() == AbilityStats.Targeting.UNIT:
		if hovered == null:
			return
		order = Order.ability(_team, _main_ids(), hovered.ground_point(), hovered.id)
		marker_point = hovered.ground_point()
	else:
		if not ground.is_finite():
			return
		order = Order.ability(_team, _main_ids(), ground)
	if _send(order, marker_point, ABILITY_COLOR):
		ability_armed = false


func move(point: Vector3) -> void:
	_send(Order.move(_team, _selection.ids(), point, _queued()), point, MOVE_COLOR)


func attack(target: Unit) -> void:
	_send(Order.attack(_team, _selection.ids(), target.id, _queued()), target.ground_point(), ATTACK_COLOR)


func attack_move(point: Vector3) -> void:
	attack_move_armed = false
	_send(Order.attack_move(_team, _selection.ids(), point, _queued()), point, ATTACK_MOVE_COLOR)


## Whether any selected unit can land on a helipad.
func can_land() -> bool:
	for unit: Unit in _selection.units:
		if unit.landing != null:
			return true
	return false


## A click on one of the team's airfields: the selection's helipad flyers land there, the rest move to the click.
func land_at(field: Airfield, point: Vector3) -> void:
	attack_move_armed = false
	var others := PackedInt32Array()
	for unit: Unit in _selection.units:
		if not field.serves(unit):
			others.append(unit.id)
	if not others.is_empty() and point.is_finite():
		_issuer.issue(Order.move(_team, others, point, _queued()))
	_send(Order.land(_team, _selection.ids(), field.airfield_id, _queued()), field.global_position, MOVE_COLOR)


## H: the selection's helipad flyers go to the nearest own airfield with room.
func seek_airfield() -> void:
	if not can_land():
		return
	attack_move_armed = false
	ability_armed = false
	if not _issuer.issue(Order.land(_team, _selection.ids(), 0, _queued())):
		return
	for unit: Unit in _selection.units:
		var order: Order = unit.orders.current()
		if unit.landing != null and order != null and order.kind == Order.Kind.LAND:
			_mark(order.target_position, MOVE_COLOR)
			return


func disarm() -> void:
	attack_move_armed = false
	ability_armed = false


## Sets the cursor for what an order click would do: `hovered` is the unit under the mouse (or null),
## `over_ground` whether there is ground under it and `over_airfield` whether that is an airfield it would land on.
func show_cursor(hovered: Unit, over_ground: bool, over_airfield: bool = false) -> void:
	var shape: Input.CursorShape = Input.CURSOR_ARROW
	if ability_armed:
		shape = Input.CURSOR_CROSS
	elif over_airfield and hovered == null and not attack_move_armed:
		shape = Input.CURSOR_POINTING_HAND
	elif not _selection.is_empty() and (hovered == null or hovered.is_enemy_of(_team)):
		if attack_move_armed or hovered:
			shape = Input.CURSOR_CROSS
		elif over_ground:
			shape = Input.CURSOR_MOVE
	if shape != _cursor:
		_cursor = shape
		Input.set_default_cursor_shape(shape)


func _send(order: Order, marker_point: Vector3, color: Color) -> bool:
	if not _issuer.issue(order):
		return false
	_mark(marker_point, color)
	return true


func _mark(point: Vector3, color: Color) -> void:
	var marker := OrderMarker.new()
	marker.setup(color, _stats.order_marker_seconds)
	_markers.add_child(marker)
	marker.global_position = point + Vector3.UP * 0.05


func _main_ids() -> PackedInt32Array:
	var ids := PackedInt32Array()
	for unit: Unit in _selection.main_units():
		ids.append(unit.id)
	return ids


func _queued() -> bool:
	return Input.is_action_pressed(&"order_queue")


func _on_selection_changed() -> void:
	ability_armed = false
	if _selection.is_empty():
		attack_move_armed = false
