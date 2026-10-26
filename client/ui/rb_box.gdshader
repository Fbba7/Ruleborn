// The kit's one box (design-system.md section 10.3): a rounded rectangle as a
// signed distance, filled with a gradient (linear at an angle, radial or
// conic, from a 1D texture so any number of stops), outlined in ink, with up
// to two inner rims, a lit band inside the top edge and a dark one inside the
// bottom, a hard drop under it, a soft shadow and a glow, all in the one quad
// RbBox draws. Every value is a token (ui/tokens.json `material`); this file
// only draws them.
shader_type canvas_item;

// The quad is the box grown by `reach` on every side, so the drop, shadow
// and glow are never clipped.
uniform vec2 box_size = vec2(100.0, 50.0);
uniform float reach = 0.0;
uniform float radius = 16.0;
// How far the body has sunk onto its drop (a press), in pixels.
uniform float body_y = 0.0;

uniform sampler2D fill_tex : filter_linear, repeat_disable;
// 0 linear at `fill_angle` (CSS degrees: 180 is top to bottom), 1 radial
// about fill_geo.xy (fractions of the box) with radii fill_geo.zw (0 for the
// farthest corner), 2 conic from `fill_angle`.
uniform int fill_mode = 0;
uniform float fill_angle = 180.0;
uniform vec4 fill_geo = vec4(0.5, 0.5, 0.0, 0.0);

uniform vec4 line_color : source_color = vec4(0.0);
uniform float line_w = 0.0;
uniform vec4 rim_color : source_color = vec4(0.0);
uniform float rim_w = 0.0;
uniform vec4 rim2_color : source_color = vec4(0.0);
uniform float rim2_w = 0.0;
uniform vec4 hi_color : source_color = vec4(0.0);
uniform float hi_w = 0.0;
uniform vec4 shade_color : source_color = vec4(0.0);
uniform float shade_w = 0.0;
uniform vec4 drop_color : source_color = vec4(0.0);
uniform float drop_y = 0.0;
uniform vec4 soft_color : source_color = vec4(0.0);
uniform float soft_y = 0.0;
uniform float soft_blur = 1.0;
uniform vec4 glow_color : source_color = vec4(0.0);
uniform float glow_r = 1.0;
uniform vec4 grain_color : source_color = vec4(0.0);
// A soft white gloss over the top half, inset from the edges (a toy's
// lacquer), at this strength.
uniform float gloss = 0.0;
// Seeded star dots over the fill (the night backdrop), per 10,000 px².
uniform float stars = 0.0;
uniform vec4 star_color : source_color = vec4(1.0, 0.96, 0.86, 0.7);
// A sunburst over the fill (a result, a level-up): `rays_count` soft rays
// from fill_geo.xy, fading out from the centre. Still, never spinning.
uniform vec4 rays_color : source_color = vec4(0.0);
uniform float rays_count = 18.0;
// Diagonal hatching over the fill (a locked reward), in this colour.
uniform vec4 stripes_color : source_color = vec4(0.0);

float sd_box(vec2 p, vec2 b, float r) {
	r = min(r, min(b.x, b.y));
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float cover(float sd, float px) {
	return clamp(0.5 - sd / px, 0.0, 1.0);
}

vec4 over(vec4 below, vec3 rgb, float a) {
	return vec4(rgb * a + below.rgb * (1.0 - a), a + below.a * (1.0 - a));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 quad = box_size + 2.0 * reach;
	vec2 p = UV * quad - quad * 0.5;
	float px = max(length(fwidth(p)) * 0.7071, 0.0001);
	vec2 b = box_size * 0.5;
	vec4 col = vec4(0.0);

	float sd_still = sd_box(p, b, radius);
	if (glow_color.a > 0.0) {
		float g = clamp(1.0 - max(sd_still, 0.0) / glow_r, 0.0, 1.0);
		col = over(col, glow_color.rgb, glow_color.a * g * g * (1.0 - cover(sd_still, px)));
	}
	if (soft_color.a > 0.0) {
		float s = sd_box(p - vec2(0.0, soft_y), b, radius);
		col = over(col, soft_color.rgb, soft_color.a * (1.0 - smoothstep(-soft_blur * 0.5, soft_blur, s)));
	}
	if (drop_color.a > 0.0 && drop_y > body_y) {
		float d = sd_box(p - vec2(0.0, drop_y), b, radius);
		col = over(col, drop_color.rgb, drop_color.a * cover(d, px));
	}

	vec2 pb = p - vec2(0.0, body_y);
	float sd = sd_box(pb, b, radius);
	if (sd < px) {
		// The fill, by where this pixel lies in the box.
		float t;
		if (fill_mode == 1) {
			vec2 c = (fill_geo.xy - 0.5) * box_size;
			vec2 rr = fill_geo.zw * box_size;
			if (rr.x <= 0.0) {
				vec2 far = b + abs(c);
				rr = vec2(length(far));
			}
			t = length((pb - c) / rr);
		} else if (fill_mode == 2) {
			float a = atan(pb.x, -pb.y) - radians(fill_angle);
			t = fract(a / 6.2831853);
		} else {
			float a = radians(fill_angle);
			vec2 dir = vec2(sin(a), -cos(a));
			float span = abs(box_size.x * dir.x) + abs(box_size.y * dir.y);
			t = dot(pb, dir) / span + 0.5;
		}
		vec4 fill = texture(fill_tex, vec2(clamp(t, 0.0, 1.0), 0.5));
		if (grain_color.a > 0.0) {
			// Wood grain: fine wavering streaks along the board.
			float w = pb.y * 0.32 + sin(pb.x * 0.018) * 3.0 + sin(pb.x * 0.061 + pb.y * 0.013) * 1.3;
			float g = 0.5 + 0.5 * sin(w);
			fill.rgb = mix(fill.rgb, grain_color.rgb, grain_color.a * smoothstep(0.72, 1.0, g));
		}
		if (stripes_color.a > 0.0) {
			float band = fract((pb.x + pb.y) / 26.0);
			fill.rgb = mix(fill.rgb, stripes_color.rgb, stripes_color.a * smoothstep(0.45, 0.5, band) *
				(1.0 - smoothstep(0.95, 1.0, band)));
		}
		if (rays_color.a > 0.0) {
			vec2 o = pb - (vec2(0.5, 0.16) - 0.5) * box_size;
			float ang = atan(o.x, -o.y);
			float wave = 0.5 + 0.5 * cos(ang * rays_count);
			float fade = 1.0 - smoothstep(0.0, max(box_size.x, box_size.y) * 0.6, length(o));
			fill.rgb = mix(fill.rgb, rays_color.rgb, rays_color.a * smoothstep(0.55, 0.95, wave) * fade);
			// The lit halo the rays come from.
			float halo = 1.0 - smoothstep(0.0, max(box_size.x, box_size.y) * 0.3, length(o));
			fill.rgb = mix(fill.rgb, vec3(0.42, 0.34, 0.78), 0.45 * halo * halo);
		}
		if (stars > 0.0) {
			vec2 cell = floor(pb / 34.0);
			float h = hash(cell);
			if (h < stars * 0.06) {
				vec2 at = (cell + vec2(hash(cell + 7.1), hash(cell + 3.7))) * 34.0;
				float size = 0.8 + 1.6 * hash(cell + 1.3);
				float s = 1.0 - smoothstep(size - px, size + px, length(pb - at));
				fill.rgb = mix(fill.rgb, star_color.rgb, star_color.a * s * (0.4 + 0.6 * hash(cell + 9.9)));
			}
		}
		// The inner box, inside the outline.
		vec2 bi = b - line_w;
		float ri = max(radius - line_w, 0.0);
		float sdi = sd_box(pb, bi, ri);
		float inside = cover(sdi, px);
		if (gloss > 0.0) {
			// Over the top half, but no deeper than one line of words, so a
			// button whose words wrap is not cut across the middle.
			float uvy = (pb.y + b.y) / (2.0 * min(box_size.y * 0.5, 66.0));
			float lacquer = cover(sd_box(pb, bi - vec2(3.0 + line_w), max(ri - 3.0, 0.0)), px);
			// A crisp lower edge at half height, brighter towards the top.
			float band = (1.0 - smoothstep(0.42, 0.5, uvy)) * (0.45 + 0.55 * (1.0 - uvy * 2.0));
			fill.rgb = mix(fill.rgb, vec3(1.0), gloss * lacquer * band);
		}
		if (hi_w > 0.0) {
			float below = cover(sd_box(pb - vec2(0.0, hi_w), bi, ri), px);
			fill.rgb = mix(fill.rgb, hi_color.rgb, hi_color.a * inside * (1.0 - below));
		}
		if (shade_w > 0.0) {
			float above = cover(sd_box(pb + vec2(0.0, shade_w), bi, ri), px);
			fill.rgb = mix(fill.rgb, shade_color.rgb, shade_color.a * inside * (1.0 - above));
		}
		if (rim_w > 0.0) {
			float band = inside * (1.0 - cover(sdi + rim_w, px));
			fill = mix(fill, vec4(rim_color.rgb, 1.0), rim_color.a * band);
		}
		if (rim2_w > 0.0) {
			float band = cover(sdi + rim_w, px) * (1.0 - cover(sdi + rim_w + rim2_w, px));
			fill = mix(fill, vec4(rim2_color.rgb, 1.0), rim2_color.a * band);
		}
		if (line_w > 0.0) {
			fill = mix(vec4(line_color.rgb, line_color.a), fill, inside);
		}
		col = over(col, fill.rgb, fill.a * cover(sd, px));
	}
	COLOR = vec4(col.a > 0.0 ? col.rgb / col.a : vec3(0.0), col.a) * COLOR;
}
