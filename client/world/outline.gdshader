// §21.3's ink outline: "1.5-pixel ink outlines (#1A0C14) drawn in screen
// space, so a far line is as thick as a near one". An inverted hull pushed
// out along the normal by a fixed number of pixels, drawn as a next pass
// behind the piece it outlines. The push is made in view space, worked out
// from the projection so it is the same number of pixels at any distance,
// under the orthographic camera or a perspective one. (Writing the clip
// position directly makes the Compatibility renderer drop the canvas sky
// behind the world.)
shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled, depth_draw_opaque, skip_vertex_transform, fog_disabled;

uniform vec4 ink : source_color = vec4(0.102, 0.047, 0.078, 1.0);
uniform float width_px = 1.5;

void vertex() {
	vec3 v = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 clip = PROJECTION_MATRIX * vec4(v, 1.0);
	vec2 dir = (PROJECTION_MATRIX * vec4(n, 0.0)).xy;
	float len = length(dir);
	if (len > 0.0001) {
		dir /= len;
		// Pixels to view units on each axis, at this depth.
		vec2 per_px = 2.0 / (VIEWPORT_SIZE * vec2(PROJECTION_MATRIX[0][0], PROJECTION_MATRIX[1][1])) * clip.w;
		v.xy += dir * width_px * per_px;
	}
	VERTEX = v;
	NORMAL = n;
}

void fragment() {
	ALBEDO = ink.rgb;
}
