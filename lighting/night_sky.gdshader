shader_type sky;
// The night sky (docs/mechanics/heightmap.md, "Night"): the day's gradient (the same curves as ProceduralSkyMaterial)
// plus stars. A star is a round point at a random spot in a cell of a grid on the faces of a cube round the viewer,
// sized in screen pixels, so it stays sharp at any resolution and field of view. No TIME, so the sky is not re-baked
// every frame. Stars fade out toward the horizon, into the haze.

uniform vec4 top_color : source_color;
uniform vec4 horizon_color : source_color;
uniform float top_curve = 0.15;
uniform float bottom_curve = 0.02;
uniform vec4 star_color : source_color;
uniform float star_density = 0.2;
uniform float star_brightness = 1.0;
uniform float star_size = 1.4;

// Grid cells across one cube face.
const float CELLS = 90.0;

vec3 hash3(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float stars(vec3 dir) {
	vec3 a = abs(dir);
	vec3 face; // Position on the face (xy) and the face's number (z).
	if (a.x >= a.y && a.x >= a.z) {
		face = vec3(dir.zy / a.x, dir.x > 0.0 ? 0.0 : 1.0);
	} else if (a.y >= a.z) {
		face = vec3(dir.xz / a.y, dir.y > 0.0 ? 2.0 : 3.0);
	} else {
		face = vec3(dir.xy / a.z, dir.z > 0.0 ? 4.0 : 5.0);
	}
	vec2 grid = (face.xy * 0.5 + 0.5) * CELLS;
	vec2 cell = floor(grid);
	vec3 r = hash3(vec3(cell, face.z * 17.0 + 3.0));
	if (r.z > star_density) {
		return 0.0;
	}
	vec3 s = hash3(vec3(cell + 71.0, face.z * 29.0 + 11.0));
	// Most stars are faint, a few bright.
	float magnitude = 0.12 + 0.88 * pow(s.x, 4.0);
	// Kept off the cell's edges, so a star is never cut off.
	vec2 at = cell + 0.15 + r.xy * 0.7;
	// One screen pixel in grid units, from the view direction (continuous across cube faces, unlike `grid`).
	float pixel = max(length(fwidth(dir)) * CELLS * 0.5, 0.00001);
	float radius = pixel * star_size * mix(0.55, 1.0, magnitude);
	float spot = 1.0 - smoothstep(radius - pixel * 0.6, radius + pixel * 0.6, length(grid - at));
	return spot * magnitude;
}

void sky() {
	float angle = acos(clamp(EYEDIR.y, -1.0, 1.0));
	float c = 1.0 - angle / (PI * 0.5);
	vec3 above = mix(horizon_color.rgb, top_color.rgb, clamp(1.0 - pow(max(1.0 - c, 0.0), 1.0 / top_curve), 0.0, 1.0));
	float d = (angle - PI * 0.5) / (PI * 0.5);
	vec3 below = mix(horizon_color.rgb, top_color.rgb, clamp(1.0 - pow(max(1.0 - d, 0.0), 1.0 / bottom_curve), 0.0, 1.0));
	vec3 color = EYEDIR.y >= 0.0 ? above : below;
	if (!AT_CUBEMAP_PASS && star_brightness > 0.0 && EYEDIR.y > 0.0) {
		color += star_color.rgb * stars(EYEDIR) * star_brightness * smoothstep(0.02, 0.25, EYEDIR.y);
	}
	COLOR = color;
}
