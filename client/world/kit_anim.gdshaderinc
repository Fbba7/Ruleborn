// The kit's idle motion, from each vertex's CUSTOM0 (geo.gd's `anim`): a
// pivot in xyz and a kind in w. One merged mesh carries every piece's
// motion, so a realm's trees, wheels and flags move with no node per piece.
// Kinds are Geo.Anim's: 1 sway, 2 spin about Y, 3 about X, 4 about Z, 5 bob,
// 6 flag, 7 swing (a bell), 8 shiver (grass and reeds).

uniform float wind = 1.0;

vec3 kit_rot(vec3 p, vec3 axis, float a) {
	float c = cos(a);
	float s = sin(a);
	return p * c + cross(axis, p) * s + axis * dot(axis, p) * (1.0 - c);
}

// Moves `v` (and turns `n`) by the vertex's motion at time `t`.
void kit_move(inout vec3 v, inout vec3 n, vec4 custom, float t) {
	int kind = int(custom.w + 0.5);
	if (kind == 0) {
		return;
	}
	vec3 pivot = custom.xyz;
	// Each piece keeps its own phase, from where it stands.
	float ph = pivot.x * 1.31 + pivot.z * 0.77;
	vec3 d = v - pivot;
	if (kind == 1 || kind == 8) {
		float h = max(d.y, 0.0);
		float amp = kind == 1 ? 0.045 : 0.16;
		float sp = kind == 1 ? 1.5 : 2.6;
		vec2 push = vec2(sin(t * sp + ph), cos(t * sp * 0.8 + ph * 1.3)) * amp * wind * h * h;
		v.xz += push;
	} else if (kind >= 2 && kind <= 4) {
		vec3 axis = kind == 2 ? vec3(0.0, 1.0, 0.0) : (kind == 3 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0));
		float a = t * (kind == 2 ? 0.9 : 1.4) + ph;
		v = pivot + kit_rot(d, axis, a);
		n = kit_rot(n, axis, a);
	} else if (kind == 5) {
		v.y += sin(t * 1.4 + ph) * 0.06;
	} else if (kind == 6) {
		float r = length(d.xz);
		v.y += sin(r * 14.0 - t * 6.0 + ph) * 0.05 * r * 2.0;
		v.xz += normalize(vec2(-d.z, d.x) + 0.0001) * sin(r * 10.0 - t * 5.0 + ph) * 0.04 * r * 2.0;
	} else if (kind == 7) {
		float a = sin(t * 2.6 + ph) * 0.22;
		v = pivot + kit_rot(d, vec3(1.0, 0.0, 0.0), a);
		n = kit_rot(n, vec3(1.0, 0.0, 0.0), a);
	}
}
