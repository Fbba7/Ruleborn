// §21.3's ink outline: "1.5-pixel ink outlines (#1A0C14) drawn in screen
// space, so a far line is as thick as a near one". An inverted hull pushed
// out along the normal in clip space by a fixed number of pixels, drawn as
// a next pass behind the piece it outlines.
shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled, depth_draw_opaque;

uniform vec4 ink : source_color = vec4(0.102, 0.047, 0.078, 1.0);
uniform float width_px = 1.5;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 dir = (PROJECTION_MATRIX * vec4(n, 0.0)).xy;
	float len = length(dir);
	if (len > 0.0001) {
		dir /= len;
		clip.xy += dir * width_px * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = ink.rgb;
}
