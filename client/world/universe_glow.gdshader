// Points of light on the universe map: stars, lanterns, windows, motes and
// skiff trails (§21.1: "glows"). Each glow is a quad whose four corners share
// its centre; the vertex stage spreads them across the screen, so a glow
// always faces the camera and a whole layer of them is one draw call. UV is
// the corner, UV2.x the glow's radius in metres; the vertex colour is its
// colour, and its alpha its strength. Additive, as the design's sprites are
// (realm_diorama.js `glow`, :521).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

// How much each glow breathes, 0 to 1, each at its own pace.
uniform float twinkle : hint_range(0.0, 1.0) = 0.0;
// A hard bright core (a star) rather than only a soft halo.
uniform float core : hint_range(0.0, 1.0) = 0.35;
uniform float strength = 1.0;

varying vec2 corner;
varying float pulse;

void vertex() {
	float seed = fract(sin(dot(VERTEX, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	vec3 at = VERTEX;
	pulse = 1.0 - twinkle * (0.5 + 0.5 * sin(TIME * (1.2 + seed * 2.6) + seed * 40.0));
	// UV2.y metres of fall: down and round again, fading at both ends.
	if (abs(UV2.y) > 0.001) {
		float u = fract(TIME * (0.08 + seed * 0.1) * 6.0 / max(abs(UV2.y), 1.0) + seed * 7.0);
		at.y -= u * UV2.y;
		pulse *= sin(u * PI);
	}
	vec3 centre = (MODELVIEW_MATRIX * vec4(at, 1.0)).xyz;
	float scale = length(MODEL_MATRIX[0].xyz);
	corner = UV * 2.0 - 1.0;
	centre.xy += corner * UV2.x * scale;
	VERTEX = centre;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

vec3 linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

void fragment() {
	float d = length(corner);
	float halo = max(0.0, 1.0 - d);
	halo *= halo;
	float spark = smoothstep(0.32, 0.0, d) * core;
	float a = (halo * (1.0 - core * 0.5) + spark) * COLOR.a * pulse * strength;
	ALBEDO = linear(COLOR.rgb) * a;
}
