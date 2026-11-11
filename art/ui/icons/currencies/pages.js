// Pages: codex pages, the currency of what the player has learned. Three
// loose parchment sheets fanned in a stack; the top one carries a gold
// star seal and three lines of writing, with a violet ribbon marker.
import { box, rod, slab, star5Shape } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'motion_light',
  glints: [[0.33, 0.24, 0.6]],
  inner: [0.44, 0.36, 0.3, 'parchment_top', 0.3],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const sheets = [['gold_bottom', 0.3, 0.2, -0.14], ['parchment_bottom', 0.12, 0.08, -0.04], ['parchment_top', -0.08, -0.06, 0.04]];
    sheets.forEach(([face, turn, x, y], i) => {
      const sheet = box(S, 1.62, 2.1, 0.16, 0.07, face, 'cream');
      sheet.material = S.toon(face, 'cream', 0.25);
      sheet.rotation.z = -turn;
      sheet.position.set(x, y, i * 0.2);
      g.add(sheet);
    });
    const top = new THREE.Group();
    top.rotation.z = 0.08;
    top.position.set(-0.06, 0.04, 0.5);
    const seal = slab(S, star5Shape(S, 0.34, 0.16), 0.3, 'gold', 'gold_top', 0.14);
    seal.position.set(0, 0.48, 0.02);
    top.add(seal);
    [[-0.08, 0.52], [-0.34, 0.52], [-0.6, 0.34]].forEach(([y, half]) => {
      top.add(rod(S, [-half, y, 0], [half, y, 0], 0.055, 'parchment_text_3', 'cream'));
    });
    const marker = new THREE.Shape();
    marker.moveTo(-0.15, 0.3); marker.lineTo(0.15, 0.3); marker.lineTo(0.15, -0.42); marker.lineTo(0, -0.28); marker.lineTo(-0.15, -0.42);
    marker.closePath();
    const tag = slab(S, marker, 0.3, 'matter', 'matter_light', 0.1);
    tag.position.set(0.5, -0.98, 0.04);
    top.add(tag);
    g.add(top);
    g.rotation.set(-0.2, 0.32, 0);
    g.position.set(-0.04, 0.04, 0);
    scene.add(g);
    return scene;
  },
};
