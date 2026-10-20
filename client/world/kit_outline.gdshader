// outline.gdshader's 1.5-pixel ink (§21.3) for pieces that move: the same
// inverted hull, moved first by the kit's idle motion so the ink stays on.
shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled, depth_draw_opaque;

#include "res://world/kit_anim.gdshaderinc"

uniform vec4 ink : source_color = vec4(0.102, 0.047, 0.078, 1.0);
uniform float width_px = 1.5;

void vertex() {
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	kit_move(v, n, CUSTOM0, TIME);
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(v, 1.0);
	vec3 vn = normalize((MODELVIEW_MATRIX * vec4(n, 0.0)).xyz);
	vec2 dir = (PROJECTION_MATRIX * vec4(vn, 0.0)).xy;
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
