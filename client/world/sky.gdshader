// §21.2's sky: "day #9FB9F0 to #F6D9C8; dusk #6A4FC9 to #F29C7B; night
// #1A1433 to #3A2B6B", crossed with the realm's own three colours (§21.4;
// the diorama's CSS sky, realm-diorama.js:1057–1059): a gradient down the
// screen, a soft glow of the low colour behind the island, and stars when
// the sky is dark. The world view sets the colours by the realm and the
// player's local time. Drawn as a quad over the whole screen at the far
// plane, behind everything, as the diorama draws its sky behind its canvas,
// so the orthographic camera sees the whole gradient. (The environment's
// sky would show the orthographic camera one colour, and its canvas
// background is lost in the Compatibility renderer once an ink outline,
// drawn with front faces culled, is on screen.)
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled, depth_draw_never;

uniform vec4 top : source_color = vec4(0.624, 0.725, 0.941, 1.0);
uniform vec4 bottom : source_color = vec4(0.965, 0.851, 0.784, 1.0);
// The middle stop; alpha 0 leaves the two-colour sky of the earlier look.
uniform vec4 middle : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 glow : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float stars = 0.0;
// The quad's depth in clip space: just short of the far plane, which the
// renderer's reversed depth puts at 0.
uniform float far_z = 0.00001;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, far_z, 1.0);
}

void fragment() {
	vec2 at = SCREEN_UV;
	float t = 1.0 - at.y;
	vec3 c;
	if (middle.a > 0.0) {
		c = t > 0.45 ? mix(middle.rgb, top.rgb, smoothstep(0.45, 1.0, t))
			: mix(bottom.rgb, middle.rgb, smoothstep(0.0, 0.45, t));
	} else {
		c = mix(bottom.rgb, top.rgb, smoothstep(0.1, 0.9, t));
	}
	// The glow behind the island: an ellipse 90% by 45% of the frame.
	vec2 q = (at - vec2(0.5, 0.55)) / vec2(0.9, 0.45);
	c = mix(c, glow.rgb, glow.a * (1.0 - smoothstep(0.0, 0.7, length(q))));
	// Stars, small and few, brighter toward the top.
	if (stars > 0.0) {
		vec2 cell = floor(at * vec2(90.0, 180.0));
		float h = hash(cell);
		vec2 f = fract(at * vec2(90.0, 180.0)) - 0.5;
		float s = step(0.985, h) * (1.0 - smoothstep(0.05, 0.25, length(f)));
		c += vec3(s) * stars * (0.4 + 0.6 * t) * (0.5 + 0.5 * hash(cell + 3.1));
	}
	ALBEDO = c;
}
