shader_type spatial;
// A last-known ghost (LastKnownGhosts): the feature-edge wireframe of a big unit where its enemy last saw it, drawn
// like a HUD line in the world. Fresh it is steady with a scan band climbing it; as the record ages the signal
// decays and the lines break into ever shorter dashes; when the record ends it dissolves upward.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform vec4 line_color : source_color = vec4(1.0);
uniform float strength = 1.0;
// Seconds between scan bands, and the band's height as a share of the ghost's.
uniform float scan_period = 3.2;
uniform float scan_width = 0.12;
// Metres of one dash at full decay.
uniform float dash = 1.6;

// 0 fresh to 1 expired; 0 to 1 through the dissolve; the ghost's height in metres.
instance uniform float age = 0.0;
instance uniform float dissolve = 0.0;
instance uniform float height = 10.0;

varying float rise;
varying vec3 world;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void vertex() {
	rise = clamp(VERTEX.y / max(height, 0.01), 0.0, 1.0);
	// Dissolving lines drift up and apart, each vertex its own way.
	float drift = dissolve * dissolve * (2.0 + 6.0 * hash(floor(VERTEX * 4.0)));
	VERTEX.y += drift;
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Decay: cells of the line drop out as the record ages, and all of them as it dissolves.
	float lost = hash(floor(world / dash));
	float decay = 0.55 * age * age + dissolve;
	if (lost < decay) {
		discard;
	}
	float scan_at = fract(TIME / scan_period);
	float band = 1.0 - smoothstep(0.0, scan_width, abs(rise - scan_at));
	float flicker = 0.88 + 0.12 * hash(vec3(floor(TIME * 18.0), lost, 0.0));
	float fade = (1.0 - age) * (1.0 - dissolve);
	ALBEDO = line_color.rgb * strength * fade * flicker * (0.55 + 0.45 * (1.0 - rise) + 1.4 * band);
}
