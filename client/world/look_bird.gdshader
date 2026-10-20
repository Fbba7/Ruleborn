// Birds wheeling round the island (the diorama's `birds`, realm-diorama.js:571):
// dark Vs, silhouette first (§21.1), each flapping and circling the island
// on its own beat. One MultiMesh; the wings beat and the flock turns in the
// vertex shader, so nothing is moved from script.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, skip_vertex_transform;

uniform vec4 ink : source_color = vec4(0.16, 0.1, 0.24, 1.0);
uniform float turn = 0.12;

void vertex() {
	float id = float(INSTANCE_ID);
	vec3 v = VERTEX;
	v.y += abs(v.x) * sin(TIME * 7.0 + id * 1.7) * 0.9;
	vec3 w = (MODEL_MATRIX * vec4(v, 1.0)).xyz;
	float a = TIME * turn * (0.8 + 0.4 * fract(id * 0.618));
	w.xz = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * w.xz;
	w.y += sin(TIME * 0.6 + id) * 0.2;
	VERTEX = (VIEW_MATRIX * vec4(w, 1.0)).xyz;
}

void fragment() {
	ALBEDO = ink.rgb;
}
