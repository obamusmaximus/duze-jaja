extends SceneTree
## Debug: the standing benchmark (`docs/performance.md`). Headless, each team's ground units on the atoll ordered across
## their own island for a fixed number of ticks, one summary line:
##   godot --headless --fixed-fps 60 --script res://debug/benchmark/benchmark.gd 2>&1 | grep BENCH
## Prints wall milliseconds per tick overall and in the unit loop, and how many units ended near their goal.

const TICKS: int = 600
const LEVEL: String = "res://levels/atoll/atoll.tscn"
## A unit this close to its team's goal at the end counts as near it, metres.
const NEAR: float = 60.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame # Autoloads register.
	var level: Node = (load(LEVEL) as PackedScene).instantiate()
	root.add_child(level)
	for i: int in 60:
		await physics_frame
	var registry: UnitRegistry = level.get_node("Units")
	var issuer: CommandIssuer = level.get_node("CommandIssuer")
	var teams: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array()]
	for node: Node in get_nodes_in_group(&"units"):
		var unit: Unit = node as Unit
		if unit.stats.resource_path.get_file() in ["unit_trooper.tres", "unit_rover.tres", "unit_ifv.tres", "unit_tank.tres"]:
			teams[unit.team].append(unit.id)
	var goals: Array[Vector3] = []
	for team: int in teams.size():
		# The unit farthest from the first one: the other side of the same island.
		var from: Vector3 = registry.get_unit(teams[team][0]).global_position
		var goal: Vector3 = from
		for id: int in teams[team]:
			var at: Vector3 = registry.get_unit(id).global_position
			if at.distance_squared_to(from) > goal.distance_squared_to(from):
				goal = at
		goals.append(goal)
		issuer.issue(Order.move(team, teams[team], goal))
	var start_usec: int = registry.get("step_usec")
	var vision: Node = get_first_node_in_group(&"vision")
	var vision_usec: int = vision.get("step_usec")
	var start_pos: Vector3 = registry.get_unit(teams[0][0]).global_position
	var started: int = Time.get_ticks_usec()
	for i: int in TICKS:
		await physics_frame
	var wall: float = float(Time.get_ticks_usec() - started) / 1000.0
	var loop: float = float(int(registry.get("step_usec")) - start_usec) / 1000.0
	var moved: float = registry.get_unit(teams[0][0]).global_position.distance_to(start_pos)
	var arrived: int = 0
	var ordered: int = 0
	for team: int in teams.size():
		ordered += teams[team].size()
		for id: int in teams[team]:
			var unit: Unit = registry.get_unit(id)
			if unit and unit.global_position.distance_to(goals[team]) < NEAR:
				arrived += 1
	print("BENCH units=%d ticks=%d tick_ms=%.2f unit_loop_ms=%.2f vision_ms=%.3f near_goal=%d first_unit_moved_m=%.1f" % [
		ordered, TICKS, wall / TICKS, loop / TICKS,
		float(int(vision.get("step_usec")) - vision_usec) / 1000.0 / TICKS, arrived, moved])
	quit()
