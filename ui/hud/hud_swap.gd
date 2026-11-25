class_name HudSwap
extends Node
## Runs the glitch traces (`HudReveal`) that swap the RTS and strategy HUDs: the outgoing HUD's modules trace out to
## their screen edges while the incoming ones trace in, one after another. Runs on real time and while paused, like
## the view flight it goes with. Turning round mid-trace carries on from where each module is.

var _stats: UiStats
## Reveal to its running tween.
var _tweens: Dictionary = {}


func setup(stats: UiStats) -> void:
	_stats = stats
	process_mode = Node.PROCESS_MODE_ALWAYS


## Traces every module of `frame` to `target` (1 shown, 0 gone), starting after `delay` seconds.
func run(frame: HudFrame, target: float, delay: float = 0.0) -> void:
	for i: int in frame.reveals.size():
		var reveal: HudReveal = frame.reveals[i]
		_stop(reveal)
		var span: float = absf(target - reveal.progress)
		if span <= 0.0:
			continue
		var tween: Tween = create_tween()
		tween.set_ignore_time_scale(true)
		tween.tween_method(reveal.set_progress, reveal.progress, target, _stats.swap_time * span) \
				.set_delay(delay + _stats.swap_stagger * i)
		_tweens[reveal] = tween


## Shows or hides `frame` at once.
func snap(frame: HudFrame, shown: bool) -> void:
	for reveal: HudReveal in frame.reveals:
		_stop(reveal)
		reveal.set_progress(1.0 if shown else 0.0)


func _stop(reveal: HudReveal) -> void:
	var running: Tween = _tweens.get(reveal)
	if running != null and running.is_valid():
		running.kill()
	_tweens.erase(reveal)
