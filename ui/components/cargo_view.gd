class_name CargoView
extends VBoxContainer
## The hold of a selected carrier: a row of slots per cargo class (infantry, machinery), each filled slot showing
## the carried unit's icon, a unit taking several slots spanning them, free slots hatched empty. Rebuilds when the
## `Cargo` changes. View only.

var _cargo: Cargo
var _slot_px: int


func _init(cargo: Cargo, slot_px: int) -> void:
	_cargo = cargo
	_slot_px = slot_px
	add_theme_constant_override(&"separation", UiTokens.UNIT)
	cargo.changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	for cargo_class: UnitStats.CargoClass in [UnitStats.CargoClass.INFANTRY, UnitStats.CargoClass.MACHINERY]:
		if _cargo.capacity(cargo_class) > 0:
			add_child(_row(cargo_class))


func _row(cargo_class: UnitStats.CargoClass) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	var title: String = "INFANTRY" if cargo_class == UnitStats.CargoClass.INFANTRY else "MACHINERY"
	column.add_child(HudModule.label("%s  %d / %d" % [title, _cargo.used(cargo_class), _cargo.capacity(cargo_class)], &"LabelCaption"))
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override(&"separation", UiTokens.UNIT / 2)
	for entry: CargoEntry in _cargo.entries:
		if entry.unit_type.cargo_class == cargo_class:
			slots.add_child(_filled(entry))
	for i: int in _cargo.free_slots(cargo_class):
		var empty := PanelContainer.new()
		empty.theme_type_variation = &"PanelHatch"
		empty.custom_minimum_size = Vector2(_slot_px, _slot_px)
		slots.add_child(empty)
	column.add_child(slots)
	return column


## A bone card as wide as the slots the unit takes (plus the gaps between them), holding its icon.
func _filled(entry: CargoEntry) -> Control:
	var span: int = Cargo.slots_of(entry.unit_type)
	var card := ColorRect.new() # Not a padded panel: the icon should fill the slot.
	card.color = UiTokens.BONE
	card.custom_minimum_size = Vector2(_slot_px * span + (UiTokens.UNIT / 2) * (span - 1), _slot_px)
	var icon := UnitIcon.new(entry.unit_type, UiTokens.BLACK)
	card.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return card
