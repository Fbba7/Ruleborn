// A law's solid pieces (hovering pebbles, regrowing hedges, crowns,
// crystals) in §21.3's one toon look, moved in the vertex stage by
// law_fx_motion. A vertex colour's alpha under 1 glows in its own colour, as
// in toon.gdshader.
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"
#include "res://world/law_fx_motion.gdshaderinc"

uniform float glow = 1.0;
// A pulse in the glow: Overcharge's threes, a crown's beat.
uniform float pulse = 0.0;

void vertex() {
	VERTEX = law_motion(VERTEX, CUSTOM0);
}

void fragment() {
	ALBEDO = saturated(COLOR.rgb);
	float beat = 1.0 + pulse * (0.5 + 0.5 * sin(t * pace * 3.0));
	EMISSION = COLOR.rgb * (1.0 - COLOR.a) * glow * beat;
}
