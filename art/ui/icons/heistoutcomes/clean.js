// Clean: the heist ended with no alarm raised. A scalloped seal in the
// success green with a gold ring and a cream tick, and one spark at its
// shoulder: spotless.
import { slab, rod } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'success_light',
  glints: [[0.3, 0.34, 0.5]],
  inner: [0.42, 0.4, 0.3, 'success_light', 0.3],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const edge = new THREE.Shape();
    const N = 240, LOBES = 10;
    for (let i = 0; i <= N; i++) {
      const a = i / N * Math.PI * 2;
      const r = 0.98 * (1 + 0.085 * Math.cos(a * LOBES));
      if (i) edge.lineTo(Math.cos(a) * r, Math.sin(a) * r); else edge.moveTo(r, 0);
    }
    const seal = slab(S, edge, 0.5, 'success', 'success_light', 0.2);
    const ring = new THREE.Mesh(new THREE.TorusGeometry(0.74, 0.085, 16, 72), S.toon('gold', 'gold_top'));
    ring.position.z = 0.14;
    const face = new THREE.Mesh(new THREE.CylinderGeometry(0.7, 0.7, 0.3, 64), S.toon('life_shadow', 'success_light', 0.5));
    face.rotation.x = Math.PI / 2;
    face.position.z = 0.02;
    g.add(seal, ring, face);
    g.add(rod(S, [-0.36, 0.0, 0.26], [-0.1, -0.26, 0.26], 0.115, 'cream', 'cream'));
    g.add(rod(S, [-0.1, -0.26, 0.26], [0.4, 0.32, 0.26], 0.115, 'cream', 'cream'));
    const spark = new THREE.Mesh(S.puffed(S.starShape(0.5, 0.11), 0.5), S.toon('gold_top', 'cream'));
    spark.position.set(0.96, 0.92, 0.3);
    spark.rotation.z = 0.2;
    g.add(spark);
    g.rotation.set(-0.1, 0.3, 0);
    g.position.set(-0.12, -0.1, 0);
    scene.add(g);
    return scene;
  },
};
