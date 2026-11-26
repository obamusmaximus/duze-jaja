class_name Landing
extends RefCounted
## A flyer's use of pads (carryalls their own, the rest helipads) (`docs/mechanics/airfield.md`): flying to an airfield on a land order, waiting its turn,
## coming down on a `Pad`, repairing there, and taking off again. A fixed wing flies in on its wings and lands and
## takes off like a hover type. A craft over or on its pad takes off before it does anything else. Simulation: the
## `Unit` steps it from `think` and the `OrderBrain` asks it what to do.

## NONE: nothing to do with pads. WAITING: every pad is taken. APPROACH: flying to its pad (or its gate). CLIMB_IN: at a
## deck pad's gate, climbing to the deck. ALIGN: sliding in to the hover point. DESCEND, DOWN, TAKEOFF: coming down,
## on the deck, climbing back. EXIT: sliding out from over a deck to its gate. DEPART: gaining speed before a pilot
## takes over.
enum Phase { NONE, WAITING, APPROACH, CLIMB_IN, ALIGN, DESCEND, DOWN, TAKEOFF, EXIT, DEPART }

## Within this of a height (metres) counts as being there.
const HEIGHT_SLACK: float = 0.4
## The eased drop slows to the touchdown speed over this many metres above the deck per m/s of descent rate.
const EASE_PER_SPEED: float = 0.35
## A fixed wing is ready for a pilot at this share of its slowest speed.
const READY_SPEED_SHARE: float = 1.0
## Within this of a gate, flat, counts as through it (metres).
const GATE_SLACK: float = 1.5

var unit: Unit
var phase: Phase = Phase.NONE
## The land order being flown is done: on the pad and fully repaired.
var finished: bool = false

var _field: Airfield
var _pad: Pad
## Called once the craft is clear and flying, for a pilot waiting to take over.
var _handback := Callable()


func _init(body: Unit) -> void:
	unit = body


## The airfield it is flying to, waiting at or sitting on, or null.
func airfield() -> Airfield:
	return _field


func is_down() -> bool:
	return phase == Phase.DOWN


## Over or on its pad, so it has to take off before it can go anywhere.
func holds_craft() -> bool:
	return phase in [Phase.ALIGN, Phase.DESCEND, Phase.DOWN, Phase.TAKEOFF, Phase.EXIT]


## Still on its way (it may fire at what is ahead).
func is_flying_in() -> bool:
	return phase in [Phase.WAITING, Phase.APPROACH, Phase.CLIMB_IN]


## The way it should face while it holds over or on its pad; zero while it flies.
func pad_facing() -> Vector3:
	return _pad.forward() if _pad != null and holds_craft() and phase != Phase.EXIT else Vector3.ZERO


## Sits the craft on `pad` of `field` at once, already landed (a carryall appearing on its pad).
func dock(field: Airfield, pad: Pad) -> void:
	_field = field
	_pad = pad
	phase = Phase.DOWN
	var deck: float = pad.position.y + pad.stats.landed_clearance
	unit.global_position = Vector3(pad.position.x, deck, pad.position.z)
	unit.rotation.y = pad.yaw
	unit.movement.altitude_override = deck
	unit.movement.autopilot.hold = pad.position
	unit.movement.autopilot.hold_speed = pad.stats.align_speed


## The brain's question before anything else, with its current order: true while the craft must get off its pad first
## (or is departing for a pilot), during which it takes no velocity from the brain.
func must_leave(order: Order) -> bool:
	if phase == Phase.TAKEOFF or phase == Phase.EXIT:
		return true
	if phase == Phase.DEPART:
		return order == null
	var stays: bool = order == null or (order.kind == Order.Kind.LAND and _field != null
			and order.airfield_id == _field.airfield_id)
	if stays:
		if order == null and phase in [Phase.WAITING, Phase.APPROACH, Phase.CLIMB_IN]:
			cancel() # The order was stopped on the way.
		elif order == null and phase == Phase.ALIGN:
			_start_takeoff()
		elif order == null and phase == Phase.DESCEND:
			_descend()
		return phase == Phase.TAKEOFF
	if holds_craft():
		_start_takeoff()
		return true
	if phase != Phase.NONE:
		cancel()
	return false


## One decision of a land order: returns the flat velocity wanted. `finished` says when the order is done.
func fly(order: Order, nav: UnitNavigator, delta: float) -> Vector3:
	finished = false
	if phase == Phase.NONE or phase == Phase.DEPART:
		_field = _find(order.airfield_id)
		if _field == null:
			finished = true
			return Vector3.ZERO
		_leave_pad_flight()
		phase = Phase.WAITING
	match phase:
		Phase.WAITING:
			_pad = _field.request_pad(unit.id)
			if _pad == null:
				nav.go_to(_field.holding_point(), unit.stats.arrive_distance)
				return nav.wanted_velocity(delta)
			phase = Phase.APPROACH
			return _approach(nav, delta)
		Phase.APPROACH:
			return _approach(nav, delta)
		Phase.CLIMB_IN:
			if _flat_distance(_pad.gate) <= GATE_SLACK and absf(unit.global_position.y - _pad.gate.y) < HEIGHT_SLACK:
				_align()
		Phase.ALIGN:
			var hover: Vector3 = _pad.hover_point()
			if _flat_distance(hover) < HEIGHT_SLACK and absf(unit.global_position.y - hover.y) < HEIGHT_SLACK:
				phase = Phase.DESCEND
				_descend()
		Phase.DESCEND:
			_descend()
		Phase.DOWN:
			finished = unit.health.current >= unit.stats.max_health
	return Vector3.ZERO


## The craft's own tick: repair on the deck, and takeoff, which goes on whatever the orders say.
func step(delta: float) -> void:
	match phase:
		Phase.DOWN:
			unit.health.repair(_field.stats.repair_rate * delta)
		Phase.TAKEOFF:
			if unit.global_position.y >= _pad.hover_point().y - HEIGHT_SLACK:
				if _pad.has_gate():
					phase = Phase.EXIT
					unit.movement.autopilot.hold = _pad.gate
					unit.movement.autopilot.hold_speed = _pad.stats.align_speed
				else:
					_clear_pad()
		Phase.EXIT:
			if _flat_distance(_pad.gate) <= GATE_SLACK:
				_clear_pad()
		Phase.DEPART:
			if _handback.is_valid() and _ready_for_pilot():
				var done: Callable = _handback
				_handback = Callable()
				phase = Phase.NONE
				done.call()


## A player wants the controls: `done` is called now if the craft is flying free, else once it has taken off and, for
## a fixed wing, picked up speed.
func hand_back(done: Callable) -> void:
	if holds_craft():
		_handback = done
		_start_takeoff()
		return
	if phase == Phase.DEPART:
		_handback = done
		return
	cancel()
	done.call()


## The pilot changed their mind: nobody is waiting for the controls any more.
func cancel_handback() -> void:
	_handback = Callable()
	if phase == Phase.DEPART:
		phase = Phase.NONE


## Drops it all at once and flies as usual. Only for a craft that isn't over or on a pad.
func cancel() -> void:
	if _field != null:
		_field.release(unit.id)
	_leave_pad_flight()
	_field = null
	_pad = null
	phase = Phase.NONE
	finished = false


func _approach(nav: UnitNavigator, delta: float) -> Vector3:
	var stats: PadStats = _pad.stats
	var autopilot: FlightAutopilot = unit.movement.autopilot
	var goal: Vector3 = _pad.gate if _pad.has_gate() else _pad.position
	var distance: float = _flat_distance(goal)
	var braking: float = unit.stats.speed * unit.stats.speed \
			/ (2.0 * unit.stats.flight_acceleration * UnitNavigator.BRAKE_MARGIN)
	if distance <= braking + stats.wing_brake_margin:
		autopilot.set_vtol(true)
	if _pad.has_gate():
		# Start up toward the deck early enough to arrive about level with it.
		var climb_time: float = absf(goal.y - unit.global_position.y) / maxf(unit.stats.flight_climb_rate, 0.1)
		if distance <= climb_time * unit.stats.speed + braking + stats.wing_brake_margin:
			unit.movement.altitude_override = goal.y
	if distance <= stats.align_radius:
		nav.stop()
		autopilot.set_vtol(true)
		autopilot.hold_speed = stats.align_speed
		autopilot.sink_rate = 0.0
		if _pad.has_gate():
			phase = Phase.CLIMB_IN
			autopilot.hold = goal
			unit.movement.altitude_override = goal.y
		else:
			_align()
		return Vector3.ZERO
	if nav.arrived:
		nav.stop() # Called there by the crowd rule while still short of the pad: go again.
	nav.go_to(goal, stats.align_radius * 0.5)
	return nav.wanted_velocity(delta)


## Slides in to the hover point over the pad.
func _align() -> void:
	phase = Phase.ALIGN
	unit.movement.autopilot.hold = _pad.position
	unit.movement.autopilot.hold_speed = _pad.stats.align_speed
	unit.movement.altitude_override = _pad.hover_point().y


## Down to the deck, easing off at the bottom.
func _descend() -> void:
	var stats: PadStats = _pad.stats
	var deck: float = _pad.position.y + stats.landed_clearance
	var left: float = unit.global_position.y - deck
	unit.movement.altitude_override = deck
	var eased: float = left / maxf(stats.descent_rate * EASE_PER_SPEED, 0.1)
	unit.movement.autopilot.sink_rate = clampf(eased, stats.touchdown_speed, maxf(stats.descent_rate, stats.touchdown_speed))
	if left <= 0.05:
		phase = Phase.DOWN


func _start_takeoff() -> void:
	if phase == Phase.TAKEOFF or phase == Phase.EXIT:
		return
	phase = Phase.TAKEOFF
	finished = false
	unit.movement.altitude_override = _pad.hover_point().y
	unit.movement.autopilot.sink_rate = 0.0


## At the hover point: the pad is free again and the craft flies as usual.
func _clear_pad() -> void:
	var departing: bool = _handback.is_valid()
	cancel()
	if departing:
		phase = Phase.DEPART


## Fast and high enough that the flight model can carry on without dropping.
func _ready_for_pilot() -> bool:
	var autopilot: FlightAutopilot = unit.movement.autopilot
	if not autopilot.is_fixed_wing():
		return true
	var flat := Vector2(autopilot.velocity.x, autopilot.velocity.z)
	return flat.length() >= unit.stats.flight_min_speed * READY_SPEED_SHARE - 0.1


## Gives the autopilot back its usual flight.
func _leave_pad_flight() -> void:
	var autopilot: FlightAutopilot = unit.movement.autopilot
	if autopilot == null:
		return
	autopilot.set_vtol(false)
	autopilot.hold = Vector3.INF
	autopilot.sink_rate = 0.0
	unit.movement.altitude_override = NAN


func _find(id: int) -> Airfield:
	for node: Node in unit.get_tree().get_nodes_in_group(&"airfields"):
		var field := node as Airfield
		if field.airfield_id == id and field.team == unit.team:
			return field
	return null


func _flat_distance(to: Vector3) -> float:
	return Vector2(to.x - unit.global_position.x, to.z - unit.global_position.z).length()
