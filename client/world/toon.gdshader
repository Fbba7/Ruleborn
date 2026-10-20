// The world's opaque material: albedo from the vertex colour, which carries
// each piece's paint, times `tint`; `glow` lights a piece from within.
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"

uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 glow : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float glow_from_alpha = 0.0;

void fragment() {
	ALBEDO = saturated(COLOR.rgb * tint.rgb);
	// A vertex whose alpha is under 1 glows in its own colour (lanterns, lava).
	EMISSION = glow.rgb + COLOR.rgb * (1.0 - COLOR.a) * glow_from_alpha;
}
