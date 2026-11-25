// Cloud shadows over the terrain (docs/mechanics/birds_eye.md): a multiply overlay on the heightmap chunks, using the
// same noise as the clouds. Only on the chunks while the bird's-eye view is up or being flown to.
shader_type spatial;
render_mode blend_mul, unshaded, depth_draw_never, cull_back, fog_disabled, shadows_disabled;

#include "res://views/birds_eye/cloud.gdshaderinc"

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	ALBEDO = vec3(cloud_shade(world_xz));
	ALPHA = 1.0;
}
