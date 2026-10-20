// The deep sky under the universe map (§21.1: islands "floating in a violet
// sky"; the design's galaxy, realm_diorama.js:1074–1112): the night's violet
// gradient, nebulae in the schools' colours, a spiral galaxy turning slowly
// beneath the Heart, and fine star dust. One plane far below the islands,
// drawn once; everything is worked out here, so no texture is loaded.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 top : source_color = vec4(0.071, 0.039, 0.22, 1.0);
uniform vec4 middle : source_color = vec4(0.165, 0.078, 0.4, 1.0);
uniform vec4 low : source_color = vec4(0.231, 0.102, 0.471, 1.0);
uniform vec4 bottom : source_color = vec4(0.353, 0.141, 0.408, 1.0);
// The galaxy's centre on the plane, and its radius in metres.
uniform vec2 galaxy_at = vec2(0.0, 40.0);
uniform float galaxy_radius = 70.0;
uniform float spin = 0.012;
// The nebulae: centres on the plane (xy) and radius (z), with colours.
uniform vec4 nebula_a = vec4(-60.0, -70.0, 70.0, 0.0);
uniform vec4 nebula_b = vec4(70.0, 10.0, 60.0, 0.0);
uniform vec4 nebula_c = vec4(-40.0, 80.0, 80.0, 0.0);
uniform vec4 nebula_d = vec4(50.0, -110.0, 60.0, 0.0);
uniform vec4 colour_a : source_color = vec4(0.878, 0.361, 0.706, 1.0);
uniform vec4 colour_b : source_color = vec4(0.235, 0.776, 0.847, 1.0);
uniform vec4 colour_c : source_color = vec4(0.949, 0.627, 0.235, 1.0);
uniform vec4 colour_d : source_color = vec4(0.549, 0.424, 0.941, 1.0);
uniform float brightness = 1.0;
// The plane's point under the middle of the screen, which the galaxy and
// nebulae are placed from: a backdrop that far off barely moves as the
// camera pans (the map sets it each frame).
uniform vec2 origin = vec2(0.0);

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x),
		u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

float blob(vec2 p, vec4 n) {
	float d = length(p - n.xy) / n.z;
	return exp(-d * d * 2.2);
}

// Points scattered on a grid of `cell` metres: a dot in some cells.
float dust(vec2 p, float cell, float chance, float size) {
	vec2 c = floor(p / cell);
	float h = hash(c);
	if (h > chance) {
		return 0.0;
	}
	vec2 at = (c + vec2(hash(c + 3.1), hash(c + 7.7)) * 0.8 + 0.1) * cell;
	float d = length(p - at) / size;
	return max(0.0, 1.0 - d) * (0.4 + 0.6 * fract(h * 91.7));
}

void fragment() {
	vec2 p = world.xz - origin;
	float t = clamp(SCREEN_UV.y, 0.0, 1.0);
	vec3 col = mix(top.rgb, middle.rgb, smoothstep(0.0, 0.4, t));
	col = mix(col, low.rgb, smoothstep(0.4, 0.75, t));
	col = mix(col, bottom.rgb, smoothstep(0.75, 1.0, t));
	// Nebulae, torn by noise so they read as clouds of gas, not discs.
	vec2 drift = vec2(TIME * 0.35, TIME * -0.2);
	float cloud = fbm(p * 0.018 + drift * 0.01);
	float wisps = fbm(p * 0.05 - drift * 0.02);
	float tear = smoothstep(0.25, 0.85, cloud * 0.75 + wisps * 0.45);
	col += colour_a.rgb * blob(p, nebula_a) * tear * 0.55;
	col += colour_b.rgb * blob(p, nebula_b) * tear * 0.42;
	col += colour_c.rgb * blob(p, nebula_c) * tear * 0.42;
	col += colour_d.rgb * blob(p, nebula_d) * tear * 0.5;
	// Dark lanes through the gas.
	col *= 0.82 + 0.3 * smoothstep(0.2, 0.7, wisps);
	// The spiral galaxy: a warm core and three arms of dust, turning.
	vec2 g = (p - galaxy_at) / galaxy_radius;
	float r = length(g);
	float a = atan(g.y, g.x) + TIME * spin;
	float arms = 0.0;
	for (int k = 0; k < 3; k++) {
		float phase = a + float(k) * 2.094 - log(max(r, 0.02)) * 2.6;
		arms += pow(0.5 + 0.5 * cos(phase), 6.0);
	}
	float fade = smoothstep(1.0, 0.15, r);
	// The arms are dust: a faint glow, and bright motes thick along them, as
	// the design's galaxy is drawn in points.
	float motes = dust(p, 1.4, 0.3, 0.4) + dust(p + 31.0, 1.0, 0.2, 0.3) * 0.6;
	vec3 arm_col = mix(vec3(1.0, 0.78, 0.9), vec3(0.8, 0.68, 1.0), smoothstep(0.2, 0.8, r));
	col += arm_col * arms * fade * (0.1 + 0.75 * motes);
	col += vec3(1.0, 0.86, 0.72) * exp(-r * r * 60.0) * 1.1;
	col += vec3(1.0, 0.62, 0.78) * exp(-r * r * 9.0) * 0.4;
	// Star dust: fine and many, and a few brighter ones.
	float stars = dust(p, 2.3, 0.3, 0.2) * 0.45 + dust(p + 50.0, 6.0, 0.25, 0.32) * 0.8;
	col += vec3(0.95, 0.92, 1.0) * stars;
	ALBEDO = col * brightness;
}
