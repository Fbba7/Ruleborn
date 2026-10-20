// The realm's ground, painted (§21.3: "hand-painted gradient textures only"):
// the vertex colour carries the paint KitGround laid (the island meadow's own
// colour, worn earth, trails, banks, moss), and this lays T2's painted grass
// and the realm's marks over it exactly as the island's meadow takes them,
// so grid and meadow are one ground; then the cobbles of a gravel path, the
// strata of a cliff, and seams at the tiles' edges faint enough to read the
// grid as texture, not a chequer.
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"

// Where tile edges fall: 0 for an even grid, 0.5 for an odd one.
uniform vec2 grid_offset = vec2(0.0);
uniform float seam = 0.035;
// T2's painted grass (LookPaint.grass) and the realm's marks (LookPaint.deco),
// laid exactly as look_ground.gdshader lays them on the island's meadow.
uniform sampler2D paint : source_color, filter_linear_mipmap, repeat_enable;
uniform float paint_scale = 4.2;
uniform float paint_strength = 1.0;
uniform sampler2D deco : source_color, filter_linear_mipmap, repeat_enable;
uniform float deco_scale = 0.0;
uniform float deco_glow = 0.0;
uniform float deco_strength = 1.0;
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
	float n1 = vnoise(p * 0.9) * 0.6 + vnoise(p * 2.3 + 5.0) * 0.4;
	float grassy = (1.0 - cliff) * (1.0 - smoothstep(0.4, 0.46, path)) * (1.0 - stone * 0.6);
	// The island's own paint over the flat ground, as on the meadow.
	float pt = texture(paint, p / paint_scale).r;
	c *= mix(1.0, pt * 1.25, paint_strength * (up > 0.6 ? 1.0 : 0.0));
	vec3 glow = vec3(0.0);
	if (deco_scale > 0.0 && up > 0.6) {
		vec4 d = texture(deco, p / deco_scale);
		d.a *= deco_strength * grassy;
		c = mix(c, d.rgb, d.a * (1.0 - deco_glow));
		glow += d.rgb * d.a * deco_glow;
	}
	// A path: a ribbon of cobbles laid in worn earth (UV.x is how near the
	// path's middle line this is), a darker kerb at its edge.
	if (path > 0.3) {
		vec3 cb = cells(p * 5.0);
		float edge = smoothstep(0.02, 0.08, cb.y - cb.x);
		vec3 stoneC = cobble.rgb * (0.84 + 0.22 * cb.z) * (0.95 + 0.08 * n1);
		vec3 pathC = mix(mortar.rgb, stoneC, edge);
		float wob = (vnoise(p * 9.0) - 0.5) * 0.06;
		float inside_ = smoothstep(0.43, 0.47, path + wob);
		float kerb = smoothstep(0.43, 0.47, path + wob) * (1.0 - smoothstep(0.47, 0.53, path + wob));
		c = mix(c, pathC, inside_);
		c = mix(c, mortar.rgb * 0.8, kerb * 0.7);
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
	EMISSION = glow;
}
