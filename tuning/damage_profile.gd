class_name DamageProfile
extends Resource
## What one weapon type does to each armor type, in hit points per hit (`UnitStats.armor` picks the number). A
## `WeaponStats` points at one; every number starts at `FALLBACK`, and a weapon with no profile does that to
## everything (tuning/damage_rifle.tres, damage_beam.tres).

const FALLBACK: float = 10.0

@export_group("Damage per hit")
## Against infantry armor.
@export_range(0.0, 1000.0, 1.0) var vs_infantry: float = FALLBACK
## Against vehicles (IFV, skiff).
@export_range(0.0, 1000.0, 1.0) var vs_vehicle: float = FALLBACK
## Against light vehicles (rover).
@export_range(0.0, 1000.0, 1.0) var vs_light_vehicle: float = FALLBACK
## Against tank armor.
@export_range(0.0, 1000.0, 1.0) var vs_tank: float = FALLBACK
## Against combat aircraft (fighter, VTOL).
@export_range(0.0, 1000.0, 1.0) var vs_aircraft: float = FALLBACK
## Against carryalls.
@export_range(0.0, 1000.0, 1.0) var vs_carryall: float = FALLBACK
## Against Explorers.
@export_range(0.0, 1000.0, 1.0) var vs_explorer: float = FALLBACK


func against(armor: UnitStats.ArmorType) -> float:
	match armor:
		UnitStats.ArmorType.INFANTRY:
			return vs_infantry
		UnitStats.ArmorType.VEHICLE:
			return vs_vehicle
		UnitStats.ArmorType.LIGHT_VEHICLE:
			return vs_light_vehicle
		UnitStats.ArmorType.TANK:
			return vs_tank
		UnitStats.ArmorType.AIRCRAFT:
			return vs_aircraft
		UnitStats.ArmorType.CARRYALL:
			return vs_carryall
		UnitStats.ArmorType.EXPLORER:
			return vs_explorer
	return FALLBACK
