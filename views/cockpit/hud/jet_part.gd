class_name JetPart
extends HelmetPart
## Visual only: base of the commando's HUD parts on the `HelmetHud` (`docs/mechanics/commando.md`): shown only for a
## jetpack type. The view is the camera's, so the screen's middle is where it looks.


func shows(flight: PilotFlight) -> bool:
	return flight.is_jetpack()


## A world point on screen, or null-like (`Vector2.INF`) behind the camera.
func point_on_screen(point: Vector3) -> Vector2:
	if hud.camera.is_position_behind(point):
		return Vector2.INF
	return hud.camera.unproject_position(point)
