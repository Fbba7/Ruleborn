// One fur shell over a character's body (creature-kit.js furShellMat): the
// body pushed out along its normal by `layer` of the fur length, cut by a hash
// of the atlas position (stable as the body moves) so strands thin toward the tips, only where the paint's
// fur mask (UV2.x over 0.5) allows. Each shell is one more draw of the body,
// so the phone keeps the count low (CreatureModel.fur_shells).
shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_back;

#include "res://world/creature_look.gdshaderinc"

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform float layer = 0.5;
uniform float fur_len = 0.0045;
// Strand cells across the atlas: the module's density per sculpt unit times
// the atlas's texels per unit, so a strand is a column through every shell.
uniform float strand_cells = 1500.0;

varying vec2 flags;

float fur_hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void vertex() {
	flags = UV2;
	float mask = UV2.x >= 0.5 ? (UV2.x - 0.5) * 2.0 : 0.0;
	VERTEX += NORMAL * layer * fur_len * step(0.02, mask);
}

void fragment() {
	float mask = flags.x >= 0.5 ? (flags.x - 0.5) * 2.0 : 0.0;
	if (mask < 0.02 || layer > mask + 0.001) {
		discard;
	}
	float h = fur_hash(vec3(floor(UV * strand_cells), 3.0));
	if (h < layer * 1.05) {
		discard;
	}
	vec3 c = texture(atlas, UV).rgb * mix(0.85, 1.15, layer);
	creature_surface(c, true, 0.0, 0.0, UV, NORMAL, VIEW, creature_far(PROJECTION_MATRIX, VERTEX, VIEWPORT_SIZE), ALBEDO, EMISSION);
	gloss_band = 0.0;
}
