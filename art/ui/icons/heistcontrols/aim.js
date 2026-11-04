// Aim: a crosshair. A thick stone ring around an alarm red bullseye, and
// four cream ticks standing out past the ring, so the icon reads as a
// sight and not a coin.
import { box, ball } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'alarm_light',
  glints: [[0.36, 0.3, 0.8], [0.47, 0.43, 0.4]],
  inner: [0.42, 0.38, 0.3, 'alarm_light', 0.25],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const tilt = new THREE.Group();
    tilt.rotation.set(-0.18, 0.22, 0);
    const ring = new THREE.Mesh(new THREE.TorusGeometry(0.82, 0.17, 32, 96), S.toon('stone', 'cream'));
    const target = new THREE.Mesh(new THREE.CylinderGeometry(0.62, 0.62, 0.14, 72), S.toon('alarm', 'alarm_light'));
    target.rotation.x = Math.PI / 2;
    const band = new THREE.Mesh(new THREE.TorusGeometry(0.4, 0.075, 20, 72), S.toon('paper', 'cream'));
    band.position.z = 0.08;
    const eye = ball(S, 0.2, 'alarm', 'alarm_light');
    eye.position.z = 0.08;
    eye.scale.z = 0.7;
    tilt.add(ring, target, band, eye);
    for (let i = 0; i < 4; i++) {
      const a = i * Math.PI / 2;
      const tick = box(S, 0.2, 0.52, 0.2, 0.08, 'cream', 'alarm_light');
      tick.position.set(Math.sin(a) * 1.18, Math.cos(a) * 1.18, 0.04);
      tick.rotation.z = -a;
      tilt.add(tick);
    }
    scene.add(tilt);
    return scene;
  },
};
