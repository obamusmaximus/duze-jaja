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
#include "res://views/birds_eye/cloud.gdshaderinc"
#include "res://terrain/terrain_shadow.gdshaderinc"

// Strength of the body's own glow (the light preset's).
uniform float body_glow = 1.0;

// 1 lights every triangle flat (facets), 0 lights it smooth from the analytic normal.
uniform float facet_amount = 1.0;

// Wave height (m), for the crest foam that joins later.
varying float wave_height_at;
// One height per triangle (its first vertex's), so the crest tint steps by facet.
varying flat float facet_height;
// How far into the terrain's shadow this pixel is (0 lit, 1 shadow), for light().
varying float terrain_shaded;

// The dense patch that follows the camera (WaterBody): waves fade to nothing at its edge so it meets the flat far sheet
// (`wave_gain` 0) without a step. `patch_half` 0 means one sheet: no fade.
uniform float wave_gain = 1.0;
// The far sheet lies this far (m) under the sea level, below any trough of the dense patch.
uniform float vertex_drop = 0.0;
uniform vec2 patch_center = vec2(0.0);
uniform float patch_half = 0.0;

float patch_fade(vec2 p) {
	if (patch_half <= 0.0) {
		return 1.0;
	}
	vec2 d = abs(p - patch_center);
	return 1.0 - smoothstep(patch_half * 0.7, patch_half, max(d.x, d.y));
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wave = wave_sum(world.xz, TIME) * wave_scale(island_distance(world.xz)) * wave_gain * patch_fade(world.xz);
	VERTEX.y += wave.x - vertex_drop;
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
	float cloud_light = cloud_shade(world_xz);
	ALBEDO = mix(shallow_color.rgb * tone, foam_color.rgb, foam) * cloud_light;
	vec3 body = mix(deep_color.rgb, shallow_color.rgb, reef_amount(world_xz));
	terrain_shaded = terrain_shadowed(world_xz);
	body *= 1.0 - terrain_shadow_sea * terrain_shaded;
	EMISSION = mix(body * tone * body_glow, foam_color.rgb * foam_glow, foam) * cloud_light;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	vec3 up = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	float ramp = light_ramp(dot(NORMAL, LIGHT), dot(up, LIGHT));
	// The terrain's shadow takes the sun or moon only (its light and its glitter), never a lamp.
	float reach = LIGHT_IS_DIRECTIONAL ? ATTENUATION * terrain_light_factor(terrain_shaded) : ATTENUATION;
	DIFFUSE_LIGHT += LIGHT_COLOR * reach * ramp * light_strength / PI;
	SPECULAR_LIGHT += glitter_tint(LIGHT_IS_DIRECTIONAL, LIGHT_COLOR) * reach * light_glitter(NORMAL, LIGHT, VIEW);
}
