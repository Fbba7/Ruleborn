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
// The builder's grid (RealmKit.show_grid): 0 none, 1 every tile drawn — an ink
// line round it with a light edge inside and the tiles in a faint chequer,
// on flat ground and cliffs alike, so a tile can be picked at a glance.
uniform float grid_show = 0.0;
// Half the grid's size in tiles: no tile is drawn past it.
uniform vec2 grid_half = vec2(7.0);
uniform vec4 cobble : source_color = vec4(0.91, 0.84, 0.74, 1.0);
uniform vec4 mortar : source_color = vec4(0.62, 0.52, 0.45, 1.0);
// The worn trails between doors, world xz of each end (RealmKit's), drawn
// crisp: trodden earth with a ragged edge and a darker rim of worn grass.
uniform vec4 lanes[48];
uniform int lane_count = 0;
uniform vec4 lane_earth : source_color = vec4(0.72, 0.6, 0.45, 1.0);
uniform vec4 strata : source_color = vec4(0.42, 0.33, 0.30, 1.0);
// The realm's own marks, the very texture the island's meadow wears (T2's
// LookPaint.deco, `deco_scale` metres a tile in world space): the Heart's
// petals, Tidehold's shells, …; `deco_glow` makes them light. Faded in from
// the grid's edge, where the meadow's own fade out.
uniform sampler2D deco : source_color, filter_linear_mipmap, repeat_enable;
uniform float deco_scale = 0.0;
uniform float deco_glow = 0.0;
// Pebbles strewn over the grass, as the design's meadow has them.
uniform vec4 pebble : source_color = vec4(0.62, 0.58, 0.6, 1.0);
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
	// Moss: soft cushions, each a little dome of light over a darker hollow.
	if (lush > 0.05) {
		vec3 mc = cells(p * 6.0);
		float cushion = 1.0 - smoothstep(0.0, 0.42, mc.x);
		float m = smoothstep(0.3, 0.8, lush) * (1.0 - cliff);
		c *= mix(1.0, mix(0.8, 1.12, cushion) * (0.94 + 0.12 * mc.z), m);
	}
	// A worn trail as the design's lanes: a chain of rounded flat stones laid
	// one after another along it, each with a lit top and a shaded foot, on a
	// narrow strip of trodden earth with a rim of worn grass.
	if (lane_count > 0 && up > 0.6) {
		float best = 9.0;
		float along = 0.0;
		float side = 0.0;
		float which = 0.0;
		for (int i = 0; i < 48; i++) {
			if (i >= lane_count) {
				break;
			}
			vec2 a = lanes[i].xy;
			vec2 b = lanes[i].zw;
			vec2 ab = b - a;
			float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
			float dl = length(p - (a + ab * t));
			if (dl < best) {
				best = dl;
				along = t * length(ab);
				vec2 nrm = normalize(vec2(-ab.y, ab.x) + vec2(0.0001));
				side = dot(p - a, nrm);
				which = float(i);
			}
		}
		float wob = (vnoise(p * 5.0) - 0.5) * 0.05;
		float d = best + wob;
		float off_path = 1.0 - smoothstep(0.4, 0.46, path);
		float rim = 1.0 - smoothstep(0.2, 0.3, d);
		float earth = 1.0 - smoothstep(0.15, 0.18, d);
		c = mix(c, c * 0.84, rim * (1.0 - earth) * grassy);
		vec3 dirt = lane_earth.rgb * (0.86 + 0.14 * vnoise(p * 6.0));
		c = mix(c, dirt, earth * off_path * (1.0 - cliff));
		// The stones: one every 0.3 m, each nudged aside and turned a little.
		float step_len = 0.33;
		float k = floor(along / step_len);
		float h1 = hash(vec2(k, which));
		vec2 q = vec2(fract(along / step_len) - 0.5 + (h1 - 0.5) * 0.15, 0.0) * step_len;
		q.y = side - (hash(vec2(which, k + 3.1)) - 0.5) * 0.07;
		vec2 e = q / vec2(0.14, 0.115 + 0.02 * h1);
		float r = length(e);
		float stone_in = 1.0 - smoothstep(0.86, 1.0, r);
		float lit = clamp(0.5 - e.y * 0.35 + 0.35 * (1.0 - r), 0.0, 1.0);
		vec3 slab = mix(cobble.rgb, lane_earth.rgb, 0.3) * (0.92 + 0.12 * h1) * mix(0.84, 1.12, lit);
		float shade = (1.0 - smoothstep(0.95, 1.18, r)) * (1.0 - stone_in);
		float on_lane = off_path * (1.0 - cliff) * step(best, 0.3);
		c = mix(c, c * 0.72, shade * on_lane * 0.6);
		c = mix(c, slab, stone_in * on_lane);
		grassy *= 1.0 - max(earth, stone_in * on_lane);
	}
	// A path: a ribbon of cobbles laid in worn earth (UV.x is how near the
	// path's middle line this is), a darker kerb at its edge.
	if (path > 0.3) {
		vec3 cb = cells(p * 3.4);
		float edge = smoothstep(0.03, 0.1, cb.y - cb.x);
		// Each stone lit on its upper side, so the ribbon reads as rounded
		// stones, not a mosaic.
		float dome = 1.0 - smoothstep(0.0, 0.55, cb.x);
		vec3 stoneC = cobble.rgb * (0.86 + 0.12 * cb.z + 0.1 * dome) * (0.97 + 0.04 * n1);
		vec3 pathC = mix(mortar.rgb, stoneC, edge);
		float wob = (vnoise(p * 9.0) - 0.5) * 0.06;
		float inside_ = smoothstep(0.43, 0.47, path + wob);
		float kerb = smoothstep(0.43, 0.47, path + wob) * (1.0 - smoothstep(0.47, 0.53, path + wob));
		c = mix(c, pathC, inside_);
		c = mix(c, mortar.rgb * 0.8, kerb * 0.7);
	}
	// Pebbles in the grass: a few small stones, lit above, shaded below.
	vec3 pb = cells(p * 2.6 + 11.0);
	float stone_dot = (1.0 - smoothstep(0.07, 0.1, pb.x)) * step(0.82, pb.z) * grassy * step(0.6, up);
	c = mix(c, pebble.rgb * (0.85 + 0.25 * pb.z), stone_dot);
	// The realm's marks over the grass.
	if (deco_scale > 0.0 && up > 0.6) {
		vec4 dm = texture(deco, p / deco_scale);
		vec2 inside_grid = grid_half - abs(p);
		dm.a *= 0.8 * grassy * smoothstep(0.2, 1.6, min(inside_grid.x, inside_grid.y));
		c = mix(c, dm.rgb, dm.a * (1.0 - deco_glow));
		glow += dm.rgb * dm.a * deco_glow;
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
	if (grid_show > 0.0) {
		float px = fwidth(p.x) + fwidth(p.y);
		float ink_line = 1.0 - smoothstep(px * 0.6, px * 1.6 + 0.012, to_edge);
		float lit_edge = (1.0 - smoothstep(px * 1.6 + 0.012, px * 2.6 + 0.05, to_edge)) * (1.0 - ink_line);
		vec2 cell = floor(p + grid_offset);
		float odd = mod(cell.x + cell.y, 2.0);
		vec2 past = abs(p) - grid_half;
		float flat_ = smoothstep(0.6, 0.9, up) * step(max(past.x, past.y), 0.0);
		c *= 1.0 + grid_show * (odd * 0.07 - 0.02) * flat_;
		c = mix(c, c * 1.25 + 0.05, lit_edge * 0.5 * grid_show * flat_);
		c = mix(c, vec3(0.10, 0.05, 0.08), ink_line * 0.55 * grid_show * flat_);
	}
	ALBEDO = saturated(c);
	EMISSION = glow;
}
