shader_type spatial;
// Last-known crosses (LastKnownHeat): a thin × with an open centre on the ground where an enemy was lost, in its team
// colour. When the contact has just been lost a ring pings out from it once; then the cross fades over the record's
// life. One multimesh: INSTANCE_CUSTOM.r is the record's age (seconds) when the multimesh was built.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform float strength = 1.0;
// Seconds since the multimesh was built, and the record's life in seconds.
uniform float elapsed = 0.0;
uniform float life = 180.0;
uniform float ping_time = 1.6;

varying float age;
varying vec3 tint;

void vertex() {
	age = INSTANCE_CUSTOM.r + elapsed;
	tint = COLOR.rgb;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0; // -1 to 1 across the quad.
	float px = max(fwidth(p.x), 0.0001);
	// The ×: distance to either diagonal, arms from a third out to the edge.
	float d = min(abs(p.x - p.y), abs(p.x + p.y)) * 0.7071;
	float r = length(p);
	float arm = (1.0 - smoothstep(0.5, 1.5, d / px)) * step(0.32, r) * step(r, 0.98);
	// A tiny centre dot.
	float dot_mark = 1.0 - smoothstep(0.04, 0.04 + 1.5 * px, r);
	float fade = clamp(1.0 - age / life, 0.0, 1.0);
	// The ping: a ring that grows to the quad's edge and fades, once.
	float ping_t = clamp(age / ping_time, 0.0, 1.0);
	float ring = (1.0 - smoothstep(0.5, 1.8, abs(r - ping_t * 0.98) / px)) * (1.0 - ping_t) * step(age, ping_time);
	float mark = max(arm, dot_mark) * (0.35 + 0.65 * fade) * fade + ring * 1.5;
	if (mark <= 0.002) {
		discard;
	}
	ALBEDO = tint * mark * strength;
}
