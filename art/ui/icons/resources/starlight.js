// Starlight: building material from the Star Wells, struck in gold. The
// style board's hero (art/ui/board/studio.html), set 8% larger in its
// square: with the soft drop it must still cover a quarter of it at 32 pt.
export default {
  families: ['icons_48', 'icons_256'],
  light: 'starlight',
  glints: [[0.37, 0.31, 1], [0.69, 0.7, 0.5]],
  inner: [0.42, 0.36, 0.3, 'gold_top', 0.35],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const gold = S.toon('starlight', 'gold_top');
    const big = new THREE.Mesh(S.puffed(S.starShape(0.98, 0.2), 0.98), gold);
    big.rotation.set(-0.22, 0.38, 0.08);
    big.position.set(-0.2, 0.16, 0);
    const small = new THREE.Mesh(S.puffed(S.starShape(0.4, 0.08), 0.4), gold);
    small.rotation.set(0.2, -0.5, 0.3);
    small.position.set(0.86, -0.82, 0.4);
    scene.add(big, small);
    scene.scale.setScalar(1.08);
    return scene;
  },
};
