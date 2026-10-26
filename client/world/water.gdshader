// Water and lava, hand painted (§21.3), never a photographic texture.
// Water: deep in the middle and light at the banks, a foam line where it
// meets the shore (UV.x: 0 at the shore, 1 a half tile out, from KitGround),
// drifting light streaks, and ink ripples — §21.10: "water also carries ink
// ripples", so it reads in grayscale against stone. COLOR tints it (marsh,
// spring). Lava (glowing > 0): a dark crust in plates over a glowing melt
// that pulses through the cracks.
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"

uniform vec4 deep : source_color = vec4(0.22, 0.58, 0.80, 1.0);
uniform vec4 foam : source_color = vec4(0.88, 0.97, 1.0, 1.0);
uniform vec4 ink : source_color = vec4(0.10, 0.18, 0.32, 1.0);
uniform float speed = 0.35;
uniform float glowing = 0.0;
// The bank the water's rounded corners show (the realm's sand).
uniform vec4 bank : source_color = vec4(0.93, 0.86, 0.70, 1.0);
// How far the water lies below its banks, in tiles, as painted: the island's
// top lies just under the grid, so the surface stays at the banks' height and
// the shader draws what a sunken pool would show from the camera, the far
// bank's wall and the water seen past the near bank.
uniform float sink = 0.2;
// The earth of that wall.
uniform vec4 cut : source_color = vec4(0.62, 0.48, 0.36, 1.0);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// A slow swell, so the surface is never still.
	if (glowing <= 0.0) {
		VERTEX.y += sin(wpos.x * 2.1 + TIME * 1.3) * sin(wpos.z * 1.7 - TIME) * 0.004;
	}
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x),
		f.y);
}

vec2 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 7.31)) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec2(d1, d2);
}

// Distance in tiles from `q` (the tile's own 0–1 square) to the shore: from
// the sides in `mask` (west 1, east 2, north 4, south 8) and, where two meet,
// from a rounded corner; at most `far`.
float shore_d(vec2 q, float far, int mask) {
	float d = far;
	bool w = (mask & 1) != 0;
	bool e = (mask & 2) != 0;
	bool n = (mask & 4) != 0;
	bool s = (mask & 8) != 0;
	if (w) d = min(d, q.x);
	if (e) d = min(d, 1.0 - q.x);
	if (n) d = min(d, q.y);
	if (s) d = min(d, 1.0 - q.y);
	float rr = 0.42;
	if (w && n && q.x < rr && q.y < rr) d = min(d, rr - length(q - vec2(rr)));
	if (e && n && q.x > 1.0 - rr && q.y < rr) d = min(d, rr - length(q - vec2(1.0 - rr, rr)));
	if (w && s && q.x < rr && q.y > 1.0 - rr) d = min(d, rr - length(q - vec2(rr, 1.0 - rr)));
	if (e && s && q.x > 1.0 - rr && q.y > 1.0 - rr) d = min(d, rr - length(q - vec2(1.0 - rr)));
	return d;
}

void fragment() {
	vec2 p = wpos.xz;
	float t = TIME * speed;
	if (glowing > 0.0) {
		vec2 cb = cells(p * 7.0 + vec2(t * 0.2, 0.0));
		float crack = 1.0 - smoothstep(0.06, 0.3, cb.y - cb.x);
		float pulse = 0.75 + 0.25 * sin(TIME * 2.0 + vnoise(p * 2.0) * 6.0);
		vec3 melt = mix(deep.rgb, foam.rgb, crack * pulse);
		vec3 crust = vec3(0.17, 0.10, 0.11) * (0.8 + 0.4 * vnoise(p * 9.0));
		float lit = max(crack, 0.35 + 0.25 * smoothstep(0.5, 0.0, cb.x));
		ALBEDO = mix(crust, melt, lit);
		EMISSION = melt * lit * glowing * 1.4;
	} else {
	// How far this point is from the shore, in tiles (UV.y's mask of the
	// sides that meet it, rounded where two meet); and the same for the
	// point of the sunken water this one shows: `sink` below, seen along the
	// camera's way, so past the near bank, and the far bank's wall where
	// that point would lie beyond the shore.
	int mask = int(UV.y + 0.5);
	vec3 fwd = -INV_VIEW_MATRIX[2].xyz;
	vec2 way = normalize(fwd.xz + vec2(0.0001));
	float reach = sink * length(fwd.xz) / max(-fwd.y, 0.2);
	float wob = (vnoise(p * 6.0) - 0.5) * 0.05;
	float top_d = shore_d(UV2, UV.x, mask) + wob;
	float d = shore_d(UV2 + way * reach, UV.x, mask) + wob;
	float shore = clamp(d * 2.0, 0.0, 1.0);
	vec3 base = mix(foam.rgb * 0.9, deep.rgb, smoothstep(0.0, 0.85, shore)) * COLOR.rgb;
	// Light streaks drifting along.
	float drift = vnoise(vec2(p.x * 1.5 - t * 2.0, p.y * 5.0));
	base = mix(base, foam.rgb, smoothstep(0.72, 0.8, drift) * 0.45);
	// Ink ripples: thin arcs that come and go.
	float r = vnoise(p * 2.4 + vec2(t, -t * 0.7));
	float ring = abs(fract(r * 4.0 - TIME * 0.25) - 0.5);
	float arc = (1.0 - smoothstep(0.0, 0.05, ring)) * step(0.45, vnoise(p * 1.3 + 3.0));
	base = mix(base, ink.rgb, arc * 0.55 * smoothstep(0.15, 0.5, shore));
	// The foam at the bank, broken up.
	float edge = 1.0 - smoothstep(0.05, 0.14, shore + (vnoise(p * 7.0 + t) - 0.5) * 0.08);
	base = mix(base, foam.rgb, edge);
	// The far bank's wall down to the water: sand at its lip, darker earth
	// toward the waterline, a wet line at its foot and an ink line at its lip
	// (§21.10), so the pool reads sunk into the ground.
	float up = clamp(-d / max(reach, 0.001), 0.0, 1.0);
	vec3 wall = mix(cut.rgb * 0.62, cut.rgb * 1.08, smoothstep(0.05, 0.85, up));
	wall *= 0.92 + 0.12 * vnoise(vec2(p.x + p.y, up * 3.0) * 8.0);
	wall = mix(wall, ink.rgb, smoothstep(0.86, 0.97, up) * 0.7);
	wall = mix(wall, foam.rgb * 0.85, (1.0 - smoothstep(0.0, 0.12, up)) * 0.6);
	base = mix(wall, base, step(0.0, d));
	// The water's own shade under the near bank.
	base *= 1.0 - 0.25 * (1.0 - smoothstep(0.0, 0.12, shore)) * step(0.0, d);
	// Past the rounded shore, the bank at the ground's height.
	base = mix(bank.rgb * (0.95 + 0.1 * vnoise(p * 9.0)), base, step(0.0, top_d));
	ALBEDO = saturated(base);
	EMISSION = vec3(0.0);
	}
}
