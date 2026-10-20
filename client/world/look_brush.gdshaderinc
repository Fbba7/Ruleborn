// The meadow's brush, shared by the island's meadow (look_ground.gdshader)
// and open to the grid's ground (kit_ground.gdshader, whose brush this is,
// written out the same so the two meet without a seam): broad patches of
// light and shade, dabs of warm and cool like short strokes, and flecks of
// blade, all from noise in world space. `grassy` is how much of it a point
// takes (0 on a path, a cliff or bare stone).

float look_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float look_vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(look_hash(i), look_hash(i + vec2(1.0, 0.0)), f.x),
		mix(look_hash(i + vec2(0.0, 1.0)), look_hash(i + vec2(1.0)), f.x), f.y);
}

// Distance to the nearest cell centre, to the next, and the nearest's id.
vec3 look_cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	float id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(look_hash(i + g), look_hash(i + g + 7.31)) * 0.8 + 0.1;
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = look_hash(i + g + 3.7);
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec3(d1, d2, id);
}

vec3 look_brush(vec3 c, vec2 p, float grassy) {
	float n1 = look_vnoise(p * 0.9) * 0.6 + look_vnoise(p * 2.3 + 5.0) * 0.4;
	c *= 1.0 + (n1 - 0.5) * 0.26 * grassy;
	vec3 dab = look_cells(vec2(p.x * 3.2 + p.y * 0.9, p.y * 8.5 - p.x * 0.6));
	float soft = smoothstep(0.05, 0.6, dab.y - dab.x);
	float tone = dab.z - 0.5;
	vec3 warm = vec3(1.06, 1.05, 0.9);
	vec3 cool = vec3(0.88, 0.97, 0.94);
	c *= mix(vec3(1.0), tone > 0.0 ? warm : cool, abs(tone) * 1.1 * soft * grassy);
	vec2 cell = floor(p * 11.0);
	float h = look_hash(cell);
	vec2 inside = fract(p * 11.0) - 0.5;
	float fleck = step(length(inside * vec2(1.0, 2.2)), 0.26) * grassy;
	c = mix(c, c * 1.16 + vec3(0.03, 0.04, 0.0), fleck * step(0.9, h));
	c = mix(c, c * 0.78, fleck * step(h, 0.08) * 0.5);
	return c;
}
