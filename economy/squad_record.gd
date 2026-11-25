class_name SquadRecord
extends RefCounted
## One squad in the match as data: its id, team, name, job and members. Built squads wait aboard the mothership as
## `CargoEntry` data in a carryall's hold, added one by one as the units finish building; the carryall puts them
## down (`Carryall`), and from then on `unit_ids` lists the live members.

var id: int = 0
var team: int = 0
var display_name: String = ""
var job: SquadSpec.Job = SquadSpec.Job.ASSAULT
## True while the squad waits aboard as data.
var aboard: bool = true
## The unit that carries it while it is aboard (a carryall's id), 0 once deployed.
var carryall_id: int = 0
var entries: Array[CargoEntry] = []
var unit_ids: PackedInt32Array = PackedInt32Array()
