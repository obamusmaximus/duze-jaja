class_name VisionContact
extends RefCounted
## What one team has on one enemy unit while it detects it, or is still losing it. Simulation.

## Whether the latest check detected it.
var seen: bool = false
## 0 to 1: rises while it is seen, falls while it isn't. Views fade by it.
var level: float = 0.0
## The team knows of it: from the moment `level` reaches 1 until it falls back to 0.
var known: bool = false
## The unit id (or 0) and the sensor (or null) that saw it last, tried first at the next check.
var observer_id: int = 0
var sensor: VisionSensor
var type: UnitStats
## The unit's team.
var team: int = 0
## Where it was and which way it faced at the last check that saw it.
var position := Vector3.ZERO
var yaw: float = 0.0
