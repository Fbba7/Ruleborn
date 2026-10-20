// Soft shade on the ground under what stands on it — a building, a tree, the
// citadel — so each sits on its island rather than floating over it: a
// disc darkest at its middle, tinted violet, as §21.3 tints every shadow.
// The vertex colour's alpha is how dark; UV.y runs from the middle (0) out.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_mix;

uniform vec4 shade : source_color = vec4(0.16, 0.08, 0.3, 1.0);

void fragment() {
	float fade = 1.0 - clamp(UV.y, 0.0, 1.0);
	ALBEDO = shade.rgb;
	ALPHA = COLOR.a * smoothstep(0.0, 0.6, fade);
}
