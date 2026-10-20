// The realm's ground, painted (§21.3: "hand-painted gradient textures only"):
// the vertex colour carries the paint KitGround laid (the island meadow's own
// colour beside the grid, worn earth, trails, banks, moss), and this lays the
// meadow's shared brush over it (look_brush.gdshaderinc), exactly as the
// island's meadow wears it next to the grid, so the two are one ground; then
// the cobbles of a gravel path, the
// strata of a cliff, and seams at the tiles' edges faint enough to read the
// grid as texture, not a chequer.
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"
#include "res://world/look_brush.gdshaderinc"

// Where tile edges fall: 0 for an even grid, 0.5 for an odd one.
uniform vec2 grid_offset = vec2(0.0);
uniform float seam = 0.035;
uniform vec4 cobble : source_color = vec4(0.91, 0.84, 0.74, 1.0);
uniform vec4 mortar : source_color = vec4(0.62, 0.52, 0.45, 1.0);
// The worn trails between doors, world xz of each end (RealmKit's), drawn
// crisp: trodden earth with a ragged edge and a darker rim of worn grass.
uniform vec4 lanes[48];
uniform int lane_count = 0;
uniform vec4 lane_earth : source_color = vec4(0.72, 0.6, 0.45, 1.0);
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
	// The meadow's brush (look_brush.gdshaderinc), the very one the island's
	// meadow wears beside the grid, so the two meet as one painted ground.
	c = look_brush(c, p, grassy);
	vec3 glow = vec3(0.0);
	// A worn trail: crisp trodden earth, wobbling, with stones in it.
	if (lane_count > 0 && up > 0.6) {
		float best = 9.0;
		for (int i = 0; i < 48; i++) {
			if (i >= lane_count) {
				break;
			}
			vec2 a = lanes[i].xy;
			vec2 b = lanes[i].zw;
			vec2 ab = b - a;
			float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
			best = min(best, length(p - (a + ab * t)));
		}
		float wob = (vnoise(p * 5.0) - 0.5) * 0.08 + (vnoise(p * 17.0) - 0.5) * 0.03;
		float d = best + wob;
		float rim = 1.0 - smoothstep(0.24, 0.34, d);
		float earth = 1.0 - smoothstep(0.2, 0.23, d);
		c = mix(c, c * 0.84, rim * (1.0 - earth) * grassy);
		vec3 dirt = lane_earth.rgb * (0.9 + 0.18 * vnoise(p * 6.0));
		vec3 pebbles = cells(p * 9.0);
		dirt = mix(dirt, dirt * 1.18, (1.0 - smoothstep(0.08, 0.14, pebbles.x)) * step(0.7, pebbles.z));
		c = mix(c, dirt, earth * (1.0 - smoothstep(0.4, 0.46, path)) * (1.0 - cliff));
		grassy *= 1.0 - earth;
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
