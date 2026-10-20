// §21.3's ink outline on a character: "1.5-pixel ink outlines (#1A0C14) drawn
// in screen space". An inverted hull pushed out along the skinned normal in
// clip space, drawn as the body material's next pass. The design's handoff
// says the owner had the character outline removed; §21.3 asks for it, so it
// is on by default and CreatureModel.OUTLINE turns it off in one place.
shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled, depth_draw_opaque;

uniform vec4 ink : source_color = vec4(0.102, 0.047, 0.078, 1.0);
uniform float width_px = 1.5;

void vertex() {
	// Accessories (UV2.x under 0.5) take a finer line than the body, so eyes and
	// straps are not ringed in ink.
	float w = UV2.x >= 0.5 ? width_px : width_px * 0.3;
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 dir = (PROJECTION_MATRIX * vec4(n, 0.0)).xy;
	float len = length(dir);
	if (len > 0.0001) {
		dir /= len;
		clip.xy += dir * w * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = ink.rgb;
}
