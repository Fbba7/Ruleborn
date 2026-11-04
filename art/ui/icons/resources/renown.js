// Renown: the league standing, a laurel medal. A thick gold medal with a
// raised star, a green laurel round its lower rim, and two violet ribbon
// tails behind it.
import { star5Shape, slab, ball } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'motion_light',
  glints: [[0.36, 0.34, 0.6]],
  inner: [0.42, 0.38, 0.3, 'gold_top', 0.3],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    for (const side of [-1, 1]) {
      const tail = new THREE.Shape();
      tail.moveTo(-0.22, 0.2); tail.lineTo(0.22, 0.2); tail.lineTo(0.22, -0.95); tail.lineTo(0, -0.75); tail.lineTo(-0.22, -0.95);
      tail.closePath();
      const t = slab(S, tail, 0.3, side < 0 ? 'matter' : 'matter_shadow', 'matter_light', 0.12);
      t.position.set(side * 0.42, -0.62, -0.35);
      t.rotation.z = side * 0.35;
      g.add(t);
    }
    const disc = new THREE.Mesh(new THREE.CylinderGeometry(0.82, 0.82, 0.26, 64), S.toon('gold', 'gold_top'));
    disc.rotation.x = Math.PI / 2;
    const rim = new THREE.Mesh(new THREE.TorusGeometry(0.82, 0.12, 16, 64), S.toon('gold_bottom', 'gold_top'));
    const face = new THREE.Mesh(new THREE.CylinderGeometry(0.66, 0.66, 0.3, 64), S.toon('gold_round_mid', 'gold_top', 0.6));
    face.rotation.x = Math.PI / 2;
    const star = slab(S, star5Shape(S, 0.42, 0.19), 0.3, 'cream', 'gold_top', 0.18);
    star.position.z = 0.2;
    g.add(disc, rim, face, star);
    for (const side of [-1, 1]) {
      for (let i = 0; i < 4; i++) {
        const a = -Math.PI / 2 + side * (0.5 + i * 0.42);
        const leaf = ball(S, 0.2, i % 2 ? 'life' : 'life_shadow', 'life_light');
        leaf.scale.set(0.62, 1.3, 0.62);
        leaf.position.set(Math.cos(a) * 0.98, Math.sin(a) * 0.98, 0.12);
        leaf.rotation.z = a + side * 0.5;
        g.add(leaf);
      }
    }
    g.rotation.set(0.12, 0.3, 0);
    g.scale.setScalar(1.08);
    g.position.y = 0.08;
    scene.add(g);
    return scene;
  },
};
