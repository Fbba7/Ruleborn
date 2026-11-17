// The icons' studio (art/ui/icons/README.md): one toon light for every
// icon, the world's own (client/world/toon_light.gdshaderinc), mirrored
// number for number as the style board's studio does
// (art/ui/board/studio.html): a ramp of four steps read by N·L remapped to
// [0, 1]; albedo saturated by 10%; shade that falls toward violet, not
// black; a rim on the lit side in the icon's light colour, at the icon
// strength (0.42, the world's 0.28 and a half: an icon has no world around
// it to edge it). No metalness, no reflections, no clear coat (§21.3,
// D5 (b)): gold is gold by its colour and its glint.
//
// Every colour is a name in client/ui/tokens.json. An icon's module gets
// this file's exports as its `S` argument.
//
// The studio runs in Node, not a browser (README.md, "Why the bake is plain
// arithmetic"): three.js builds the scene, raster.js draws it.
import fs from 'node:fs';
import * as THREE from '../../../../tools/ui_research/node_modules/three/build/three.module.js';
import { RoundedBoxGeometry } from '../../../../tools/ui_research/node_modules/three/examples/jsm/geometries/RoundedBoxGeometry.js';
import { rasterize } from './raster.js';

export { THREE, RoundedBoxGeometry };

const TOKENS = JSON.parse(fs.readFileSync(new URL('../../../../client/ui/tokens.json', import.meta.url), 'utf8'));

// A colour token by name, following names that point at other names.
export function tok(name) {
  let v = name;
  for (let i = 0; i < 8 && !String(v).startsWith('#'); i++) {
    if (!TOKENS.color[v]) throw new Error(`no colour token ${v}`);
    v = TOKENS.color[v].value;
  }
  return String(v).slice(0, 7);
}

// The same colour as CSS at an alpha: light and glow are token colours
// faded, never new hues.
export function rgba(name, a) {
  const h = tok(name);
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
  return `rgba(${r},${g},${b},${a})`;
}

export const STUDIO = {
  key: { colour: 'cream', at: [-3, 4, 5] },
  fill: { sky: 'paper', power: 0.06 },
  ramp: [62, 140, 215, 255],
  shade: [0.55, 0.47, 0.82],
  saturation: 1.1,
  rim: 0.42,
  // The ramp's four steps meet over a short blend (in N·L remapped to
  // [0, 1]), so a body reads as a gradient in steps, not posterised bands
  // at phone size (rubric.md quality 1: banding fails).
  rampSoft: 0.05,
  // The gloss: a toon highlight, the key's half vector cut by a step (no
  // physically based specular, §21.3): a crisp cream spot that sits on and
  // follows the surface it lights. `at` is the N·H where it starts.
  gloss: { colour: 'cream', at: 0.955, soft: 0.012, strength: 0.9 },
};

// The scene in the studio's camera as a w x h picture (picture.js).
export function renderTo(scene, w, h = w) {
  return rasterize(scene, camera(w / h), w, h);
}

export function camera(aspect = 1) {
  const c = new THREE.PerspectiveCamera(24, aspect, 0.1, 100);
  c.position.set(0, 0, 7.8);
  c.lookAt(0, 0, 0);
  return c;
}

// The material as a GPU would run it. raster.js works the same light, line
// for line, from the uniforms; the GLSL stays as its specification.
const TOON_VERTEX = `
uniform vec3 keyAt;
varying vec3 vNormal;
varying vec3 vView;
varying vec3 vKey;
void main() {
  vec4 at = modelViewMatrix * vec4(position, 1.0);
  vNormal = normalize(normalMatrix * normal);
  vView = -at.xyz;
  vKey = normalize((viewMatrix * vec4(keyAt, 0.0)).xyz);
  gl_Position = projectionMatrix * at;
}`;
const TOON_FRAGMENT = `
uniform vec3 albedo;
uniform vec3 keyColour;
uniform vec3 fill;
uniform vec3 rimColour;
uniform vec3 shade;
uniform vec4 ramp;
uniform float saturation;
uniform float rimStrength;
uniform float rampSoft;
uniform vec3 glossColour;
uniform vec3 gloss;
varying vec3 vNormal;
varying vec3 vView;
varying vec3 vKey;
vec3 saturated(vec3 c) {
  float l = dot(c, vec3(0.299, 0.587, 0.114));
  return clamp(mix(vec3(l), c, saturation), 0.0, 1.0);
}
float toonRamp(float ndl) {
  float x = ndl * 0.5 + 0.5;
  float r = ramp.x;
  r = mix(r, ramp.y, smoothstep(0.25 - rampSoft, 0.25 + rampSoft, x));
  r = mix(r, ramp.z, smoothstep(0.5 - rampSoft, 0.5 + rampSoft, x));
  return mix(r, ramp.w, smoothstep(0.75 - rampSoft, 0.75 + rampSoft, x));
}
void main() {
  vec3 n = normalize(vNormal) * (gl_FrontFacing ? 1.0 : -1.0);
  vec3 v = normalize(vView);
  float ndl = dot(n, vKey);
  float lit = toonRamp(ndl);
  vec3 tint = mix(shade, vec3(1.0), lit);
  vec3 c = saturated(albedo) * (keyColour * lit * tint + fill);
  float rim = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 3.0) * step(0.0, ndl);
  c += keyColour * rimColour * rim * rimStrength;
  float ndh = dot(n, normalize(vKey + v));
  c = mix(c, glossColour, smoothstep(gloss.x, gloss.x + gloss.y, ndh) * gloss.z);
  gl_FragColor = vec4(c, 1.0);
  #include <colorspace_fragment>
}`;

// The one material: a token colour in the studio's toon light, its rim in
// the icon's light colour (`rim`, a token). `glossy` scales the gloss: 0
// for a matte part (wood grain, cloth), 1 by default.
export function toon(face, rim, glossy = 1) {
  const G = STUDIO.gloss;
  const colour = (name) => new THREE.Color(tok(name));
  return new THREE.ShaderMaterial({
    vertexShader: TOON_VERTEX,
    fragmentShader: TOON_FRAGMENT,
    uniforms: {
      albedo: { value: colour(face) },
      keyColour: { value: colour(STUDIO.key.colour) },
      keyAt: { value: new THREE.Vector3(...STUDIO.key.at).normalize() },
      fill: { value: colour(STUDIO.fill.sky).multiplyScalar(STUDIO.fill.power) },
      rimColour: { value: colour(rim || face) },
      shade: { value: new THREE.Vector3(...STUDIO.shade) },
      ramp: { value: new THREE.Vector4(...STUDIO.ramp.map((v) => v / 255)) },
      saturation: { value: STUDIO.saturation },
      rimStrength: { value: STUDIO.rim },
      rampSoft: { value: STUDIO.rampSoft },
      glossColour: { value: colour(G.colour) },
      gloss: { value: new THREE.Vector3(G.at, G.soft, G.strength * glossy) },
    },
  });
}

// ---- shapes the icons share ----

// A four-pointed star with concave, curved sides (Starlight's mark).
export function starShape(tip, waist) {
  const s = new THREE.Shape();
  for (let i = 0; i < 4; i++) {
    const a = Math.PI / 2 - i * Math.PI / 2;
    const b = a - Math.PI / 4;
    const n = a - Math.PI / 2;
    if (i === 0) s.moveTo(Math.cos(a) * tip, Math.sin(a) * tip);
    s.quadraticCurveTo(Math.cos(b) * waist, Math.sin(b) * waist, Math.cos(n) * tip, Math.sin(n) * tip);
  }
  return s;
}

// A flat shape puffed into a toy-like solid by a deep rounded bevel.
export function puffed(shape, size, depth = 0.36) {
  const g = new THREE.ExtrudeGeometry(shape, { depth: size * 0.02, bevelEnabled: true, bevelThickness: size * depth,
    bevelSize: size * 0.15, bevelSegments: 10, curveSegments: 48 });
  g.center();
  g.computeVertexNormals();
  return g;
}
