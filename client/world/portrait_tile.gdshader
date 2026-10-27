// A portrait tile in one draw (StageHeroSkin.portrait_tile): the school's
// glow behind the portrait, the portrait over it, the corners rounded and
// an ink outline round them. One quad, no clipping group, so a grid of
// tiles stays inside §21.3's draw calls.
shader_type canvas_item;

uniform vec4 glow_in : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform vec4 glow_out : source_color = vec4(0.5, 0.3, 0.1, 1.0);
uniform vec4 line_color : source_color = vec4(0.102, 0.047, 0.078, 1.0);
// The tile's size and its corner and outline, in pixels.
uniform vec2 px_size = vec2(300.0, 300.0);
uniform float radius = 36.0;
uniform float line_w = 3.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec2 half_size = px_size * 0.5;
	vec2 q = abs(local - half_size) - half_size + vec2(radius);
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	vec2 g = (local - px_size * vec2(0.5, 0.42)) / max(px_size.x, 1.0);
	vec4 ground = mix(glow_in, glow_out, clamp(length(g) / 0.6, 0.0, 1.0));
	vec4 pic = texture(TEXTURE, UV);
	vec3 col = mix(ground.rgb, pic.rgb, pic.a);
	col = mix(col, line_color.rgb, clamp(d + line_w + 0.5, 0.0, 1.0));
	COLOR = vec4(col, clamp(0.5 - d, 0.0, 1.0));
}
