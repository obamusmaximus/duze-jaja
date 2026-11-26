class_name CargoStats
extends Resource
## Tunable numbers for a carrier's hold (a carryall's, the Explorer's). A unit type points at one from
## `UnitStats.cargo`; how much room a carried unit takes is its own `UnitStats.cargo_size`.

@export_group("Capacity")
## Room in the hold, counted in infantry. One shared volume for every kind of cargo: a hold of 40 takes 40 troopers,
## 16 IFVs, 8 tanks or flyers, 4 carryalls, or any mix that adds up.
@export_range(1.0, 200.0, 0.5) var volume: float = 10.0
