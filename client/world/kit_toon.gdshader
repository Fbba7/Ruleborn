// The kit's opaque material: toon.gdshader's look (the shared ramp, rim and
// violet shade of toon_light.gdshaderinc) with the kit's idle motion, and a
// slow breath on whatever glows (lanterns, crystals, windows).
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"
#include "res://world/kit_anim.gdshaderinc"

uniform vec4 tint : source_color = vec4(1.0);
uniform float glow_from_alpha = 1.0;
// 0 by day, 1 at night (RealmKit.by_hour): glows shine brighter after dark.
uniform float night = 0.0;

varying float breath;
varying float contact;

void vertex() {
	// A contact shade at a piece's foot: still pieces carry their foot's
	// height in CUSTOM0.y, swaying ones their pivot, which is their foot.
	int kind = int(CUSTOM0.w + 0.5);
	contact = (kind == 0 || kind == 1 || kind == 8) ? smoothstep(0.0, 0.32, VERTEX.y - CUSTOM0.y) : 1.0;
	kit_move(VERTEX, NORMAL, CUSTOM0, TIME);
	breath = 0.82 + 0.18 * sin(TIME * 2.2 + VERTEX.x * 0.9 + VERTEX.z * 1.3);
}

void fragment() {
	ALBEDO = saturated(COLOR.rgb * tint.rgb) * mix(0.74, 1.0, contact);
	EMISSION = COLOR.rgb * (1.0 - COLOR.a) * glow_from_alpha * breath * (1.0 + 1.6 * night);
}
