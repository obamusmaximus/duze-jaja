class_name Production
extends Node
## The production lines of every team's mothership. `queue` pays for a squad and puts it on a line. When a job reaches
## the front it gets a free carryall on a pad of the team's mothership (waiting while no pad is free), and the line
## builds the squad's units one by one into that carryall's hold on the fixed tick. A carryall that takes off early
## stops the job and refunds `takeoff_refund` of the unbuilt units. Reached only through `CommandIssuer` (`produce` and
## `cancel` orders). Simulation. A playtest probe (events `produce`, `cancel`, `squad_ready`, `takeoff`). Group `production`.

signal playtest_event(event: StringName, data: Dictionary)
## A team's lines or aboard squads changed (for the HUD).
signal changed(team: int)

var economy: Economy
var squads: SquadRegistry
var fleet: CarryallFleet
var _stats: EconomyStats
## Team to Array[ProductionLine].
var _lines: Dictionary = {}
var _next_ticket: int = 1


## `line_counts` is team to the number of lines (a mothership's production bays).
func setup(economy_node: Economy, squad_registry: SquadRegistry, carryalls: CarryallFleet, line_counts: Dictionary) -> void:
	economy = economy_node
	squads = squad_registry
	fleet = carryalls
	fleet.took_off.connect(_on_took_off)
	_stats = economy.stats
	add_to_group(&"production")
	add_to_group(&"playtest_probe")
	for team: int in line_counts:
		var lines: Array[ProductionLine] = []
		for i: int in int(line_counts[team]):
			lines.append(ProductionLine.new(team, i))
		_lines[team] = lines


func _physics_process(delta: float) -> void:
	for team: int in _lines:
		for line: ProductionLine in _lines[team]:
			var job: ProductionLine.Job = line.current()
			if job == null or not _ensure_carryall(team, job, line):
				continue
			var built: UnitStats = job.step(delta)
			if built == null:
				continue
			var entry := CargoEntry.new(0, built)
			entry.squad_id = job.squad.id
			if job.carryall.unit.cargo.load_entry(entry):
				job.squad.entries.append(entry)
			if job.done():
				line.jobs.erase(job)
				job.carryall.building = false
				playtest_event.emit(&"squad_ready", {"team": team, "line": line.index, "squad": job.squad.id, "name": job.squad.display_name})
			changed.emit(team)


func lines_of(team: int) -> Array[ProductionLine]:
	var out: Array[ProductionLine] = []
	out.assign(_lines.get(team, []))
	return out


## Pays for `spec` and queues it. Returns the ticket, or 0 if refused (no such team or line, a bad squad, a full
## queue, not enough credits). `line_index` -1 picks the shortest queue.
func queue(team: int, spec: SquadSpec, line_index: int = -1) -> int:
	var lines: Array[ProductionLine] = lines_of(team)
	if lines.is_empty() or spec == null or spec.validate(_stats) != "":
		return 0
	var line: ProductionLine = _pick(lines, line_index)
	if line == null or line.length() >= _stats.queue_length:
		return 0
	if not Cargo.new(fleet_hold()).fits_all(spec.types()):
		return 0 # One squad rides one carryall.
	var cost: int = spec.cost()
	if not economy.spend(team, cost):
		return 0
	var job := ProductionLine.Job.new()
	job.ticket = _next_ticket
	_next_ticket += 1
	job.spec = spec
	job.cost = cost
	job.total = spec.build_seconds(_stats.build_time_scale)
	job.left = job.total
	job.types = spec.types()
	job.scale = _stats.build_time_scale
	line.add(job)
	playtest_event.emit(&"produce", {"team": team, "line": line.index, "ticket": job.ticket, "squad": spec.to_dict(), "cost": cost})
	changed.emit(team)
	return job.ticket


## Takes the job with `ticket` off its line and refunds `cancel_refund` of its cost. False if the team has no such job.
func cancel(team: int, ticket: int) -> bool:
	for line: ProductionLine in lines_of(team):
		var job: ProductionLine.Job = line.find(ticket)
		if job == null:
			continue
		line.jobs.erase(job)
		if job.started(): # Scrapped: what was built so far is lost, the carryall stays empty on its pad.
			_scrap(job)
		economy.deposit(team, int(round(float(job.cost) * _stats.cancel_refund)))
		playtest_event.emit(&"cancel", {"team": team, "line": line.index, "ticket": ticket})
		changed.emit(team)
		return true
	return false


## The line asked for, or the one with the shortest queue that has room.
func _pick(lines: Array[ProductionLine], index: int) -> ProductionLine:
	if index >= 0:
		return lines[index] if index < lines.size() else null
	var best: ProductionLine = null
	for line: ProductionLine in lines:
		if line.length() < _stats.queue_length and (best == null or line.length() < best.length()):
			best = line
	return best


## The hold a squad must fit: the carryall type's own.
func fleet_hold() -> CargoStats:
	return CarryallFleet.carryall_type().cargo


## Gives the job at the front of `line` its carryall and squad record once a pad is free; false while it waits (or
## when its carryall was lost, which drops the job).
func _ensure_carryall(team: int, job: ProductionLine.Job, line: ProductionLine) -> bool:
	if job.started():
		if is_instance_valid(job.carryall.unit) and job.carryall.unit.alive:
			return true
		line.jobs.erase(job) # The carryall was shot down with the squad half built: the credits are gone.
		changed.emit(line.team)
		return false
	var carryall: Carryall = fleet.claim_on_pad(team)
	if carryall == null:
		return false
	job.carryall = carryall
	carryall.building = true
	job.squad = squads.create(team, job.spec)
	job.squad.carryall_id = carryall.unit.id
	changed.emit(team)
	return true


## A started job stops: its squad record and the hold are emptied; the carryall stays.
func _scrap(job: ProductionLine.Job) -> void:
	job.carryall.building = false
	job.carryall.unit.cargo.clear()
	squads.disband(job.squad)


## A carryall left its pad: if a line was loading it, the squad stays as built so far and the line moves on.
func _on_took_off(carryall: Carryall) -> void:
	for team: int in _lines:
		for line: ProductionLine in _lines[team]:
			var job: ProductionLine.Job = line.current()
			if job == null or job.carryall != carryall:
				continue
			line.jobs.erase(job)
			var refund: int = int(round(float(job.unbuilt_cost()) * _stats.takeoff_refund))
			economy.deposit(team, refund)
			if job.squad.entries.is_empty():
				squads.disband(job.squad)
			playtest_event.emit(&"takeoff", {"team": team, "line": line.index, "squad": job.squad.id, "built": job.built, "of": job.types.size(), "refund": refund})
			changed.emit(team)
			return
