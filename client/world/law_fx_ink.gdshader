// §21.3's ink outline (outline.gdshader's), for a law's moving pieces: the
// same 1.5-pixel inverted hull, moved by law_fx_motion first so the line
// stays on the piece.
shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled, depth_draw_opaque;

#include "res://world/law_fx_motion.gdshaderinc"

uniform vec4 ink : source_color = vec4(0.102, 0.047, 0.078, 1.0);
uniform float width_px = 1.5;

void vertex() {
	vec3 v = law_motion(VERTEX, CUSTOM0);
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(v, 1.0);
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
