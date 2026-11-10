// Spotted: a guard has seen the crew. A wide open eye, a cream white with
// a time blue iris and an ink pupil, in alarm red lids, on a warn yellow
// flash bursting behind it.
import { ball, slab } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'alarm_light',
  glints: [[0.42, 0.42, 0.6]],
  inner: [0.42, 0.42, 0.3, 'warn', 0.3],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const burst = new THREE.Shape();
    const n = 8;
    for (let i = 0; i < n * 2; i++) {
      const a = Math.PI / 2 + i * Math.PI / n;
      const r = i % 2 ? 0.86 : 1.42;
      if (i === 0) burst.moveTo(Math.cos(a) * r, Math.sin(a) * r); else burst.lineTo(Math.cos(a) * r, Math.sin(a) * r);
    }
    burst.closePath();
    const flash = slab(S, burst, 0.4, 'warn', 'cream', 0.12);
    flash.position.z = -0.4;
    flash.rotation.z = 0.2;
    const g = new THREE.Group();
    const almond = new THREE.Shape();
    almond.moveTo(-1.0, 0);
    almond.quadraticCurveTo(0, 1.1, 1.0, 0);
    almond.quadraticCurveTo(0, -1.1, -1.0, 0);
    const lid = slab(S, almond, 0.6, 'alarm', 'alarm_light', 0.2);
    const white = ball(S, 0.6, 'paper', 'cream');
    white.scale.set(1.18, 0.82, 0.5);
    white.position.z = 0.16;
    const iris = ball(S, 0.36, 'time', 'time_light');
    iris.scale.z = 0.45;
    iris.position.set(0.04, 0.0, 0.36);
    const pupil = ball(S, 0.17, 'ink_deep', 'time_light');
    pupil.scale.z = 0.4;
    pupil.position.set(0.05, 0.0, 0.5);
    g.add(lid, white, iris, pupil);
    g.rotation.set(0.1, 0.25, 0);
    g.position.set(0, -0.02, 0.1);
    scene.add(flash, g);
    return scene;
  },
};
