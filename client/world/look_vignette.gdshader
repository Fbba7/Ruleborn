// §21.3's screen-space tint: the diorama's vignette (realm-diorama.js:116,
// "radial-gradient(ellipse 90% 70%, transparent 55%, rgba(8,5,26,.42)")
// darkening the frame's edges toward the realm's night, with a faint tint of
// the hour over the whole. One quad drawn over the world; no post-processing.
shader_type canvas_item;

uniform vec4 edge : source_color = vec4(0.031, 0.02, 0.102, 0.42);
uniform vec4 wash : source_color = vec4(1.0, 1.0, 1.0, 0.0);

void fragment() {
	vec2 q = (UV - 0.5) / vec2(0.9, 0.7);
	float d = length(q);
	float v = smoothstep(0.55, 1.0, d) * edge.a;
	vec3 c = mix(wash.rgb, edge.rgb, v / max(v + wash.a, 0.0001));
	COLOR = vec4(c, clamp(v + wash.a, 0.0, 1.0));
}
