@tool
class_name StyleBoxHatch
extends StyleBox
## A flat fill crossed by thin diagonal lines ("/"), with an optional border of the one weight: the style guide's
## mark for an empty or unavailable slot. Hard edges, no antialiasing on the fill; the lines are clipped to the box.

@export var fill: Color = UiTokens.BLACK
@export var line: Color = UiTokens.CONCRETE
@export var border: Color = Color(0, 0, 0, 0)
@export var spacing: float = UiTokens.HATCH_SPACING
@export var line_width: float = UiTokens.HATCH_WIDTH


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var server := RenderingServer
	server.canvas_item_add_rect(to_canvas_item, rect, fill)
	var start: float = rect.position.x + rect.position.y
	var end: float = rect.end.x + rect.end.y
	# Lines x + y = c, stepped from the top-left corner so the pattern is fixed to the box.
	var c: float = start + spacing
	while c < end:
		var x0: float = maxf(rect.position.x, c - rect.end.y)
		var x1: float = minf(rect.end.x, c - rect.position.y)
		if x1 > x0:
			server.canvas_item_add_line(to_canvas_item, Vector2(x0, c - x0), Vector2(x1, c - x1), line, line_width, true)
		c += spacing
	if border.a > 0.0:
		var w: float = UiTokens.BORDER
		server.canvas_item_add_rect(to_canvas_item, Rect2(rect.position, Vector2(rect.size.x, w)), border)
		server.canvas_item_add_rect(to_canvas_item, Rect2(rect.position + Vector2(0, rect.size.y - w), Vector2(rect.size.x, w)), border)
		server.canvas_item_add_rect(to_canvas_item, Rect2(rect.position, Vector2(w, rect.size.y)), border)
		server.canvas_item_add_rect(to_canvas_item, Rect2(rect.position + Vector2(rect.size.x - w, 0), Vector2(w, rect.size.y)), border)
