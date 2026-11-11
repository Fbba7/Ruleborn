// Star: the HUD's single star, a rating or a mark earned. One fat gold
// five-pointed star, turned a little so its bevel catches the key.
import { star5Shape, slab } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'starlight',
  glints: [[0.36, 0.32, 0.8]],
  inner: [0.42, 0.38, 0.3, 'gold_top', 0.35],
  build(S) {
    const scene = new S.THREE.Scene();
    const star = slab(S, star5Shape(S, 1.12, 0.56, 0.2), 1.0, 'gold', 'gold_top', 0.3);
    star.rotation.set(-0.16, 0.3, 0.06);
    star.position.y = -0.04;
    scene.add(star);
    return scene;
  },
};
