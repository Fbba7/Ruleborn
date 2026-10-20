// A law's motes (§21.3: "law signatures use particles"): every mote is a
// camera-facing quad in one mesh, moved here from the heist's clock, so a
// whole field of dust, sparks or petals is one draw call and a replay shows
// the same motes every time it plays.
//
// Per vertex: VERTEX the mote's start, UV its corner (−1..1), COLOR its colour
// and its strongest opacity; CUSTOM0 its velocity (metres a second) and the
// seconds of one loop (0: it stays put and twinkles); CUSTOM1 its phase in the
// loop, its radius, how far it wobbles, and its shape.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled, skip_vertex_transform;

// The heist's seconds (ticks / 30), set by LawFx.sync.
uniform float t = 0.0;
// A law's overall strength: 0 hides it, 1 is the law as woven; a harmony
// raises it, Unmaking blinks it.
uniform float strength = 1.0;
// How fast the whole field runs: Haste speeds it, Stillness all but stops it.
uniform float pace = 1.0;
// Glow added on top of the colour, so a mote reads on dark ground too.
uniform float glow = 0.35;
// Every mote's size, times its own: one dial for reading at phone size,
// where a tile is about 30 points (§21.1: a heist shows about 12 tiles).
uniform float size = 1.8;

varying vec4 colour;
varying vec2 corner;
varying float shape;
varying float fade;

// Shapes: 0 soft dot, 1 inked dot, 2 four-point sparkle, 3 streak, 4 a "Z",
// 5 petal, 6 ring, 7 hexagon, 8 zigzag spark, 9 drop, 10 leaf, 11 wisp.

void vertex() {
	float period = CUSTOM0.w;
	float phase = CUSTOM1.x;
	float radius = CUSTOM1.y * size;
	float wobble = CUSTOM1.z;
	shape = CUSTOM1.w;
	float s = t * pace;
	vec3 at = VERTEX;
	float u = 0.0;
	fade = 1.0;
	if (period > 0.0) {
		u = fract(s / period + phase);
		at += CUSTOM0.xyz * u * period;
		fade = sin(3.14159 * u);
	} else {
		fade = 0.65 + 0.35 * sin(s * 2.6 + phase * 40.0);
	}
	float w = s + phase * 31.0;
	at += vec3(sin(w * 1.7), cos(w * 1.3) * 0.6, cos(w * 1.1)) * wobble;
	vec4 v = MODELVIEW_MATRIX * vec4(at, 1.0);
	vec2 off = UV * radius;
	if (shape > 2.5 && shape < 3.5) {
		// A streak lies along its own motion, as the screen sees it.
		vec3 dir = (MODELVIEW_MATRIX * vec4(CUSTOM0.xyz, 0.0)).xyz;
		vec2 d = length(dir.xy) > 0.0001 ? normalize(dir.xy) : vec2(1.0, 0.0);
		off = d * UV.x * radius * 5.0 + vec2(-d.y, d.x) * UV.y * radius * 0.7;
	}
	v.xy += off;
	VERTEX = v.xyz;
	corner = UV;
	colour = COLOR;
}

float sd_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 p = corner;
	float r = length(p);
	float a = 0.0;
	float ink = 0.0;
	int k = int(shape + 0.5);
	if (k == 0) {
		a = smoothstep(1.0, 0.0, r);
		a *= a;
	} else if (k == 1) {
		a = step(r, 0.82);
		ink = step(0.68, r) * a;
	} else if (k == 2) {
		float star = min(abs(p.x) * 3.0 + abs(p.y), abs(p.y) * 3.0 + abs(p.x));
		a = smoothstep(1.0, 0.6, star) + smoothstep(0.35, 0.0, r);
	} else if (k == 3) {
		a = smoothstep(1.0, 0.2, abs(p.y)) * smoothstep(1.0, 0.3, abs(p.x)) * (0.55 + 0.45 * p.x);
	} else if (k == 4) {
		float d = min(min(sd_segment(p, vec2(-0.6, 0.6), vec2(0.6, 0.6)),
			sd_segment(p, vec2(0.6, 0.6), vec2(-0.6, -0.6))), sd_segment(p, vec2(-0.6, -0.6), vec2(0.6, -0.6)));
		a = step(d, 0.2);
		ink = step(d, 0.2) * step(0.1, d);
	} else if (k == 5) {
		vec2 q = vec2(p.x * 1.8, p.y);
		a = step(length(q - vec2(0.0, 0.1)), 0.8) * step(abs(p.x), 0.5);
		ink = a * step(0.7, length(q - vec2(0.0, 0.1))) * 0.5;
	} else if (k == 6) {
		a = smoothstep(0.12, 0.0, abs(r - 0.7));
	} else if (k == 7) {
		vec2 q = abs(p);
		float h = max(q.x * 0.866 + q.y * 0.5, q.y);
		a = step(h, 0.85);
		ink = a * step(0.62, h);
	} else if (k == 8) {
		float d = min(min(sd_segment(p, vec2(-0.2, 0.9), vec2(0.25, 0.1)),
			sd_segment(p, vec2(0.25, 0.1), vec2(-0.25, -0.1))), sd_segment(p, vec2(-0.25, -0.1), vec2(0.2, -0.9)));
		a = smoothstep(0.26, 0.16, d);
		ink = smoothstep(0.08, 0.16, d) * a;
	} else if (k == 9) {
		vec2 q = vec2(p.x, p.y + 0.25);
		float d = length(q) - 0.6;
		d = min(d, max(abs(p.x) - (0.6 - (p.y + 0.25) * 0.55), -(p.y + 0.25)));
		a = step(d, 0.0) * step(p.y, 0.95);
		ink = a * step(-0.18, d);
	} else if (k == 10) {
		vec2 q = vec2(p.x - p.y * 0.3, p.y);
		float d = length(vec2(q.x * 2.2, q.y)) - 0.85;
		a = step(d, 0.0);
		ink = a * max(step(-0.22, d), step(abs(q.x), 0.06));
	} else {
		float d = abs(p.y - sin(p.x * 3.0 + t * 3.0) * 0.3);
		a = smoothstep(0.5, 0.2, d) * smoothstep(1.0, 0.5, abs(p.x));
		ink = smoothstep(0.3, 0.45, d) * a;
	}
	vec3 c = mix(colour.rgb, vec3(0.102, 0.047, 0.078), ink * 0.85);
	ALBEDO = c * (1.0 + glow * (1.0 - ink));
	ALPHA = clamp(a, 0.0, 1.0) * colour.a * fade * strength;
}
