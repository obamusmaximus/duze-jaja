class_name LampSet
extends Node3D
## Visual only: the lamps of one thing (a unit's airframe, a pad, a hull), in this node's space. It only holds them;
## the level's `LampField` draws every set in one draw call, and only while the set is visible in the tree, so a
## hidden or freed owner takes its lamps with it. Colours are palette roles. Group: `lamp_sets`.

## How a lamp shines. BLINK is on for part of each period, STROBE flashes twice and goes dark.
enum Pattern { STEADY, BLINK, STROBE }

## Floats per lamp in `data`: position (3), colour (3), strength, size, smallest screen size, period, phase.
const STRIDE: int = 11

## The lamps, packed.
var data := PackedFloat32Array()
## Bumped on every change, so the field knows to read the set again.
var revision: int = 0
## Dims every lamp of the set, 0 to 1 (a unit fading out of view).
var fade: float = 1.0
## The field's cache of this set in the world (`LampField` only).
var cached := PackedFloat32Array()
var cached_transform := Transform3D()
var cached_revision: int = -1


func _init() -> void:
	add_to_group(&"lamp_sets")


## Adds a lamp at `at`: `size` metres across, never under `min_px` pixels, `strength` 0 to 1. A blinking or strobing
## lamp takes its `period` (seconds) and a `phase` (0 to 1 of the period).
func add(at: Vector3, color: Color, size: float, min_px: float, strength: float = 1.0,
		pattern: Pattern = Pattern.STEADY, period: float = 0.0, phase: float = 0.0) -> void:
	# The shader reads instance colours as linear values.
	var linear: Color = color.srgb_to_linear()
	var signed_period: float = 0.0
	if pattern == Pattern.BLINK:
		signed_period = period
	elif pattern == Pattern.STROBE:
		signed_period = -period
	data.append_array(PackedFloat32Array([at.x, at.y, at.z, linear.r, linear.g, linear.b, strength, size, min_px,
		signed_period, phase]))
	revision += 1


func set_fade(value: float) -> void:
	if value != fade:
		fade = value
		revision += 1


func clear() -> void:
	data.clear()
	revision += 1


func count() -> int:
	return data.size() / STRIDE
