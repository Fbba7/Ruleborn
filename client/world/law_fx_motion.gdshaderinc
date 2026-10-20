// How a law's solid pieces move (§21.3: "vertex animation"), shared by
// law_fx_solid and law_fx_glass. Per vertex: CUSTOM0 is the piece's pivot
// (x, y, z) and its phase; `motion` picks the movement and `amount` its size.
// Every movement is a function of the heist's clock alone, so a replay moves
// the same every time.

uniform float t = 0.0;
uniform float pace = 1.0;
uniform int motion = 0;
uniform float amount = 1.0;
// 0..1: the whole signature fading in or out (a pylon broken, Unmaking).
uniform float strength = 1.0;

vec3 law_motion(vec3 v, vec4 custom) {
	vec3 pivot = custom.xyz;
	float phase = custom.w;
	float s = t * pace;
	vec3 d = v - pivot;
	if (motion == 1) {
		// Hover (Half gravity): lifted a hand off the ground, bobbing slowly,
		// turning.
		float a = s * 0.35 + phase * 6.0;
		d = vec3(d.x * cos(a) - d.z * sin(a), d.y, d.x * sin(a) + d.z * cos(a));
		d.y += amount * (0.7 + 0.3 * sin(s * 0.9 + phase * 6.28));
	} else if (motion == 2) {
		// Time-lapse growth (Bloom): from a stub to full in seconds, held,
		// then cut back and grown again.
		float u = fract(s / 9.0 + phase);
		float g = smoothstep(0.0, 0.45, u) * (1.0 - smoothstep(0.92, 1.0, u));
		g = max(g, 0.18);
		float pop = 1.0 + 0.08 * sin(clamp(u / 0.45, 0.0, 1.0) * 9.42) * (1.0 - smoothstep(0.3, 0.6, u));
		d *= vec3(mix(0.55, 1.0, g) * pop, g, mix(0.55, 1.0, g) * pop);
	} else if (motion == 3) {
		// Jelly (Bounce): a wobble that runs up the piece now and then.
		float u = fract(s / 3.2 + phase);
		float w = exp(-u * 4.0) * sin(u * 34.0) * amount;
		float h = max(d.y, 0.0);
		d.x += w * h * 0.35;
		d.z += w * h * 0.2;
		d.y *= 1.0 - w * 0.25;
		d.xz *= 1.0 + w * 0.12;
	} else if (motion == 4) {
		// Hum (Crystal, Glowing dark): a slow breathing scale.
		d *= 1.0 + amount * 0.08 * sin(s * 2.4 + phase * 6.28);
	} else if (motion == 5) {
		// Sway: tips bend one way and back.
		float h = max(d.y, 0.0);
		d.x += sin(s * 1.6 + phase * 6.28) * amount * h * h;
	} else if (motion == 6) {
		// Orbit about the pivot's upright axis.
		float a = s * amount + phase * 6.28;
		d = vec3(d.x * cos(a) - d.z * sin(a), d.y + sin(s * 1.3 + phase * 6.28) * 0.08, d.x * sin(a) + d.z * cos(a));
	} else if (motion == 7) {
		// Float (Echoes): a slow rise and fall a little off the ground.
		d.y += 0.12 + sin(s * 0.8 + phase * 6.28) * 0.08 * amount;
	} else if (motion == 8) {
		// Tremble (Brittle stone's crumbs, Static): a fine shake.
		float k = floor(s * 14.0 + phase * 50.0);
		d.x += (fract(sin(k * 12.9898) * 43758.5) - 0.5) * 0.03 * amount;
		d.z += (fract(sin(k * 78.233) * 43758.5) - 0.5) * 0.03 * amount;
	} else if (motion == 9) {
		// Drop: a crumb or drop falling slowly from the pivot and gone.
		float u = fract(s / 2.6 + phase);
		d.y -= u * u * amount;
		d *= 1.0 - smoothstep(0.8, 1.0, u);
	}
	d *= mix(0.001, 1.0, clamp(strength, 0.0, 1.0));
	return pivot + d;
}
