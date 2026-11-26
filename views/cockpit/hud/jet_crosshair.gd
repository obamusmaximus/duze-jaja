class_name JetCrosshair
extends JetPart
## Visual only: the commando's crosshair, a ring with a dot in the middle of the screen (where the view and the
## shotgun aim), dimmed while the afterburner locks the weapon out.


func _paint() -> void:
	var color: Color = UiTokens.HUD_REFERENCE if hud.flight.jetpack.afterburning() else UiTokens.HUD_LINE
	var center: Vector2 = size * 0.5
	ring(center, hud.jet_stats.crosshair_radius, color)
	draw_circle(center, UiTokens.BORDER * 1.5, UiTokens.HUD_EDGE)
	draw_circle(center, UiTokens.BORDER, color)
