class_name DeckAirfield
extends Airfield
## Pads on a mothership's deck (`docs/mechanics/airfield.md`): its carryall pads, its helipads or its Explorer pad. The same pad
## handing, landing and repair as a ground `Airfield`, but there is no deck to build, nothing on the map grid and no
## platform on the air layer (flyers pass under the hull). Each pad has a gate beyond the hull's side toward the
## atoll: a craft climbs there, slides in level over the deck, and leaves the same way. Placed once, where the
## mothership hovers at level load. Simulation.

var _ship: Mothership


## Puts a pad on each of `ship`'s markers `marker_name`0..`count`-1, facing `yaw`, and joins the match.
func setup_on_deck(ship: Mothership, marker_name: String, count: int, pad_stats: PadStats, yaw: float,
		registry: UnitRegistry, listed: bool = true) -> void:
	if listed: # Unlisted (the Explorer pad): no land order, click or "nearest airfield" ever finds it.
		add_to_group(&"airfields")
	_ship = ship
	team = ship.team
	var middle := Vector3.ZERO
	for i: int in count:
		var at: Vector3 = ship.marker_position("%s%d" % [marker_name, i])
		var pad := Pad.new(at, yaw, pad_stats)
		pad.gate = ship.side_point(at.z, ship.stats.gate_margin, pad.hover_point().y)
		pads.append(pad)
		middle += at
	if pads.is_empty():
		return
	global_position = middle / float(pads.size())
	_deck = global_position.y
	_area = Rect2(Vector2(pads[0].position.x, pads[0].position.z), Vector2.ZERO)
	for pad: Pad in pads:
		_area = _area.expand(Vector2(pad.position.x, pad.position.z))
	_area = _area.grow(ship.stats.pad_pick_margin)
	registry.unit_removed.connect(func(unit: Unit) -> void: release(unit.id))


## Out beyond the gates, over the sea.
func holding_point() -> Vector3:
	var at: Vector3 = _ship.side_point(global_position.z, _ship.stats.gate_margin + stats.holding_distance, 0.0)
	return at
