// Loot bag: what the crew carries out. A fat leather sack tied at the
// neck with a gold cord, its top bunched into a ruffle, and a gold star
// stamped on its front so it reads as loot and not as a plain sack.
import { lathe, profile, star5Shape, slab } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'motion_light',
  glints: [[0.36, 0.44, 0.7]],
  inner: [0.42, 0.46, 0.28, 'gold_top', 0.15],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const sack = lathe(S, profile(S, [[0, -1.12], [0.72, -1.02], [1.0, -0.55], [0.92, 0.0], [0.5, 0.42], [0.28, 0.6]]),
      'leather_light', 'gold_top', 0);
    const ruffle = lathe(S, profile(S, [[0.22, 0.56], [0.36, 0.7], [0.58, 0.98], [0.5, 1.12], [0.3, 1.04], [0, 1.0]], 24),
      'leather_light', 'gold_top', 0.25);
    // A stitched hem of the rim leather round the foot lifts the body off
    // a dark ground in grayscale.
    const hem = new THREE.Mesh(new THREE.TorusGeometry(0.93, 0.07, 12, 64), S.toon('leather_rim', 'gold_top', 0));
    hem.rotation.x = Math.PI / 2;
    hem.position.y = -0.78;
    const cord = new THREE.Mesh(new THREE.TorusGeometry(0.3, 0.085, 16, 48), S.toon('gold', 'gold_top'));
    cord.rotation.x = Math.PI / 2 - 0.15;
    cord.position.y = 0.6;
    const tail = new THREE.Mesh(new THREE.CapsuleGeometry(0.07, 0.36, 8, 16), S.toon('gold', 'gold_top'));
    tail.position.set(0.3, 0.38, 0.22);
    tail.rotation.z = 0.5;
    const star = slab(S, star5Shape(S, 0.4, 0.19), 0.3, 'gold', 'gold_top', 0.16);
    star.position.set(0, -0.4, 1.12);
    star.rotation.x = -0.12;
    g.add(sack, ruffle, hem, cord, tail, star);
    g.rotation.set(0.12, -0.25, -0.06);
    g.position.y = 0.0;
    scene.add(g);
    return scene;
  },
};
