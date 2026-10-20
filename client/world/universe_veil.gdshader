// Light that is not a solid on the universe map: the Heart's beam, a rift's
// portal, a waterfall's fall and the chute's running water. The vertex
// colour is the light; UV.y runs from its root (0) to where it fades out (1),
// and UV.x along it, where streaks scroll at `flow` (the design's scrolling
// water and beam textures, realm_diorama.js:1186–1189).
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_add;

uniform float flow = 0.0;
uniform float streaks = 0.0;
uniform float fade_power = 1.4;
uniform float strength = 1.0;

vec3 linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

void fragment() {
	// UV2.y says how it fades: 0 from its root to its end, 1 to both its
	// edges, 2 both.
	float edge = 1.0 - abs(UV2.x * 2.0 - 1.0);
	float fade = UV2.y > 0.5 ? smoothstep(0.0, 0.6, edge) : 1.0;
	if (UV2.y < 0.5 || UV2.y > 1.5) {
		fade *= pow(clamp(1.0 - UV.y, 0.0, 1.0), fade_power);
	}
	float s = 1.0;
	if (streaks > 0.0) {
		float w = fract(UV.x * streaks - TIME * flow + sin(UV2.x * 9.0) * 0.15);
		s = 0.55 + 0.75 * smoothstep(0.75, 0.95, w) * smoothstep(1.0, 0.95, w);
	}
	ALBEDO = linear(COLOR.rgb) * COLOR.a * fade * s * strength;
	// Written, so the light is drawn after every solid and the galaxy, as
	// light should be; added, so its own strength is in ALBEDO.
	ALPHA = 1.0;
}
