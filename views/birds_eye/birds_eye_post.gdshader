shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled;
// Full-screen post pass of the bird's-eye view: tilt-shift and edge blur from the screen texture's mips (nine taps),
// an unsharp mask in the sharp area, then grade, haze and vignette. Screen-space only (SCREEN_UV), fixed cost.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float strength = 1.0;
uniform float band_center = 0.55;
uniform float band_half = 0.175;
uniform float band_falloff = 0.35;
uniform float far_blur = 0.9;
uniform float near_blur = 0.6;
uniform float edge_blur = 0.7;
uniform float max_lod = 4.5;
uniform float clarity = 0.6;
uniform float focus_saturation = 1.2;
uniform float focus_contrast = 1.1;
uniform vec3 haze_color = vec3(0.72, 0.8, 0.88);
uniform float edge_haze = 0.35;
uniform float edge_desat = 0.4;
uniform float vignette = 0.25;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 sharp = textureLod(screen_tex, uv, 0.0).rgb;
	// Tilt-shift: blur grows past the band, more toward the far (top) side.
	float d = uv.y - band_center;
	float row = smoothstep(0.0, band_falloff, abs(d) - band_half);
	float row_blur = row * (d < 0.0 ? far_blur : near_blur);
	// Radial: toward the corners, aspect-corrected so it is round.
	vec2 c = (uv - 0.5) * 2.0;
	float edge = smoothstep(0.45, 1.25, length(c));
	float amount = max(row_blur, edge * edge_blur);
	float lod = amount * max_lod;
	vec2 px = 1.0 / vec2(textureSize(screen_tex, 0));
	vec2 r = px * exp2(lod) * 0.7;
	vec3 blurred = textureLod(screen_tex, uv, lod).rgb * 0.25;
	blurred += textureLod(screen_tex, uv + vec2(r.x, 0.0), lod).rgb * 0.125;
	blurred += textureLod(screen_tex, uv - vec2(r.x, 0.0), lod).rgb * 0.125;
	blurred += textureLod(screen_tex, uv + vec2(0.0, r.y), lod).rgb * 0.125;
	blurred += textureLod(screen_tex, uv - vec2(0.0, r.y), lod).rgb * 0.125;
	blurred += textureLod(screen_tex, uv + r, lod).rgb * 0.0625;
	blurred += textureLod(screen_tex, uv - r, lod).rgb * 0.0625;
	blurred += textureLod(screen_tex, uv + vec2(r.x, -r.y), lod).rgb * 0.0625;
	blurred += textureLod(screen_tex, uv + vec2(-r.x, r.y), lod).rgb * 0.0625;
	// Focus mask: 1 in the sharp area, 0 where blur is at its most.
	float focus = 1.0 - clamp(max(row_blur, edge * edge_blur) / max(max(far_blur, edge_blur), 0.001), 0.0, 1.0);
	// Clarity: unsharp mask against a small blur, where the view is sharp.
	vec3 soft = textureLod(screen_tex, uv, 2.0).rgb;
	vec3 col = blurred + (sharp - soft) * clarity * focus * focus;
	// Grade.
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(luma), col, mix(1.0 - edge_desat, focus_saturation, focus));
	col = (col - 0.18) * mix(1.0, focus_contrast, focus) + 0.18;
	col = mix(col, haze_color, (1.0 - focus) * edge_haze);
	col *= 1.0 - vignette * edge * edge;
	ALBEDO = mix(sharp, max(col, vec3(0.0)), strength);
}
