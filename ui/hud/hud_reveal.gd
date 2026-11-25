class_name HudReveal
extends RefCounted
## The glitch trace of one HUD module (`hud_reveal.gdshader`): while it runs, the module and everything in it share
## one shader material; whole, the material comes off so the settled HUD costs nothing; gone, the module is hidden
## (no room taken, no clicks). `HudSwap` drives `set_progress`.

const SHADER: Shader = preload("res://ui/hud/hud_reveal.gdshader")

var module: HudModule
var progress: float = 1.0
var _material := ShaderMaterial.new()


## `side` is the screen edge the module is bound to (`SIDE_LEFT`, `SIDE_TOP`, `SIDE_RIGHT`, `SIDE_BOTTOM`).
func _init(of: HudModule, side: Side) -> void:
	module = of
	_material.shader = SHADER
	_material.set_shader_parameter(&"side", int(side))
	_material.set_shader_parameter(&"seed", float(randi() % 1000))
	_material.set_shader_parameter(&"trace_color", UiTokens.GREEN)


func apply_stats(stats: UiStats) -> void:
	_material.set_shader_parameter(&"cell", stats.glitch_cell)
	_material.set_shader_parameter(&"band", stats.glitch_band)
	_material.set_shader_parameter(&"jitter", stats.glitch_jitter)
	_material.set_shader_parameter(&"head", stats.glitch_head)
	_material.set_shader_parameter(&"flicker_rate", stats.glitch_flicker_rate)


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	module.visible = progress > 0.0
	if progress >= 1.0:
		module.material = null
		return
	if module.material != _material:
		module.material = _material
		_share(module)
	_material.set_shader_parameter(&"progress", progress)
	var rect: Rect2 = module.get_global_rect()
	_material.set_shader_parameter(&"rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))


## Makes every canvas item under `node` draw with the module's material (rows a module adds later pick it up on the
## next trace).
static func _share(node: Node) -> void:
	for child: Node in node.get_children():
		if child is CanvasItem:
			(child as CanvasItem).use_parent_material = true
		_share(child)
