// The winds round the Heart (§5.4: "The Heart is ringed by strong winds, so
// skiffs can't land there"), drawn as the design's faint dome (realm_diorama.js
// :1141): a shell that shows only at its edge, where the eye looks along it,
// and streaks of wind running round it.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 colour : source_color = vec4(0.97, 0.65, 0.85, 1.0);
uniform float strength = 0.5;

varying vec3 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	float edge = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	edge = pow(edge, 3.0);
	float a = atan(local.z, local.x);
	float wind = 0.6 + 0.4 * smoothstep(0.7, 1.0, sin(a * 6.0 + local.y * 2.0 - TIME * 1.4));
	// Fades out toward the ground, so the shell rises from the meadow.
	float rise = smoothstep(0.0, 0.25, local.y / max(length(local), 0.001));
	ALBEDO = colour.rgb * edge * wind * rise * strength;
	ALPHA = 1.0;
}
