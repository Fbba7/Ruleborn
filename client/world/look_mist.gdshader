// Soft mist and the cloud sea under the island: a camera-facing quad with a
// round, feathered alpha, tinted to the sky, drifting slowly. A screen-space
// soft shape, never full-screen post-processing (§21.3).
// Drawn as one MultiMesh, each puff's opacity its instance's alpha.
shader_type spatial;
render_mode skip_vertex_transform, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(1.0);
uniform float opacity = 0.3;
uniform float drift = 0.0;

void vertex() {
	// The quad is rebuilt facing the camera round the puff's centre (the
	// instance's transform is in MODELVIEW_MATRIX): its width comes in its
	// custom data's w, its height over its width in its colour's red.
	vec2 corner = (UV - 0.5) * vec2(1.0, -1.0) * vec2(INSTANCE_CUSTOM.w, INSTANCE_CUSTOM.w * COLOR.r);
	VERTEX = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz + vec3(corner, 0.0);
	VERTEX.x += sin(TIME * 0.05 + INSTANCE_CUSTOM.z) * drift;
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float d = dot(q, q);
	float a = exp(-d * 3.0) * (1.0 - smoothstep(0.7, 1.0, d));
	ALBEDO = colour.rgb;
	ALPHA = a * opacity * COLOR.a;
}
