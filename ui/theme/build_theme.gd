extends SceneTree
## Debug: writes the game's Theme (UiThemeBuilder) to res://ui/theme/game_theme.tres. Run after changing
## UiTokens or UiThemeBuilder:  godot --headless --script res://ui/theme/build_theme.gd


func _init() -> void:
	var error: Error = ResourceSaver.save(UiThemeBuilder.build(), "res://ui/theme/game_theme.tres")
	print("theme saved: ", error_string(error))
	quit()
