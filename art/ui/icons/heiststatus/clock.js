// Clock: the heist's time left. A gold pocket clock with a cream face,
// twelve-o'clock tick marks, two ink hands, and a crown and loop on top.
import { box, ball } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'time_light',
  glints: [[0.34, 0.36, 0.7]],
  inner: [0.42, 0.42, 0.3, 'time_light', 0.25],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const caseBody = new THREE.Mesh(new THREE.CylinderGeometry(0.95, 0.95, 0.32, 72), S.toon('gold', 'gold_top'));
    caseBody.rotation.x = Math.PI / 2;
    const bezel = new THREE.Mesh(new THREE.TorusGeometry(0.88, 0.11, 18, 72), S.toon('gold_top', 'cream'));
    bezel.position.z = 0.16;
    const face = new THREE.Mesh(new THREE.CylinderGeometry(0.8, 0.8, 0.34, 72), S.toon('paper', 'cream', 0.3));
    face.rotation.x = Math.PI / 2;
    g.add(caseBody, bezel, face);
    for (let i = 0; i < 4; i++) {
      const a = i * Math.PI / 2;
      const t = box(S, 0.1, 0.2, 0.06, 0.03, 'time_shadow', 'time_light');
      t.position.set(Math.sin(a) * 0.62, Math.cos(a) * 0.62, 0.19);
      t.rotation.z = -a;
      g.add(t);
    }
    const hour = box(S, 0.13, 0.46, 0.06, 0.05, 'ink_deep', 'time_light');
    hour.position.set(0.17, 0.13, 0.22);
    hour.rotation.z = -0.95;
    const minute = box(S, 0.1, 0.62, 0.06, 0.04, 'ink_deep', 'time_light');
    minute.position.set(-0.03, 0.29, 0.24);
    minute.rotation.z = 0.12;
    const pin = ball(S, 0.08, 'alarm', 'alarm_light');
    pin.position.z = 0.27;
    const crown = new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.16, 0.2, 32), S.toon('gold', 'gold_top'));
    crown.position.y = 1.05;
    const loop = new THREE.Mesh(new THREE.TorusGeometry(0.2, 0.07, 14, 40), S.toon('gold_bottom', 'gold_top'));
    loop.position.y = 1.3;
    g.add(hour, minute, pin, crown, loop);
    g.rotation.set(0.1, 0.32, -0.08);
    g.position.y = -0.16;
    scene.add(g);
    return scene;
  },
};
