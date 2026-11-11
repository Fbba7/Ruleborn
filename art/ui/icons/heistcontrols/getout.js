// Get out: the escape. A wooden door standing open on the dark of the
// vault, and the success green arrow leaving through it to the right.
import { box, slab, ball, arrowShape } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'success_light',
  glints: [[0.3, 0.26, 0.7], [0.78, 0.55, 0.5]],
  inner: [0.38, 0.36, 0.3, 'gold_top', 0.25],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const frame = box(S, 1.36, 2.1, 0.3, 0.12, 'wood', 'gold_top');
    frame.position.set(-0.42, 0.04, -0.2);
    const dark = box(S, 1.0, 1.78, 0.2, 0.08, 'ink_deep', 'matter_light');
    dark.position.set(-0.42, -0.02, -0.06);
    const hinge = new THREE.Group();
    hinge.position.set(-0.92, 0, 0.04);
    hinge.rotation.y = -0.95;
    const door = box(S, 0.96, 1.74, 0.16, 0.07, 'soil', 'gold_top');
    door.position.set(0.48, -0.02, 0);
    const knob = ball(S, 0.08, 'gold', 'gold_top');
    knob.position.set(0.82, -0.04, 0.12);
    hinge.add(door, knob);
    const arrow = slab(S, arrowShape(S, 1.5, 0.42, 0.98, 0.62), 1.1, 'success', 'success_light', 0.26);
    arrow.position.set(0.52, -0.3, 0.55);
    arrow.rotation.set(0.1, -0.25, 0);
    scene.add(frame, dark, hinge, arrow);
    return scene;
  },
};
