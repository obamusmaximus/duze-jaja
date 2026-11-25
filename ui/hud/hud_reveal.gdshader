// The HUD swap's glitch trace (`docs/mechanics/ui.md`, "HUD swap"): a module traces in from the screen edge it is
// bound to, in streaks of blocks per row (or column), with a flickering band of dropouts and an acid-green head at
// the front. `progress` 0 is gone, 1 is whole. Every canvas item in the module shares the one material
// (`use_parent_material`), so positions are compared in canvas space against the module's rectangle.
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
// The module's rectangle in canvas space: position, size.
uniform vec4 rect = vec4(0.0, 0.0, 1.0, 1.0);
// The edge it is bound to: 0 left, 1 top, 2 right, 3 bottom.
uniform int side = 2;
// Block size in pixels (along the streak, across it).
uniform vec2 cell = vec2(24.0, 8.0);
// Width of the flickering band behind the front, as a fraction of the module.
uniform float band = 0.3;
// How far streaks lag each other, as a fraction of the module.
uniform float jitter = 0.35;
// Width of the solid head at the front, in pixels.
uniform float head = 6.0;
uniform float flicker_rate = 30.0;
uniform float seed = 0.0;
uniform vec4 trace_color : source_color = vec4(0.72, 1.0, 0.0, 1.0);

varying vec2 canvas_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	canvas_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 local = (canvas_pos - rect.xy) / max(rect.zw, vec2(1.0));
	bool across = side == 0 || side == 2;
	// Distance from the bound edge (0) to the far side (1), and the module's length along it in pixels.
	float t = side == 0 ? local.x : side == 2 ? 1.0 - local.x : side == 1 ? local.y : 1.0 - local.y;
	float length_px = across ? rect.z : rect.w;
	vec2 blocks = across ? cell : cell.yx;
	vec2 c = floor((canvas_pos - rect.xy) / blocks);
	float lane = across ? c.y : c.x;
	float lag = hash(vec2(lane, seed)) * jitter;
	float front = progress * (1.0 + jitter + band) - lag;
	float d = front - t;
	if (d < 0.0) {
		COLOR.a = 0.0;
	} else if (d * length_px < head) {
		// The head: the trace colour wherever the module draws.
		COLOR = vec4(trace_color.rgb, COLOR.a > 0.01 ? max(COLOR.a, trace_color.a) : 0.0);
	} else if (d < band) {
		// Behind the head: blocks flicker out, fewer as the band passes, tinted toward the trace colour.
		float k = 1.0 - d / band;
		float flick = hash(c + vec2(seed, floor(TIME * flicker_rate)));
		if (flick < k * 0.7) {
			COLOR.a = 0.0;
		} else {
			COLOR.rgb = mix(COLOR.rgb, trace_color.rgb, k * 0.6 * step(0.85, hash(c + seed)));
		}
	}
}
