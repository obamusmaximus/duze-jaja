// Water shading: `deep_color` as a floor (emitted, so shadows and facets turned away keep it), the light adding
// `shallow_color` on top in `ramp_steps` posterized steps, a stepped tint by facet height (crests lighter, troughs
// darker), and the glitter path, a hard-edged specular stripe toward each light that the facets break up: toward the
// moon or a sun (any directional light, in `glitter_color`), and toward lamps (in the lamp's own hue, `lamp_glitter`).
//
// The light steps are measured from how flat water is lit, not from N dot L itself: calm water at any moon height sits
// in the middle step, and `ramp_contrast` decides how much a facet must turn toward or away from the light to change
// step. So the two sides of a wave fall in different steps and the waves read as stripes, seen from any angle.

uniform vec4 deep_color : source_color = vec4(0.05, 0.11, 0.22, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.16, 0.3, 0.5, 1.0);
uniform int ramp_steps = 3;
uniform float ramp_contrast = 3.0;
uniform float crest_tint = 0.25;
uniform float light_strength = 1.0;
uniform vec4 glitter_color : source_color = vec4(0.85, 0.92, 1.0, 1.0);
uniform float glitter_strength = 1.5;
uniform float glitter_threshold = 0.985;
uniform float lamp_glitter = 4.0;

// 0 to 1 in `ramp_steps` hard steps from how much more (or less) this facet faces the light than flat water does.
// Flat water gives 0.5 before the steps.
float light_ramp(float n_dot_l, float flat_n_dot_l) {
	float steps = float(max(ramp_steps, 2));
	float shade = clamp(0.5 + (n_dot_l - flat_n_dot_l) * ramp_contrast, 0.0, 1.0);
	return clamp(floor(shade * steps) / (steps - 1.0), 0.0, 1.0);
}

// Brightness factor from a facet's height, `height` being -1 (deepest trough) to 1 (highest crest), in `ramp_steps`
// hard steps: 1 - crest_tint to 1 + crest_tint.
float crest_tone(float height) {
	float steps = float(max(ramp_steps, 2));
	float band = clamp(floor((clamp(height, -1.0, 1.0) * 0.5 + 0.5) * steps) / (steps - 1.0), 0.0, 1.0);
	return 1.0 + crest_tint * (band * 2.0 - 1.0);
}

// 1 where a facet mirrors the light into the eye closely enough, else 0. All vectors in the same space.
float light_glitter(vec3 normal, vec3 to_light, vec3 to_eye) {
	return step(glitter_threshold, dot(reflect(-to_light, normal), to_eye));
}

// Colour and strength of the glitter for one light: `glitter_color` for a directional light (moon, sun); for a lamp
// (omni or spot) its own light colour and energy times `lamp_glitter`, so a warm street light glitters warm and a
// brighter lamp glitters brighter. (The lamp's distance falloff comes in through ATTENUATION.)
vec3 glitter_tint(bool directional, vec3 light_color) {
	if (directional) {
		return glitter_color.rgb * glitter_strength;
	}
	return light_color * glitter_strength * lamp_glitter;
}
