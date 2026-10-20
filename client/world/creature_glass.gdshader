// A character's glass, crystal and glow parts (the design's transmission and
// additive materials), and the Echo form's twin: the vertex colour's alpha is
// its opacity, lit by the same ramp, with a strong rim so glass reads as glass.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_disabled;

#include "res://world/creature_look.gdshaderinc"

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
// The Echo twin: everything one translucent colour.
uniform float echo = 0.0;
uniform vec4 echo_colour : source_color = vec4(0.93, 0.36, 0.86, 0.38);

varying vec2 flags;

void vertex() {
	flags = UV2;
}

void fragment() {
	vec3 c = texture(atlas, UV).rgb * COLOR.rgb;
	bool body = flags.x >= 0.5;
	float emit = body ? 0.0 : flags.y;
	creature_surface(c, body, 0.0, emit, UV, NORMAL, VIEW, ALBEDO, EMISSION);
	gloss_band = body ? 0.0 : flags.x / 0.45;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALPHA = clamp(COLOR.a + fr * 0.35, 0.0, 1.0);
	if (echo > 0.0) {
		ALBEDO = mix(ALBEDO, echo_colour.rgb, echo * 0.85);
		EMISSION = mix(EMISSION, echo_colour.rgb * (0.4 + fr), echo);
		ALPHA = mix(ALPHA, echo_colour.a * (0.55 + fr), echo);
	}
}
