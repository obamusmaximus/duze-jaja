class_name Pad
extends RefCounted
## A landing spot for one craft at a time: where it is, which way a craft on it faces, the hover point above it that
## landings come down from and takeoffs climb back to, and who holds it. Its owner (an `Airfield`; the mothership
## later) places it and hands it out; the craft flies itself there (`Landing`). Simulation data, no nodes.

## The middle of the deck under the pad, in the world.
var position := Vector3.ZERO
## The heading (radians) of a craft sitting on it.
var yaw: float = 0.0
var stats: PadStats
## For a pad up on a deck (a mothership's): the point out beyond the hull, level with the hover point, that a craft
## climbs to before it slides in over the deck, and leaves by. `Vector3.INF` for a pad on the ground.
var gate := Vector3.INF

## The id of the unit that has it, or 0.
var _holder: int = 0


func _init(at: Vector3, facing: float, pad_stats: PadStats) -> void:
	position = at
	yaw = facing
	stats = pad_stats


## The point above the pad.
func hover_point() -> Vector3:
	return position + Vector3.UP * stats.hover_height


func has_gate() -> bool:
	return gate.is_finite()


## The way a craft on it faces: a flat unit vector.
func forward() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, yaw)


func is_free() -> bool:
	return _holder == 0


## The id of the unit that has it, or 0.
func holder() -> int:
	return _holder


## Takes the pad for `unit_id`. False if another unit has it.
func reserve(unit_id: int) -> bool:
	if _holder != 0 and _holder != unit_id:
		return false
	_holder = unit_id
	return true


## Frees the pad if `unit_id` has it.
func release(unit_id: int) -> void:
	if _holder == unit_id:
		_holder = 0
