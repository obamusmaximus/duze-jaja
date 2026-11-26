shader_type spatial;
// A flat pool of light (LightPool): additive, brightest in the middle, fading to nothing at its edge.
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled, fog_disabled;

global uniform float pool_brightness;

uniform vec4 tint : source_color = vec4(1.0);
uniform float strength = 0.15;
// 1 an ellipse, near 0 a rectangle with soft edges.
uniform float roundness = 1.0;

void fragment() {
	vec2 p = abs(UV - vec2(0.5)) * 2.0;
	float power = mix(8.0, 2.0, roundness);
	float d = pow(pow(p.x, power) + pow(p.y, power), 1.0 / power);
	float fall = 1.0 - smoothstep(0.0, 1.0, d);
	ALBEDO = tint.rgb * fall * strength * pool_brightness;
}
