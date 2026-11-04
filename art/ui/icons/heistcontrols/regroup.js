// Regroup: three crew pips drawn together round a gold-pennant flag,
// on one small stone pad.
import { pip, rod, slab } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'time_light',
  glints: [[0.62, 0.17, 0.6], [0.3, 0.5, 0.45]],
  inner: [0.48, 0.4, 0.32, 'time_light', 0.22],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const pad = new THREE.Mesh(new THREE.CylinderGeometry(1.08, 1.08, 0.12, 72), S.toon('gold', 'gold_top'));
    pad.position.set(0, -0.98, 0);
    pad.rotation.x = 0.35;
    const pole = rod(S, [0.02, -0.9, -0.3], [0.02, 1.15, -0.3], 0.055, 'wood', 'gold_top');
    const flag = new THREE.Shape();
    flag.moveTo(0, 0); flag.lineTo(0.62, -0.2); flag.lineTo(0, -0.44); flag.closePath();
    const pennant = slab(S, flag, 0.5, 'alarm', 'alarm_light', 0.18);
    pennant.position.set(0.32, 0.92, -0.3);
    const a = pip(S, 'time', 'time_light', 1.05);
    a.position.set(-0.62, -0.38, 0.1);
    const b = pip(S, 'energy', 'energy_light', 1.05);
    b.position.set(0.62, -0.38, 0.1);
    const c = pip(S, 'matter', 'matter_light', 1.05);
    c.position.set(0, -0.48, 0.55);
    scene.add(pad, pole, pennant, a, b, c);
    return scene;
  },
};
