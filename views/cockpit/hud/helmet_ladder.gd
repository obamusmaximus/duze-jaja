class_name HelmetLadder
extends HelmetPart
## Visual only: the horizon line and the pitch ladder. Every mark is a world direction, so they roll and slide with
## the view and lie on the real horizon. The ladder stands on the nose's heading and shows the rungs near the nose;
## rungs below the horizon are dashed, and every rung's end ticks point to the horizon. The horizon follows where the
## view looks, so free look never loses it.

## Length of a rung's end tick, degrees of view.
const TICK_DEGREES: float = 1.2
## Dashes of a rung below the horizon.
const DASHES: int = 3
## Below this length of a direction's flat part there is no heading to take from it.
const MIN_FLAT: float = 0.02


func _paint() -> void:
	_horizon()
	_ladder()


func _horizon() -> void:
	var level: Vector3 = _flat(-hud.camera.global_basis.z, hud.up)
	var side: Vector3 = level.cross(Vector3.UP)
	var inner: float = tan(deg_to_rad(hud.stats.rung_gap))
	var outer: float = tan(deg_to_rad(hud.stats.horizon_half_width))
	for sign_x: float in [-1.0, 1.0]:
		world_line(level + side * inner * sign_x, level + side * outer * sign_x)


func _ladder() -> void:
	var level: Vector3 = _flat(hud.nose, -hud.up if hud.nose.y > 0.0 else hud.up)
	var side: Vector3 = level.cross(Vector3.UP)
	var nose_pitch: float = rad_to_deg(asin(clampf(hud.nose.y, -1.0, 1.0)))
	var step: float = hud.stats.ladder_step
	var first: int = ceili((nose_pitch - hud.stats.ladder_span) / step)
	var last: int = floori((nose_pitch + hud.stats.ladder_span) / step)
	for i: int in range(first, last + 1):
		var degrees: float = i * step
		if i != 0 and absf(degrees) < 90.0:
			_rung(level, side, degrees)


func _rung(level: Vector3, side: Vector3, degrees: float) -> void:
	var pitch: float = deg_to_rad(degrees)
	var middle: Vector3 = level * cos(pitch) + Vector3.UP * sin(pitch)
	var upward: Vector3 = side.cross(middle)
	var to_horizon: Vector3 = upward * tan(deg_to_rad(TICK_DEGREES)) * -signf(degrees)
	var inner: float = tan(deg_to_rad(hud.stats.rung_gap))
	var outer: float = tan(deg_to_rad(hud.stats.rung_half_width))
	var pieces: int = DASHES * 2 - 1 if degrees < 0.0 else 1
	for sign_x: float in [-1.0, 1.0]:
		var from: Vector3 = middle + side * inner * sign_x
		var to: Vector3 = middle + side * outer * sign_x
		for piece: int in range(0, pieces, 2):
			world_line(from.lerp(to, float(piece) / pieces), from.lerp(to, float(piece + 1) / pieces))
		world_line(to, to + to_horizon)
		var label_at: Vector3 = middle + side * (outer + tan(deg_to_rad(1.8))) * sign_x
		if ahead(label_at):
			text(project(label_at), str(roundi(absf(degrees))))


## `direction` laid level; pointing straight up or down it takes the heading of `fallback`.
func _flat(direction: Vector3, fallback: Vector3) -> Vector3:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length() < MIN_FLAT:
		flat = Vector3(fallback.x, 0.0, fallback.z)
	return flat.normalized() if flat.length() > 0.0001 else Vector3.FORWARD
