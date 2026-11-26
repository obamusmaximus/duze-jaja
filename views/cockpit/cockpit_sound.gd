class_name CockpitSound
extends Node
## The sound of an inhabited flight: an engine loop and a wind loop that follow the flight, and the stall warning.
## Fades in and out over the cockpit switch. After the flight ends (leaving, death) the last sound fades away.
## View side: it only reads the flight.

const ENGINE_CUE: StringName = &"flight_engine"
const WIND_CUE: StringName = &"flight_wind"
const WARNING_CUE: StringName = &"stall_warning"

var _stats: FlightSoundStats
var _cockpit: CockpitStats
var _unit: Unit
var _engine: SfxLoop
var _wind: SfxLoop
var _warning: SfxLoop
## The fade over the switch, 0 to 1.
var _level: float = 0.0
var _engine_gain: float = 0.0
var _engine_pitch: float = 1.0
var _wind_gain: float = 0.0
var _wind_pitch: float = 1.0


func setup(stats: FlightSoundStats, cockpit: CockpitStats) -> void:
	_stats = stats
	_cockpit = cockpit
	_engine = _add_loop(ENGINE_CUE)
	_wind = _add_loop(WIND_CUE)
	_warning = _add_loop(WARNING_CUE)
	set_process(false)


func start(unit: Unit) -> void:
	_unit = unit
	var flight: PilotFlight = unit.pilot_flight()
	if flight != null:
		_follow(flight, 1.0)
	_drive()
	for loop: SfxLoop in [_engine, _wind]:
		if loop != null and not loop.playing:
			loop.play()
	set_process(true)


## The flight is over: fade out, then stop. The warning stops at once.
func stop() -> void:
	_unit = null
	_set_warning(false)


func is_warning() -> bool:
	return _warning != null and _warning.playing


func _process(delta: float) -> void:
	var flying: bool = is_instance_valid(_unit)
	_level = move_toward(_level, 1.0 if flying else 0.0, delta / maxf(_cockpit.transition_time, 0.01))
	if flying:
		var flight: PilotFlight = _unit.pilot_flight()
		if flight != null:
			_follow(flight, 1.0 - exp(-_stats.response * delta))
			_warn(flight.model)
		else:
			_set_warning(false) # On the autopilot.
	_drive()
	if not flying and _level <= 0.0:
		for loop: SfxLoop in [_engine, _wind]:
			if loop != null:
				loop.stop()
		set_process(false)


## Moves the two loops toward what the flight sounds like now, by `share` of the way.
func _follow(flight: PilotFlight, share: float) -> void:
	var model: PilotModel = flight.model
	var pace: float = model.velocity.length() / model.top_speed()
	var load_share: float = minf(model.stall_load(), 1.0)
	var pitch: float = lerpf(_stats.engine_pitch_slow, _stats.engine_pitch_fast, clampf(pace, 0.0, 1.5)) \
		+ _stats.engine_pitch_hover * model.hover_share()
	var rush: float = clampf(inverse_lerp(_stats.wind_from, maxf(_stats.wind_to, _stats.wind_from + 0.001), pace),
			0.0, 1.0)
	var wind: float = rush * rush + _stats.wind_stall_load * load_share * load_share * minf(pace, 1.0)
	if not flight.hovering() and flight.controls.air_brake:
		wind += _stats.wind_air_brake * minf(pace, 1.0)
	_engine_gain = lerpf(_engine_gain, 1.0, share)
	_engine_pitch = lerpf(_engine_pitch, pitch, share)
	_wind_gain = lerpf(_wind_gain, minf(wind, 1.5), share)
	_wind_pitch = lerpf(_wind_pitch, lerpf(_stats.wind_pitch_slow, _stats.wind_pitch_fast, clampf(pace, 0.0, 1.5)), share)


## On at the warning load, off only a little below it, so it never chatters; faster and higher in the stall itself.
func _warn(model: PilotModel) -> void:
	_set_warning(FlightWarnings.stall(model, is_warning(), _stats))
	if is_warning():
		_warning.drive(_level, _stats.warning_stall_pitch if model.stalled else 1.0)


## Starts from the top each time, so it always opens with a whole beep.
func _set_warning(on: bool) -> void:
	if _warning == null or on == _warning.playing:
		return
	if on:
		_warning.drive(_level)
		_warning.play()
	else:
		_warning.stop()


func _drive() -> void:
	if _engine != null:
		_engine.drive(_engine_gain * _level, _engine_pitch)
	if _wind != null:
		_wind.drive(_wind_gain * _level, _wind_pitch)


func _add_loop(id: StringName) -> SfxLoop:
	var loop: SfxLoop = Sfx.make_loop(id)
	if loop != null:
		add_child(loop)
	return loop
