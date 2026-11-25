// Distance to the shore and what depends on it. The shore is a union of rectangles (the island's parts, the carriers):
// the distance is the smallest box distance over `shore_rects` (min x, min z, max x, max z each), set by WaterBody.
// No depth texture is needed. Anything not listed in the rectangles gets no foam and no calm.

const int MAX_SHORE_RECTS = 48;
uniform vec4 shore_rects[MAX_SHORE_RECTS];
uniform int shore_rect_count = 0;
uniform float calm_begin = 150.0;
uniform float calm_end = 400.0;
uniform float foam_width = 5.0;
uniform float shore_calm_reach = 25.0;
uniform float shore_calm_level = 0.35;

// The baked shore field (ShoreField): red is the signed distance (m), green the water depth (m). Used instead of the
// rectangles when `use_field` is set (a heightmap level). The texture covers `field_origin` (world x, z of texel 0's
// centre) in steps of `field_texel` metres.
uniform sampler2D shore_field : filter_linear, repeat_disable;
uniform bool use_field = false;
uniform vec2 field_origin = vec2(0.0);
uniform float field_texel = 4.0;
uniform float reef_depth = 8.0;
uniform float reef_strength = 0.7;

vec2 field_at(vec2 p) {
	vec2 size = vec2(textureSize(shore_field, 0));
	return textureLod(shore_field, ((p - field_origin) / field_texel + 0.5) / size, 0.0).rg;
}

// How much of the shallow colour shallow water shows over the reef: 1 at no depth, 0 at `reef_depth`, 0 without a field.
float reef_amount(vec2 p) {
	if (!use_field) {
		return 0.0;
	}
	return (1.0 - smoothstep(0.0, max(reef_depth, 0.01), field_at(p).g)) * reef_strength;
}

// Signed distance (m) from world point `p` (x, z) to the nearest shore: negative inside.
float island_distance(vec2 p) {
	if (use_field) {
		return field_at(p).r;
	}
	float best = 100000.0;
	for (int i = 0; i < MAX_SHORE_RECTS; i++) {
		if (i >= shore_rect_count) {
			break;
		}
		vec4 r = shore_rects[i];
		vec2 centre = (r.xy + r.zw) * 0.5;
		vec2 half_size = (r.zw - r.xy) * 0.5;
		vec2 q = abs(p - centre) - half_size;
		best = min(best, length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0));
	}
	return best;
}

// The share of the wave height at `distance_m` from the shore: falling to 0 (flat water) between `calm_begin` and
// `calm_end`, so the far water doesn't shimmer, and damped to `shore_calm_level` within `shore_calm_reach` of the
// shore, as if it broke the waves.
float wave_scale(float distance_m) {
	float far_calm = 1.0 - smoothstep(calm_begin, max(calm_end, calm_begin + 0.01), distance_m);
	float shore_calm = mix(shore_calm_level, 1.0, smoothstep(0.0, max(shore_calm_reach, 0.01), distance_m));
	return far_calm * shore_calm;
}

// The shore factor: 1 at the shore, falling straight to 0 at `foam_width` out (m). What the foam is cut from.
float shore_factor(float distance_m) {
	return 1.0 - clamp(distance_m / max(foam_width, 0.01), 0.0, 1.0);
}
