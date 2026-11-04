// Pip, the crew's skyskipper (motion school, "Carrier"), as a crew badge:
// a night-enamel toon disc (card_top) in a ring of the motion school's
// amber, and Pip's own toon render
// (renders/pip.png, client/tests/shots/icon_portraits.gd) standing in it,
// the head out over the ring's top so the badge reads by its silhouette.
const DISC = { y: -0.16, r: 1.12, ring: 0.12 };
// The render's place in the badge, as fractions of the side.
const PLACE = { x: 0.08, y: 0.07, side: 0.82 };

export default {
  families: ['icons_48'],
  light: 'motion_light',
  glints: [[0.34, 0.3, 0.6]],
  inner: [0.4, 0.34, 0.34, 'motion_light', 0.22],
  render: 'renders/pip.png',
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const disc = new THREE.Mesh(new THREE.CylinderGeometry(DISC.r, DISC.r, 0.16, 96), S.toon('card_top', 'motion_light'));
    disc.rotation.x = Math.PI / 2 - 0.12;
    disc.position.y = DISC.y;
    const ring = new THREE.Mesh(new THREE.TorusGeometry(DISC.r, DISC.ring, 32, 128), S.toon('motion', 'motion_light'));
    ring.rotation.x = -0.12;
    ring.position.set(0, DISC.y, 0.06);
    scene.add(disc, ring);
    return scene;
  },
  async draw(S, R) {
    const back = S.renderTo(this.build(S), R);
    const out = document.createElement('canvas');
    out.width = out.height = R;
    const x = out.getContext('2d');
    x.drawImage(back, 0, 0);
    const img = new Image();
    img.src = new URL(`../${this.render}`, import.meta.url).href;
    await img.decode();
    // The camera's half height at the badge's plane, in world units.
    const unit = (R / 2) / (7.8 * Math.tan(12 * Math.PI / 180));
    const cy = R / 2 - DISC.y * unit;
    const cr = (DISC.r - DISC.ring * 0.2) * unit;
    x.save();
    x.beginPath();
    x.arc(R / 2, cy, cr, 0, Math.PI);
    x.lineTo(R / 2 - cr, 0);
    x.lineTo(R / 2 + cr, 0);
    x.closePath();
    x.clip();
    x.drawImage(img, PLACE.x * R, PLACE.y * R, PLACE.side * R, PLACE.side * R);
    x.restore();
    return out;
  },
};
