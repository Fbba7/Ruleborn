// The backdrop the menus stand on (§21.2: "Menus stand on a night backdrop
// (#171046 to #2C3AA8)"), painted as the same picture-book sky the realms
// float in: the gradient, a soft glow where the world would be, stars, a few
// far islets drifting with their roots, a cloud sea in two layers at the
// foot, and the vignette as a tint at the edges. It is the screen's
// background, one quad and one draw call, not post-processing (§21.3).
shader_type canvas_item;

uniform vec4 top : source_color = vec4(0.090, 0.063, 0.275, 1.0);
uniform vec4 bottom : source_color = vec4(0.173, 0.227, 0.659, 1.0);
// The glow behind the middle of the screen, and its strength.
uniform vec4 glow : source_color = vec4(0.62, 0.45, 0.95, 1.0);
uniform float glow_strength = 0.35;
// The cloud sea: its lit tops and its body.
uniform vec4 cloud_top : source_color = vec4(0.72, 0.62, 0.95, 1.0);
uniform vec4 cloud_body : source_color = vec4(0.36, 0.33, 0.78, 1.0);
// Where the far and the near layer of the cloud sea rise to (0 the top of
// the screen, 1 its foot).
uniform float cloud_far = 0.80;
uniform float cloud_near = 0.88;
uniform float stars = 1.0;
uniform float islets = 1.0;
// The far islets' colour (a dark violet against the sky).
uniform vec4 islet : source_color = vec4(0.16, 0.12, 0.38, 1.0);
uniform vec4 islet_lit : source_color = vec4(0.42, 0.36, 0.72, 1.0);
// The vignette: its colour and how strong it is at the corners.
uniform vec4 edge : source_color = vec4(0.04, 0.02, 0.12, 1.0);
uniform float vignette = 0.35;
// Width over height of the rectangle, so round things stay round.
uniform float aspect = 0.4615;
// 0 holds it still (reduced motion, §21.8).
uniform float motion = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// The top of a row of round cloud lobes at `x`: the highest lobe over it.
float lobes(float x, float scale, float seed) {
	float cell = floor(x * scale);
	float best = 0.0;
	for (int i = -1; i <= 1; i++) {
		float c = cell + float(i);
		float r = 0.45 + 0.4 * hash(vec2(c, seed));
		float cx = (c + 0.5 + (hash(vec2(seed, c)) - 0.5) * 0.4) / scale;
		float dx = (x - cx) * scale / r;
		if (abs(dx) < 1.0) {
			best = max(best, sqrt(1.0 - dx * dx) * r / scale);
		}
	}
	return best;
}

// A far islet centred at `c` (in the rectangle's square units), `s` across:
// 1 inside it, and how lit its top is.
vec2 isle(vec2 p, vec2 c, float s) {
	vec2 q = (p - c) / s;
	// The grass cap: a flat ellipse.
	float cap = step(length(q * vec2(1.0, 3.2)), 1.0);
	// The rock: a cone hanging under the cap, slightly lumpy.
	float lump = 0.06 * sin(q.x * 9.0 + c.x * 20.0);
	float cone = step(0.0, q.y) * step(abs(q.x), (1.0 - q.y / 1.6) * 0.95 + lump) * step(q.y, 1.6);
	// Two roots dangling from its point.
	float roots = step(abs(q.x - 0.18 - 0.05 * sin(q.y * 6.0)), 0.035) * step(1.0, q.y) * step(q.y, 2.3);
	roots += step(abs(q.x + 0.22 + 0.04 * sin(q.y * 5.0)), 0.03) * step(0.9, q.y) * step(q.y, 2.0);
	float inside = clamp(cap + cone + roots, 0.0, 1.0);
	float lit = cap * smoothstep(0.1, -0.3, q.y);
	return vec2(inside, lit);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * motion;
	vec3 c = mix(top.rgb, bottom.rgb, smoothstep(0.0, 1.0, uv.y));
	// Square units: x across scaled by the aspect, so circles stay round.
	vec2 p = vec2(uv.x * aspect, uv.y);
	// The glow where the world would float, a little above the middle.
	float g = exp(-pow(length((p - vec2(0.5 * aspect, 0.55)) * vec2(1.0, 1.3)) * 2.2, 2.0));
	c = mix(c, glow.rgb, g * glow_strength);
	// Stars in the upper sky, twinkling.
	if (stars > 0.0) {
		vec2 cell = floor(p * 90.0);
		float h = hash(cell);
		if (h > 0.985) {
			vec2 f = fract(p * 90.0) - 0.5;
			float tw = 0.6 + 0.4 * sin(t * (1.0 + h * 3.0) + h * 40.0);
			float s = smoothstep(0.18, 0.0, length(f)) * tw * (1.0 - smoothstep(0.25, 0.75, uv.y));
			c += vec3(0.95, 0.9, 1.0) * s * stars * (h - 0.985) * 66.0;
		}
	}
	// Far islets, bobbing slowly.
	if (islets > 0.0) {
		vec2 a = isle(p, vec2(0.12 * aspect + 0.02, 0.33 + 0.006 * sin(t * 0.5)), 0.036);
		vec2 b = isle(p, vec2(0.86 * aspect, 0.52 + 0.006 * sin(t * 0.4 + 2.0)), 0.026);
		vec2 d = isle(p, vec2(0.70 * aspect, 0.19 + 0.005 * sin(t * 0.6 + 4.0)), 0.022);
		float far_mix = 0.55;
		vec3 far_col = mix(islet.rgb, c, far_mix);
		c = mix(c, mix(islet.rgb, islet_lit.rgb, a.y), a.x * islets);
		c = mix(c, mix(mix(islet.rgb, c, 0.3), islet_lit.rgb, b.y * 0.8), b.x * islets);
		c = mix(c, mix(far_col, islet_lit.rgb, d.y * 0.6), d.x * islets);
	}
	// The cloud sea at the foot: a far layer, then a near one, each with
	// lit tops, drifting.
	float far_top = cloud_far - lobes(uv.x * aspect + t * 0.004, 9.0, 3.0) * 0.9;
	float far_in = smoothstep(far_top - 0.003, far_top + 0.003, uv.y);
	vec3 far_col2 = mix(c, cloud_body.rgb, 0.55);
	far_col2 = mix(far_col2, mix(c, cloud_top.rgb, 0.55), smoothstep(far_top + 0.03, far_top, uv.y));
	c = mix(c, far_col2, far_in);
	float near_top = cloud_near - lobes(uv.x * aspect - t * 0.007 + 0.37, 6.0, 7.0) * 0.9;
	float near_in = smoothstep(near_top - 0.003, near_top + 0.003, uv.y);
	vec3 near_col = mix(cloud_body.rgb, cloud_top.rgb, smoothstep(near_top + 0.05, near_top, uv.y));
	c = mix(c, near_col, near_in * 0.92);
	// The vignette as a tint toward the edge colour.
	vec2 v = (uv - 0.5) * vec2(1.0, 0.8);
	float vig = smoothstep(0.25, 0.75, length(v)) * vignette;
	c = mix(c, edge.rgb, vig);
	COLOR = vec4(c, 1.0);
}
