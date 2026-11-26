class_name RtsPlayer
extends Node
## The local player's RTS view controls for one team: turns mouse gestures and keys into selection changes and
## orders. Left-click selects, right-click orders (the StarCraft scheme), both decided on release (PointerInput): a box
## selects; a click on an own unit selects it; a click on an enemy inspects it, on ground clears the selection.
## A right click with a selection moves (ground) or attacks (enemy); with no selection it only cancels attack-move.
## A click, left or right, on an own airfield with a flyer that uses helipads selected lands it there.
## Attack-move, once armed, takes the next left click, and so does a targeted ability (a right click cancels it).
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
	_pointer.right_clicked.connect(func(point: Vector2) -> void: _pending.append(_resolve_order.bind(point)))


## Wires the HUD's command buttons to the same actions as their keys.
func bind_hud(commands: HudCommands) -> void:
	commands.ability_pressed.connect(_orders.use_ability)
	_orders.ability_armed_changed.connect(func(armed: bool) -> void: commands.ability_armed = armed)


func _physics_process(_delta: float) -> void:
	if _selection == null:
		return
	for gesture: Callable in _pending:
		gesture.call()
	_pending.clear()
	_update_cursor()


func _resolve_click(point: Vector2, double_click: bool) -> void:
	var unit: Unit = _unit_under(point)
	if _orders.ability_armed:
		_orders.target_ability(unit, GroundPick.ground_point(get_viewport(), point))
		return
	if _orders.attack_move_armed and not _selection.is_empty():
		_order_at(unit, point)
		return
	var field: Airfield = null if unit != null else _landing_field_under(point)
	if field != null:
		_orders.land_at(field, GroundPick.ground_point(get_viewport(), point))
	elif unit and unit.team == _team:
		_selection_control.click_unit(unit, double_click)
	elif unit:
		_selection_control.inspect(unit)
	elif GroundPick.ground_point(get_viewport(), point).is_finite():
		_selection_control.clear()


func _resolve_order(point: Vector2) -> void:
	if _orders.ability_armed:
		_orders.disarm()
		return
	if _selection.is_empty():
		_orders.disarm()
		return
	var unit: Unit = _unit_under(point)
	var field: Airfield = null if unit != null or _orders.attack_move_armed else _landing_field_under(point)
	if field != null:
		_orders.land_at(field, GroundPick.ground_point(get_viewport(), point))
	else:
		_order_at(unit, point)


## Gives the selection an order at a screen point: attack an enemy there, else move (or attack-move when armed).
func _order_at(unit: Unit, point: Vector2) -> void:
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


func _unit_under(point: Vector2) -> Unit:
	return GroundPick.object_under(get_viewport(), point, stats.flyer_pick_min_px) as Unit


## The own airfield under a screen point, if the selection has something that can land on it; else null.
func _landing_field_under(point: Vector2) -> Airfield:
	if _selection.is_empty() or not _orders.can_land():
		return null
	var field: Airfield = GroundPick.airfield_under(get_viewport(), point)
	return field if field != null and field.team == _team else null


func _update_cursor() -> void:
	if _pointer.is_boxing():
		_orders.show_cursor(null, false)
		return
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var unit: Unit = _unit_under(mouse)
	_orders.show_cursor(unit, GroundPick.ground_point(get_viewport(), mouse).is_finite(),
			_landing_field_under(mouse) != null)
