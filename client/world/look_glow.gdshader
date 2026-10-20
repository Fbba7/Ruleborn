// Soft pools of light lying on the ground (the diorama's additive glow
// sprites, realm-diorama.js:893 and :1051): Lantern Vale's glowing ground,
// Emberreach's heat. A round falloff in the instance's colour, added to what
// is beneath; no depth written, no shadow.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float strength = 0.6;

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float d = dot(q, q);
	float a = (1.0 - smoothstep(0.0, 1.0, d)) * strength;
	ALBEDO = COLOR.rgb * a;
}
