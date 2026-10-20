// Wind streaks across Skyfield's sky (§21.4: "High clouds, wind streaks"):
// a long thin quad facing the camera, a bright dash running along it and
// fading, each on its own beat. One MultiMesh; the instance's transform is
// in MODELVIEW_MATRIX, its length and thickness in its custom data.
shader_type spatial;
render_mode skip_vertex_transform, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float opacity = 0.55;
uniform float speed = 0.22;

varying float run;

void vertex() {
	vec2 corner = (UV - 0.5) * vec2(INSTANCE_CUSTOM.x, INSTANCE_CUSTOM.y);
	VERTEX = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz + vec3(corner, 0.0);
	run = fract(TIME * speed + float(INSTANCE_ID) * 0.37);
}

void fragment() {
	float along = UV.x;
	float head = smoothstep(run - 0.35, run, along) * (1.0 - smoothstep(run, run + 0.04, along));
	float across = 1.0 - abs(UV.y - 0.5) * 2.0;
	ALBEDO = colour.rgb;
	ALPHA = head * across * opacity;
}
