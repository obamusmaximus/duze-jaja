class_name ProductionLine
extends RefCounted
## One production line (a mothership bay): a queue of squads, the first one being built. Pure data stepped by
## `Production` on the fixed tick; a job builds its units one by one into a carryall waiting on a pad.

class Job:
	extends RefCounted
	var ticket: int = 0
	var spec: SquadSpec
	var cost: int = 0
	var total: float = 0.0
	var left: float = 0.0
	## The unit types still to build, in order, and how many are built (aboard `carryall`).
	var types: Array[UnitStats] = []
	var built: int = 0
	## Seconds per build second of a unit (`EconomyStats.build_time_scale`).
	var scale: float = 1.0
	## Once the job has started: the carryall it loads (on a pad) and the squad being filled.
	var carryall: Carryall
	var squad: SquadRecord
	var _unit_left: float = -1.0

	func progress() -> float:
		return 1.0 - left / maxf(total, 0.001)

	func started() -> bool:
		return carryall != null

	func done() -> bool:
		return built >= types.size()

	## Works on the unit being built; returns its type when it finishes this step, else null.
	func step(delta: float) -> UnitStats:
		if done():
			return null
		if _unit_left < 0.0:
			_unit_left = types[built].build_time * scale
		var spent: float = minf(delta, _unit_left)
		_unit_left -= spent
		left = maxf(left - spent, 0.0)
		if _unit_left > 0.0:
			return null
		var finished: UnitStats = types[built]
		built += 1
		_unit_left = -1.0
		if done():
			left = 0.0
		return finished

	## Price of the units not built yet.
	func unbuilt_cost() -> int:
		var sum: int = 0
		for i: int in range(built, types.size()):
			sum += types[i].cost
		return sum

var team: int = 0
var index: int = 0
var jobs: Array[Job] = []


func _init(owner_team: int, line_index: int) -> void:
	team = owner_team
	index = line_index


func length() -> int:
	return jobs.size()


func add(job: Job) -> void:
	jobs.append(job)


## The job with `ticket`, or null.
func find(ticket: int) -> Job:
	for job: Job in jobs:
		if job.ticket == ticket:
			return job
	return null


## The job being built (the first), or null.
func current() -> Job:
	return null if jobs.is_empty() else jobs[0]
