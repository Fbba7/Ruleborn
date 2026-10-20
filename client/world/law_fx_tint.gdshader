// A law's screen-space tint (§21.3: "screen-space tints, never full-screen
// post-processing"): one quad over the screen, blended over the frame —
// the edges darkened toward a colour (Glowing dark's black, Sleepwalk's
// dream), the whole washed (Day and night's dark phase, a chord's flash).
// Nothing of the world is drawn again for it.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float t = 0.0;
uniform vec4 colour : source_color = vec4(0.1, 0.05, 0.2, 1.0);
// How dark the edges go, 0..1.
uniform float edge = 0.0;
// How much the whole screen is washed in `colour`, 0..1.
uniform float wash = 0.0;
// A flash of light over the screen, 0..1 (Tempest's lightning).
uniform float flash = 0.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 0.0, 1.0);
}

void fragment() {
	// Portrait first (§21.1): the sides darken as much as the ends.
	vec2 d = SCREEN_UV - vec2(0.5);
	d.y *= 0.8;
	float v = smoothstep(0.18, 0.62, length(d));
	float a = clamp(v * edge + wash, 0.0, 1.0);
	ALBEDO = mix(colour.rgb, vec3(1.0, 0.98, 0.9), flash);
	ALPHA = clamp(a + flash * 0.55, 0.0, 0.95);
}
