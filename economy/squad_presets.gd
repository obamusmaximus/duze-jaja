class_name SquadPresets
extends RefCounted
## The squad presets the squad builder offers (`tuning/squad_*.tres`).

const ALL: Array[SquadStats] = [
	preload("res://tuning/squad_fireteam.tres"), preload("res://tuning/squad_motorized.tres"),
	preload("res://tuning/squad_armor.tres"), preload("res://tuning/squad_covert.tres"),
	preload("res://tuning/squad_scout.tres")]
