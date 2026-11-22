// Flat concrete-grey ground with a thin panel grid in world space (a 10 m coarse grid, a faint 2 m fine one), so
// distances and unit scale read at a glance. Flat colour, no texture: it follows the style guide
// (docs/style_guide.md). Visual only; the physics ground is a separate body.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec3 base_color : source_color = vec3(0.541, 0.541, 0.525); // concrete grey #8A8A86
uniform vec3 line_color : source_color = vec3(0.35, 0.35, 0.34);
uniform float coarse_cell : hint_range(1.0, 50.0) = 10.0;
uniform float coarse_width : hint_range(0.01, 1.0) = 0.12;
uniform float fine_cell : hint_range(0.5, 20.0) = 2.0;
uniform float fine_width : hint_range(0.01, 0.5) = 0.03;
uniform float fine_strength : hint_range(0.0, 1.0) = 0.35;

varying vec3 world_pos;

float grid_line(vec2 p, float cell, float width) {
	vec2 g = abs(fract(p / cell - 0.5) - 0.5) * cell;
	float d = min(g.x, g.y);
	float w = fwidth(d);
	return 1.0 - smoothstep(width * 0.5 - w, width * 0.5 + w, d);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float coarse = grid_line(world_pos.xz, coarse_cell, coarse_width);
	float fine = grid_line(world_pos.xz, fine_cell, fine_width) * fine_strength;
	ALBEDO = mix(base_color, line_color, max(coarse, fine));
}
