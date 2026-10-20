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
// The world's sun stands high (58°), which leaves a character's face, a
// vertical surface, in the lower steps. The steps keep §21.3's values; on a
// character they start earlier, so faces and fronts read in the light.
uniform float ramp_bias : hint_range(0.0, 0.5) = 0.22;
// The design's vcGlow: the body's warm paint glows (embers, lanterns).
uniform float glow_vc = 0.0;
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

varying float gloss_band;

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
	return smoothstep(far_ppm, far_ppm * 0.4, ppm);
}

float creature_ramp(float ndl) {
	const float w = 0.025;
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

void creature_surface(vec3 c, bool body, float gloss, float emit, vec2 uv, vec3 lp, vec3 n, vec3 v, float far,
		out vec3 albedo, out vec3 emission) {
	float glow = body ? glow_vc * smoothstep(0.3, 0.65, c.r - c.b) : emit;
	vec3 stars = vec3(0.0);
	vec3 col = c;
	if (hush > 0.0) {
		col = mix(c, creature_hush(c, uv, body, stars), hush);
		stars *= hush;
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
			extra += bow * smoothstep(0.05, 0.6, fr) * body_iris * 0.8;
		}
		extra += body_emit * (1.0 - hush);
		if (echo_form > 0.0) {
			float ring = creature_echo_rings(lp) * echo_form;
			col = mix(col, mix(col, echo_colour_note.rgb, 0.55), ring);
			extra += echo_colour_note.rgb * ring * 0.35;
		}
	}
	// Spark warms the paint toward embers before it glows.
	col = mix(col, col * vec3(1.2, 0.72, 0.42), 0.55 * spark);
	col = mix(col, flash.rgb, flash.a);
	albedo = creature_saturate(col);
	// Small on screen, the rim wraps further round and the paint keeps its
	// colour in shade (a light lift of the darkest step, as emission).
	float side = smoothstep(mix(-0.2, -0.75, far), 0.6, n.x * 0.8 + n.y * 0.4);
	float rs = rim_strength * mix(1.0, far_rim, far);
	// Hush's "soft, silent edges": a broad moonlit rim all round, not a hard one.
	float soft = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 1.6);
	vec3 rim_col = mix(rim_colour.rgb, mix(echo_colour_note.rgb, vec3(1.0), 0.2), echo_form);
	vec3 rim = rim_col * fr * side * 0.9 * rs * (1.0 - hush)
		+ albedo * vec3(1.0, 0.55, 0.35) * wrap * fr * 0.6 * rs * (1.0 - hush);
	rim += mix(hush_colour.rgb, vec3(0.75, 0.8, 1.0), 0.45) * soft * 0.55 * hush;
	rim += albedo * 0.06 * far * (1.0 - hush * 0.6);
	emission = albedo * glow + rim + stars + extra;
	if (spark > 0.0) {
		// Spark: lit from within (the Rig page's emissive #6A2208 at 0.35), hotter at the edge.
		emission += (albedo * 0.3 + spark_colour.rgb * (0.12 + smoothstep(0.02, 0.5, fr) * 1.8)) * spark;
		if (body) {
			emission += creature_spark(uv, lp, fr) * spark;
		}
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT) + ramp_bias;
	float lit = creature_ramp(ndl) * mix(0.62, 1.0, smoothstep(0.3, 0.7, ATTENUATION));
	vec3 shade = mix(shade_tint.rgb, vec3(1.0), lit);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit * shade;
	float top = smoothstep(0.33 - 0.025, 0.33 + 0.025, ndl) * 0.45 + smoothstep(0.66 - 0.025, 0.66 + 0.025, ndl) * 0.55;
	// Only light paint pales (a tone curve's shoulder); pupils and ink stay dark.
	float value = smoothstep(0.12, 0.55, dot(ALBEDO, vec3(0.2126, 0.7152, 0.0722)));
	SPECULAR_LIGHT += LIGHT_COLOR / PI * (sheen.rgb - ALBEDO * sheen.rgb) * top * lift * value
		* smoothstep(0.3, 0.7, ATTENUATION);
	if (gloss_band > 0.0) {
		// Brass and clearcoat: one hard highlight band, not a physical lobe.
		vec3 h = normalize(LIGHT + VIEW);
		float s = smoothstep(0.9, 0.93, dot(NORMAL, h));
		SPECULAR_LIGHT += LIGHT_COLOR / PI * s * gloss_band * 0.7 * ATTENUATION;
	}
}
