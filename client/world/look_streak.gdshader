// Wind streaks across Skyfield's sky (§21.4: "High clouds, wind streaks"):
// a long thin quad facing the camera, a bright dash running along it and
// fading, each on its own beat. One MultiMesh; the instance's transform is
// in MODELVIEW_MATRIX, its length and thickness its scale.
shader_type spatial;
render_mode skip_vertex_transform, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float opacity = 0.7;
uniform float speed = 0.22;
// The streak's smallest thickness on screen, in pixels, so it reads at the
// home camera's whole-realm zoom (look_spark.gdshader's way).
uniform float min_px = 4.0;

varying float run;

void vertex() {
	vec2 size = vec2(length(MODELVIEW_MATRIX[0].xyz), length(MODELVIEW_MATRIX[1].xyz));
	vec3 centre = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float persp = PROJECTION_MATRIX[2][3] < -0.5 ? -centre.z : 1.0;
	float px_per_m = VIEWPORT_SIZE.y * 0.5 * PROJECTION_MATRIX[1][1] / max(persp, 0.01);
	size.y = min(max(size.y, min_px / max(px_per_m, 0.001)), 0.5);
	vec2 corner = (UV - 0.5) * size;
	VERTEX = centre + vec3(corner, 0.0);
	run = fract(TIME * speed + float(INSTANCE_ID) * 0.37);
}

void fragment() {
	float along = UV.x;
	float head = smoothstep(run - 0.35, run, along) * (1.0 - smoothstep(run, run + 0.04, along));
	float across = 1.0 - abs(UV.y - 0.5) * 2.0;
	ALBEDO = colour.rgb;
	ALPHA = head * across * opacity;
}
