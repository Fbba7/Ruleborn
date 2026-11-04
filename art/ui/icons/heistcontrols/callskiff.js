// Call skiff: the crew's skiff under sail, called in: a wooden hull, a
// cream sail on its mast, and a ring of the time colour calling it.
import { rod, slab } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'time_light',
  glints: [[0.43, 0.3, 0.7], [0.3, 0.7, 0.45]],
  inner: [0.46, 0.42, 0.32, 'gold_top', 0.25],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const call = new THREE.Mesh(new THREE.TorusGeometry(1.2, 0.09, 20, 96, Math.PI * 1.1), S.toon('time', 'time_light'));
    call.rotation.z = Math.PI * -0.05;
    call.position.set(0, -0.15, -0.6);
    const keel = new THREE.Shape();
    keel.moveTo(-1.1, 0.2); keel.lineTo(1.15, 0.2);
    keel.quadraticCurveTo(0.95, -0.38, 0.55, -0.38);
    keel.lineTo(-0.6, -0.38);
    keel.quadraticCurveTo(-0.95, -0.36, -1.1, 0.2);
    const hull = slab(S, keel, 1.3, 'wood', 'gold_top', 0.18);
    hull.position.set(0, -0.72, 0.2);
    hull.rotation.set(0.12, -0.3, 0);
    const trim = rod(S, [-1.02, -0.47, 0.5], [1.06, -0.47, 0.18], 0.06, 'gold', 'gold_top');
    const mast = rod(S, [0, -0.5, 0.15], [0, 1.2, 0.15], 0.06, 'soil', 'gold_top');
    const cloth = new THREE.Shape();
    cloth.moveTo(0, 0); cloth.quadraticCurveTo(0.55, 0.5, 0.06, 1.4); cloth.lineTo(0, 1.4);
    cloth.lineTo(-0.9, 0); cloth.closePath();
    const sail = slab(S, cloth, 0.9, 'cream', 'time_light', 0.14);
    sail.position.set(0.0, 0.32, 0.25);
    sail.rotation.y = -0.25;
    scene.add(call, hull, trim, mast, sail);
    return scene;
  },
};
