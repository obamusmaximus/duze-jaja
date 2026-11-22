shader_type spatial;
render_mode cull_back;
// The faceted sea. vertex() and fragment() only call the modules; every number is a uniform set by WaterLook
// from WaterStats. Waves are stateless (driven by TIME), so they keep moving during a rewind.
//   waves.gdshaderinc    wave height and slope
//   shore.gdshaderinc    distance to the island, where the waves calm down, shore factor
//   foam.gdshaderinc     foam band along the cliffs, shore bands travelling in
//   shading.gdshaderinc  posterized light ramp, crest tint, sun glitter
// All lighting happens in light(), which runs for every light on the water, of any kind: no light is named here, so a
// sun or street lights in another level work the same way as the sun and the lamps here. Each light gets its own
// stepped light, shadows and glitter path toward it.

#include "res://water/waves.gdshaderinc"
#include "res://water/shore.gdshaderinc"
#include "res://water/foam.gdshaderinc"
#include "res://water/shading.gdshaderinc"

// 1 lights every triangle flat (facets), 0 lights it smooth from the analytic normal.
uniform float facet_amount = 1.0;

// Wave height (m), for the crest foam that joins later.
varying float wave_height_at;
// One height per triangle (its first vertex's), so the crest tint steps by facet.
varying flat float facet_height;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wave = wave_sum(world.xz, TIME) * wave_scale(island_distance(world.xz));
	VERTEX.y += wave.x;
	NORMAL = normalize(vec3(-wave.y, 1.0, -wave.z));
	wave_height_at = wave.x;
	facet_height = wave.x;
}

void fragment() {
	// The true normal of this triangle, turned toward the eye (the visible side).
	vec3 facet = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(facet, VIEW) < 0.0) {
		facet = -facet;
	}
	NORMAL = normalize(mix(NORMAL, facet, facet_amount));
	float tone = crest_tone(facet_height / max(wave_height, 0.01));
	// The shore distance per pixel (exact, unlike a varying across a 4 m triangle), so the band's corners stay round.
	vec2 world_xz = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float shore_m = island_distance(world_xz);
	float foam = max(foam_mask(world_xz, shore_factor(shore_m), TIME), foam_bands(world_xz, shore_m, TIME));
	ALBEDO = mix(shallow_color.rgb * tone, foam_color.rgb, foam);
	EMISSION = mix(deep_color.rgb * tone, foam_color.rgb * foam_glow, foam);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	vec3 up = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	float ramp = light_ramp(dot(NORMAL, LIGHT), dot(up, LIGHT));
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * ramp * light_strength / PI;
	SPECULAR_LIGHT += glitter_tint(LIGHT_IS_DIRECTIONAL, LIGHT_COLOR) * ATTENUATION * light_glitter(NORMAL, LIGHT, VIEW);
}
