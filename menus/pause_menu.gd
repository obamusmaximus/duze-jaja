class_name PauseMenu
extends CanvasLayer
## Pause menu: ESC pauses the game and offers Resume, Options (volume, fullscreen), the debug Tuning panel (debug
## builds only) and Quit. ESC again goes back, or resumes. It keeps running while the tree is paused (process mode
## "always"). Every level instances one.

@onready var _main_panel: Control = %MainPanel
@onready var _options_panel: Control = %OptionsPanel
@onready var _resume_button: Button = %ResumeButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _tuning_button: Button = %TuningButton
@onready var _tuning_panel: TuningPanel = %TuningPanel
@onready var _back_button: Button = %BackButton
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	GameSettings.load_and_apply()
	_volume_slider.value = GameSettings.master_volume
	_fullscreen_check.button_pressed = GameSettings.fullscreen
	_volume_slider.value_changed.connect(_on_volume_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_resume_button.pressed.connect(resume)
	_options_button.pressed.connect(_show_options.bind(true))
	_back_button.pressed.connect(_show_options.bind(false))
	_quit_button.pressed.connect(get_tree().quit)
	_tuning_button.visible = OS.is_debug_build()
	_tuning_button.pressed.connect(_show_tuning.bind(true))
	_tuning_panel.back_pressed.connect(_show_tuning.bind(false))
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	get_viewport().set_input_as_handled()
	if not get_tree().paused:
		pause()
	elif _options_panel.visible:
		_show_options(false)
	elif _tuning_panel.visible:
		_show_tuning(false)
	else:
		resume()


func pause() -> void:
	get_tree().paused = true
	visible = true
	_tuning_panel.visible = false
	_show_options(false)


func resume() -> void:
	GameSettings.save()
	get_tree().paused = false
	visible = false


func _show_options(show_options: bool) -> void:
	_options_panel.visible = show_options
	_main_panel.visible = not show_options
	if show_options:
		_volume_slider.grab_focus()
	else:
		GameSettings.save()
		_resume_button.grab_focus()


func _show_tuning(show_tuning: bool) -> void:
	_tuning_panel.visible = show_tuning
	_main_panel.visible = not show_tuning
	if show_tuning:
		_tuning_panel.open()
	else:
		_tuning_button.grab_focus()


func _on_volume_changed(value: float) -> void:
	GameSettings.master_volume = value
	GameSettings.apply()


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.fullscreen = pressed
	GameSettings.apply()
