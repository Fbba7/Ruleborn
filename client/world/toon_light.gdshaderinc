// §21.3's one toon look: "the designs' diorama ramp of four steps, with its
// 10% extra saturation, coloured shadows tinted toward violet, a soft rim
// light". The ramp is the diorama's gradient map, [62, 140, 215, 255] of 255
// (Screens v3, realm_diorama.js:485), read as three.js's toon material reads
// it: by N·L remapped from [-1, 1] to [0, 1], so a face turned side-on to the
// sun still stands in the third step. The sun's shadow takes a lit face down
// to the second step, not to black. Shared by every world material.

uniform vec4 shadow_tint : source_color = vec4(0.55, 0.47, 0.82, 1.0);
uniform vec4 rim_colour : source_color = vec4(1.0, 0.86, 0.96, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.28;

vec3 saturated(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	return clamp(mix(vec3(l), c, 1.1), 0.0, 1.0);
}

float toon_ramp(float ndl) {
	float x = ndl * 0.5 + 0.5;
	if (x < 0.25) return 62.0 / 255.0;
	if (x < 0.5) return 140.0 / 255.0;
	if (x < 0.75) return 215.0 / 255.0;
	return 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// A soft-edged shadow: half a step of blur, so pieces sit on the ground.
	float shade = smoothstep(0.2, 0.8, ATTENUATION);
	float lit = toon_ramp(mix(min(ndl, -0.12), ndl, shade));
	// Shade falls toward violet, not toward black.
	vec3 tint = mix(shadow_tint.rgb, vec3(1.0), lit);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit * tint;
	// A soft rim on the lit side.
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * step(0.0, ndl) * shade;
	SPECULAR_LIGHT += LIGHT_COLOR / PI * rim_colour.rgb * rim * rim_strength;
}
