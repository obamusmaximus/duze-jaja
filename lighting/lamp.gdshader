shader_type spatial;
// Every lamp (LampField, one instance each): a camera-facing glow with a hot centre and a soft halo, `size` metres
// across but never under `min_px` pixels, so it still reads from far away. Instance colour is the lamp's colour
// (alpha its strength); custom data is size, smallest screen size, period (0 steady, positive blinking, negative a
// double strobe) and phase. Additive and unshaded: an effect (docs/style_guide.md). The light preset sets how bright.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

global uniform float lamp_brightness;

// Off: only steady lamps show (the night check).
uniform bool blinking = true;

// How far (m) toward the eye a lamp is drawn, so the surface it sits on doesn't cut its glow in half.
const float PULL = 1.2;

varying flat vec4 lamp_color;

float shining(float period, float phase) {
	if (period == 0.0) {
		return 1.0;
	}
	if (!blinking) {
		return 0.0;
	}
	float t = fract(TIME / abs(period) + phase);
	if (period > 0.0) {
		return step(t, 0.35);
	}
	return step(t, 0.04) + step(0.1, t) * step(t, 0.14);
}

void vertex() {
	vec3 center = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz, 1.0)).xyz;
	// Metres one pixel covers at the lamp's depth.
	float pixel = 2.0 * max(-center.z, 0.0) / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y);
	float diameter = max(INSTANCE_CUSTOM.x, INSTANCE_CUSTOM.y * pixel) * shining(INSTANCE_CUSTOM.z, INSTANCE_CUSTOM.w);
	// Toward the eye along its own ray, shrunk to match, so it stays the same size on screen.
	float reach = max(length(center), 0.001);
	float keep = 1.0 - min(PULL, reach * 0.5) / reach;
	POSITION = PROJECTION_MATRIX * vec4((center + vec3(VERTEX.xy * diameter, 0.0)) * keep, 1.0);
	lamp_color = COLOR;
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float core = 1.0 - smoothstep(0.28, 0.48, r);
	float halo = pow(max(1.0 - r, 0.0), 2.0) * 0.8;
	ALBEDO = mix(lamp_color.rgb, vec3(1.0), core * 0.12) * (core + halo) * lamp_color.a * 2.2 * lamp_brightness;
}
