// The realm's ground, painted (§21.3: "hand-painted gradient textures only"):
// the vertex colour carries the paint KitGround laid (grass, worn earth,
// banks, moss), and this adds the brush — long strokes and flecks of blade —
// the cobbles of a path, the strata of a cliff, and seams at the tiles'
// edges faint enough to read the grid without a chequer. Everything is drawn
// in world space from noise, so no texture is shipped.
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"

// Where tile edges fall: 0 for an even grid, 0.5 for an odd one.
uniform vec2 grid_offset = vec2(0.0);
uniform float seam = 0.09;
uniform vec4 cobble : source_color = vec4(0.91, 0.84, 0.74, 1.0);
uniform vec4 mortar : source_color = vec4(0.62, 0.52, 0.45, 1.0);
uniform vec4 strata : source_color = vec4(0.42, 0.33, 0.30, 1.0);

varying vec3 wpos;
varying float up;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	up = NORMAL.y;
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

// Distance to the nearest cell centre and to the next: cobbles.
vec3 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	float id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 7.31)) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = hash(i + g + 3.7);
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec3(d1, d2, id);
}

void fragment() {
	vec3 c = COLOR.rgb;
	float path = UV.x;
	float lush = UV.y;
	float cliff = UV2.x;
	float stone = UV2.y;
	vec2 p = wpos.xz;
	// The brush: broad strokes across the ground, then finer ones along them.
	float n1 = vnoise(p * 1.3);
	float stroke = vnoise(vec2(p.x * 2.2 + p.y * 1.1, p.y * 7.0 - p.x * 2.0) + n1 * 3.0);
	float blades = vnoise(vec2(p.x * 26.0, p.y * 9.0) + stroke * 4.0);
	float grassy = (1.0 - cliff) * (1.0 - path) * (1.0 - stone * 0.6);
	c *= 1.0 + (stroke - 0.5) * 0.16 * grassy + (blades - 0.5) * 0.14 * grassy * (0.6 + lush);
	// Flecks: light blade tips and the odd dark clump, a painter's dabs.
	vec2 cell = floor(p * 11.0);
	float h = hash(cell);
	vec2 inside = fract(p * 11.0) - 0.5;
	float dab = step(length(inside * vec2(1.0, 2.2)), 0.28) * grassy;
	c = mix(c, c * 1.18 + vec3(0.03, 0.04, 0.0), dab * step(0.9, h));
	c = mix(c, c * 0.78, dab * step(h, 0.07) * (0.5 + lush));
	// A path: cobbles laid in the worn earth, mortar between them.
	if (path > 0.01) {
		vec3 cb = cells(p * 4.2);
		float edge = smoothstep(0.02, 0.09, cb.y - cb.x);
		vec3 stoneC = cobble.rgb * (0.86 + 0.2 * cb.z) * (0.94 + 0.08 * n1);
		vec3 pathC = mix(mortar.rgb, stoneC, edge);
		c = mix(c, pathC, smoothstep(0.35, 0.65, path + (n1 - 0.5) * 0.25));
	}
	// Scree and bare rock: grit.
	c *= 1.0 - stone * (hash(floor(p * 30.0)) - 0.5) * 0.25;
	// A cliff: strata bands, uneven, and darker toward the foot.
	if (cliff > 0.01) {
		float band = sin(wpos.y * 26.0 + vnoise(p * 3.0) * 4.0);
		c = mix(c, c * mix(vec3(1.0), strata.rgb * 1.6, 0.35), cliff * smoothstep(0.55, 0.95, band));
		c *= 1.0 - cliff * (vnoise(vec2(p.x + p.y, wpos.y) * 9.0) - 0.5) * 0.18;
	}
	// The grid: a faint seam where tiles meet, on flat ground only.
	vec2 g = abs(fract(p + grid_offset) - 0.5);
	float to_edge = 0.5 - max(g.x, g.y);
	float line = 1.0 - smoothstep(0.0, 0.03, to_edge);
	c *= 1.0 - seam * line * smoothstep(0.85, 0.98, up) * (1.0 - cliff);
	ALBEDO = saturated(c);
}
