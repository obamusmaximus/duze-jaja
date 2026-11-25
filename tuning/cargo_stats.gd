class_name CargoStats
extends Resource
## Tunable numbers for a carrier's hold (a carryall's, later a mothership bay's). A unit type points at one from
## `UnitStats.cargo`; a carried unit's slot use is its own `UnitStats` (`cargo_class`, `cargo_slots`).

@export_group("Capacity")
## Slots for infantry. Twice the machinery slots by design (`GAME_DESIGN.md`, "Carryalls").
@export_range(0, 64, 1) var infantry_slots: int = 8
## Slots for machinery. A tank takes all of them, an IFV half.
@export_range(0, 64, 1) var machinery_slots: int = 4


## The slot count for a cargo class (`UnitStats.CargoClass`).
func capacity(cargo_class: UnitStats.CargoClass) -> int:
	match cargo_class:
		UnitStats.CargoClass.INFANTRY:
			return infantry_slots
		UnitStats.CargoClass.MACHINERY:
			return machinery_slots
	return 0
