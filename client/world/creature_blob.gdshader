// The soft shadow under a character (the diorama's `shMat`): a ground quad
// darkening toward violet at its centre; turned to the camera, a halo. Characters do not cast the sun's
// shadow on the phone (docs/analysis/screens-v3/3d-pipeline.md §5).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 shade : source_color = vec4(0.16, 0.10, 0.30, 0.42);
// The same soft disc turned to the camera is a lantern's halo.
uniform bool face_camera = false;

void vertex() {
	if (face_camera) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	ALBEDO = shade.rgb;
	ALPHA = shade.a * smoothstep(1.0, 0.25, r);
}
