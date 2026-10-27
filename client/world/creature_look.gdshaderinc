// The character look shared by creature.gdshader and its fur shells.
//
// §21.3's toon look with the numbers the world uses (toon_light.gdshaderinc):
// the diorama's ramp [62, 140, 215, 255] of 255, +10% saturation, shade tinted
// toward violet. The steps are softened by a hair so a band edge does not
// crawl on a moving body. On top, the design kit's `rimize` (creature-kit.js):
// a Fresnel rim masked to the upper right in view space, in the kind's rim
// colour, and a warm wrap at the edge.

// The world's violet shade, a step lighter on characters: on saturated warm
// paint the world's tint turns crimson, and a character must read in shade.
uniform vec4 shade_tint : source_color = vec4(0.68, 0.6, 0.9, 1.0);
uniform vec4 rim_colour : source_color = vec4(0.62, 0.83, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.38;
uniform float wrap : hint_range(0.0, 1.0) = 0.35;
// The design's sheen and tone curve make its sculpts pale and soft where lit
// (Featherkin's portrait is butter, not orange): the two top steps of the
// ramp lift the paint toward this warm white.
uniform vec4 sheen : source_color = vec4(1.0, 0.95, 0.84, 1.0);
uniform float lift : hint_range(0.0, 1.0) = 0.5;
// The design's portraits are its paint under image light, sheen and ACES
// (the *_Hero pages): butter where the paint is gold, mint where it is green,
// lilac where it is violet, while dark paint stays dark. `tone` carries the
// paint toward that colour before the ramp lights it: light paint whitens by
// its own value (fitted on Featherkin's and the Glass Golem's portraits).
uniform float tone : hint_range(0.0, 1.0) = 0.3;
uniform float tone_from = 0.2;
uniform float tone_to = 0.75;
// A kind's own correction toward its portrait (CreatureModel.LOOK), times the paint.
uniform vec3 paint_tint = vec3(1.0);
// The paint's values drawn closer to `paint_mid` (1 keeps them): the Golem's
// baked facets run from near black to lilac, its portrait's from violet to lilac.
uniform float paint_contrast : hint_range(0.0, 1.0) = 1.0;
uniform float paint_mid = 0.4;
// Saturated paint pales this much toward white (by its saturation): the
// portraits' sheen turns Bloomling's crimson petals pink, not the paler body.
uniform float pastel : hint_range(0.0, 1.0) = 0.0;
uniform vec4 pastel_colour : source_color = vec4(1.0);
uniform float pastel_by_value : hint_range(0.0, 1.0) = 1.0;
// The world's noon sun clips warm paint's red (Featherkin's gold went
// orange-pink): characters take it a little softer.
uniform float exposure : hint_range(0.5, 1.5) = 0.8;
// A character keeps its own colour under every realm's light (the Heart's
// pink noon turned Featherkin's butter to salmon): the sun's hue is taken
// this much toward its own grey on characters. The world keeps its light.
uniform float light_neutral : hint_range(0.0, 1.0) = 0.6;
// A character's eye adapting to a dim sun (light()): the noon sun's value in
// LIGHT_COLOR's units, how far toward it, and the most it may gain.
uniform float day_sun = 1.1;
uniform float night_eye : hint_range(0.0, 1.0) = 0.5;
uniform float night_gain = 1.7;
// The world's sun stands high (58°), which leaves a character's face, a
// vertical surface, in the lower steps. The steps keep §21.3's values; on a
// character they start earlier, so faces and fronts read in the light.
uniform float ramp_bias : hint_range(0.0, 0.5) = 0.22;
// The design's vcGlow: the body's warm paint glows (embers, lanterns).
uniform float glow_vc = 0.0;
// The paint glows where its red runs this far over its blue: an ember's
// cracks (far over) glow, its tan belly (a little over) stays paint.
uniform float glow_from = 0.3;
uniform float glow_to = 0.65;
// The accessories' paint scaled where it is mid-valued (stone, wood), so a
// pale stone bracer reads as the design's while its iron bands stay dark.
uniform vec3 gear_tint = vec3(1.0);
// Red paint (red well over green: petals, flames) scaled toward the design's
// pinks, where the toon light reads a kind's pink as coral.
uniform vec3 red_tint = vec3(1.0);
// How far a glowing part's face burns toward warm white (the flames' core).
uniform float hot_core = 0.55;
// The sky a metal part reflects where it faces up (alpha: how much).
uniform vec4 metal_sky : source_color = vec4(0.8, 0.8, 0.88, 0.45);
// The body material's character, from the design's bodyMat: metal (Echoplate),
// clearcoat (the highlight band, set as gloss in the shader), iridescence
// (Prism Mite's rainbow edges) and a body glow (the Golem's inner light).
uniform float body_metal : hint_range(0.0, 1.0) = 0.0;
uniform float body_gloss : hint_range(0.0, 1.0) = 0.0;
uniform float body_iris : hint_range(0.0, 1.0) = 0.0;
uniform vec3 body_emit = vec3(0.0);
// Forms.
uniform float hush : hint_range(0.0, 1.0) = 0.0;
uniform float spark : hint_range(0.0, 1.0) = 0.0;
uniform vec4 spark_colour : source_color = vec4(1.0, 0.42, 0.1, 1.0);
uniform float echo_form : hint_range(0.0, 1.0) = 0.0;
// The notes' colours (8.1's wheel, as law_fx_links.gd draws them).
uniform vec4 hush_colour : source_color = vec4(0.353, 0.29, 0.604, 1.0);
uniform vec4 echo_colour_note : source_color = vec4(0.235, 0.776, 0.847, 1.0);
// The body's height in the mesh's own units (the export's), so a pattern
// laid by height fits every kind.
uniform float unit_height = 1.0;
// A flash of colour (hit, heal), mixed into the albedo.
uniform vec4 flash : source_color = vec4(1.0, 1.0, 1.0, 0.0);
// Readability at small size (§21.3: "every character ... must read as a dark
// shape at 32 points tall"): under this many pixels per metre on screen the
// rim strengthens toward `far_rim` and the shade opens a little, so a
// character the heist's camera draws 40 px tall keeps its edge and its colour.
uniform float far_ppm = 240.0;
uniform float far_rim = 1.8;

// Small on screen: the value step from the ground (the paint drawn this much
// lighter and its shade opened, so a character stands off painted grass in
// grayscale) and a light rim all round its silhouette inside the ink.
uniform float far_value = 0.18;
uniform vec4 far_rim_colour : source_color = vec4(1.0, 0.96, 0.86, 1.0);
// Small on screen the darkest light step rises to this, so a character is one
// clear shape of its own colour (a sticker on the grass), not a lit and a
// shaded half.
uniform float far_floor = 0.45;
// Small on screen the paint is read this many mip levels softer: its fine
// detail (scales, fleece, cracks) is noise at 40 px, its large shapes are not.
uniform float far_blur = 1.5;

varying float gloss_band;
varying float far_mix;
// The sculpt's relief normal (view space). The ramp's steps follow the smooth
// body, so the bands are the big clean shapes of a toy; the relief only
// shades within a step (`relief_detail`), as the design's fine feather, fleece
// and scale texture, instead of breaking the bands into crumpled foil.
varying vec3 relief_n;
uniform float relief_detail = 0.55;

vec3 creature_tone(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	return c + (1.0 - c) * tone * smoothstep(tone_from, tone_to, l);
}

vec3 creature_saturate(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	return clamp(mix(vec3(l), c, 1.1), 0.0, 1.0);
}

// How far toward "small on screen" this fragment is (0 near, 1 at the
// heist's 12 tiles across): from the projection and the view depth.
float creature_far(mat4 proj, vec3 view_pos, vec2 viewport) {
	float ortho = proj[3][3];
	float depth = mix(max(0.05, -view_pos.z), 1.0, ortho);
	float ppm = viewport.y * proj[1][1] * 0.5 / depth;
	// In a phone's 540 × 1170 pixels, whatever the drawing's resolution.
	ppm /= clamp(min(viewport.x / 540.0, viewport.y / 1170.0), 1.0, 3.0);
	return smoothstep(far_ppm, far_ppm * 0.4, ppm);
}

// The hero view (the Character screen, portraits: CreatureModel.set_hero):
// the design's hero pages light a sculpt with sheen, image light and a soft
// tone curve. In the toon look that is softer step edges, an image light
// (the paint lit by a cool sky above and a warm bounce below, by the
// normal's facing), and a sheen of the kind's own colour at grazing angles.
uniform float hero : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hero_sky : source_color = vec4(0.78, 0.8, 1.0, 1.0);
uniform vec4 hero_bounce : source_color = vec4(1.0, 0.82, 0.66, 1.0);
uniform float hero_image = 0.2;
uniform float hero_sheen = 0.4;
// The fragment's normal against the world's up (set in fragment()).
varying float n_up;

// How soft each of the ramp's step edges is, in N·L. Sharp steps on a light
// mesh draw its polygons (a band edge runs straight across each triangle);
// a softer edge keeps the four values and loses the facets.
uniform float ramp_soft = 0.07;
// A kind lit flatter than the ramp (CreatureModel.LOOK): the Glass Golem's
// portrait is glass lit through, its facets close in value, not four steps.
uniform float flatten : hint_range(0.0, 1.0) = 0.0;

float creature_ramp(float ndl) {
	float w = mix(ramp_soft, 0.16, hero);
	float r = 62.0 / 255.0;
	r += (140.0 - 62.0) / 255.0 * smoothstep(-w, w, ndl);
	r += (215.0 - 140.0) / 255.0 * smoothstep(0.33 - w, 0.33 + w, ndl);
	r += (255.0 - 215.0) / 255.0 * smoothstep(0.66 - w, 0.66 + w, ndl);
	return r;
}

float creature_hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Hush (§21.6: "a form that only differs by colour has failed"; the Rig page
// remaps by luminance): the paint becomes midnight by its own value, so the
// pattern survives, and a scatter of star freckles glows on the body.
vec3 creature_hush(vec3 c, vec2 uv, bool body, out vec3 stars) {
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	vec3 deep = vec3(0.03, 0.025, 0.10);
	vec3 mid = vec3(0.13, 0.10, 0.34);
	vec3 moon = vec3(0.24, 0.26, 0.6);
	vec3 r = l < 0.3 ? mix(deep, mid, l / 0.3) : mix(mid, moon, clamp((l - 0.3) / 0.7, 0.0, 1.0));
	stars = vec3(0.0);
	if (body) {
		vec2 cell = floor(uv * 96.0);
		float h = creature_hash(cell);
		vec2 f = fract(uv * 96.0) - 0.5;
		float s = step(0.93, h) * smoothstep(0.32, 0.0, length(f));
		stars = vec3(0.75, 0.85, 1.0) * s * 1.4;
	}
	return r;
}

// Spark's "crackling tips and ember flecks" (11.10): flecks that flare and
// fade in the paint, and arcs that crawl along the silhouette's edge.
vec3 creature_spark(vec2 uv, vec3 lp, float fr) {
	vec2 cell = floor(uv * 72.0);
	float h = creature_hash(cell);
	vec2 f = fract(uv * 72.0) - 0.5;
	float flare = 0.5 + 0.5 * sin(TIME * (2.0 + h * 5.0) + h * 40.0);
	float fleck = step(0.9, h) * smoothstep(0.38, 0.05, length(f)) * flare;
	float y = lp.y / unit_height;
	float arc = abs(sin(y * 38.0 + sin(lp.x / unit_height * 23.0 + TIME * 7.0) * 2.2 + TIME * 3.0));
	float crackle = smoothstep(0.12, 0.0, arc) * smoothstep(0.25, 0.7, fr);
	crackle *= step(0.35, fract(sin(floor(TIME * 9.0) * 12.9898 + floor(y * 6.0) * 78.233) * 43758.5453));
	return vec3(1.0, 0.72, 0.3) * fleck * 1.6 + vec3(1.0, 0.85, 0.5) * crackle * 2.2;
}

// Echo's pattern: rings that run up the body like a sound's echo, in the
// note's colour.
float creature_echo_rings(vec3 lp) {
	float y = lp.y / unit_height;
	float band = fract(y * 5.0 - TIME * 0.45);
	return smoothstep(0.0, 0.06, band) * smoothstep(0.2, 0.08, band);
}

// Each kind's own form pattern (§21.6: a form "changes a ruleborn's pattern,
// glow and one accessory"; CreatureModel.FORM_PATTERN): spots, bands,
// chevrons, rings, scales, a swirl or a zigzag, laid on the body by its own
// shape at the kind's scale. Hush darkens inside it and edges it in starlight,
// Spark runs embers along its edges, Echo pulses it in the note's cyan.
// x is inside the shape, y its edge.
uniform float form_pattern = 0.0;
uniform float form_scale = 6.0;

vec2 creature_form_pattern(vec3 lp) {
	vec3 p = lp / unit_height * form_scale;
	float d = 1.0;
	int kind = int(form_pattern + 0.5);
	if (kind == 0) {
		// Spots: a jittered dot in each cell, of varied size.
		vec3 cell = floor(p);
		vec3 f = fract(p) - 0.5;
		float h = creature_hash(cell.xy + cell.z * 7.31);
		vec3 o = vec3(h - 0.5, fract(h * 13.7) - 0.5, fract(h * 7.3) - 0.5) * 0.35;
		d = length(f - o) - mix(0.18, 0.34, fract(h * 3.1));
	} else if (kind == 1) {
		// Bands round the body, gently waved.
		float y = p.y + 0.18 * sin(p.x * 2.3 + p.z * 1.7);
		d = (abs(fract(y) - 0.5) - 0.16);
	} else if (kind == 2) {
		// Chevrons pointing down the front, like layered feathers.
		float y = p.y + abs(p.x) * 0.9;
		d = (abs(fract(y) - 0.5) - 0.14);
	} else if (kind == 3) {
		// Rings out from the belly, like ripples.
		float r = length(vec2(p.x, p.y - form_scale * 0.5));
		d = (abs(fract(r) - 0.5) - 0.13);
	} else if (kind == 4) {
		// Scales (diamonds).
		vec2 q = vec2(p.x + p.z, p.y) * mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071));
		vec2 f = abs(fract(q) - 0.5);
		d = 0.36 - max(f.x, f.y);
	} else if (kind == 5) {
		// A swirl round the body's axis, climbing.
		float a = atan(p.z, p.x) / 6.2831 * 3.0;
		d = (abs(fract(a + p.y * 0.5) - 0.5) - 0.12);
	} else {
		// A zigzag, like a lightning mark (rounded at the turns).
		float y = p.y + abs(fract(p.x * 0.8 + p.z * 0.8) - 0.5) * 1.4;
		d = (abs(fract(y) - 0.5) - 0.12);
	}
	float inside = smoothstep(0.03, -0.03, d);
	float edge = smoothstep(0.07, 0.0, abs(d));
	return vec2(inside, edge);
}

void creature_surface(vec3 c, bool body, float gloss, float emit, vec2 uv, vec3 lp, vec3 n, vec3 v, float far,
		out vec3 albedo, out vec3 emission) {
	float glow = body ? glow_vc * smoothstep(glow_from, glow_to, c.r - c.b) : emit;
	if (!body) {
		float gv = dot(c, vec3(0.299, 0.587, 0.114));
		c = clamp(mix(c, c * gear_tint, smoothstep(0.06, 0.12, gv) * (1.0 - step(0.01, emit))), 0.0, 1.0);
	}
	vec3 stars = vec3(0.0);
	if (paint_contrast < 1.0 && body) {
		float pl = max(0.02, dot(c, vec3(0.299, 0.587, 0.114)));
		c = clamp(c * mix(paint_mid, pl, paint_contrast) / pl, 0.0, 1.0);
	}
	c = mix(c, clamp(c * red_tint, 0.0, 1.0), smoothstep(0.2, 0.45, c.r - c.g));
	c = creature_tone(c * paint_tint);
	if (!body && gloss > 0.99) {
		// Metal parts (iron bands, brass): the design's sit in a bright room
		// and read pale where they face up; dark iron otherwise drew black.
		float up = reflect(-v, n).y;
		c = mix(c, metal_sky.rgb, metal_sky.a * smoothstep(-0.3, 0.6, up));
	}
	if (pastel > 0.0) {
		float sat = (max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b))) / max(0.02, max(c.r, max(c.g, c.b)));
		// Light paint pales most, so a petal's deep base stays deep under its pale tip.
		float pv = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(c, pastel_colour.rgb, pastel * smoothstep(0.35, 0.85, sat) * mix(1.0, smoothstep(0.1, 0.5, pv), pastel_by_value));
	}
	vec3 col = c;
	vec2 pat = vec2(0.0);
	if (body && hush + spark + echo_form > 0.0) {
		pat = creature_form_pattern(lp);
	}
	if (hush > 0.0) {
		col = mix(c, creature_hush(c, uv, body, stars), hush);
		// Inside the kind's pattern the midnight deepens; its edge is starlit.
		col = mix(col, col * 0.45, pat.x * hush);
		stars = stars * hush + vec3(0.62, 0.7, 1.0) * pat.y * 0.55 * hush;
	}
	float fr = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 3.0);
	vec3 extra = vec3(0.0);
	if (body) {
		if (body_metal > 0.0) {
			// Toon chrome: what faces the sky is bright, what faces the ground dark.
			float up = reflect(-v, n).y;
			col *= mix(1.0, mix(0.32, 1.15, smoothstep(-0.2, 0.5, up)), body_metal);
		}
		if (body_iris > 0.0) {
			vec3 bow = 0.5 + 0.5 * cos(6.2831 * (fr * 1.6 + dot(n, v) * 0.6 + vec3(0.0, 0.33, 0.67)));
			// Small on screen the rainbow is sparkle noise over the shape: it fades.
			extra += bow * smoothstep(0.05, 0.6, fr) * body_iris * 0.8 * (1.0 - far * 0.8);
		}
		extra += body_emit * (1.0 - hush);
		if (echo_form > 0.0) {
			// The kind's pattern, pulsing in the note's colour as the rings pass.
			float pulse = 0.55 + 0.45 * sin(TIME * 3.0 - lp.y / unit_height * 9.0);
			col = mix(col, mix(col, echo_colour_note.rgb, 0.5), pat.x * 0.6 * echo_form);
			extra += echo_colour_note.rgb * (pat.y * 0.9 + pat.x * 0.15) * pulse * echo_form;
			float ring = creature_echo_rings(lp) * echo_form;
			col = mix(col, mix(col, echo_colour_note.rgb, 0.55), ring);
			extra += echo_colour_note.rgb * ring * 0.35;
		}
	}
	// Spark warms the paint toward embers before it glows.
	col = mix(col, col * vec3(1.2, 0.72, 0.42), 0.55 * spark);
	col = mix(col, flash.rgb, flash.a);
	albedo = creature_saturate(col);
	// Small on screen, the paint steps up in value (most where it is darkest,
	// so dark kinds keep their order) and the rim wraps all the way round.
	vec3 up_value = 1.0 - (1.0 - albedo) * (1.0 - far_value);
	float l_up = dot(up_value, vec3(0.299, 0.587, 0.114));
	up_value = clamp(mix(vec3(l_up), up_value, 1.4), 0.0, 1.0);
	albedo = mix(albedo, up_value, far * (1.0 - hush * 0.7));
	float side = mix(smoothstep(-0.2, 0.6, n.x * 0.8 + n.y * 0.4), 1.0, far);
	float rs = rim_strength * mix(1.0, far_rim, far);
	// Hush's "soft, silent edges": a broad moonlit rim all round, not a hard one.
	float soft = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 1.6);
	vec3 rim_col = mix(rim_colour.rgb, mix(echo_colour_note.rgb, vec3(1.0), 0.2), echo_form);
	rim_col = mix(rim_col, mix(rim_col, far_rim_colour.rgb, 0.4), far);
	fr = mix(fr, pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 2.0), far);
	vec3 rim = rim_col * fr * side * 0.9 * rs * (1.0 - hush)
		+ albedo * vec3(1.0, 0.55, 0.35) * wrap * fr * 0.6 * rs * (1.0 - hush);
	rim += mix(hush_colour.rgb, vec3(0.75, 0.8, 1.0), 0.45) * soft * 0.55 * hush;
	rim += albedo * 0.06 * far * (1.0 - hush * 0.6);
	// A glowing part (flames, lanterns, embers) burns hotter at its core: the
	// design's flames run orange to yellow under bloom; here the face turned to
	// the eye goes toward warm yellow-white, the edge keeps the paint's colour.
	vec3 hot = mix(albedo, vec3(1.0, 0.86, 0.48), hot_core * smoothstep(0.2, 0.9, dot(n, v)));
	emission = mix(albedo, hot, step(0.01, emit) * (body ? 0.0 : 1.0)) * glow + rim + stars + extra;
	if (hero > 0.0) {
		vec3 image = albedo * mix(hero_bounce.rgb * 0.55, hero_sky.rgb, smoothstep(-0.6, 0.8, n_up)) * hero_image;
		float graze = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 2.2);
		float pale = smoothstep(0.08, 0.5, dot(albedo, vec3(0.2126, 0.7152, 0.0722)));
		vec3 sheen_col = mix(sheen.rgb, albedo, 0.35);
		emission += (image + sheen_col * graze * hero_sheen * pale) * hero * (1.0 - hush * 0.6);
	}
	if (spark > 0.0) {
		// Spark: lit from within (the Rig page's emissive #6A2208 at 0.35), hotter at the edge.
		emission += (albedo * 0.3 + spark_colour.rgb * (0.12 + smoothstep(0.02, 0.5, fr) * 1.8)) * spark;
		if (body) {
			emission += creature_spark(uv, lp, fr) * spark;
			// Embers run along the kind's pattern, flickering.
			float run = 0.6 + 0.4 * sin(TIME * 6.0 + (lp.x + lp.y) / unit_height * 14.0);
			albedo = mix(albedo, albedo * 0.55, pat.x * 0.5 * spark);
			emission += (vec3(1.0, 0.55, 0.18) * pat.y * 1.4 * run + vec3(1.0, 0.4, 0.1) * pat.x * 0.2) * spark;
		}
	}
}

void light() {
	vec3 sun = mix(LIGHT_COLOR, vec3(dot(LIGHT_COLOR, vec3(0.299, 0.587, 0.114))), light_neutral);
	// Under a dimmer sun (dusk, night, the twilight realms) a character keeps
	// part of its daytime value, so a guard is not a dark blob on dark grass:
	// the sun is taken toward `day_sun` by `night_eye`, at most `night_gain` times.
	float sun_l = max(0.001, dot(sun, vec3(0.299, 0.587, 0.114)));
	if (LIGHT_IS_DIRECTIONAL) {
		sun *= clamp(pow(day_sun / sun_l, night_eye), 1.0, night_gain);
	}
	float ndl = dot(NORMAL, LIGHT) + ramp_bias;
	// Close up (the hero view) the relief shades deeper: the fleece's lumps, the feathers' scallops.
	float rd = mix(relief_detail, 1.6, hero);
	float grain = clamp(1.0 + rd * (dot(normalize(relief_n), LIGHT) - dot(NORMAL, LIGHT)), mix(0.55, 0.3, hero), 1.3);
	float lit = creature_ramp(ndl) * grain * mix(0.62, 1.0, smoothstep(0.3, 0.7, ATTENUATION));
	// Small on screen the darkest step opens, so the shape is one clear value.
	lit = mix(lit, far_floor + lit * (1.0 - far_floor), far_mix * 0.85);
	lit = mix(lit, 0.62 + lit * 0.38, flatten);
	vec3 shade = mix(shade_tint.rgb, vec3(1.0), lit);
	DIFFUSE_LIGHT += sun / PI * lit * shade * exposure;
	float rs = mix(ramp_soft, 0.16, hero);
	float top = smoothstep(0.33 - rs, 0.33 + rs, ndl) * 0.45 + smoothstep(0.66 - rs, 0.66 + rs, ndl) * 0.55;
	// Only light paint pales (a tone curve's shoulder); pupils and ink stay dark.
	float value = smoothstep(0.12, 0.55, dot(ALBEDO, vec3(0.2126, 0.7152, 0.0722)));
	SPECULAR_LIGHT += sun / PI * (sheen.rgb - ALBEDO * sheen.rgb) * top * lift * value
		* smoothstep(0.3, 0.7, ATTENUATION);
	if (gloss_band > 0.0) {
		// Brass and clearcoat: one hard highlight band, not a physical lobe.
		vec3 h = normalize(LIGHT + VIEW);
		float s = smoothstep(0.9, 0.93, dot(NORMAL, h));
		SPECULAR_LIGHT += sun / PI * s * gloss_band * 0.7 * ATTENUATION;
	}
}
