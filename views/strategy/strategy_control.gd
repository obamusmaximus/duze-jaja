class_name StrategyControl
extends Node
## The strategist's mouse in the bird's-eye view (`docs/mechanics/rts_controls.md`), where the
## RTS player controls are off. Left click: put down the armed map marker, else pick the figure under the cursor
## (a squad, unit, carryall; own team only) and select its units through `Selection`; empty ground clears. Right
## click (without a drag, which pans): disarm, else take a marker away, else send the selection to the ground or at
## an enemy figure. Owns the on-screen `StrategyOverlay` (markers, outlines). Picking is in screen space against the
## figures, so it needs no physics. View side: it changes the game only through the `CommandIssuer`.

signal playtest_event(event: StringName, data: Dictionary)

static var control_stats: StrategyControlStats = preload("res://tuning/strategy_control_default.tres")

var _team: int
var _selection: Selection
var _issuer: CommandIssuer
var _markers: MapMarkers
var _tools: StrategyTools
var _views: ViewSwitcher
var _projector := StrategyProjector.new()
var _overlay := StrategyOverlay.new()
var _units: UnitRegistry
var _since_hover: float = INF
var _right_down: bool = false
var _right_start: Vector2
var _right_moved: bool = false


func setup(team: int, selection: Selection, issuer: CommandIssuer, markers: MapMarkers, tools: StrategyTools,
		views: ViewSwitcher, heights: TerrainHeights) -> void:
	_team = team
	_selection = selection
	_issuer = issuer
	_markers = markers
	_tools = tools
	_views = views
	_projector.heights = heights
	var layer := CanvasLayer.new()
	layer.name = "OverlayLayer"
	layer.layer = 6 # Above the blips (5), below the HUD (10).
	add_child(layer)
	_overlay.name = "Overlay"
	layer.add_child(_overlay)
	_overlay.setup(control_stats, _projector, selection, markers, tools, team)
	_overlay.visible = false
	views.view_changed.connect(_on_view_changed)


func overlay() -> StrategyOverlay:
	return _overlay


func is_active() -> bool:
	return _views != null and _views.view == ViewSwitcher.View.BIRDS_EYE and not _views.flying()


func _on_view_changed(view: ViewSwitcher.View) -> void:
	if view == ViewSwitcher.View.RTS:
		_tools.disarm()
		_overlay.hover_index = -1


func _process(delta: float) -> void:
	var on: bool = is_active()
	if _overlay.visible != on:
		_overlay.visible = on
		_since_hover = INF
	if not on:
		return
	_since_hover += delta
	if _since_hover >= 1.0 / control_stats.hover_hz:
		_since_hover = 0.0
		_overlay.refresh()
		var over_hud: bool = get_viewport().gui_get_hovered_control() != null
		_overlay.hover_index = -1 if over_hud else _pick(get_viewport().get_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if not is_active():
		return
	if event is InputEventMouseMotion and _right_down:
		if (event as InputEventMouseMotion).position.distance_to(_right_start) > control_stats.click_slop_px:
			_right_moved = true
	elif event is InputEventMouseButton:
		var point: Vector2 = (event as InputEventMouseButton).position
		if event.is_action_pressed(&"select"):
			_left_click(point)
		elif event.is_action_pressed(&"order_click"):
			_right_down = true
			_right_start = point
			_right_moved = false
		elif event.is_action_released(&"order_click") and _right_down:
			_right_down = false
			if not _right_moved:
				_right_click(point)


func _left_click(point: Vector2) -> void:
	if _tools.armed != -1:
		var ground: Vector3 = _projector.ground_at(get_viewport(), point)
		if ground.is_finite():
			_place(_tools.armed as MapMarker.Kind, ground)
		return
	_overlay.refresh()
	var index: int = _pick(point)
	var adding: bool = Input.is_action_pressed(&"select_add")
	if index < 0:
		if not adding and _projector.ground_at(get_viewport(), point).is_finite():
			_selection.clear()
		return
	var figures: StrategyFigures = _overlay.figures
	if figures.teams[index] != _team:
		var enemy: Array[Unit] = _units_of(figures.members[index])
		if enemy.size() == 1: # One unit shows in the HUD; a squad figure only raises the event.
			_selection.inspect(enemy[0])
		playtest_event.emit(&"inspect", {"kind": figures.kinds[index], "team": figures.teams[index]})
		return
	var picked: Array[Unit] = _units_of(figures.members[index])
	if picked.is_empty(): # A mothership: nothing to select yet.
		playtest_event.emit(&"pick_mothership", {"team": _team})
		return
	if adding:
		_selection.add(picked)
	else:
		_selection.set_units(picked)
	playtest_event.emit(&"strategy_select", {"kind": figures.kinds[index], "ids": _selection.ids()})


func _right_click(point: Vector2) -> void:
	if _tools.armed != -1:
		_tools.disarm()
		return
	var marker: MapMarker = _marker_near(point)
	if marker != null:
		_issuer.issue(Order.clear_marker(_team, marker.id))
		return
	if _selection.is_empty():
		return
	_overlay.refresh()
	var index: int = _pick(point)
	var queued: bool = Input.is_action_pressed(&"order_queue")
	if index >= 0 and _overlay.figures.teams[index] != _team:
		var target: PackedInt32Array = _overlay.figures.members[index]
		if not target.is_empty():
			_issuer.issue(Order.attack(_team, _selection.ids(), target[0], queued))
		return
	var ground: Vector3 = _projector.ground_at(get_viewport(), point)
	if ground.is_finite():
		_issuer.issue(Order.move(_team, _selection.ids(), ground, queued))


## Puts the armed marker at `ground`. The landing zone also sends selected loaded carryalls to deliver there.
func _place(kind: MapMarker.Kind, ground: Vector3) -> void:
	if not _issuer.issue(Order.place_marker(_team, kind, ground)):
		return
	if kind == MapMarker.Kind.LZ and not _selection.is_empty():
		_issuer.issue(Order.deliver(_team, _selection.ids(), ground))
	if not Input.is_action_pressed(&"select_add"):
		_tools.disarm()


## The figure whose pick radius holds `point` and whose centre is nearest (scaled by that radius), or -1.
func _pick(point: Vector2) -> int:
	var figures: StrategyFigures = _overlay.figures
	var best: int = -1
	var best_score: float = 1.0
	for i: int in figures.size():
		if not figures.knowns[i]:
			continue
		var at: Vector2 = _projector.to_screen(get_viewport(), figures.positions[i])
		if not at.is_finite():
			continue
		var radius: float = control_stats.pick_radius_px * (control_stats.ship_pick_scale if figures.kinds[i] == StrategyFigures.Kind.MOTHERSHIP else 1.0)
		var score: float = at.distance_to(point) / radius
		if score < best_score:
			best_score = score
			best = i
	return best


func _marker_near(point: Vector2) -> MapMarker:
	var best: MapMarker = null
	var best_distance: float = control_stats.marker_clear_px
	for marker: MapMarker in _markers.of_team(_team):
		var at: Vector2 = _projector.to_screen(get_viewport(), marker.position)
		if at.is_finite() and at.distance_to(point) < best_distance:
			best_distance = at.distance_to(point)
			best = marker
	return best


func _units_of(ids: PackedInt32Array) -> Array[Unit]:
	if _units == null:
		_units = get_tree().get_first_node_in_group(&"unit_registry") as UnitRegistry
	var found: Array[Unit] = []
	for id: int in ids:
		var unit: Unit = _units.get_unit(id)
		if unit:
			found.append(unit)
	return found
