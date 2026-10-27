// §21.3's ink outline on a character: "1.5-pixel ink outlines (#1A0C14) drawn
// in screen space". An inverted hull pushed out along the skinned normal in
// clip space, drawn as the body material's next pass. The design's handoff
// says the owner had the character outline removed; §21.3 asks for it, so it
// is on by default and CreatureModel.OUTLINE turns it off in one place.
shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled, depth_draw_opaque;

uniform vec4 ink : source_color = vec4(0.102, 0.047, 0.078, 1.0);
uniform float width_px = 1.5;
// Small on screen (under `far_ppm` pixels per metre) the line thickens toward
// `far_width`, so a 40 px character keeps its dark silhouette on the grass.
uniform float far_ppm = 240.0;
uniform float far_width = 1.8;
// The hull sits this far (metres) behind the body, so it shows only at the
// silhouette: the relief's bumps (fleece, scales, feathers) do not poke ink
// through the paint as speckles, and the inside of the shape stays clean.
uniform float depth_push = 0.05;
// A faceted body (the Glass Golem's crystal, the Mossbear's stone) has a
// normal per face, which pushes the hull apart into loose flakes: there the
// push leans toward the body's own outward direction (from its vertical
// axis), so the ink stays one closed line.
uniform float smooth_push = 0.0;

void vertex() {
	// Accessories (UV2.x under 0.5) take a finer line than the body, so eyes and
	// straps are not ringed in ink.
	float w = UV2.x >= 0.5 ? width_px : width_px * 0.3;
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.z -= depth_push;
	vec4 clip = PROJECTION_MATRIX * view;
	float depth = mix(max(0.05, clip.w), 1.0, PROJECTION_MATRIX[3][3]);
	float ppm = VIEWPORT_SIZE.y * PROJECTION_MATRIX[1][1] * 0.5 / depth;
	// Widths are for a phone's screen at 540 × 1170; the game draws at twice
	// that (project.godot's 1080 × 2340) and the line keeps its thickness.
	float dpi = clamp(min(VIEWPORT_SIZE.x / 540.0, VIEWPORT_SIZE.y / 1170.0), 1.0, 3.0);
	w *= dpi * mix(1.0, far_width, smoothstep(far_ppm * dpi, far_ppm * dpi * 0.4, ppm));
	vec3 out_dir = vec3(VERTEX.x, 0.0, VERTEX.z);
	vec3 push = length(out_dir) > 0.0001 ? normalize(mix(NORMAL, normalize(out_dir), smooth_push)) : NORMAL;
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(push, 0.0)).xyz);
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
