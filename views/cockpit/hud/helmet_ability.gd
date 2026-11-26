class_name HelmetAbility
extends HelmetPart
## Visual only: the flown unit's ability, under the altitude tape: its key and name, a bar (full when ready, running
## down while active, filling while it cools) and the state in words with the charges (`AbilityStatus`). Nothing for
## a type without one.

const BAR := Vector2(220.0, 14.0)
## How far below the altitude tape the block starts, and between its lines, pixels.
const DROP: float = 130.0
const LINE_GAP: float = 34.0


func _paint() -> void:
	var flown: Array[Unit] = [hud.unit]
	var status: AbilityStatus = AbilityStatus.of(flown)
	if status == null:
		return
	var at := Vector2(size.x * 0.5 + hud.stats.tape_offset, size.y * 0.5 + hud.stats.tape_height * 0.5 + DROP)
	var live: bool = status.state == AbilityStatus.State.READY or status.state == AbilityStatus.State.ACTIVE
	var color: Color = UiTokens.HUD_LINE if live else UiTokens.HUD_REFERENCE
	text(at, "F  %s" % status.stats.display_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, color, &"LabelNumber")
	var frame := Rect2(at + Vector2(-BAR.x * 0.5, LINE_GAP - BAR.y * 0.5), BAR)
	draw_rect(Rect2(frame.position, Vector2(BAR.x * clampf(status.fraction, 0.0, 1.0), BAR.y)), color)
	box(frame, color)
	text(at + Vector2(0.0, LINE_GAP * 2.0), status.text(), HORIZONTAL_ALIGNMENT_CENTER, color)


func shows(_flight: PilotFlight) -> bool:
	return true
