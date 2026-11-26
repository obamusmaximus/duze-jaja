// A beacon light's glow (`ExplorerLook`): a camera-facing quad with a hot centre and a soft halo. Additive and
// unshaded: an effect (`docs/style_guide.md`).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0);
// Quad size in metres.
uniform float size = 2.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	VERTEX *= size;
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float core = 1.0 - smoothstep(0.0, 0.18, r);
	float halo = pow(max(1.0 - r, 0.0), 2.5) * 0.8;
	ALBEDO = mix(tint.rgb, vec3(1.0), core * 0.7) * (core + halo) * 2.0;
}
