// §21.2's sky: "day #9FB9F0 to #F6D9C8; dusk #6A4FC9 to #F29C7B; night
// #1A1433 to #3A2B6B", a gradient from the horizon up; the world view sets
// the pair by the player's local time.
shader_type sky;

uniform vec4 top : source_color = vec4(0.624, 0.725, 0.941, 1.0);
uniform vec4 bottom : source_color = vec4(0.965, 0.851, 0.784, 1.0);

void sky() {
	float t = clamp(EYEDIR.y * 0.5 + 0.5, 0.0, 1.0);
	COLOR = mix(bottom.rgb, top.rgb, smoothstep(0.25, 0.95, t));
}
