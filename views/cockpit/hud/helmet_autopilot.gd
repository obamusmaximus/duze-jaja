class_name HelmetAutopilot
extends HelmetPart
## Visual only: the one thing the helmet HUD shows while the autopilot has the unit (flying to an airfield, sitting
## on a pad, taking off): what it is doing and the key that takes the controls back.


## It draws exactly when the other parts don't (there is no flight to read).
func _draw() -> void:
	if hud == null or hud.flight != null or hud.unit == null or not is_instance_valid(hud.unit):
		return
	var at := Vector2(size.x * 0.5, size.y * 0.72)
	var health: float = hud.unit.health.fraction()
	text(at, "AUTOPILOT  %s" % _doing(), HORIZONTAL_ALIGNMENT_CENTER, UiTokens.HUD_LINE, &"LabelHeading")
	text(at + Vector2(0.0, 38.0), "HULL %d%%" % floori(health * 100.0))
	var explorer: Explorer = hud.unit.explorer
	if explorer != null:
		if explorer.can_toggle():
			_hint(at, &"unit_ability", "PACK UP")
	else:
		_hint(at, &"order_seek_airfield", "TAKE THE CONTROLS")


func _hint(at: Vector2, action: StringName, does: String) -> void:
	var keys: Array[InputEvent] = InputMap.action_get_events(action)
	if not keys.is_empty():
		text(at + Vector2(0.0, 66.0), "%s  %s" % [keys[0].as_text().replace(" - Physical", "").to_upper(), does])


func _doing() -> String:
	if hud.unit.explorer != null:
		return String(Explorer.State.keys()[hud.unit.explorer.state])
	var order: Order = hud.unit.orders.current()
	if order != null and order.kind == Order.Kind.DELIVER:
		return "DEPLOYING"
	if hud.unit.landing == null: # A jetpack type uses no pads.
		return ""
	match hud.unit.landing.phase:
		Landing.Phase.WAITING:
			return "WAITING FOR A PAD"
		Landing.Phase.APPROACH:
			return "TO THE PADS"
		Landing.Phase.CLIMB_IN, Landing.Phase.ALIGN, Landing.Phase.DESCEND:
			return "LANDING"
		Landing.Phase.DOWN:
			return "ON THE PAD"
		Landing.Phase.TAKEOFF, Landing.Phase.EXIT, Landing.Phase.DEPART:
			return "TAKING OFF"
	return ""
