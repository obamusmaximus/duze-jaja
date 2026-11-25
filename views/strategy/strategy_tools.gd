class_name StrategyTools
extends RefCounted
## What the strategist's next ground click will do: nothing, or put down a map marker of an armed kind (attack,
## guard, gather, scout, or the landing zone). Armed from the commands panel, spent by `StrategyControl`. View state
## only; the simulation never reads it.

signal changed

## The armed marker kind (`MapMarker.Kind`), or -1 for none.
var armed: int = -1


## Arms `kind`; arming the one already armed turns it off.
func arm(kind: MapMarker.Kind) -> void:
	armed = -1 if armed == kind else kind
	changed.emit()


func disarm() -> void:
	if armed != -1:
		armed = -1
		changed.emit()
