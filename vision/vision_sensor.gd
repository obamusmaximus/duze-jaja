class_name VisionSensor
extends RefCounted
## A sensor that is not a unit: an airfield's or a mothership's. It reads its place and numbers live, so a moved
## mothership or a retuned range applies at once. Simulation.

var team: int
var body: Node3D
## Returns the range against signature 1, metres.
var _range: Callable
## Returns how far above `body` it looks from, metres.
var _height: Callable


func _init(owner_team: int, node: Node3D, sensor_range: Callable, eye_height: Callable) -> void:
	team = owner_team
	body = node
	_range = sensor_range
	_height = eye_height


func reach() -> float:
	return _range.call()


func eye() -> Vector3:
	return body.global_position + Vector3.UP * float(_height.call())
