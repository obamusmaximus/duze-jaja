class_name StatChip
extends PanelContainer
## A small inset block: a caption over a figure and its unit ("RANGE / 40 M"). `row_for` lays out a unit type's
## speed, range, damage and rate of fire.


func _init(caption: String, figure: String, unit_text: String = "") -> void:
	theme_type_variation = &"PanelInset"
	custom_minimum_size.x = UiTokens.px(12)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	column.add_child(HudModule.label(caption.to_upper(), &"LabelCaption"))
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", UiTokens.UNIT / 2)
	line.add_child(HudModule.label(figure, &"LabelNumber"))
	if unit_text != "":
		var unit_label := HudModule.label(unit_text, &"LabelCaption")
		unit_label.size_flags_vertical = Control.SIZE_SHRINK_END
		line.add_child(unit_label)
	column.add_child(line)
	add_child(column)


static func row_for(stats: UnitStats) -> HBoxContainer:
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override(&"separation", UiTokens.UNIT)
	chips.add_child(StatChip.new("Speed", "%.1f" % stats.speed, "M/S"))
	var weapon: WeaponStats = stats.weapon
	if weapon != null:
		chips.add_child(StatChip.new("Range", "%d" % roundi(weapon.max_range), "M"))
		chips.add_child(StatChip.new("Damage", "%d" % roundi(weapon.damage)))
		chips.add_child(StatChip.new("Rate", "%.1f" % (1.0 / weapon.cooldown), "/S"))
	return chips
