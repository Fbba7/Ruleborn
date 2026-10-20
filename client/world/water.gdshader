// Water and lava: the toon ramp, with bands that drift with time — hand
// painted, never a photographic texture (§21.3).
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"

uniform vec4 deep : source_color = vec4(0.35, 0.72, 0.86, 1.0);
uniform vec4 foam : source_color = vec4(0.86, 0.97, 1.0, 1.0);
uniform float speed = 0.35;
uniform float glowing = 0.0;

void fragment() {
	vec2 p = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float band = sin(p.x * 3.1 + p.y * 1.7 + TIME * speed * 6.0) + sin(p.y * 4.3 - TIME * speed * 4.0) * 0.6;
	float f = step(1.15, band);
	ALBEDO = saturated(mix(deep.rgb, foam.rgb, f));
	EMISSION = ALBEDO * glowing;
}
