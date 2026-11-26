// The terrain's sun and moon shadow (docs/mechanics/heightmap.md, "Terrain shadow"). TerrainShadow fills the mask (one
// byte per height sample, 1 lit) and its place; WorldLight sets the two strengths from the light preset. All are global
// shader uniforms (project.godot). With no mask (`terrain_shadow_rect` zero) everything is lit.
global uniform sampler2D terrain_shadow_mask : repeat_disable, filter_linear, hint_default_white;
// World x, z of the texture's corner, then one over its size in metres.
global uniform vec4 terrain_shadow_rect;
global uniform float terrain_shadow_strength;
global uniform float terrain_shadow_sea;

// 0 lit to 1 in shadow at world x, z.
float terrain_shadowed(vec2 xz) {
	vec2 uv = (xz - terrain_shadow_rect.xy) * terrain_shadow_rect.zw;
	if (terrain_shadow_rect.z <= 0.0 || any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return 0.0;
	}
	return 1.0 - textureLod(terrain_shadow_mask, uv, 0.0).r;
}

// The share of the directional light that gets through, `shadowed` from terrain_shadowed().
float terrain_light_factor(float shadowed) {
	return 1.0 - terrain_shadow_strength * shadowed;
}
