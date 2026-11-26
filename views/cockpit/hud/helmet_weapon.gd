class_name HelmetWeapon
extends HelmetPart
## Visual only: the flown unit's weapon: the crosshair (always for a turret type, else while the head is turned, to
## point at what to lock) with the reload bar under it, and a box on the locked target with its distance, orange while
## a shot would bend onto it. A locked target out of view is held at the screen's edge. Nothing for an unarmed type.


func _paint() -> void:
	var weapon: PilotWeapon = hud.flight.weapon
	if not weapon.armed():
		return
	var look: Vector3 = hud.controls.view()
	var turret: bool = hud.unit.stats.pilot_turret
	if turret or not hud.controls.look.is_zero_approx():
		_crosshair(look)
	_reload(look if turret else hud.nose)
	var locked: Unit = weapon.target()
	if locked != null:
		_lock(weapon, locked, look if turret else hud.nose)


func _crosshair(look: Vector3) -> void:
	if not ahead(look):
		return
	var at: Vector2 = project(look)
	var inner: float = hud.stats.crosshair_size * 0.4
	for way: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		line(at + way * inner, at + way * hud.stats.crosshair_size)


func _reload(along: Vector3) -> void:
	var left: float = hud.unit.weapon.cooling()
	if left <= 0.0 or not ahead(along):
		return
	var half: float = hud.stats.crosshair_size
	var at: Vector2 = project(along) + Vector2(-half, hud.stats.crosshair_size * 1.7)
	line(at, at + Vector2(half * 2.0 * (1.0 - left), 0.0), UiTokens.HUD_REFERENCE)


func _lock(weapon: PilotWeapon, locked: Unit, along: Vector3) -> void:
	var from: Vector3 = weapon.eye(hud.flight.model)
	var to: Vector3 = locked.get_global_transform_interpolated().origin + Vector3.UP * locked.stats.height * 0.5 \
			- hud.camera.global_position
	var color: Color = UiTokens.HUD_WARNING if weapon.in_envelope(from, along) else UiTokens.HUD_LINE
	var half: float = hud.stats.lock_size
	var area := Rect2(Vector2.ZERO, size).grow(-hud.stats.path_edge_inset)
	var at := Vector2.ZERO
	var shown: bool = ahead(to.normalized())
	if shown:
		at = project(to)
		shown = area.has_point(at)
	if not shown:
		var local: Vector3 = hud.camera.global_basis.inverse() * to
		var way := Vector2(local.x, -local.y)
		way = way.normalized() if way.length() > 0.001 else Vector2.DOWN
		var reach: Vector2 = area.size * 0.5
		at = area.get_center() + way * minf(reach.x / maxf(absf(way.x), 0.001), reach.y / maxf(absf(way.y), 0.001))
		half *= 0.5
	box(Rect2(at - Vector2.ONE * half, Vector2.ONE * half * 2.0), color)
	text(at + Vector2(0.0, half + 16.0), "LOCK  %d M" % roundi(from.distance_to(locked.center())),
			HORIZONTAL_ALIGNMENT_CENTER, color)
