// The world's see-through material: crystal, fog, ice, a sight overlay.
shader_type spatial;
render_mode diffuse_toon, specular_disabled, depth_draw_opaque, cull_disabled;

#include "res://world/toon_light.gdshaderinc"

uniform vec4 tint : source_color = vec4(1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	ALBEDO = saturated(COLOR.rgb * tint.rgb);
	ALPHA = opacity * COLOR.a;
}
