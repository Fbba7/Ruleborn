// Vault progress: how far the crew is into the vault. A round stone vault
// door with a gold spoked handle wheel, inside a success green progress
// ring that runs three quarters round a dark track.
import { rod, ball, box } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'success_light',
  glints: [[0.36, 0.34, 0.6]],
  inner: [0.42, 0.42, 0.3, 'success_light', 0.25],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const track = new THREE.Mesh(new THREE.TorusGeometry(1.2, 0.13, 18, 96), S.toon('ink_deep', 'success_light', 0.3));
    const done = new THREE.Mesh(new THREE.TorusGeometry(1.2, 0.18, 20, 96, Math.PI * 1.5), S.toon('success', 'success_light'));
    done.rotation.z = Math.PI / 2;
    done.position.z = 0.02;
    const door = new THREE.Mesh(new THREE.CylinderGeometry(0.92, 0.92, 0.3, 72), S.toon('gravel', 'cream', 0.5));
    door.rotation.x = Math.PI / 2;
    const rim = new THREE.Mesh(new THREE.TorusGeometry(0.88, 0.09, 16, 72), S.toon('stone', 'cream', 0.5));
    rim.position.z = 0.15;
    const wheel = new THREE.Mesh(new THREE.TorusGeometry(0.56, 0.1, 16, 64), S.toon('gold', 'gold_top'));
    wheel.position.z = 0.3;
    g.add(track, done, door, rim, wheel);
    for (let i = 0; i < 3; i++) {
      const a = i * Math.PI / 3 + 0.3;
      g.add(rod(S, [Math.cos(a) * 0.5, Math.sin(a) * 0.6, 0.3], [-Math.cos(a) * 0.6, -Math.sin(a) * 0.6, 0.3], 0.07, 'gold', 'gold_top'));
    }
    const hub = ball(S, 0.2, 'gold_top', 'gold_top');
    hub.position.z = 0.34;
    g.add(hub);
    // The progress's leading end: a bright knob riding the ring, and the
    // door's two hinges standing out on the left, so the silhouette is not
    // a plain disc at 32 pt.
    const head = ball(S, 0.27, 'success_light', 'cream');
    head.position.set(Math.cos(Math.PI / 2 + Math.PI * 1.5) * 1.2, Math.sin(Math.PI / 2 + Math.PI * 1.5) * 1.2, 0.08);
    g.add(head);
    for (const y of [0.5, -0.5]) {
      const hinge = box(S, 0.62, 0.36, 0.32, 0.1, 'gravel', 'cream');
      hinge.position.set(-1.24, y, 0.04);
      g.add(hinge);
    }
    g.rotation.set(-0.12, 0.25, 0);
    g.position.x = 0.08;
    scene.add(g);
    return scene;
  },
};
