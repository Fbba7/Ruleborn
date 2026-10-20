// The ambient light as the diorama's hemisphere light (realm-diorama.js:487,
// `HemisphereLight`): the realm's sky colour from above and its ground colour
// from below, so faces turned down fall into cool violet shade (§21.1: "warm
// light on the islands and cool shadows beneath"). Lights the world only;
// the sky seen behind it is sky.gdshader's.
shader_type sky;

uniform vec4 above : source_color = vec4(1.0);
uniform vec4 below : source_color = vec4(0.33, 0.27, 0.47, 1.0);
// How strong the ambient is against the sun.
uniform float strength = 0.4;

void sky() {
	COLOR = mix(below.rgb, above.rgb, clamp(EYEDIR.y * 0.5 + 0.5, 0.0, 1.0)) * strength;
}
