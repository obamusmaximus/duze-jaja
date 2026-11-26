class_name HudCommands
extends RefCounted
## The link between HUD command buttons and the RTS controls, which own the orders: a module's button asks here and
## the controls act on it exactly as on the key; the controls report back what is armed so the button can show it.

## The ability button was pressed (the same as the `unit_ability` key).
signal ability_pressed
signal armed_changed

## A targeted ability is waiting for its click.
var ability_armed: bool = false:
	set(value):
		if value != ability_armed:
			ability_armed = value
			armed_changed.emit()
