// A speck of light: fireflies, Lantern Vale's flies, the Heart's golden
// motes, Verdant's pollen and Emberreach's sparks (§21.4's particles). A
// camera-facing quad with a bright core and a soft halo, added to what is
// behind it, pulsing on its own beat. Never smaller than `min_px` pixels on
// screen, so the particles read at the home camera's whole-realm zoom as
// well as in the heist's close follow camera. One MultiMesh a kind; the
// instance's transform is in MODELVIEW_MATRIX, the speck's size its scale.
shader_type spatial;
render_mode skip_vertex_transform, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled,
	blend_add;

// Shown by the hour: 0 hides it (by day), 1 shows it.
uniform float appear = 1.0;
// The halo's width over the speck's.
uniform float halo = 5.0;
// The halo's smallest width on screen, in pixels at the viewport's size.
uniform float min_px = 12.0;
// The halo's largest width, in metres.
uniform float max_width = 0.7;
uniform float strength = 1.0;
// Metres it wanders sideways, and metres it rises over `rise_period`
// seconds before starting again (sparks, motes).
uniform float drift = 0.25;
uniform float rise = 0.0;
uniform float rise_period = 6.0;

varying float pulse;
varying vec3 tint;

void vertex() {
	float size = length(MODELVIEW_MATRIX[0].xyz);
	vec3 centre = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float seed = float(INSTANCE_ID) * 1.618;
	vec3 view_up = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	vec3 view_side = (VIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz;
	float f = 0.0;
	if (rise > 0.0) {
		f = fract(TIME / rise_period + seed * 0.382);
		centre += view_up * f * rise;
	}
	centre += view_side * sin(TIME * 0.7 + seed) * drift + view_up * sin(TIME * 0.9 + seed * 2.0) * drift * 0.5;
	// Pixels a metre is drawn at this depth: the orthographic camera's
	// is the same everywhere; a perspective camera's falls with distance.
	float persp = PROJECTION_MATRIX[2][3] < -0.5 ? -centre.z : 1.0;
	float px_per_m = VIEWPORT_SIZE.y * 0.5 * PROJECTION_MATRIX[1][1] / max(persp, 0.01);
	float width = min(max(size * halo, min_px / max(px_per_m, 0.001)), max_width);
	vec2 corner = (UV - 0.5) * width;
	VERTEX = centre + vec3(corner, 0.0);
	pulse = 0.65 + 0.35 * sin(TIME * (1.6 + fract(seed) * 1.4) + seed * 5.0);
	// A rising spark fades in and out over its climb.
	if (rise > 0.0) {
		pulse *= smoothstep(0.0, 0.15, f) * (1.0 - smoothstep(0.7, 1.0, f));
	}
	pulse *= appear * strength;
	tint = COLOR.rgb;
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float d = dot(q, q);
	float core = exp(-d * 28.0);
	float glow = exp(-d * 4.5) * (1.0 - smoothstep(0.75, 1.0, d));
	ALBEDO = (tint * glow * 0.55 + mix(tint, vec3(1.0), 0.6) * core) * pulse;
}
