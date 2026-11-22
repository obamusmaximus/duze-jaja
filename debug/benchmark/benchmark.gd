extends SceneTree
## Debug: the standing benchmark (`docs/performance.md`). Headless, a fixed number of units ordered across the
## sandbox for a fixed number of ticks, one summary line:
##   godot --headless --fixed-fps 60 --script res://debug/benchmark/benchmark.gd 2>&1 | grep BENCH
## Prints wall milliseconds per tick overall and in the unit loop, and how many units arrived.

const UNITS: int = 100
const TICKS: int = 600
const LEVEL: String = "res://levels/sandbox/sandbox.tscn"
const UNIT_SCENE: String = "res://units/unit.tscn"
const UNIT_STATS: String = "res://tuning/unit_default.tres"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame # Autoloads register.
	var level: Node = (load(LEVEL) as PackedScene).instantiate()
	root.add_child(level)
	for i: int in 10:
		await physics_frame
	var registry: UnitRegistry = level.get_node("Units")
	var issuer: CommandIssuer = level.get_node("CommandIssuer")
	var scene: PackedScene = load(UNIT_SCENE)
	var stats: UnitStats = load(UNIT_STATS)
	var ids := PackedInt32Array()
	for i: int in UNITS:
		var unit: Unit = scene.instantiate()
		unit.stats = stats
		unit.team = 0
		unit.position = Vector3(-90.0 + (i % 10) * 2.5, 0.0, -90.0 + (i / 10) * 2.5)
		ids.append(registry.add(unit))
	var goal := Vector3(80.0, 0.0, 80.0)
	issuer.issue(Order.move(0, ids, goal))
	var start_usec: int = registry.get("step_usec")
	var start_pos: Vector3 = registry.get_unit(ids[0]).global_position
	var started: int = Time.get_ticks_usec()
	for i: int in TICKS:
		await physics_frame
	var wall: float = float(Time.get_ticks_usec() - started) / 1000.0
	var loop: float = float(int(registry.get("step_usec")) - start_usec) / 1000.0
	var moved: float = registry.get_unit(ids[0]).global_position.distance_to(start_pos)
	var arrived: int = 0
	for id: int in ids:
		var unit: Unit = registry.get_unit(id)
		if unit and unit.global_position.distance_to(goal) < 60.0:
			arrived += 1
	print("BENCH units=%d ticks=%d tick_ms=%.2f unit_loop_ms=%.2f near_goal=%d first_unit_moved_m=%.1f" % [
		UNITS, TICKS, wall / TICKS, loop / TICKS, arrived, moved])
	quit()
