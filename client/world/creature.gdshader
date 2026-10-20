// A character's one material (§21.3: "Characters are not drawn in a
// physically based material"): the sculpt's own paint, baked into the atlas
// with its occlusion, lit by the world's four-step ramp with violet shade, and
// the design kit's side rim and warm wrap (creature-kit.js `rimize`). Plain
// accessories carry their colour in the vertex colour and sample the atlas's
// white cell. UV2.x at or over 0.5 marks the body (its fur mask above that);
// under 0.5 it is an accessory's gloss. UV2.y is an accessory's glow.
//
// Forms (§21.6, 11.10) are uniforms on the same material: Hush remaps the paint
// by luminance into midnight, Spark lights it from within, and the Echo twin
// uses creature_glass.gdshader.
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/creature_look.gdshaderinc"

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
// The sculpt's own normals at full detail, baked into the body's charts.
uniform sampler2D normals : hint_normal, filter_linear_mipmap, repeat_disable;
uniform float relief : hint_range(0.0, 1.0) = 1.0;
uniform float binormal_sign = -1.0;

varying vec2 flags;
varying vec3 local_pos;

void vertex() {
	flags = UV2;
	local_pos = VERTEX;
}

void fragment() {
	vec3 c = texture(atlas, UV).rgb * COLOR.rgb;
	bool body = flags.x >= 0.5;
	if (body && relief > 0.0) {
		vec2 nxy = texture(normals, UV).xy * 2.0 - 1.0;
		vec3 nt = vec3(nxy, sqrt(max(0.0, 1.0 - dot(nxy, nxy))));
		vec3 n = normalize(TANGENT * nt.x + BINORMAL * nt.y * binormal_sign + NORMAL * nt.z);
		NORMAL = normalize(mix(NORMAL, n, relief));
	}
	float gloss = body ? body_gloss : flags.x / 0.45;
	float emit = body ? 0.0 : flags.y;
	creature_surface(c, body, gloss, emit, UV, local_pos, NORMAL, VIEW, creature_far(PROJECTION_MATRIX, VERTEX, VIEWPORT_SIZE), ALBEDO, EMISSION);
	gloss_band = gloss;
}
