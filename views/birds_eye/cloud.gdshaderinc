// Shared cloud globals and the shadow lookup (docs/mechanics/birds_eye.md). The cloud layers, the sea and the terrain
// overlay all read the same noise at world x, z, so a shadow always lies under its cloud. The values are global shader
// uniforms (project.godot) set by BirdsEyeClouds; cloud_shadow_strength is 0 outside the bird's-eye view.
global uniform sampler2D cloud_noise : repeat_enable, filter_linear;
global uniform vec2 cloud_offset;
global uniform float cloud_scale;
global uniform float cloud_coverage;
global uniform float cloud_softness;
global uniform vec2 cloud_shadow_shift;
global uniform float cloud_shadow_strength;

// Cloud density (0 to 1) at world x, z for one layer: `scale_mul` and `offset_mul` vary the layers.
float cloud_cover(vec2 xz, float scale_mul, vec2 offset_mul) {
	float n = texture(cloud_noise, xz * cloud_scale * scale_mul + cloud_offset * offset_mul).r;
	float edge = 1.0 - cloud_coverage;
	return smoothstep(edge - cloud_softness * 0.5, edge + cloud_softness * 0.5, n);
}

// Light factor (1 = full sun) the clouds leave at a ground point.
float cloud_shade(vec2 xz) {
	if (cloud_shadow_strength <= 0.0) {
		return 1.0;
	}
	return 1.0 - cloud_cover(xz + cloud_shadow_shift, 1.0, vec2(1.0)) * cloud_shadow_strength;
}
