// The kit's see-through material: toon_clear.gdshader's (crystal, fog, ice,
// spray), with the kit's idle motion so fog drifts and crystals turn.
shader_type spatial;
render_mode diffuse_toon, specular_disabled, depth_draw_opaque, cull_disabled;

#include "res://world/toon_light.gdshaderinc"
#include "res://world/kit_anim.gdshaderinc"

uniform vec4 tint : source_color = vec4(1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.55;

void vertex() {
	kit_move(VERTEX, NORMAL, CUSTOM0, TIME);
}

void fragment() {
	ALBEDO = saturated(COLOR.rgb * tint.rgb);
	// A colour's alpha under 1 glows a little and shows through more.
	EMISSION = COLOR.rgb * (1.0 - COLOR.a) * 0.6;
	ALPHA = opacity * mix(1.0, 0.7, 1.0 - COLOR.a);
}
