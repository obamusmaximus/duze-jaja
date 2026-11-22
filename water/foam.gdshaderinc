// Foam masks. The foam band along the cliffs: the shore factor (shore.gdshaderinc) cut hard against two drifting
// octaves of value noise, so its outer edge eats in and out but the water right at the cliff is always foam. The shore
// bands: broken lines at constant distance from the cliffs that travel in toward them, fading in at `band_reach` and
// thinning out into the foam band. Later: crest foam from the wave height.

uniform vec4 foam_color : source_color = vec4(0.75, 0.84, 0.95, 1.0);
uniform float foam_raggedness = 0.6;
uniform float foam_noise_scale = 3.0;
uniform float foam_speed = 0.6;
uniform float foam_glow = 0.35;
uniform float band_spacing = 9.0;
uniform float band_speed = 1.2;
uniform float band_width = 0.9;
uniform float band_reach = 32.0;
uniform float band_breakup = 0.45;

float foam_hash(vec2 p) {
	p = fract(p * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

float foam_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = foam_hash(i);
	float b = foam_hash(i + vec2(1.0, 0.0));
	float c = foam_hash(i + vec2(0.0, 1.0));
	float d = foam_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 0 to 1, anti-aliased but hard-edged. `p` is the world point (x, z), `shore` its shore factor, `t` the time.
float foam_mask(vec2 p, float shore, float t) {
	vec2 q = p / max(foam_noise_scale, 0.01);
	float drift = t * foam_speed / max(foam_noise_scale, 0.01);
	// Two octaves drifting different ways, so the edge churns instead of sliding.
	float n = 0.65 * foam_noise(q + vec2(drift, 0.3 * drift)) + 0.35 * foam_noise(q * 2.3 - vec2(0.4 * drift, drift));
	float edge = shore - foam_raggedness * n;
	float aa = max(fwidth(edge), 0.0001);
	return clamp(edge / aa + 0.5, 0.0, 1.0) * step(0.0001, shore);
}

// 0 to 1: the shore bands at world point `p` (x, z), `distance_m` from the cliffs, at time `t`.
float foam_bands(vec2 p, float distance_m, float t) {
	if (distance_m <= 0.0 || distance_m >= band_reach) {
		return 0.0;
	}
	float spacing = max(band_spacing, 0.1);
	// How far (m) this point is behind the nearest line in front of it; the lines move inward over time.
	float behind = fract((distance_m + t * band_speed) / spacing) * spacing;
	float fade_in = smoothstep(band_reach, band_reach * 0.6, distance_m);
	float thin_out = smoothstep(foam_width * 0.5, foam_width * 1.5, distance_m);
	float width = band_width * fade_in * thin_out;
	float aa = max(fwidth(distance_m), 0.0001);
	float line = clamp((width - behind) / aa + 0.5, 0.0, 1.0);
	float n = foam_noise(p / max(foam_noise_scale, 0.01) * 0.7 + vec2(13.0, 7.0) + vec2(t * 0.05));
	return line * step(band_breakup, n);
}
