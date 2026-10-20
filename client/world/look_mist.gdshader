// Soft mist and the cloud sea under the island: a camera-facing quad with a
// round, feathered alpha, tinted to the sky, drifting slowly. A screen-space
// soft shape, never full-screen post-processing (§21.3).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(1.0);
uniform float opacity = 0.3;
uniform float drift = 0.0;

void vertex() {
	// Face the camera.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	VERTEX.x += sin(TIME * 0.05 + MODEL_MATRIX[3].x) * drift;
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float d = dot(q, q);
	float a = exp(-d * 3.0) * (1.0 - smoothstep(0.7, 1.0, d));
	ALBEDO = colour.rgb;
	ALPHA = a * opacity;
}
