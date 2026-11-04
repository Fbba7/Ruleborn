// Starglass: the wrapper a gift arrives in (§9.1), a cut star gem. A
// five-pointed star cut in flat facets, so each facet is one step of the
// toon ramp: a gem by its cut and its colour, never by glass lighting
// (§21.3).
import { star5Shape } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'spirit_light',
  glints: [[0.38, 0.33, 0.7]],
  inner: [0.42, 0.38, 0.28, 'spirit_light', 0.3],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const geo = new THREE.ExtrudeGeometry(star5Shape(S, 1.2, 0.55), { depth: 0.05, bevelEnabled: true,
      bevelThickness: 0.5, bevelSize: 0.36, bevelSegments: 1, curveSegments: 1 });
    geo.center();
    const flat = geo.toNonIndexed();
    flat.computeVertexNormals();
    const gem = new THREE.Mesh(flat, S.toon('spirit', 'spirit_light'));
    gem.rotation.set(-0.28, 0.4, 0.06);
    scene.add(gem);
    return scene;
  },
};
