// A law's see-through pieces: Glass's clear walls with coloured edges, the
// faint silhouettes of Echoes and Afterimage, Soul swap's wisps. Brightest at
// the rim, so a clear shape still reads as a shape (§21.1: silhouette first).
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled, fog_disabled;

#include "res://world/law_fx_motion.gdshaderinc"

uniform vec4 edge : source_color = vec4(0.55, 0.42, 0.94, 1.0);
uniform float fill = 0.12;
uniform float rim = 0.85;

void vertex() {
	VERTEX = law_motion(VERTEX, CUSTOM0);
}

void fragment() {
	float f = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0);
	float sweep = smoothstep(0.1, 0.0, abs(fract(dot(NORMAL, vec3(0.4, 0.8, 0.2)) * 1.5 - t * pace * 0.2) - 0.5));
	ALBEDO = mix(COLOR.rgb, edge.rgb, f) + vec3(sweep * 0.3);
	ALPHA = clamp((fill + f * rim + sweep * 0.15) * COLOR.a * strength, 0.0, 1.0);
}
