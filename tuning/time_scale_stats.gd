class_name TimeScaleStats
extends Resource
## Tunable numbers for the slow-time dev tool (debug/time_scale/). One .tres per preset
## (tuning/time_scale_default.tres), loaded by the DebugTimeScale autoload.

@export_group("Speeds")
## The game speeds (`Engine.time_scale`) the slower and faster keys step through, slowest first. Keep 1 in the list:
## the reset key returns to it.
@export var steps: PackedFloat32Array = PackedFloat32Array([0.1, 0.25, 0.5, 1.0, 2.0])
