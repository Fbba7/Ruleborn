// Birds wheeling round the island (the diorama's `birds`, realm-diorama.js:571):
// dark Vs, silhouette first (§21.1), each flapping and circling the island
// on its own beat. Butterflies use it too, in their own colours. One MultiMesh; the wings beat and the flock turns in the
// vertex shader, so nothing is moved from script.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, skip_vertex_transform;

uniform vec4 ink : source_color = vec4(0.16, 0.1, 0.24, 1.0);
uniform float turn = 0.12;
// Butterflies: their own colours (the instance's), a quicker beat, and a
// wander over the meadow rather than a wide wheel.
uniform bool coloured = false;
uniform float beat = 7.0;
uniform float wander = 0.0;

void vertex() {
	float id = float(INSTANCE_ID);
	vec3 v = VERTEX;
	v.y += abs(v.x) * sin(TIME * beat + id * 1.7) * 0.9;
	vec3 w = (MODEL_MATRIX * vec4(v, 1.0)).xyz;
	float a = TIME * turn * (0.8 + 0.4 * fract(id * 0.618));
	w.xz = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * w.xz;
	w.y += sin(TIME * 0.6 + id) * 0.2;
	w.x += sin(TIME * 0.7 + id * 2.1) * wander;
	w.z += cos(TIME * 0.5 + id * 1.3) * wander;
	w.y += abs(sin(TIME * 1.9 + id)) * wander * 0.3;
	VERTEX = (VIEW_MATRIX * vec4(w, 1.0)).xyz;
}

void fragment() {
	ALBEDO = coloured ? COLOR.rgb : ink.rgb;
}
