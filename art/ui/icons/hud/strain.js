// Strain: how hard the woven laws pull on the realm (§5.5). A gold gauge,
// its cream dial banded from the strain bands' calm to breaking colours,
// the ink needle pushed into the red, and a dark crack across the glass.
import { rod, ball, box } from '../studio/shapes.js';

const BANDS = ['band_quiet', 'band_steady', 'band_humming', 'band_brimming', 'band_strained', 'band_breaking'];

export default {
  families: ['icons_48'],
  light: 'alarm_light',
  glints: [[0.36, 0.34, 0.6]],
  inner: [0.42, 0.42, 0.3, 'alarm_light', 0.25],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const body = new THREE.Mesh(new THREE.CylinderGeometry(1.05, 1.05, 0.32, 72), S.toon('gold', 'gold_top'));
    body.rotation.x = Math.PI / 2;
    const face = new THREE.Mesh(new THREE.CylinderGeometry(0.88, 0.88, 0.34, 72), S.toon('paper', 'cream', 0.3));
    face.rotation.x = Math.PI / 2;
    g.add(body, face);
    const span = Math.PI * 1.3;
    const start = Math.PI / 2 + span / 2;
    BANDS.forEach((b, i) => {
      const arc = new THREE.Mesh(new THREE.TorusGeometry(0.64, 0.14, 12, 24, span / BANDS.length), S.toon(b, 'cream', 0.3));
      arc.rotation.z = start - (i + 1) * span / BANDS.length;
      arc.position.z = 0.18;
      g.add(arc);
    });
    const needle = box(S, 0.13, 0.86, 0.06, 0.05, 'ink_deep', 'alarm_light');
    const at = start - span * 0.92;
    needle.position.set(Math.cos(at) * 0.36, Math.sin(at) * 0.36, 0.26);
    needle.rotation.z = at - Math.PI / 2;
    const hub = ball(S, 0.14, 'ink_deep', 'alarm_light');
    hub.position.z = 0.27;
    g.add(needle, hub);
    const zig = [[-0.84, 0.02], [-0.56, -0.12], [-0.5, -0.34], [-0.24, -0.46], [-0.18, -0.68], [0.04, -0.82]];
    for (let k = 1; k < zig.length; k++) {
      g.add(rod(S, [...zig[k - 1], 0.3], [...zig[k], 0.3], 0.04, 'ink_line', 'alarm_light'));
    }
    // A pressure gauge's stem and nut below, and a puff of steam venting
    // from the top right: the strain is past what the realm holds.
    const stem = box(S, 0.34, 0.42, 0.3, 0.06, 'gold_bottom', 'gold_top');
    stem.position.y = -1.18;
    const nut = box(S, 0.62, 0.22, 0.4, 0.06, 'gold', 'gold_top');
    nut.position.y = -1.36;
    g.add(stem, nut);
    for (const [x, y, r] of [[0.86, 0.84, 0.24], [1.12, 1.06, 0.2], [0.82, 1.14, 0.17]]) {
      const puff = ball(S, r, 'paper', 'alarm_light');
      puff.position.set(x, y, 0.1);
      g.add(puff);
    }
    g.rotation.set(-0.08, 0.3, 0);
    g.scale.setScalar(0.94);
    g.position.set(-0.08, 0.1, 0);
    scene.add(g);
    return scene;
  },
};
