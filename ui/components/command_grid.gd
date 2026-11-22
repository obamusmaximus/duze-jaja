class_name CommandGrid
extends GridContainer
## A grid of equal square cells for command and build buttons (the style guide's "grids of equal cells"). Cells are
## `CommandCell` buttons; unused ones stay disabled (hatched, with a "+" mark) so the grid shape always reads. The
## HUD fills cells with orders and build items through `set_cell`.

signal cell_pressed(index: int)

const EMPTY_MARK: String = "+"

var _cells: Array[Button] = []


## Builds `columns` x `rows` cells of `cell_units` base units each, `gap` pixels apart.
func setup(columns: int, rows: int, cell_units: int, gap: int = UiTokens.UNIT) -> void:
	for cell: Button in _cells:
		cell.queue_free()
	_cells.clear()
	self.columns = columns
	add_theme_constant_override(&"h_separation", gap)
	add_theme_constant_override(&"v_separation", gap)
	for i: int in columns * rows:
		var cell := Button.new()
		cell.theme_type_variation = &"CommandCell"
		cell.custom_minimum_size = Vector2.ONE * UiTokens.px(cell_units)
		cell.focus_mode = Control.FOCUS_NONE
		cell.pressed.connect(cell_pressed.emit.bind(i))
		add_child(cell)
		_cells.append(cell)
		clear_cell(i)


func set_cell(index: int, label: String, enabled: bool = true) -> void:
	_cells[index].text = label.to_upper()
	_cells[index].disabled = not enabled


func clear_cell(index: int) -> void:
	set_cell(index, EMPTY_MARK, false)


func cell_count() -> int:
	return _cells.size()
