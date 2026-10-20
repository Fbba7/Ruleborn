// A waterfall off the island's rim (§21.1: "Islands hang over the sky with
// roots and waterfalls beneath"): a ribbon of pale water, bright at its
// heart and fading at its edges and its foot, with streaks running down.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 water : source_color = vec4(0.78, 0.94, 1.0, 1.0);
uniform vec4 foam : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float speed = 1.4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;
	float edge = 1.0 - smoothstep(0.55, 1.0, across);
	// Streaks: columns of dashes falling at their own pace.
	float col = floor(UV.x * 9.0);
	float run = UV.y * 3.0 - TIME * speed * (0.8 + 0.4 * hash(vec2(col, 1.0)));
	float dash = step(0.55, fract(run + hash(vec2(col, 7.0))));
	vec3 c = mix(water.rgb, foam.rgb, 0.35 + 0.45 * dash * (1.0 - across));
	ALBEDO = c;
	float foot = 1.0 - smoothstep(0.62, 1.0, UV.y);
	ALPHA = edge * foot * (0.82 + 0.18 * dash);
}
