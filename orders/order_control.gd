class_name OrderControl
extends Node
## Turns the player's order clicks and keys into `Order`s for the selection and sends them through the
## CommandIssuer. Holding `order_queue` (Alt) queues a waypoint; `order_attack_move` (A) arms attack-move for the next
## left click (orders themselves are right clicks); `order_stop` (S) stops. Also the feedback: the cursor and a short marker where an order landed.
## View side: it only reads the selection and sends orders.

## Confirm is acid green; hostile orders are safety orange (`UiTokens`).
const MOVE_COLOR: Color = UiTokens.GREEN
const ATTACK_COLOR: Color = UiTokens.ORANGE
const ATTACK_MOVE_COLOR: Color = UiTokens.ORANGE

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


func _unhandled_input(event: InputEvent) -> void:
	if _selection.is_empty():
		return
	if event.is_action_pressed(&"order_attack_move"):
		attack_move_armed = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"order_stop"):
		_issuer.issue(Order.stop(_team, _selection.ids()))
		attack_move_armed = false
		get_viewport().set_input_as_handled()


func move(point: Vector3) -> void:
	_send(Order.move(_team, _selection.ids(), point, _queued()), point, MOVE_COLOR)


func attack(target: Unit) -> void:
	_send(Order.attack(_team, _selection.ids(), target.id, _queued()), target.global_position, ATTACK_COLOR)


func attack_move(point: Vector3) -> void:
	attack_move_armed = false
	_send(Order.attack_move(_team, _selection.ids(), point, _queued()), point, ATTACK_MOVE_COLOR)


func disarm() -> void:
	attack_move_armed = false


## Sets the cursor for what an order click would do: `hovered` is the unit under the mouse (or null) and
## `over_ground` whether there is ground under it.
func show_cursor(hovered: Unit, over_ground: bool) -> void:
	var shape: Input.CursorShape = Input.CURSOR_ARROW
	if not _selection.is_empty() and (hovered == null or hovered.is_enemy_of(_team)):
		if attack_move_armed or hovered:
			shape = Input.CURSOR_CROSS
		elif over_ground:
			shape = Input.CURSOR_MOVE
	if shape != _cursor:
		_cursor = shape
		Input.set_default_cursor_shape(shape)


func _send(order: Order, marker_point: Vector3, color: Color) -> void:
	if not _issuer.issue(order):
		return
	var marker := OrderMarker.new()
	marker.setup(color, _stats.order_marker_seconds)
	_markers.add_child(marker)
	marker.global_position = marker_point + Vector3.UP * 0.05


func _queued() -> bool:
	return Input.is_action_pressed(&"order_queue")


func _on_selection_changed() -> void:
	if _selection.is_empty():
		attack_move_armed = false
