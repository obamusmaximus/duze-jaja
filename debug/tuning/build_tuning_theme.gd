extends SceneTree
## Debug: writes the tuning panel's Theme (TuningThemeBuilder) to res://debug/tuning/tuning_theme.tres. Run after
## changing UiTokens or TuningThemeBuilder:  godot --headless --script res://debug/tuning/build_tuning_theme.gd


func _init() -> void:
	var error: Error = ResourceSaver.save(TuningThemeBuilder.build(), "res://debug/tuning/tuning_theme.tres")
	print("tuning theme saved: ", error_string(error))
	quit()
