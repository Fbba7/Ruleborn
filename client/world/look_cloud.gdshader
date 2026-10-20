// Clouds at the island's level and below (the diorama's `cloud`,
// realm-diorama.js:940, and its soft cloud sprites, :1008): each a painted
// sprite facing the camera, two triangles, its shape a cluster of round
// lobes on a flat base, white on top and a cool violet beneath where the sky
// lights it (§21.1: "cool shadows beneath"), with a soft painted edge. They
// wander slowly on the wind. One MultiMesh: the instance's transform is in
// MODELVIEW_MATRIX; its width and height are its scale, its seed its custom data's w.
shader_type spatial;
render_mode skip_vertex_transform, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 top : source_color = vec4(1.0);
uniform vec4 under : source_color = vec4(0.72, 0.68, 0.92, 1.0);
uniform float drift = 0.6;
uniform float opacity = 0.96;

varying float seed;

void vertex() {
	seed = INSTANCE_CUSTOM.w;
	vec2 size = vec2(length(MODELVIEW_MATRIX[0].xyz), length(MODELVIEW_MATRIX[1].xyz));
	vec2 corner = (UV - 0.5) * vec2(1.0, -1.0) * size;
	VERTEX = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz + vec3(corner, 0.0);
	VERTEX.x += sin(TIME * 0.07 + seed * 7.0) * drift;
}

float h1(float n) {
	return fract(sin(n * 91.3458) * 47453.5453);
}

void fragment() {
	// x in [-1, 1] across, y in [-1, 1] up.
	vec2 q = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);
	float field = 0.0;
	float shade = 0.0;
	for (int k = 0; k < 5; k++) {
		float fk = float(k);
		float x = mix(-0.62, 0.62, fk / 4.0) + (h1(seed + fk) - 0.5) * 0.18;
		float r = 0.3 + 0.16 * h1(seed * 3.1 + fk) + (k == 2 ? 0.14 : 0.0) - abs(fk - 2.0) * 0.03;
		vec2 c = vec2(x, -0.45 + r * 0.95);
		vec2 d = (q - c) / vec2(r, r * 1.6);
		float v = 1.0 - dot(d, d);
		field = max(field, v);
		// Light from above in each lobe: its top bright, its underside in shade.
		shade = max(shade, v * smoothstep(-0.7, 0.6, (q.y - c.y) / (r * 1.6)));
	}
	// A flat base, as a cartoon cloud sits on the air.
	field *= smoothstep(-0.62, -0.5, q.y);
	float edge = smoothstep(0.0, 0.12, field);
	float lit = smoothstep(0.18, 0.5, shade);
	ALBEDO = mix(under.rgb, top.rgb, lit);
	ALPHA = edge * opacity;
}
