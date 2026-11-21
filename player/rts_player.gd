class_name RtsPlayer
extends Node
## The local player's RTS view controls for one team: turns mouse gestures and keys into selection changes and
## orders. Left-click both selects and orders, decided on release (PointerInput): a box selects; a click on an own
## unit selects it; otherwise, with a selection, a click on ground moves and on an enemy attacks; without one, a
## click on an enemy inspects it. Right-click clears the selection (or cancels attack-move).
##
## Gestures are resolved on the next physics tick, where picking (GroundPick) is safe. View side: it changes the
## game only through the CommandIssuer.

@export var stats: PlayerControlStats

var _team: int
var _selection: Selection
## Gestures waiting for the next physics tick: Callables taking no arguments.
var _pending: Array[Callable] = []

@onready var _pointer: PointerInput = $PointerInput
@onready var _selection_control: SelectionControl = $SelectionControl
@onready var _groups: ControlGroups = $ControlGroups
@onready var _orders: OrderControl = $OrderControl
@onready var _box: SelectionBox = $BoxLayer/SelectionBox
@onready var _markers: Node3D = $Markers


func setup(team: int, selection: Selection, issuer: CommandIssuer, camera_rig: CameraRig) -> void:
	_team = team
	_selection = selection
	_pointer.setup(stats, _box)
	_selection_control.setup(team, selection)
	_groups.setup(stats, selection, camera_rig)
	_orders.setup(team, selection, issuer, stats, _markers)
	_pointer.left_clicked.connect(func(point: Vector2, double_click: bool) -> void:
		_pending.append(_resolve_click.bind(point, double_click)))
	_pointer.box_released.connect(func(rect: Rect2) -> void: _pending.append(_selection_control.select_box.bind(rect)))
	_pointer.right_clicked.connect(func(_point: Vector2) -> void: _pending.append(_on_right_click))


func _physics_process(_delta: float) -> void:
	if _selection == null:
		return
	for gesture: Callable in _pending:
		gesture.call()
	_pending.clear()
	_update_cursor()


func _resolve_click(point: Vector2, double_click: bool) -> void:
	var unit := GroundPick.object_under(get_viewport(), point) as Unit
	if unit and unit.team == _team and not _orders.attack_move_armed:
		_selection_control.click_unit(unit, double_click)
		return
	if _selection.is_empty():
		if unit:
			_selection_control.inspect(unit)
		return
	if unit and unit.is_enemy_of(_team):
		_orders.attack(unit)
		return
	var ground: Vector3 = GroundPick.ground_point(get_viewport(), point)
	if not ground.is_finite():
		return
	if _orders.attack_move_armed:
		_orders.attack_move(ground)
	else:
		_orders.move(ground)


func _on_right_click() -> void:
	if _orders.attack_move_armed:
		_orders.disarm()
	else:
		_selection_control.clear()


func _update_cursor() -> void:
	if _pointer.is_boxing():
		_orders.show_cursor(null, false)
		return
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var unit := GroundPick.object_under(get_viewport(), mouse) as Unit
	_orders.show_cursor(unit, GroundPick.ground_point(get_viewport(), mouse).is_finite())
