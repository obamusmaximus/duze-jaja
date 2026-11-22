class_name HudLayout
extends Resource
## Where the HUD's modules sit (`ui/hud/layouts/`). The screen is nine sections (`HudPlacement.Section`); any module
## can go in any of them. An edge can be framed: it then gets a solid band across the whole edge (the Generals
## bottom bar, the C&C sidebar) that holds that edge's sections and blocks clicks to the map behind it. Unframed
## sections float over the map with only the modules themselves taking clicks.

const BAND_TOP: int = 1
const BAND_BOTTOM: int = 2
const BAND_LEFT: int = 4
const BAND_RIGHT: int = 8

@export_flags("Top", "Bottom", "Left", "Right") var bands: int = BAND_BOTTOM
## Side bands and columns run the full height of the screen, with the top and bottom rows between them (a C&C
## sidebar). Off: top and bottom run the full width, sides between them (the Generals bar).
@export var sides_first: bool = false
@export var placements: Array[HudPlacement] = []


func has_band(band: int) -> bool:
	return bands & band != 0


## The placements in one section, in order.
func in_section(section: HudPlacement.Section) -> Array[HudPlacement]:
	var found: Array[HudPlacement] = []
	for placement: HudPlacement in placements:
		if placement != null and placement.module != null and placement.section == section:
			found.append(placement)
	found.sort_custom(func(a: HudPlacement, b: HudPlacement) -> bool: return a.order < b.order)
	return found
