// Alarm: the island is raised. An alarm red bell with a gold crown and
// clapper, swung to one side, and a sound arc ringing out on each side.
import { lathe, profile, ball } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'alarm_light',
  glints: [[0.38, 0.34, 0.7]],
  inner: [0.42, 0.4, 0.3, 'alarm_light', 0.3],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const bell = new THREE.Group();
    const body = lathe(S, profile(S, [[0, 0.78], [0.3, 0.74], [0.5, 0.4], [0.6, -0.2], [0.92, -0.6], [0.9, -0.72], [0.6, -0.7]]),
      'alarm', 'alarm_light');
    const lip = new THREE.Mesh(new THREE.TorusGeometry(0.88, 0.09, 16, 64), S.toon('gold', 'gold_top'));
    lip.rotation.x = Math.PI / 2;
    lip.position.y = -0.68;
    const knob = ball(S, 0.2, 'gold', 'gold_top');
    knob.position.y = 0.88;
    const clapper = ball(S, 0.2, 'gold_bottom', 'gold_top');
    clapper.position.set(0.14, -0.86, 0.1);
    bell.add(body, lip, knob, clapper);
    bell.rotation.set(0.2, 0.2, -0.28);
    bell.position.set(-0.12, 0.02, 0);
    scene.add(bell);
    for (const side of [-1, 1]) {
      for (const [r, k] of [[1.3, 0.55]]) {
        // A fat glossy tube with a ball at each end, so the arc is a
        // rounded solid and not a flat stroke.
        const arc = new THREE.Group();
        arc.add(new THREE.Mesh(new THREE.TorusGeometry(r, 0.15, 16, 40, k * 1.3), S.toon('alarm_light', 'cream', 1)));
        for (const a of [0, k * 1.3]) {
          const cap = ball(S, 0.15, 'alarm_light', 'cream');
          cap.position.set(Math.cos(a) * r, Math.sin(a) * r, 0);
          arc.add(cap);
        }
        arc.rotation.z = side > 0 ? -k * 0.65 : Math.PI - k * 0.65;
        arc.position.set(-0.12, 0.08, 0.1);
        scene.add(arc);
      }
    }
    return scene;
  },
};
