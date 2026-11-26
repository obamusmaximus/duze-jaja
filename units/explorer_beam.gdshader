// A beam of light along a mesh's local Y (`ExplorerLook`): the searchlight cones and the beam up from the hull.
// Brightest at local y = -0.5 (the source), fading to nothing at +0.5, and fading where the beam is seen edge on.
// Additive and unshaded: an effect (`docs/style_guide.md`).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float intensity : hint_range(0.0, 4.0) = 0.15;
// How fast it fades along its length (higher: shorter).
uniform float falloff : hint_range(0.1, 8.0) = 1.2;

varying float along;

void vertex() {
	along = clamp(VERTEX.y + 0.5, 0.0, 1.0);
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	// Edge on (the cone's rim) fades out, and so does the far end, so no hard disc shows where it meets the ground.
	float body = pow(1.0 - along, falloff) * pow(facing, 3.0) * (1.0 - smoothstep(0.75, 1.0, along));
	ALBEDO = tint.rgb * intensity * body;
}
