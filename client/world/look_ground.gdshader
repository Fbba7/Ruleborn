// The island's painted ground and rock: the vertex colour (the meadow's
// noise fields, the rim's bands) times a grey hand-painted texture
// (LookPaint), lit by the one toon ramp (§21.3). The meadow takes its
// texture from where it lies (from above, or from the side a wall faces), so
// the island and the grid's flagstones share one painted ground; the rock
// takes it from its own UV, round the cone. Scatter and vines sway in the
// wind by `sway`, more the further from their root.
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

#include "res://world/toon_light.gdshaderinc"

uniform sampler2D paint : source_color, filter_linear_mipmap, repeat_enable;
uniform float paint_strength = 1.0;
// Metres a texture tile spans on the ground; 0 reads the mesh's UV instead.
uniform float world_scale = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
// The realm's own marks over the meadow (LookPaint.deco), `deco_scale`
// metres a tile, 0 for none; `deco_glow` makes them light, not paint.
uniform sampler2D deco : source_color, filter_linear_mipmap, repeat_enable;
uniform float deco_scale = 0.0;
uniform float deco_glow = 0.0;
uniform float sway = 0.0;
// Sway by the distance along a vine (its UV.y) rather than by height.
uniform bool sway_by_uv = false;
// Metres a piece wanders on the wind (clouds).
uniform float drift = 0.0;
// Metres a piece rises over one cycle of `rise_period` seconds, then starts
// again from the ground, shrinking away at the top (sparks, motes).
uniform float rise = 0.0;
uniform float rise_period = 6.0;
uniform float glow_from_alpha = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	if (sway > 0.0) {
		vec3 root = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		float phase = root.x * 1.7 + root.z * 1.3 + float(INSTANCE_ID) * 0.37 + (sway_by_uv ? (VERTEX.x + VERTEX.z) * 0.8 : 0.0);
		float reach = sway_by_uv ? UV.y * 0.25 : abs(VERTEX.y);
		VERTEX.x += sin(TIME * 1.1 + phase) * sway * reach;
		VERTEX.z += cos(TIME * 0.9 + phase * 1.3) * sway * reach * 0.7;
	}
	if (drift > 0.0) {
		vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		VERTEX.x += sin(TIME * 0.07 + o.z * 0.3 + float(INSTANCE_ID)) * drift;
	}
	if (rise > 0.0) {
		float scale = max(length(MODEL_MATRIX[0].xyz), 0.0001);
		float f = fract(TIME / rise_period + float(INSTANCE_ID) * 0.618);
		VERTEX *= 1.0 - smoothstep(0.7, 1.0, f) - (1.0 - smoothstep(0.0, 0.08, f));
		VERTEX.y += f * rise / scale;
		VERTEX.x += sin(f * 9.0 + float(INSTANCE_ID)) * 0.3 / scale;
	}
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = UV;
	if (world_scale > 0.0) {
		// Laid from above, or from the side a wall faces, so a wall is not streaked.
		vec3 a = abs(world_normal);
		uv = (a.y > 0.6 ? world_pos.xz : (a.x > a.z ? world_pos.zy : world_pos.xy)) / world_scale;
	}
	float p = texture(paint, uv).r;
	// The grey texture averages about 0.8: lift it so the vertex colour reads true.
	float m = mix(1.0, p * 1.25, paint_strength);
	vec3 albedo = COLOR.rgb * tint.rgb * m;
	vec3 lit = vec3(0.0);
	if (deco_scale > 0.0 && world_normal.y > 0.6) {
		vec4 d = texture(deco, world_pos.xz / deco_scale);
		albedo = mix(albedo, d.rgb, d.a * (1.0 - deco_glow));
		lit = d.rgb * d.a * deco_glow;
	}
	ALBEDO = saturated(albedo);
	EMISSION = COLOR.rgb * (1.0 - COLOR.a) * glow_from_alpha + lit;
}
