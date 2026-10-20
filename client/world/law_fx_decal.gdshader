// A law's mark on the ground (§21.3: decals as flat meshes): tile-sized
// quads laid just over the realm's flagstones, painted here by `pattern` and
// moved by the heist's clock. Hand-painted shapes only, never a texture.
//
// Per vertex: UV the world's x and z (so a pattern runs on across tiles),
// COLOR how strongly this tile shows it, CUSTOM0 a local centre (x, z), the
// tile's phase and a free value.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform int pattern = 0;
uniform float t = 0.0;
uniform float strength = 1.0;
uniform float pace = 1.0;
uniform vec4 colour_a : source_color = vec4(1.0);
uniform vec4 colour_b : source_color = vec4(0.1, 0.05, 0.08, 1.0);
// The Heart, for patterns that lead toward it (Inward pull).
uniform vec2 focus = vec2(0.0);

varying vec2 world;
varying vec4 local;
varying float weight;
varying vec3 tint;

void vertex() {
	world = UV;
	local = CUSTOM0;
	weight = COLOR.a;
	tint = COLOR.rgb;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

// Distance to the nearest edge between cells: cracks, crystal facets.
float cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 17.0));
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return d2 - d1;
}

float hex_edge(vec2 p) {
	vec2 s = vec2(1.0, 1.7320508);
	vec2 h = s * 0.5;
	vec2 a = mod(p, s) - h;
	vec2 b = mod(p - h, s) - h;
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	vec2 q = abs(g);
	return 0.5 - max(dot(q, normalize(vec2(1.0, 1.7320508))), q.x);
}

void fragment() {
	float s = t * pace;
	vec3 c = colour_a.rgb;
	float a = 0.0;
	vec2 p = world;
	if (pattern == 0) {
		// Frictionless: glossy ice, bright streaks sliding over it, a darker
		// mirror of the sky under them.
		float band = fract((p.x + p.y) * 0.22 - s * 0.12);
		float glint = smoothstep(0.07, 0.0, abs(band - 0.5)) + smoothstep(0.025, 0.0, abs(fract((p.x + p.y) * 0.9 + 0.3) - 0.5)) * 0.35;
		float scratch = smoothstep(0.03, 0.0, abs(fract(p.x * 1.3 - p.y * 0.4) - 0.5)) * noise(p * 3.0);
		c = mix(colour_a.rgb, vec3(1.0), clamp(glint, 0.0, 1.0));
		c = mix(c, colour_b.rgb, scratch * 0.5);
		a = 0.42 + glint * 0.5 + scratch * 0.2;
	} else if (pattern == 1) {
		// Honeycomb: a golden hexagon sheen, lines inked darker, a light band
		// passing over it.
		float e = hex_edge(p * 2.2);
		float line = smoothstep(0.07, 0.02, e);
		float sheen = smoothstep(0.35, 0.0, abs(fract(p.x * 0.12 + p.y * 0.08 - s * 0.08) - 0.5));
		c = mix(colour_a.rgb, colour_b.rgb, line * 0.8);
		c = mix(c, vec3(1.0, 0.97, 0.8), sheen * 0.45 * (1.0 - line));
		a = 0.32 + line * 0.55 + sheen * 0.2;
	} else if (pattern == 2) {
		// Brittle stone: hairline cracks everywhere.
		float e = cells(p * 1.6 + local.z * 3.0);
		float fine = cells(p * 4.1 + 5.0);
		float crack = smoothstep(0.06, 0.0, e) + smoothstep(0.035, 0.0, fine) * 0.6;
		c = colour_b.rgb;
		a = crack * 0.85;
	} else if (pattern == 3) {
		// Inward pull: faint spiral streaks drawn in toward the Heart.
		vec2 d = p - focus;
		float r = length(d) + 0.001;
		float ang = atan(d.y, d.x);
		float arm = fract(ang / 6.28318 * 4.0 + log(r) * 1.6 + s * 0.25);
		float dash = smoothstep(0.5, 0.1, abs(fract(r * 0.8 + s * 0.6) - 0.5));
		float line = smoothstep(0.12, 0.03, abs(arm - 0.5));
		c = mix(colour_a.rgb, colour_b.rgb, smoothstep(0.03, 0.0, abs(arm - 0.5)));
		a = line * (0.3 + 0.4 * dash) * smoothstep(0.3, 1.6, r);
	} else if (pattern == 4) {
		// Delay: ripples that linger round anything triggered, each ring
		// a beat behind the one before.
		float r = length(p - local.xy);
		float u = fract(s * 0.35 + local.z);
		float ring = 0.0;
		for (int i = 0; i < 3; i++) {
			float ui = fract(u - float(i) * 0.18);
			ring += smoothstep(0.12, 0.0, abs(r - ui * local.w * 0.9)) * (1.0 - ui);
		}
		c = colour_a.rgb;
		a = ring;
	} else if (pattern == 5) {
		// Aurora: ribbons of light sweeping slowly across the ground.
		float w = sin(p.x * 0.8 + p.y * 0.45 + sin(p.y * 0.6 + s * 0.3) * 1.5 - s * 0.45);
		float band = smoothstep(0.25, 0.85, w);
		float edge = smoothstep(0.8, 0.95, w);
		float hue = smoothstep(-0.6, 0.6, sin(p.x * 0.35 - p.y * 0.5 + s * 0.2));
		c = mix(colour_a.rgb, colour_b.rgb, hue);
		c = mix(c, vec3(1.0), edge * 0.6);
		a = band * 0.72;
	} else if (pattern == 6) {
		// Regrowth: moss creeping out over everything and in again.
		float n = noise(p * 1.4) * 0.6 + noise(p * 4.0) * 0.4;
		float reach = 0.42 + 0.14 * sin(s * 0.25 + local.z * 2.0);
		float moss = smoothstep(reach, reach + 0.06, n);
		float rim = smoothstep(reach, reach + 0.02, n) - smoothstep(reach + 0.03, reach + 0.06, n);
		c = mix(colour_a.rgb, colour_b.rgb, noise(p * 9.0) * 0.6 + rim);
		a = moss * 0.72 + rim * 0.2;
	} else if (pattern == 7) {
		// Glowing dark: a rune ring glowing on a tile, pulsing slowly.
		vec2 d = p - local.xy;
		float r = length(d);
		float ring = smoothstep(0.035, 0.0, abs(r - 0.36));
		float ang = atan(d.y, d.x);
		float ticks = step(0.7, fract(ang / 6.28318 * 8.0 + local.z)) * smoothstep(0.04, 0.0, abs(r - 0.27));
		float glyph = smoothstep(0.03, 0.0, min(abs(d.x + d.y * 0.4), abs(d.y - d.x * 0.6))) * step(r, 0.2);
		float pulse = 0.65 + 0.35 * sin(s * 1.6 + local.z * 6.0);
		c = colour_a.rgb * 1.3;
		a = (ring + ticks + glyph) * pulse + smoothstep(0.55, 0.0, r) * 0.18 * pulse;
	} else if (pattern == 8) {
		// A soft pool of light round a centre.
		float r = length(p - local.xy) / max(local.w, 0.1);
		c = colour_a.rgb;
		a = smoothstep(1.0, 0.2, r) * 0.55 * (0.85 + 0.15 * sin(s * 2.0 + local.z * 9.0));
	} else if (pattern == 9) {
		// Sleepwalk: a dreamy haze drifting slowly over the ground.
		float n = noise(p * 0.55 + vec2(s * 0.08, s * 0.05)) * 0.65 + noise(p * 1.7 - vec2(s * 0.1, 0.0)) * 0.35;
		c = mix(colour_a.rgb, colour_b.rgb, n);
		a = smoothstep(0.35, 0.8, n) * 0.5;
	} else if (pattern == 10) {
		// Static: thin crackling lines that jump about the ground.
		float step_t = floor(s * 6.0);
		float e = cells(p * 1.2 + vec2(hash(vec2(step_t, 1.0)), hash(vec2(step_t, 2.0))) * 7.0);
		float on = step(0.6, hash(floor(p * 0.8) + step_t));
		c = colour_a.rgb;
		a = smoothstep(0.06, 0.0, e) * on;
		c = mix(colour_a.rgb, vec3(1.0), smoothstep(0.02, 0.0, e));
	} else if (pattern == 11) {
		// Glass: a clear floor of facets with coloured edges.
		float e = cells(p * 0.9);
		float edge = smoothstep(0.05, 0.0, e);
		float glint = smoothstep(0.12, 0.0, abs(fract((p.x - p.y) * 0.18 - s * 0.1) - 0.5));
		c = mix(colour_a.rgb, colour_b.rgb, edge);
		a = edge * 0.55 + glint * 0.2;
	} else if (pattern == 12) {
		// Echoes: faint silhouettes' shadows that come and go.
		float r = length((p - local.xy) * vec2(1.0, 1.6));
		float u = sin(s * 0.7 + local.z * 6.0) * 0.5 + 0.5;
		c = colour_a.rgb;
		a = smoothstep(0.32, 0.25, r) * u * 0.35 + smoothstep(0.03, 0.0, abs(r - 0.36)) * u * 0.6;
	} else if (pattern == 14) {
		// Stillness: a clock face laid round the pylon, its hands held still,
		// rings of calm spreading slowly from it. local.w is its radius.
		vec2 d = (p - local.xy) / max(local.w, 0.1);
		float r = length(d);
		float ang = atan(d.y, d.x);
		float rim = smoothstep(0.025, 0.0, abs(r - 0.97)) + smoothstep(0.012, 0.0, abs(r - 0.82));
		float tick = step(fract(ang / 6.28318 * 60.0 + 0.5), 0.12) * step(0.84, r) * step(r, 0.92);
		float hour = step(fract(ang / 6.28318 * 12.0 + 0.5), 0.05) * step(0.72, r) * step(r, 0.95);
		vec2 h1 = vec2(cos(-0.9), sin(-0.9));
		vec2 h2 = vec2(cos(0.6), sin(0.6));
		float hand = smoothstep(0.03, 0.0, abs(dot(d, vec2(-h1.y, h1.x)))) * step(0.0, dot(d, h1)) * step(r, 0.72);
		hand += smoothstep(0.045, 0.0, abs(dot(d, vec2(-h2.y, h2.x)))) * step(0.0, dot(d, h2)) * step(r, 0.5);
		float face = step(r, 1.0);
		float calm = 0.0;
		for (int i = 0; i < 2; i++) {
			float u = fract(s * 0.08 + float(i) * 0.5);
			calm += smoothstep(0.02, 0.0, abs(r - u * 2.2)) * (1.0 - u) * step(1.0, r);
		}
		float ink = clamp(rim + tick + hour + hand, 0.0, 1.0);
		c = mix(colour_a.rgb, colour_b.rgb, ink);
		a = face * (0.32 + ink * 0.6) + calm * 0.5;
	} else if (pattern == 15) {
		// Haste: cloud shadows racing over the ground.
		float n = noise(p * 0.32 + vec2(s * 0.9, s * 0.25)) * 0.7 + noise(p * 0.9 + vec2(s * 1.4, 0.0)) * 0.3;
		c = colour_a.rgb;
		a = smoothstep(0.52, 0.68, n) * 0.24;
	} else if (pattern == 16) {
		// Slow rivers: water thick as syrup, folding over itself slowly, a
		// glossy highlight on each fold.
		vec2 q = p * 1.1 + vec2(noise(p * 0.7 + s * 0.05), noise(p * 0.7 - s * 0.04)) * 1.8;
		float fold = sin(q.x * 2.2 + q.y * 1.3 - s * 0.35) * 0.5 + 0.5;
		float hi = smoothstep(0.86, 0.97, fold);
		float lo = smoothstep(0.25, 0.0, fold);
		c = mix(colour_a.rgb, colour_b.rgb, lo * 0.7);
		c = mix(c, vec3(1.0), hi * 0.85);
		a = 0.78;
	} else {
		// Density: the ground's grain enlarged, a heavy coarse weave.
		float n = noise(p * 2.0);
		float line = smoothstep(0.04, 0.0, abs(fract(p.x * 0.5) - 0.5)) + smoothstep(0.04, 0.0, abs(fract(p.y * 0.5) - 0.5));
		c = mix(colour_a.rgb, colour_b.rgb, n);
		a = line * 0.45 + n * 0.12;
	}
	ALBEDO = c * tint;
	ALPHA = clamp(a, 0.0, 1.0) * weight * strength;
}
