// Puffy clouds at the island's level and below (the diorama's `cloud`,
// realm-diorama.js:940): white on top, a cool violet underneath where the
// sky lights them (§21.1: "cool shadows beneath"): two soft tones taken
// from the sky rather than the ramp's four, so they read as weather, not as
// rock, in every realm's light. They
// wander slowly on the wind.
shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform vec4 top : source_color = vec4(1.0);
uniform vec4 under : source_color = vec4(0.72, 0.68, 0.92, 1.0);
uniform float drift = 0.6;

varying float up;

void vertex() {
	vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	VERTEX.x += sin(TIME * 0.07 + o.z * 0.3 + float(INSTANCE_ID)) * drift;
	up = (MODEL_MATRIX * vec4(NORMAL, 0.0)).y;
}

void fragment() {
	ALBEDO = mix(under.rgb, top.rgb * COLOR.rgb, smoothstep(-0.35, 0.45, up));
}

