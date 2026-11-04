// Cast: the Sage's wand casting a spark. A wooden wand on the diagonal,
// a matter-violet orb at its tip in a gold collar, and a struck star
// spark leaving it toward the top right.
import { rod, ball, slab } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'matter_light',
  glints: [[0.5, 0.33, 0.8], [0.8, 0.2, 0.45]],
  inner: [0.5, 0.38, 0.28, 'matter_light', 0.3],
  build(S) {
    const scene = new S.THREE.Scene();
    const wand = rod(S, [-1.05, -1.05, 0], [0.1, 0.1, 0.1], 0.13, 'wood', 'gold_top');
    const grip = rod(S, [-1.1, -1.1, 0], [-0.62, -0.62, 0.04], 0.165, 'leather_light', 'gold_top');
    const collar = new S.THREE.Mesh(new S.THREE.TorusGeometry(0.17, 0.07, 16, 48), S.toon('gold', 'gold_top'));
    collar.position.set(0.14, 0.14, 0.12);
    collar.rotation.set(Math.PI / 2, 0, -Math.PI / 4);
    const orb = ball(S, 0.4, 'matter', 'matter_light');
    orb.position.set(0.36, 0.36, 0.2);
    const spark = slab(S, S.starShape(0.36, 0.08), 0.36, 'cream', 'motion_light');
    spark.position.set(0.98, 0.98, 0.3);
    spark.rotation.set(0.15, -0.3, 0.2);
    const mote = slab(S, S.starShape(0.2, 0.05), 0.2, 'gold_top', 'motion_light');
    mote.position.set(1.12, 0.32, 0.25);
    mote.rotation.set(0, 0.3, -0.3);
    scene.add(wand, grip, collar, orb, spark, mote);
    return scene;
  },
};
