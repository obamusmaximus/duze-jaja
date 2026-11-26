// The Explorer's energy bubble (`ExplorerLook`): a sphere of light that unfurls from its top down (`reveal`), with a
// bright band at the unfurling edge, a glowing rim and faint latitude and longitude ribs. Additive and unshaded: an
// effect, so it may glow (`docs/style_guide.md`).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.0, 0.85, 1.0, 1.0);
// 0: nothing, 1: the whole sphere (unfurled from the top down).
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.08;

varying vec3 local_dir;

void vertex() {
	local_dir = normalize(VERTEX);
}

void fragment() {
	float from_top = acos(clamp(local_dir.y, -1.0, 1.0)) / PI;
	if (from_top > reveal) {
		discard;
	}
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(1.0 - facing, 3.0);
	float lon = atan(local_dir.z, local_dir.x) / TAU * 24.0;
	float lat = from_top * 12.0;
	float ribs = max(1.0 - abs(fract(lon) - 0.5) * 2.0 / 0.04, 0.0) + max(1.0 - abs(fract(lat) - 0.5) * 2.0 / 0.04, 0.0);
	float front = (1.0 - smoothstep(0.0, 0.04, reveal - from_top)) * step(reveal, 0.999);
	float shimmer = 0.85 + 0.15 * sin(TIME * 2.0 + from_top * 40.0);
	float glow = opacity * shimmer + rim * 0.45 + clamp(ribs, 0.0, 1.0) * 0.06 + front * 0.9;
	ALBEDO = tint.rgb * glow;
}
