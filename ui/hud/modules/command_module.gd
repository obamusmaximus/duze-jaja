class_name CommandModule
extends HudModule
## HUD module: the command and build grid (`CommandGrid`). Its cells are empty placeholders until orders and
## building get buttons.

var grid := CommandGrid.new()


func _title() -> String:
	return "COMMAND"


func _build() -> void:
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(grid)
	context.selection.changed.connect(_on_selection_changed)
	_on_selection_changed()


func _apply() -> void:
	var stats: UiStats = context.stats
	grid.setup(stats.command_columns, stats.command_rows, stats.command_cell_units)


func _on_selection_changed() -> void:
	set_note("STANDBY" if context.selection.units.is_empty() else "READY")
