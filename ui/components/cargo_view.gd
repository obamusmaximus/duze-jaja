class_name CargoView
extends VBoxContainer
## The hold of a selected carrier: a caption with the room used of the hold's volume, a fill bar, and a card per
## unit type aboard (its icon and how many), so even the Explorer's 40 fit in a row. Rebuilds when the `Cargo`
## changes. View only.

var _cargo: Cargo
var _slot_px: int


func _init(cargo: Cargo, slot_px: int) -> void:
	_cargo = cargo
	_slot_px = slot_px
	add_theme_constant_override(&"separation", UiTokens.UNIT / 2)
	cargo.changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	add_child(HudModule.label("HOLD  %s / %s" % [_amount(_cargo.used()), _amount(_cargo.capacity())], &"LabelCaption"))
	var bar := StatBar.new()
	bar.warn_when_low = false
	bar.fill_color = UiTokens.BONE
	bar.fraction = _cargo.used() / maxf(_cargo.capacity(), 0.001)
	add_child(bar)
	var cards := HFlowContainer.new()
	cards.add_theme_constant_override(&"h_separation", UiTokens.UNIT / 2)
	cards.add_theme_constant_override(&"v_separation", UiTokens.UNIT / 2)
	for row: Dictionary in _cargo.type_counts():
		cards.add_child(_card(row.type, row.count))
	if _cargo.entries.is_empty():
		var empty := PanelContainer.new()
		empty.theme_type_variation = &"PanelHatch"
		empty.custom_minimum_size = Vector2(_slot_px, _slot_px)
		cards.add_child(empty)
	add_child(cards)


## A bone card with the type's icon and, beside it, how many are aboard.
func _card(type: UnitStats, count: int) -> Control:
	var card := ColorRect.new() # Not a padded panel: the icon should fill its square.
	card.color = UiTokens.BONE
	card.custom_minimum_size = Vector2(_slot_px * 2, _slot_px)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 0)
	card.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var icon := UnitIcon.new(type, UiTokens.BLACK)
	icon.custom_minimum_size = Vector2(_slot_px, _slot_px)
	row.add_child(icon)
	var number := HudModule.label("%d" % count, &"LabelNumberDark")
	number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(number)
	return card


func _amount(value: float) -> String:
	return "%d" % int(value) if is_equal_approx(value, roundf(value)) else "%.1f" % value
