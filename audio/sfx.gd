extends Node
## Autoload `Sfx`: plays cues. World sounds come from a place (`play_at`), heard from the camera's focus point (the
## listener `attach_listener` puts on the camera rig); flat ones (`play_ui`) have no place. Keeps pools of players,
## a voice limit per cue and across the game, and puts a snappy hover and click on every button by itself. View
## side only: the simulation never calls it, it only emits signals that `GameSound` turns into cues.

const STATS_PATH: String = "res://tuning/audio_default.tres"
const LIBRARY_PATH: String = "res://tuning/sfx_library.tres"
## Buses made at start (Master already exists), in this order.
const BUSES: Array[StringName] = [&"SFX", &"UI", &"Ambient", &"Music"]
## Meta flag: a button with it set makes no UI sounds.
const SILENT_META: StringName = &"no_ui_sound"

var stats: AudioStats = load(STATS_PATH)
## Cue id to SfxCue.
var _cues: Dictionary = {}
var _world: Array[AudioStreamPlayer3D] = []
var _flat: Array[AudioStreamPlayer] = []
var _last_play: Dictionary = {}
var _ambient: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # UI sounds must work in the paused menu.
	_make_buses()
	var library: SfxLibrary = load(LIBRARY_PATH)
	for cue: SfxCue in library.cues:
		_cues[cue.id] = cue
	for i: int in stats.world_voices:
		var player := AudioStreamPlayer3D.new()
		add_child(player)
		_world.append(player)
	for i: int in stats.flat_voices:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_flat.append(player)
	stats.changed.connect(_apply_stats)
	_apply_stats()
	get_tree().node_added.connect(_on_node_added)


## Puts the listener on `rig` (the camera rig, whose origin is the focus point on the ground), so world sounds are
## loud near what the player is looking at and panned by the view's left and right.
func attach_listener(rig: Node3D) -> void:
	for old: Node in rig.find_children("*", "AudioListener3D", false, false):
		return
	var listener := AudioListener3D.new()
	listener.name = "SfxListener"
	rig.add_child(listener)
	listener.make_current()


## Plays `id` at a world point.
func play_at(id: StringName, point: Vector3) -> void:
	var cue: SfxCue = _ready_cue(id)
	if cue == null:
		return
	if not cue.positional:
		_play_flat(cue)
		return
	var player: AudioStreamPlayer3D = _free_player(_world, cue)
	if player == null:
		return
	player.stream = _pick(cue)
	player.global_position = point
	player.volume_db = cue.volume_db
	player.pitch_scale = randf_range(cue.pitch_min, cue.pitch_max)
	player.bus = cue.bus
	player.unit_size = stats.full_volume_distance
	player.max_distance = stats.max_distance
	player.panning_strength = stats.panning
	player.set_meta(&"cue", cue.id)
	player.play()


## Plays `id` flat (UI sounds, order acknowledgements: no place).
func play_ui(id: StringName) -> void:
	var cue: SfxCue = _ready_cue(id)
	if cue:
		_play_flat(cue)


## Starts a looping cue (an ambient bed) and returns nothing; `stop_ambient` ends it. One at a time.
func start_ambient(id: StringName) -> void:
	stop_ambient()
	var cue: SfxCue = _cues.get(id)
	if cue == null or cue.streams.is_empty():
		return
	_ambient = AudioStreamPlayer.new()
	_ambient.stream = _looped(cue.streams[0])
	_ambient.bus = cue.bus
	_ambient.volume_db = cue.volume_db
	add_child(_ambient)
	_ambient.play()


func stop_ambient() -> void:
	if _ambient:
		_ambient.queue_free()
		_ambient = null


func has_cue(id: StringName) -> bool:
	return _cues.has(id)


func _make_buses() -> void:
	for bus_name: StringName in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, &"Master")


func _apply_stats() -> void:
	var volumes: Dictionary = {&"SFX": stats.sfx_db, &"UI": stats.ui_db, &"Ambient": stats.ambient_db, &"Music": stats.music_db}
	for bus_name: StringName in volumes:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), volumes[bus_name])


## The cue if it exists and is allowed to play now (interval and voice limit), else null.
func _ready_cue(id: StringName) -> SfxCue:
	var cue: SfxCue = _cues.get(id)
	if cue == null or cue.streams.is_empty():
		return null
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_play.get(id, -10.0) < cue.min_interval:
		return null
	if _voices_of(cue) >= cue.max_voices:
		return null
	_last_play[id] = now
	return cue


func _voices_of(cue: SfxCue) -> int:
	var count: int = 0
	for player: AudioStreamPlayer3D in _world:
		if player.playing and player.get_meta(&"cue", &"") == cue.id:
			count += 1
	for player: AudioStreamPlayer in _flat:
		if player.playing and player.get_meta(&"cue", &"") == cue.id:
			count += 1
	return count


func _play_flat(cue: SfxCue) -> void:
	var player: AudioStreamPlayer = _free_player(_flat, cue)
	if player == null:
		return
	player.stream = _pick(cue)
	player.volume_db = cue.volume_db
	player.pitch_scale = randf_range(cue.pitch_min, cue.pitch_max)
	player.bus = cue.bus
	player.set_meta(&"cue", cue.id)
	player.play()


## An idle player from `pool`, or null when all are busy (the sound is dropped).
func _free_player(pool: Array, _cue: SfxCue) -> Variant:
	for player: Variant in pool:
		if not player.playing:
			return player
	return null


func _pick(cue: SfxCue) -> AudioStream:
	return cue.streams[randi() % cue.streams.size()]


func _looped(stream: AudioStream) -> AudioStream:
	var copy: AudioStream = stream.duplicate()
	if copy is AudioStreamWAV:
		var wav := copy as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / (2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1) / (2 if wav.stereo else 1)
	elif copy is AudioStreamOggVorbis:
		(copy as AudioStreamOggVorbis).loop = true
	return copy


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		if button.toggle_mode:
			button.toggled.connect(_on_button_toggled.bind(button))
		else:
			button.pressed.connect(_on_button_pressed.bind(button))
		button.mouse_entered.connect(_on_button_hover.bind(button))


func _on_button_hover(button: BaseButton) -> void:
	if not button.disabled and not button.has_meta(SILENT_META):
		play_ui(&"ui_hover")


func _on_button_pressed(button: BaseButton) -> void:
	if not button.has_meta(SILENT_META):
		play_ui(&"ui_click")


func _on_button_toggled(_on: bool, button: BaseButton) -> void:
	if not button.has_meta(SILENT_META):
		play_ui(&"ui_toggle")
