// The key frames' runtime: the mode from the address, the game's words from
// words.js, the numbers as the game writes them, the grain, and the realm
// pins kept clear of the interface. One CSS pixel is one point.
//
//   ?lang=en | pt_BR    the language (en by default)
//   ?text=200           the text at 200% (100 by default)
//   ?hc=1               the high-contrast mode
(() => {
  const q = new URLSearchParams(location.search);
  const lang = q.get('lang') === 'pt_BR' ? 'pt_BR' : 'en';
  const text = Number(q.get('text') || 100);
  const html = document.documentElement;
  html.lang = lang === 'pt_BR' ? 'pt-BR' : 'en';
  if (q.has('hc')) html.classList.add('hc');
  // Above SIDE_BY_SIDE_UP_TO (125) the game's bars go icon-only and the
  // heist's band stands on end (client/world/stage_hero_kit.gd).
  if (text > 125) html.classList.add('large');
  html.style.setProperty('--ts', String(text / 100));
  const W = window.WORDS[lang];

  // client/i18n: Strings.t's %s, %d, %02d and %%.
  const sprintf = (f, args) => {
    let i = 0;
    return f.replace(/%(0\d)?([sd%])/g, (_, w, c) => (c === '%' ? '%'
      : w ? String(args[i++]).padStart(Number(w.slice(1)), '0') : String(args[i++])));
  };
  // ShopPresenter.grouped and UniverseHud.compact.
  const grouped = (n) => {
    let d = String(Math.abs(Math.trunc(n))), out = '';
    while (d.length > 3) { out = W.NUMBER_GROUP + d.slice(-3) + out; d = d.slice(0, -3); }
    return (n < 0 ? '-' : '') + d + out;
  };
  const compact = (n, from = 10000) => {
    if (Math.abs(n) < from) return grouped(n);
    const big = Math.abs(n) >= 1000000;
    const tenths = Math.floor(Math.abs(n) / (big ? 100000 : 100));
    const t = (n < 0 ? '-' : '') + grouped(Math.floor(tenths / 10)) + W.NUMBER_DECIMAL + (tenths % 10);
    return sprintf(W[big ? 'HOME_AMOUNT_MILLIONS' : 'HOME_AMOUNT_THOUSANDS'], [t]);
  };
  // One argument: n:142050 grouped, c:142050 compact, c1000:3400 compact
  // from 1,000, k:KEY a word, d:24 a whole number, s:text as written.
  const arg = (a) => {
    const at = a.indexOf(':');
    const kind = a.slice(0, at), v = a.slice(at + 1);
    if (kind === 'n') return grouped(Number(v));
    if (kind.startsWith('c')) return compact(Number(v), kind.length > 1 ? Number(kind.slice(1)) : 10000);
    if (kind === 'k') return W[v];
    if (kind === 'd') return String(Math.trunc(Number(v)));
    return v;
  };
  const args = (el) => (el.dataset.args ? el.dataset.args.split('|').map(arg) : []);
  for (const el of document.querySelectorAll('[data-key]')) {
    if (!(el.dataset.key in W)) throw new Error(`no word ${el.dataset.key} in words.js`);
    el.textContent = sprintf(W[el.dataset.key], args(el));
  }
  for (const el of document.querySelectorAll('[data-num]')) el.textContent = arg(el.dataset.num);
  for (const el of document.querySelectorAll('[data-label]')) {
    if (!(el.dataset.label in W)) throw new Error(`no word ${el.dataset.label} in words.js`);
    el.setAttribute('aria-label', sprintf(W[el.dataset.label], args(el)));
  }

  // Grain, as on the board: noise as alpha, in one token colour.
  const grains = { leather: ['--c-drop', '0.55', 2, 11, '1.6 0 0 0 -0.62', 0.45],
    parchment: ['--c-soil', '0.012 0.11', 4, 5, '1.8 0 0 0 -0.75', 0.2],
    oak: ['--c-oak-grain', '0.015 0.42', 3, 7, '2.2 0 0 0 -0.85', 0.6] };
  const ns = 'http://www.w3.org/2000/svg';
  const defs = Object.entries(grains).map(([n, [c, f, o, s, m, a]]) =>
    `<filter id="grain-${n}" x="0" y="0" width="100%" height="100%" color-interpolation-filters="sRGB">`
    + `<feTurbulence type="fractalNoise" baseFrequency="${f}" numOctaves="${o}" seed="${s}"/>`
    + `<feColorMatrix type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  ${m}"/>`
    + `<feComponentTransfer result="noise"><feFuncA type="linear" slope="${a}"/></feComponentTransfer>`
    + `<feFlood style="flood-color: var(${c})" result="ink"/><feComposite in="ink" in2="noise" operator="in"/></filter>`).join('');
  document.body.insertAdjacentHTML('afterbegin', `<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>${defs}</defs></svg>`);
  for (const [n, [c]] of Object.entries(grains)) {
    for (const el of document.querySelectorAll(`.${n === 'oak' ? 'plaque' : n}`)) {
      const svg = document.createElementNS(ns, 'svg');
      svg.setAttribute('class', 'tex');
      svg.setAttribute('aria-hidden', 'true');
      svg.innerHTML = `<rect width="100%" height="100%" style="fill: var(${c})" filter="url(#grain-${n})"/>`;
      el.prepend(svg);
    }
  }

  // The realm pins stand where the game puts them (bake_home.gd PINS=1),
  // centred on their realm. Where large text makes one meet the interface
  // or another pin, it moves to the nearest clear place within 64 points, as
  // the game's labels give way; where none is that near, it keeps only its
  // level, as the game's pin does over a small island
  // (client/world/universe_pins.gd), and takes the nearest clear place. If
  // that leaves one with nowhere, every pin keeps only its level and they
  // stand on the even grid that holds the most, each in the free cell
  // nearest its realm.
  const settle = () => {
    const box = (el) => { const r = el.getBoundingClientRect(); return [r.left, r.top, r.right, r.bottom]; };
    const meets = (a, b) => a[0] < b[2] + 4 && b[0] < a[2] + 4 && a[1] < b[3] + 4 && b[1] < a[3] + 4;
    const hud = [...document.querySelectorAll('.hud, .hud .plate, .hud .badge')].map(box);
    const pins = [...document.querySelectorAll('.pin')];
    const at = (p) => p.dataset.at.split(',').map(Number);
    pins.sort((a, b) => at(a)[1] - at(b)[1]);
    const put = (p, b) => { p.style.left = `${b[0]}px`; p.style.top = `${b[1]}px`; };
    let taken = [...hud];
    const near = (p, cx, cy, most) => {
      const w = p.offsetWidth, h = p.offsetHeight;
      let best = null, far = most * most;
      for (let y = 44; y + h <= 811; y += 2) {
        for (let x = 8; x + w <= 382; x += 2) {
          const d = (x + w / 2 - cx) ** 2 + (y + h / 2 - cy) ** 2;
          if (d > far) continue;
          const b = [x, y, x + w, y + h];
          if (!taken.some((t) => meets(t, b))) { best = b; far = d; }
        }
      }
      return best;
    };
    let room = true;
    for (const p of pins) {
      const [cx, cy] = at(p);
      let best = near(p, cx, cy, 64);
      if (!best) { p.classList.add('small'); best = near(p, cx, cy, 2000); }
      if (!best) { room = false; break; }
      put(p, best);
      taken.push(best);
    }
    if (room) return;
    for (const p of pins) p.classList.add('small');
    const w = Math.max(...pins.map((p) => p.offsetWidth)) + 4, h = Math.max(...pins.map((p) => p.offsetHeight)) + 4;
    let cells = [];
    for (let oy = 0; oy < h; oy += 2) {
      for (let ox = 0; ox < w; ox += 2) {
        const free = [];
        for (let y = 44 + oy; y + h - 4 <= 811; y += h) {
          for (let x = 8 + ox; x + w - 4 <= 382; x += w) {
            const b = [x, y, x + w - 4, y + h - 4];
            if (!hud.some((t) => meets(t, b))) free.push(b);
          }
        }
        if (free.length > cells.length) cells = free;
      }
    }
    if (cells.length < pins.length) throw new Error(`room for ${cells.length} of ${pins.length} pins`);
    for (const p of pins) {
      const [cx, cy] = at(p);
      const d = (b) => ((b[0] + b[2]) / 2 - cx) ** 2 + ((b[1] + b[3]) / 2 - cy) ** 2;
      const i = cells.reduce((m, b, j) => (d(b) < d(cells[m]) ? j : m), 0);
      put(p, cells[i]);
      cells.splice(i, 1);
    }
  };
  // Every face loads, used or not, so the page is the same in every form.
  for (const f of document.fonts) f.load();
  document.fonts.ready.then(() => { settle(); html.dataset.ready = '1'; });
})();
