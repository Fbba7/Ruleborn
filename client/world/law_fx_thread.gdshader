// §21.7's links between pylons: "a thread in the note's colour links the two
// pylons; a dissonance is a jagged, flickering line; a chord forms a slowly
// turning triangle of light between three pylons." A strip that always faces
// the camera, as thick on screen near or far.
//
// Per vertex: VERTEX the point on the line, UV (how far along, 0..1; which
// side, −1 or 1), COLOR the colour, CUSTOM0 the line's direction there and
// its kind (0 harmony, 1 dissonance, 2 chord, 3 a bolt: a white-hot core
// in a wide glow, 4 a wavy wind line).

shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled, skip_vertex_transform;

uniform float t = 0.0;
uniform float pace = 1.0;
uniform float strength = 1.0;
// Half the strip's width, in metres.
uniform float width = 0.07;
// §20.8's reduced motion: 1 stops the flicker and slows the jags.
uniform float steady = 0.0;

varying float along;
varying float side;
varying float kind;
varying vec4 colour;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void vertex() {
	along = UV.x;
	side = UV.y;
	kind = CUSTOM0.w;
	colour = COLOR;
	float s = t * pace;
	vec4 v = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 dir = (MODELVIEW_MATRIX * vec4(CUSTOM0.xyz, 0.0)).xyz;
	vec2 d = length(dir.xy) > 0.0001 ? normalize(dir.xy) : vec2(1.0, 0.0);
	vec2 n = vec2(-d.y, d.x);
	float w = width;
	if (kind > 0.5 && kind < 1.5) {
		// A dissonance's jags, redrawn several times a second.
		float k = floor(s * mix(9.0, 1.0, steady));
		float seg = floor(along * 14.0);
		float j = (hash(seg + k * 7.0) - 0.5) * 0.28 * sin(3.14159 * along);
		v.xy += n * j;
		w *= 1.25;
	} else if (kind > 2.5 && kind < 3.5) {
		// A bolt: jags like a dissonance's, redrawn faster.
		float k = floor(s * mix(14.0, 1.0, steady));
		float seg = floor(along * 18.0);
		v.xy += n * (hash(seg + k * 5.0) - 0.5) * 0.35 * sin(3.14159 * along);
	} else if (kind > 3.5) {
		// A wind line: a slow wave along its length.
		v.xy += n * sin(along * 18.0 - s * 3.0) * 0.08;
	} else if (kind > 1.5) {
		w *= 0.8;
	}
	v.xy += n * side * w;
	VERTEX = v.xyz;
}

void fragment() {
	float s = t * pace;
	float core = 1.0 - abs(side);
	float a = smoothstep(0.0, 0.5, core);
	vec3 c = colour.rgb;
	if (kind < 0.5) {
		// Harmony: light flows along the thread, both ways.
		// The note's colour through the body, darker at the rim so it reads
		// by value too, white only where a pulse is passing.
		float pulse = smoothstep(0.2, 0.0, abs(fract(along * 3.0 - s * 0.5) - 0.5) - 0.3);
		c = mix(c * 0.55, c, smoothstep(0.15, 0.45, core));
		c = mix(c, vec3(1.0), pulse * 0.55 * step(0.5, core));
		a = smoothstep(0.0, 0.25, core) * (0.7 + 0.25 * pulse);
	} else if (kind < 1.5) {
		// Dissonance: flickers on and off, uneasy.
		float k = floor(s * mix(9.0, 1.0, steady));
		// An ink core in a rim of the clashing notes' colour, so it reads
		// by value on any ground (§21.10).
		float f = mix(step(0.3, hash(k + 3.0)), 1.0, steady);
		c = mix(c, vec3(0.16, 0.06, 0.14), smoothstep(0.45, 0.7, core));
		a = smoothstep(0.0, 0.35, core) * (0.5 + 0.5 * f);
	} else if (kind > 2.5 && kind < 3.5) {
		// A bolt: white-hot in the middle, its colour as a glow round it,
		// flickering out now and then.
		float k = floor(s * mix(14.0, 1.0, steady));
		float hot = smoothstep(0.55, 0.85, core);
		c = mix(c, vec3(1.0), hot);
		a = smoothstep(0.0, 0.9, core) * 0.5 + hot * 0.5;
		a *= mix(step(0.12, hash(k + floor(colour.g * 16.0) * 3.0 + 11.0)), 1.0, steady);
	} else if (kind > 3.5) {
		// A wind line: an ink rim round its colour, so it reads by value on
		// any ground (21.10), whispers running along it in white.
		float run = smoothstep(0.3, 0.0, abs(fract(along * 4.0 - s * 0.6) - 0.5) - 0.15);
		c = mix(vec3(0.16, 0.06, 0.14), c, smoothstep(0.2, 0.45, core));
		c = mix(c, vec3(1.0), run * step(0.55, core) * 0.7);
		a = smoothstep(0.0, 0.2, core) * (0.75 + 0.25 * run);
	} else {
		// Chord: light runs round the triangle.
		float run = smoothstep(0.25, 0.0, abs(fract(along - s * 0.12) - 0.5) - 0.2);
		c = mix(c, vec3(1.0, 0.98, 0.9), run * 0.3);
		a *= 0.4 + 0.45 * run;
	}
	ALBEDO = c * 1.15;
	ALPHA = clamp(a * colour.a * strength, 0.0, 1.0);
}
