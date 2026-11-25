// One cloud layer (docs/mechanics/birds_eye.md): a big flat quad, unshaded and alpha blended, coverage from the shared
// noise (cloud.gdshaderinc), a second noise tap toward the sun for fake volume, thicker toward the screen edges, and
// faded out near the camera so the flight passes through without whiteout.
shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

#include "res://views/birds_eye/cloud.gdshaderinc"

uniform float scale_mul = 1.0;
uniform vec2 offset_mul = vec2(1.0);
uniform vec3 lit_color : source_color = vec3(1.0);
uniform vec3 shade_color : source_color = vec3(0.62, 0.68, 0.78);
uniform vec2 sun_uv = vec2(0.02, 0.02);
uniform float light_gain = 6.0;
uniform float opacity = 0.9;
uniform float edge_bias = 0.8;
uniform float edge_start = 0.3;
uniform float fade_near = 40.0;
uniform float fade_range = 200.0;
uniform float strength = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 xz = world_pos.xz;
	float cover = cloud_cover(xz, scale_mul, offset_mul);
	// Fake volume: more cloud toward the sun than at the point means a shaded face.
	float toward = texture(cloud_noise, xz * cloud_scale * scale_mul + cloud_offset * offset_mul + sun_uv).r;
	float here = texture(cloud_noise, xz * cloud_scale * scale_mul + cloud_offset * offset_mul).r;
	float lit = clamp(0.5 + (here - toward) * light_gain, 0.0, 1.0);
	ALBEDO = mix(shade_color, lit_color, lit);
	// Thick at the screen edges, thin over the middle.
	float r = length((SCREEN_UV - 0.5) * 2.0) * 0.7071;
	float framing = mix(1.0 - edge_bias, 1.0, smoothstep(edge_start, 1.0, r));
	float height_fade = smoothstep(fade_near, fade_near + fade_range, abs(CAMERA_POSITION_WORLD.y - world_pos.y));
	ALPHA = cover * opacity * framing * height_fade * strength;
}
