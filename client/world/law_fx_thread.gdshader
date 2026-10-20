// §21.7's links between pylons: "a thread in the note's colour links the two
// pylons; a dissonance is a jagged, flickering line; a chord forms a slowly
// turning triangle of light between three pylons." A strip that always faces
// the camera, as thick on screen near or far.
//
// Per vertex: VERTEX the point on the line, UV (how far along, 0..1; which
// side, −1 or 1), COLOR the colour, CUSTOM0 the line's direction there and
// its kind (0 harmony, 1 dissonance, 2 chord).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled, skip_vertex_transform;

uniform float t = 0.0;
uniform float pace = 1.0;
uniform float strength = 1.0;
// Half the strip's width, in metres.
uniform float width = 0.045;

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
		float k = floor(s * 9.0);
		float seg = floor(along * 14.0);
		float j = (hash(seg + k * 7.0) - 0.5) * 0.28 * sin(3.14159 * along);
		v.xy += n * j;
		w *= 0.8;
	} else if (kind > 1.5) {
		w *= 1.3;
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
		float pulse = smoothstep(0.2, 0.0, abs(fract(along * 3.0 - s * 0.5) - 0.5) - 0.3);
		c = mix(c, vec3(1.0), pulse * 0.6 + step(0.75, core) * 0.4);
		a *= 0.6 + 0.4 * pulse;
	} else if (kind < 1.5) {
		// Dissonance: flickers on and off, uneasy.
		float k = floor(s * 9.0);
		float f = step(0.3, hash(k + 3.0));
		c = mix(c, vec3(1.0), step(0.7, core) * 0.6);
		a *= 0.35 + 0.65 * f;
	} else {
		// Chord: light runs round the triangle.
		float run = smoothstep(0.25, 0.0, abs(fract(along - s * 0.12) - 0.5) - 0.2);
		c = mix(c, vec3(1.0, 0.98, 0.9), run * 0.7 + step(0.7, core) * 0.35);
		a *= 0.55 + 0.45 * run;
	}
	ALBEDO = c * 1.15;
	ALPHA = clamp(a * colour.a * strength, 0.0, 1.0);
}
