// A character's glass, crystal and glow parts (the design's transmission and
// additive materials), and the Echo form's twin: the vertex colour's alpha is
// its opacity, lit by the same ramp, with a strong rim so glass reads as glass.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_disabled;

#include "res://world/creature_look.gdshaderinc"

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
// An Echo ghost (CreatureModel.ECHO_GHOSTS): its strength, 0 off.
uniform float echo = 0.0;
// A glowing veil (the design's translucent outer flame over a hotter core,
// drawn with bloom) is thinner face-on, so the core inside shows through.
uniform float veil_see = 0.6;

varying vec2 flags;
varying vec3 local_pos;

void vertex() {
	flags = UV2;
	local_pos = VERTEX;
}

void fragment() {
	vec3 c = texture(atlas, UV).rgb * COLOR.rgb;
	bool body = flags.x >= 0.5;
	float emit = body ? 0.0 : flags.y;
	relief_n = NORMAL;
	far_mix = creature_far(PROJECTION_MATRIX, VERTEX, VIEWPORT_SIZE);
	n_up = dot(NORMAL, normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz));
	creature_surface(c, body, 0.0, emit, UV, local_pos, NORMAL, VIEW, far_mix, ALBEDO, EMISSION);
	gloss_band = body ? 0.0 : flags.x / 0.45;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALPHA = clamp(COLOR.a + fr * 0.35, 0.0, 1.0);
	ALPHA *= 1.0 - veil_see * step(0.01, emit) * step(COLOR.a, 0.99) * smoothstep(0.2, 0.85, dot(NORMAL, VIEW));
	if (echo > 0.0) {
		// An Echo ghost: the note's colour, faint inside and bright at the
		// silhouette, so it reads as an outline a step behind.
		float edge = smoothstep(0.1, 0.7, pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.5));
		ALBEDO = echo_colour_note.rgb * 0.6;
		EMISSION = mix(echo_colour_note.rgb, vec3(0.85, 1.0, 1.0), edge * 0.4) * (0.25 + edge * 1.3);
		ALPHA = echo * (0.07 + 0.8 * edge);
	}
}
