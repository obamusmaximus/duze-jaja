class_name SquadStats
extends Resource
## A squad preset (`tuning/squad_*.tres`): a name, a job and the unit types in it. The squad builder offers presets
## and the AI picks them; cost and build time come from the units (`UnitStats`). A custom squad is a `SquadSpec`.

@export_group("Squad")
## The preset's name, for the HUD.
@export var display_name: String = "Squad"
## What the squad is for (a squad has one job; its units can still be micro'd one by one).
@export var job: SquadSpec.Job = SquadSpec.Job.ASSAULT
## The unit types, one entry per unit (a type listed twice is two units). Cargo-class types only.
@export var units: Array[UnitStats] = []


func to_spec() -> SquadSpec:
	return SquadSpec.from_types(display_name, job, units)
