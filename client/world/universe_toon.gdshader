// The universe map's solids: the world's one toon look (toon_light), with the
// vertex colour read as the sRGB it is written in, as the design's three.js
// reads its hex colours (ColorManagement), so the night islands keep their
// depth instead of washing out. A vertex whose alpha is under 1 glows in its
// own colour (lanterns, windows, crystals).
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"

uniform float glow_strength = 1.6;

vec3 linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

void fragment() {
	vec3 albedo = linear(COLOR.rgb);
	ALBEDO = saturated(albedo);
	EMISSION = albedo * (1.0 - COLOR.a) * glow_strength;
}
