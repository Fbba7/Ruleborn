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
	float edge = 1.0 - smoothstep(0.6, 1.0, across);
	// Strands: soft columns of water falling at their own pace, each a long
	// rounded streak rather than a hard dash, wavering a little sideways.
	float x = UV.x * 7.0 + sin(UV.y * 9.0 + TIME * 0.8) * 0.12;
	float col = floor(x);
	float within = abs(fract(x) - 0.5) * 2.0;
	float run = UV.y * 2.2 - TIME * speed * (0.75 + 0.5 * hash(vec2(col, 1.0)));
	float phase = fract(run + hash(vec2(col, 7.0)));
	float strand = smoothstep(0.0, 0.25, phase) * (1.0 - smoothstep(0.55, 0.95, phase));
	strand *= 1.0 - smoothstep(0.35, 0.9, within);
	vec3 c = mix(water.rgb, foam.rgb, 0.25 + 0.55 * strand * (1.0 - across * 0.6));
	// A bright core down the middle that swells and ebbs, as the diorama's
	// falls do (realm-diorama.js:1003, its texture brightest at the middle).
	float pulse = 0.75 + 0.25 * sin(TIME * 2.2 - UV.y * 6.0);
	float core = 1.0 - smoothstep(0.0, 0.45, across);
	c = mix(c, foam.rgb, core * pulse * 0.55);
	// White water where it tips over the lip.
	c = mix(c, foam.rgb, (1.0 - smoothstep(0.08, 0.2, UV.y)) * 0.7);
	ALBEDO = c;
	// It thins into spray toward its foot, the strands lasting longest.
	float foot = 1.0 - smoothstep(0.55, 1.0, UV.y);
	float spray = 1.0 - smoothstep(0.75, 1.0, UV.y);
	ALPHA = edge * mix(spray * strand * 0.8, 0.88 + 0.12 * strand, foot);
}
