class_name TuningPanel
extends PanelContainer
## Debug: the panel (opened from the pause menu) for tuning the game while testing it. Each tab (TABS) shows the
## stats resources of its classes found in `res://tuning/`, with one foldable
## sub-label per `@export_group` (see TuningFields). Values change live; Save writes the current tab's
## resources back to their .tres files, Reset reloads them from disk. The preview column beside the tabs
## (TuningPreview) shows an animated diagram and the description of the setting last hovered.
## To add a new stats resource, put its .tres in `tuning/` and list its class in TABS.

## Emitted when Back is pressed. The pause menu closes this panel.
signal back_pressed

const TUNING_DIR: String = "res://tuning/"
## Tab name to the stats classes shown on it.
const TABS: Dictionary = {
	"Camera": ["CameraStats", "CockpitStats"],
	"Units": ["UnitStats", "WeaponStats", "DamageProfile", "BoostStats", "DeployStats", "FlightModeStats", "OrderStats", "CargoStats", "CarryallStats", "AirfieldStats", "PadStats", "ExplorerStats", "EconomyStats", "VisionStats"],
	"Flight": ["FlightStats", "HoverStats", "HelmetHudStats"],
	"Commando": ["JetpackStats", "SeekerShotgunStats", "TrackingStats", "JetHudStats"],
	"Map": ["BattlefieldStats", "MothershipStats", "MapStats", "BirdsEyeStats", "HeightmapStats", "WaterStats", "WorldLookStats", "LightStats", "LampStats"],
	"Audio": ["AudioStats", "FlightSoundStats", "SfxCue", "FxStats"],
	"Controls": ["PlayerControlStats", "StrategyControlStats", "UiStats"],
	"Debug": ["PlaytestLogStats", "TimeScaleStats"],
}
## Share of the viewport the panel takes, and the width below which the preview column is dropped.
const SCREEN_SHARE: Vector2 = Vector2(0.9, 0.88)
const PREVIEW_MIN_PANEL_WIDTH: float = 1100.0

var _built: bool = false
## Stats class name to the resources of that class found in TUNING_DIR.
var _by_class: Dictionary = {}

@onready var _tabs: TabContainer = %Tabs
@onready var _preview: TuningPreview = %Preview
@onready var _status: Label = %Status
@onready var _save_button: Button = %SaveButton
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_save_button.pressed.connect(_on_save_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button.pressed.connect(back_pressed.emit)


## Shows the panel, building the tabs the first time.
func open() -> void:
	if not _built:
		_build()
	fit_to_screen()
	_status.text = ""
	visible = true
	_back_button.grab_focus()


## Sizes the panel to a share of the screen, allowing for the menu scale. The tabs take whatever height is left.
func fit_to_screen() -> void:
	var menu_scale: Vector2 = get_global_transform().get_scale().max(Vector2(0.01, 0.01))
	var room: Vector2 = get_viewport_rect().size / menu_scale
	custom_minimum_size = (room * SCREEN_SHARE).floor()
	_preview.visible = custom_minimum_size.x >= PREVIEW_MIN_PANEL_WIDTH # Too narrow: the rows need the room.


func _build() -> void:
	_built = true
	_find_resources()
	for tab_name: String in TABS:
		var scroll := ScrollContainer.new()
		scroll.name = tab_name
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.theme_type_variation = &"TuningGapV"
		scroll.add_child(column)
		_tabs.add_child(scroll)
		_tabs.set_tab_title(_tabs.get_tab_count() - 1, tab_name.to_upper())
		_fill_tab(scroll)


## Loads every .tres in TUNING_DIR and files it under its stats class. Resources a scene already loaded
## come back as the same instance, so edits reach the running game.
func _find_resources() -> void:
	_by_class.clear()
	for file: String in DirAccess.get_files_at(TUNING_DIR):
		var clean: String = file.trim_suffix(".remap")
		if not clean.ends_with(".tres"):
			continue
		var resource: Resource = load(TUNING_DIR + clean)
		var script: Script = resource.get_script() if resource != null else null
		if script == null:
			continue
		var stats_class: String = script.get_global_name()
		if not _by_class.has(stats_class):
			_by_class[stats_class] = []
		(_by_class[stats_class] as Array).append(resource)


## Fills a tab's scroll area with a header and the controls for each of its resources.
func _fill_tab(scroll: ScrollContainer) -> void:
	var column: VBoxContainer = scroll.get_child(0)
	var shown: Array[Resource] = []
	for stats_class: String in TABS[scroll.name]:
		for resource: Resource in _by_class.get(stats_class, []):
			var strip := PanelContainer.new()
			strip.theme_type_variation = &"TuningResourceStrip"
			var header := Label.new()
			header.text = resource.resource_path.get_file().to_upper()
			header.theme_type_variation = &"TuningResourceLabel"
			strip.add_child(header)
			column.add_child(strip)
			column.add_child(TuningFields.build(resource, _preview.show_for))
			shown.append(resource)
	scroll.set_meta("resources", shown)


func _current_resources() -> Array[Resource]:
	var scroll: ScrollContainer = _tabs.get_current_tab_control()
	var items: Array[Resource] = []
	items.assign(scroll.get_meta("resources", []))
	return items


func _on_save_pressed() -> void:
	var saved: PackedStringArray = PackedStringArray()
	for resource: Resource in _current_resources():
		var error: int = ResourceSaver.save(resource, resource.resource_path)
		if error != OK:
			_status.text = "Could not save %s (error %d)" % [resource.resource_path.get_file(), error]
			return
		saved.append(resource.resource_path.get_file())
	_status.text = "Saved " + ", ".join(saved)


func _on_reset_pressed() -> void:
	var scroll: ScrollContainer = _tabs.get_current_tab_control()
	for resource: Resource in _current_resources():
		var fresh: Resource = ResourceLoader.load(resource.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if fresh != null:
			TuningFields.copy_values(fresh, resource)
	_preview.clear()
	var column: Node = scroll.get_child(0)
	for child: Node in column.get_children():
		column.remove_child(child)
		child.queue_free()
	_fill_tab(scroll)
	_status.text = "Reset to the saved values"
