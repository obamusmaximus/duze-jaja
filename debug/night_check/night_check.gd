extends SceneTree
## Debug: night readability check (`docs/mechanics/debug_tools.md`, "Night check"). Takes the same fixed shots of the
## atoll by day and by night with its own test units, and prints how much each unit stands out from what is behind
## it: the mean luminance contrast ratio, over the unit's own pixels, between the frame with the unit and the frame
## without it (1 is invisible). In the bird's-eye view the unit's blip is measured, not its model. Run with a window:
##   godot --resolution 1600x900 --script res://debug/night_check/night_check.gd -- [output folder]
## Saves each shot as a PNG (default folder `user://night_check`). Changes nothing in the project.

const LEVEL: String = "res://levels/atoll/atoll.tscn"
const PRESETS: Dictionary = {
	"night": "res://tuning/light_night.tres",
	"day": "res://tuning/light_day.tres",
}
const GROUND_TYPES: Array[String] = ["trooper", "rover", "ifv", "tank", "vtol"]
const AIR_TYPES: Array[String] = ["vtol", "fighter", "carryall"]
## A night ratio below this share of day's is flagged.
const FLAG_BELOW: float = 0.9

var _out: String = "user://night_check"
var _level: Node
## Shot name -> {camera setup, subjects}.
var _lit: Vector3
var _shaded: Vector3
var _sea: Vector3
var _peak: Vector3
var _subjects: Array[Node3D] = []
var _labels: PackedStringArray = []
var _camera: Camera3D
## "shot/unit" -> {preset: ratio}.
var _results: Dictionary = {}


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	for path: String in ["res://tuning/camera_atoll.tres", "res://tuning/camera_birdseye.tres"]:
		load(path).set("edge_scroll_enabled", false)
	_level = (load(LEVEL) as PackedScene).instantiate()
	root.add_child(_level)
	await _wait(3.0)
	_freeze()
	_find_spots()
	_camera = Camera3D.new()
	_camera.far = 6000.0
	_level.add_child(_camera)
	for preset: String in PRESETS:
		_level.get_node("WorldLight").use_preset(load(PRESETS[preset]))
		await _wait(1.0)
		await _ground_shot(preset, "rts_lit", _lit)
		await _ground_shot(preset, "rts_shadow", _shaded)
		await _sea_shot(preset)
		await _ridge_shot(preset)
		await _cockpit_shot(preset)
		await _birds_shot(preset)
	_report()
	quit()


## Stops the simulation, the sea, the clouds and blinking lamps (steady lamps stay on), so frames differ only in what the check changes, and clears the
## level's own units out of the shots.
func _freeze() -> void:
	_level.fog.reveal_all = true
	_level._units.set_physics_process(false)
	for unit: Node3D in _level._units.all_units():
		unit.visible = false
		unit.global_position.y -= 2000.0
	var water: Resource = _level.get_node("Water").stats
	for property: String in ["wave_speed", "foam_speed", "band_speed"]:
		water.set(property, 0.0)
	water.emit_changed()
	var birds: Resource = load("res://tuning/birds_eye_default.tres")
	birds.set("wind_speed", 0.0)
	birds.emit_changed()
	_level.get_node("LampField").set_blinking(false)
	_level.get_node("Hud").visible = false
	_level.get_node("BattlefieldReadout").visible = false


## Fixed spots near team 0's airfield, chosen from the night preset's terrain shadow: gentle lit ground, gentle
## shadowed ground, open sea, and the highest ground.
func _find_spots() -> void:
	_level.get_node("WorldLight").use_preset(load(PRESETS.night))
	var heights: TerrainHeights = _level.heights
	var shadow: TerrainShadow = _level.get_node("TerrainChunks").shadow()
	var home: Vector2 = _level.battlefield.airfield_west
	var best_lit: float = INF
	var best_shaded: float = INF
	var best_sea: float = INF
	var top: float = -INF
	for iz: int in range(8, heights.samples.y - 8, 4):
		for ix: int in range(8, heights.samples.x - 8, 4):
			var at: Vector2 = heights.origin + Vector2(ix, iz) * heights.spacing
			var height: float = heights.sample_height(ix, iz)
			if height > top:
				top = height
				_peak = Vector3(at.x, height, at.y)
			var distance: float = at.distance_to(home)
			if distance < 60.0 or distance > 900.0:
				continue
			var low: float = INF
			var high: float = -INF
			var lit: float = 0.0
			var count: int = 0
			var reach: int = ceili(26.0 / heights.spacing)
			for dz: int in range(-reach, reach + 1, 2):
				for dx: int in range(-reach, reach + 1, 2):
					var h: float = heights.sample_height(clampi(ix + dx, 0, heights.samples.x - 1),
							clampi(iz + dz, 0, heights.samples.y - 1))
					low = minf(low, h)
					high = maxf(high, h)
					lit += shadow.lit_at(ix + dx, iz + dz)
					count += 1
			lit /= count
			if high < -4.0 and distance < best_sea:
				best_sea = distance
				_sea = Vector3(at.x, 0.0, at.y)
			if low < 1.5 or high - low > 12.0:
				continue
			# Prefer flat, then near.
			var score: float = (high - low) * 40.0 + distance
			if lit > 0.97 and score < best_lit:
				best_lit = score
				_lit = Vector3(at.x, height, at.y)
			if lit < 0.12 and score < best_shaded:
				best_shaded = score
				_shaded = Vector3(at.x, height, at.y)
	print("spots: lit %s  shadow %s  sea %s  peak %s" % [_lit.round(), _shaded.round(), _sea.round(), _peak.round()])


func _spawn(type: String, team: int, at: Vector3, height: float = 0.0) -> void:
	var stats: UnitStats = load("res://tuning/unit_%s.tres" % type)
	var ground: float = maxf(_level.heights.height_at(at.x, at.z), 0.0)
	var lift: float = height if height > 0.0 else (10.0 if stats.flying else 0.1)
	var unit: Node3D = _level._units.spawn(stats, team, Vector3(at.x, ground + lift, at.z))
	unit.global_position = Vector3(at.x, ground + lift, at.z)
	unit.rotation.y = 0.6
	_subjects.append(unit)
	_labels.append("%s_t%d" % [type, team])


func _clear() -> void:
	for unit: Node3D in _subjects:
		unit.visible = false
		unit.global_position.y -= 2000.0
	_subjects.clear()
	_labels.clear()


## A row per team of every ground type (and a hovering VTOL), seen by the RTS camera.
func _ground_shot(preset: String, shot: String, spot: Vector3) -> void:
	for team: int in 2:
		for i: int in GROUND_TYPES.size():
			_spawn(GROUND_TYPES[i], team, spot + Vector3((i - 2) * 11.0, 0.0, team * 16.0 - 8.0))
	await _rts_view(spot)
	await _measure(preset, shot)
	_clear()


func _sea_shot(preset: String) -> void:
	for team: int in 2:
		for i: int in AIR_TYPES.size():
			_spawn(AIR_TYPES[i], team, _sea + Vector3((i - 1) * 24.0, 0.0, team * 26.0 - 13.0), 12.0)
	await _rts_view(_sea)
	await _measure(preset, "rts_sea")
	_clear()


## Units on the skyline of the highest ground, seen from low down to its south.
func _ridge_shot(preset: String) -> void:
	var eye: Vector3 = _peak + Vector3(0.0, -22.0, 130.0)
	for i: int in 4:
		_spawn(["tank", "ifv", "tank", "rover"][i], i % 2, _skyline(eye, _peak.x + (i - 1.5) * 14.0))
	for team: int in 2:
		_spawn("vtol", team, _skyline(eye, _peak.x + (team * 2 - 1) * 42.0), 14.0)
	_fixed_view(eye, _peak + Vector3(0.0, 2.0, 0.0), 50.0)
	await _measure(preset, "ridge")
	_clear()


## The point at `x` that makes the skyline as seen from `eye`: the ground seen highest.
func _skyline(eye: Vector3, x: float) -> Vector3:
	var best := Vector3(x, 0.0, _peak.z)
	var steepest: float = -INF
	for offset: int in range(-60, 61, 2):
		var z: float = _peak.z + offset
		var height: float = _level.heights.height_at(x, z)
		var slope: float = (height - eye.y) / maxf(eye.z - z, 1.0)
		if slope > steepest:
			steepest = slope
			best = Vector3(x, height, z)
	return best


## What a pilot sees: flyers ahead against the sky, the land and the sea.
func _cockpit_shot(preset: String) -> void:
	var eye: Vector3 = _lit + Vector3(0.0, 70.0, 0.0)
	var ahead: Vector3 = (_sea - _lit).slide(Vector3.UP).normalized()
	var side: Vector3 = ahead.cross(Vector3.UP)
	var places: Array[Array] = [["fighter", 1, 80.0, -30.0, 82.0], ["vtol", 1, 90.0, 25.0, 76.0],
			["fighter", 0, 120.0, 0.0, 45.0], ["vtol", 0, 110.0, -45.0, 35.0], ["carryall", 1, 170.0, 40.0, 40.0]]
	for place: Array in places:
		var at: Vector3 = eye + ahead * place[2] + side * place[3]
		_spawn(place[0], place[1], at, 1.0)
		_subjects[-1].global_position.y = _lit.y + place[4]
	_fixed_view(eye, eye + ahead * 100.0 + Vector3(0.0, -12.0, 0.0), 75.0)
	await _measure(preset, "cockpit")
	_clear()


## Blips over lit ground, shadowed ground and sea.
func _birds_shot(preset: String) -> void:
	var spots: Dictionary = {"ground": _lit, "shadow": _shaded, "sea": _sea}
	for place: String in spots:
		for team: int in 2:
			var type: String = "carryall" if place == "sea" else "tank"
			_spawn(type, team, spots[place] + Vector3(team * 60.0 - 30.0, 0.0, 0.0), 20.0 if place == "sea" else 0.0)
			_labels[-1] = "%s_%s" % [place, _labels[-1]]
	_camera.current = false
	_level._camera_rig.get_camera().make_current()
	_level.views.switch_to(ViewSwitcher.View.BIRDS_EYE)
	await _wait(2.5)
	_level.birds_eye.rig.focus_on((_lit + _shaded + _sea) / 3.0, true)
	await _wait(1.0)
	await _measure_blips(preset)
	_clear()
	_level.views.switch_to(ViewSwitcher.View.RTS)
	await _wait(2.5)


func _rts_view(spot: Vector3) -> void:
	_camera.current = false
	_level._camera_rig.get_camera().make_current()
	_level._camera_rig.focus_on(spot, true)
	await _wait(2.0)


func _fixed_view(from: Vector3, to: Vector3, fov: float) -> void:
	_camera.fov = fov
	_camera.look_at_from_position(from, to)
	_camera.make_current()


func _measure(preset: String, shot: String) -> void:
	await _wait(0.5)
	var full: Image = await _frame()
	full.save_png("%s/%s_%s.png" % [_out, preset, shot])
	var magenta: StandardMaterial3D = _flat(Color(1.0, 0.0, 1.0))
	var green: StandardMaterial3D = _flat(Color(0.0, 1.0, 0.0))
	for i: int in _subjects.size():
		var unit: Node3D = _subjects[i]
		unit.visible = false
		var without: Image = await _frame()
		unit.visible = true
		var parts: Array[Node] = unit.find_children("*", "GeometryInstance3D", true, false)
		var old: Array[Material] = []
		for part: GeometryInstance3D in parts:
			old.append(part.material_overlay)
			part.material_overlay = magenta
		var first: Image = await _frame()
		for part: GeometryInstance3D in parts:
			part.material_overlay = green
		var second: Image = await _frame()
		for p: int in parts.size():
			(parts[p] as GeometryInstance3D).material_overlay = old[p]
		_record(preset, shot, _labels[i], full, without, first, second, Rect2i(Vector2i.ZERO, full.get_size()))


func _measure_blips(preset: String) -> void:
	await _wait(0.5)
	var full: Image = await _frame()
	full.save_png("%s/%s_birds.png" % [_out, preset])
	var blips: Control = _level.birds_eye.blips
	blips.modulate.a = 0.0
	for unit: Node3D in _subjects:
		unit.visible = false
	var bare: Image = await _frame()
	blips.modulate.a = 1.0
	var camera: Camera3D = root.get_viewport().get_camera_3d()
	var scale: Vector2 = Vector2(full.get_size()) / root.get_visible_rect().size
	for i: int in _subjects.size():
		var at := Vector2i(camera.unproject_position(_subjects[i].global_position) * scale)
		var window := Rect2i(at - Vector2i(10, 10), Vector2i(21, 21)).intersection(Rect2i(Vector2i.ZERO, full.get_size()))
		_record(preset, "birds", _labels[i], full, bare, full, bare, window)


## Adds the unit's contrast: the pixels of `window` where `first` and `second` differ are the unit's.
func _record(preset: String, shot: String, label: String, full: Image, without: Image, first: Image,
		second: Image, window: Rect2i) -> void:
	var total: float = 0.0
	var count: int = 0
	for y: int in range(window.position.y, window.end.y):
		for x: int in range(window.position.x, window.end.x):
			var a: Color = first.get_pixel(x, y)
			var b: Color = second.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.35:
				continue
			var with_unit: float = full.get_pixel(x, y).srgb_to_linear().get_luminance()
			var behind: float = without.get_pixel(x, y).srgb_to_linear().get_luminance()
			total += (maxf(with_unit, behind) + 0.05) / (minf(with_unit, behind) + 0.05)
			count += 1
	var key: String = "%s/%s" % [shot, label]
	if not _results.has(key):
		_results[key] = {}
	_results[key][preset] = Vector2(total / maxi(count, 1), count)


func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.disable_fog = true
	return material


func _frame() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


## A line per unit, then each shot's mean and worst unit.
func _report() -> void:
	var shots: Dictionary = {}
	var lines: PackedStringArray = ["shot/unit, day ratio, night ratio, night/day, night pixels"]
	for key: String in _results:
		var day: Vector2 = _results[key].get("day", Vector2.ZERO)
		var night: Vector2 = _results[key].get("night", Vector2.ZERO)
		var shot: String = key.get_slice("/", 0)
		if night.y < 4.0 or day.y < 4.0:
			lines.append("%s, not visible (day %d px, night %d px)" % [key, day.y, night.y])
			continue
		lines.append("%s, %.2f, %.2f, %.2f, %d" % [key, day.x, night.x, night.x / day.x, night.y])
		if not shots.has(shot):
			shots[shot] = []
		shots[shot].append([day.x, night.x, key.get_slice("/", 1)])
	var file := FileAccess.open(_out + "/report.csv", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("shot: mean day / night, worst day / night, units under %.0f %% of day" % (FLAG_BELOW * 100.0))
	for shot: String in shots:
		var sums := Vector2.ZERO
		var worst := Vector2(INF, INF)
		var flagged: PackedStringArray = []
		for row: Array in shots[shot]:
			sums += Vector2(row[0], row[1])
			worst = worst.min(Vector2(row[0], row[1]))
			if row[1] < row[0] * FLAG_BELOW:
				flagged.append("%s %.2f/%.2f" % [row[2], row[0], row[1]])
		sums /= shots[shot].size()
		print("%-10s mean %.2f / %.2f   worst %.2f / %.2f   %s" % [shot, sums.x, sums.y, worst.x, worst.y,
				", ".join(flagged)])
	print("report and shots in ", ProjectSettings.globalize_path(_out))
