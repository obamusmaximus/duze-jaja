shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;
// Debug overlay: colours the ground by height with a contour line every `interval` metres and a bright line at the
// waterline (0 m). Below the sea it darkens with depth. Drawn over the terrain as a material overlay.

uniform float interval = 10.0;
uniform float band_top = 100.0;
uniform vec4 sea_color : source_color;
uniform vec4 low_color : source_color;
uniform vec4 mid_color : source_color;
uniform vec4 high_color : source_color;
uniform vec4 line_color : source_color;
uniform vec4 shore_color : source_color;

varying float h;

void vertex() {
	h = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	vec3 c;
	if (h < 0.0) {
		c = mix(sea_color.rgb, vec3(0.0), clamp(-h / 50.0, 0.0, 0.8));
	} else {
		float t = clamp(h / band_top, 0.0, 1.0);
		c = t < 0.5 ? mix(low_color.rgb, mid_color.rgb, t * 2.0) : mix(mid_color.rgb, high_color.rgb, t * 2.0 - 1.0);
	}
	float f = h / interval;
	float line = 1.0 - smoothstep(0.0, 1.0, abs(fract(f - 0.5) - 0.5) / (fwidth(f) * 1.5 + 0.0001));
	float shore = 1.0 - smoothstep(0.0, 1.0, abs(h) / (fwidth(h) * 1.5 + 0.0001));
	c = mix(c, line_color.rgb, line);
	c = mix(c, shore_color.rgb, shore);
	ALBEDO = c;
	ALPHA = clamp(0.6 + line * 0.4 + shore * 0.4, 0.0, 1.0);
}
