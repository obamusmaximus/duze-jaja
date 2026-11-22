// Wave height and slope: a few summed directional sine waves with analytic height and slope, so normals are exact.
// Wave i is `wavelength_falloff`^i as long and `height_falloff`^i as high as the first, and turned `direction_spread`
// away from it, alternating sides. Each travels at deep-water speed for its length times `wave_speed`.

uniform int wave_count = 4;
uniform float wave_height = 0.6;
uniform float wavelength = 30.0;
uniform float wavelength_falloff = 0.6;
uniform float height_falloff = 0.4;
// Radians.
uniform float wave_direction = 0.5;
uniform float direction_spread = 0.6;
uniform float wave_speed = 1.0;

const int MAX_WAVES = 6;
const float GRAVITY = 9.81;

// x: height above the rest level, y and z: the slope (dh/dx, dh/dz) at world point `p` (x, z) and time `t`.
vec3 wave_sum(vec2 p, float t) {
	vec3 sum = vec3(0.0);
	float amplitude = wave_height;
	float length_m = wavelength;
	for (int i = 0; i < MAX_WAVES; i++) {
		if (i >= wave_count) {
			break;
		}
		float side = (i % 2 == 0) ? 1.0 : -1.0;
		float angle = wave_direction + direction_spread * side * float((i + 1) / 2);
		vec2 dir = vec2(sin(angle), -cos(angle));
		float k = 6.2831853 / max(length_m, 0.01);
		float omega = sqrt(GRAVITY * k) * wave_speed;
		float phase = k * dot(dir, p) - omega * t + float(i) * 1.7;
		sum.x += amplitude * sin(phase);
		sum.yz += amplitude * k * cos(phase) * dir;
		amplitude *= height_falloff;
		length_m *= wavelength_falloff;
	}
	return sum;
}
