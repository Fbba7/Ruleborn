// The scout's mist (StageScout): soft cards that always face the camera,
// each a lumpy cloud edge lit lighter on top and violet beneath (§21.1's
// cool shadows), drifting slowly. One mesh for all of them; every vertex of
// a card sits at its centre, and the card is spread in view space here.
// COLOR.r is the card's seed, COLOR.g its size (a fifth of its width in
// metres, so it fits a colour's 0–1).
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 top : source_color = vec4(0.97, 0.95, 1.0, 1.0);
uniform vec4 under : source_color = vec4(0.66, 0.6, 0.9, 1.0);
uniform float opacity = 0.86;
uniform float drift = 1.0;

varying float seed;

void vertex() {
	seed = COLOR.r;
	vec3 centre = VERTEX;
	centre.x += sin(TIME * 0.13 * drift + seed * 6.28) * 0.5;
	centre.z += cos(TIME * 0.1 * drift + seed * 4.1) * 0.4;
	centre.y += sin(TIME * 0.4 * drift + seed * 9.0) * 0.06;
	vec4 v = MODELVIEW_MATRIX * vec4(centre, 1.0);
	v.xy += (UV - 0.5) * vec2(5.0, -2.9) * COLOR.g;
	POSITION = PROJECTION_MATRIX * v;
}

void fragment() {
	vec2 p = UV - 0.5;
	float r = length(p * vec2(1.0, 1.55));
	float a = atan(p.y, p.x);
	// Three or four rounded lobes, as a cloud's top has.
	float edge = 0.42 + 0.045 * sin(a * 3.0 + seed * 21.0 + TIME * 0.2 * drift)
		+ 0.03 * sin(a * 5.0 - seed * 13.0);
	float body = smoothstep(edge, edge - 0.2, r);
	ALBEDO = mix(under.rgb, top.rgb, smoothstep(0.22, -0.18, p.y));
	ALPHA = body * opacity;
}
