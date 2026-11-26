shader_type spatial;
// The heightmap ground (WorldMaterials.ground()): one palette role, flat-shaded facets, the baked vertex colours as
// albedo. It exists for light(), which takes the terrain's shadow off the directional light only; Godot has no other
// way to block one kind of light. light() is the same Burley diffuse and GGX highlight the models' StandardMaterial3D
// uses, so ground and models match.

#include "res://terrain/terrain_shadow.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness = 1.0;
uniform float specular = 0.2;

// Coverage (CoverageView): unwatched ground darkens under a fine, faint wireframe. `coverage_map` holds one texel per
// coverage cell (1 watched) and `coverage_map_from` the sweep before it, faded between by `coverage_blend`; until there
// is one, everything counts as watched. `coverage_cell` is the wireframe's square (a coverage block). The wireframe has three parts: hairlines every
// `coverage_divisions`th of a cell, small crosses on the cell corners, and a contour where watched ground ends.
uniform sampler2D coverage_map : hint_default_white, filter_linear, repeat_disable;
uniform sampler2D coverage_map_from : hint_default_white, filter_linear, repeat_disable;
uniform float coverage_blend = 1.0;
uniform vec4 coverage_area = vec4(0.0, 0.0, 1.0, 1.0); // The grid's corner (x, z) and size, metres.
uniform float coverage_cell = 32.0;
uniform float coverage_divisions = 4.0;
uniform float coverage_show = 0.0;
uniform float coverage_dim = 0.0;
uniform float coverage_line = 0.0;
uniform float coverage_tick = 0.0;
uniform float coverage_edge = 0.0;
uniform vec4 coverage_line_color : source_color = vec4(1.0);

// Last known (LastKnownHeat): lost enemies' heat on unwatched ground, as faint contour bands. `heat_map` holds, per
// texel, the heat when it was built (r) and how fast it cools (g, per second), so it fades with no rebuild:
// heat = r - g * heat_elapsed.
uniform sampler2D heat_map : hint_default_black, filter_linear, repeat_disable;
uniform vec4 heat_area = vec4(0.0, 0.0, 1.0, 1.0);
uniform float heat_elapsed = 0.0;
uniform float heat_show = 0.0;
uniform float heat_strength = 0.0;
uniform float heat_bands = 4.0;
uniform vec4 heat_color : source_color = vec4(1.0);

varying vec2 world_xz;
// How far into the terrain's shadow this pixel is (0 lit, 1 shadow), for light().
varying float terrain_shaded;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	ALBEDO = albedo.rgb * COLOR.rgb;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	terrain_shaded = terrain_shadowed(world_xz);
	vec2 from_corner = world_xz - coverage_area.xy;
	vec2 coverage_uv = from_corner / coverage_area.zw;
	float watched = mix(texture(coverage_map_from, coverage_uv).r, texture(coverage_map, coverage_uv).r, coverage_blend);
	float unwatched = smoothstep(0.25, 0.75, 1.0 - watched) * coverage_show;
	ALBEDO *= 1.0 - coverage_dim * unwatched;
	vec2 in_cells = from_corner / coverage_cell;
	vec2 cell_pixel = max(fwidth(in_cells), vec2(0.00001));
	float cell_size = max(cell_pixel.x, cell_pixel.y); // One pixel in cells: small when close.
	// Hairlines a pixel wide; they go where they would crowd closer than about eight pixels.
	vec2 in_fine = in_cells * coverage_divisions;
	vec2 fine_pixel = cell_pixel * coverage_divisions;
	vec2 fine_off = (0.5 - abs(fract(in_fine) - 0.5)) / fine_pixel;
	float fine = 1.0 - smoothstep(0.3, 1.1, min(fine_off.x, fine_off.y));
	fine *= 1.0 - smoothstep(0.08, 0.16, max(fine_pixel.x, fine_pixel.y));
	// Corner crosses: a short arm along each cell edge from every corner, a fifth of the cell, at least three pixels.
	vec2 edge_cells = 0.5 - abs(fract(in_cells) - 0.5); // Distance to the nearest edge, in cells.
	vec2 edge_px = edge_cells / cell_pixel;
	float arm = max(0.1, 3.0 * cell_size);
	float tick_x = (1.0 - smoothstep(0.4, 1.3, edge_px.x)) * step(edge_cells.y, arm);
	float tick_z = (1.0 - smoothstep(0.4, 1.3, edge_px.y)) * step(edge_cells.x, arm);
	float tick = max(tick_x, tick_z) * (1.0 - smoothstep(0.15, 0.35, cell_size));
	// The frontier: a contour where the smoothed coverage crosses one half, about a pixel and a half wide.
	float shade = 1.0 - watched;
	float edge = 1.0 - smoothstep(0.6, 1.6, abs(shade - 0.5) / max(fwidth(shade), 0.0001));
	edge *= coverage_show * step(0.001, fwidth(shade));
	float wire = (fine * coverage_line + tick * coverage_tick) * unwatched + edge * coverage_edge;
	EMISSION = coverage_line_color.rgb * wire;
	// Heat: a faint fill that rises toward the core, cut into bands with a hairline on each, on unwatched ground only.
	vec2 heat_texel = texture(heat_map, (world_xz - heat_area.xy) / heat_area.zw).rg;
	float heat = max(heat_texel.r - heat_texel.g * heat_elapsed, 0.0);
	float warm = 1.0 - exp(-heat); // 0 to 1, saturating where many were lost.
	float banded = warm * heat_bands;
	float band_line = 1.0 - smoothstep(0.5, 1.5, (0.5 - abs(fract(banded) - 0.5)) / max(fwidth(banded), 0.0001));
	band_line *= step(0.5, banded);
	float fill = floor(banded) / heat_bands * 0.35;
	float heat_mark = (fill + band_line * warm) * heat_strength * heat_show * max(unwatched, 1.0 - coverage_show);
	EMISSION += heat_color.rgb * heat_mark;
	ALBEDO *= 1.0 - 0.5 * heat_mark;
}

void light() {
	float n_dot_l = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float n_dot_v = max(dot(NORMAL, VIEW), 0.0001);
	vec3 halfway = normalize(LIGHT + VIEW);
	float n_dot_h = clamp(dot(NORMAL, halfway), 0.0, 1.0);
	float l_dot_h = clamp(dot(LIGHT, halfway), 0.0, 1.0);
	float reach = ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		reach *= terrain_light_factor(terrain_shaded);
	}
	float grazing = 2.0 * l_dot_h * l_dot_h * ROUGHNESS - 0.5;
	float view_term = 1.0 + grazing * pow(1.0 - n_dot_v, 5.0);
	float light_term = 1.0 + grazing * pow(1.0 - n_dot_l, 5.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * reach * view_term * light_term * n_dot_l / PI;
	float alpha = max(ROUGHNESS * ROUGHNESS, 0.002);
	float spread = n_dot_h * n_dot_h * (alpha * alpha - 1.0) + 1.0;
	float distribution = alpha * alpha / (PI * spread * spread);
	float visibility = 0.5 / mix(2.0 * n_dot_l * n_dot_v, n_dot_l + n_dot_v, alpha);
	float f0 = 0.16 * specular * specular;
	float fresnel = f0 + (clamp(f0 * 16.5, 0.0, 1.0) - f0) * pow(1.0 - l_dot_h, 5.0);
	SPECULAR_LIGHT += LIGHT_COLOR * reach * n_dot_l * distribution * visibility * fresnel * SPECULAR_AMOUNT;
}
