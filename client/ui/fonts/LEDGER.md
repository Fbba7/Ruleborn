# Font licence ledger

§21.11: fonts come from outside the game only under the Open Font Licence, which permits embedding them in an application. Each family below is shipped whole, as its upstream publishes it, with its own licence text beside it. §21.8 names the three faces and what each carries.

| File | Family | What it carries (§21.8) | Licence | Source | SHA-256 |
|---|---|---|---|---|---|
| `manrope/Manrope-Variable.ttf` | Manrope, variable weight 200–800 | labels, body text and every number that changes (tabular figures, `tnum`); a weight of 900 is drawn at 800 | SIL OFL 1.1 (`manrope/OFL.txt`) | https://github.com/google/fonts/tree/main/ofl/manrope | `3ae11c49db0455a3cc33e37d380f20fdb8c7f8b41dc07625c177e3d87a9d6ae6` |
| `lilita_one/LilitaOne-Regular.ttf` | Lilita One | large numbers that do not change, and some titles (no tabular figures) | SIL OFL 1.1, Reserved Font Name "Lilita" (`lilita_one/OFL.txt`) | https://github.com/google/fonts/tree/main/ofl/lilitaone | `f5b641c45c69d772ee4eda687bc9fda411d5cad6b0b45371491da4580cbc8d59` |
| `marcellus/Marcellus-Regular.ttf` | Marcellus | titles and law names | SIL OFL 1.1, Reserved Font Name "Marcellus" (`marcellus/OFL.txt`) | https://github.com/google/fonts/tree/main/ofl/marcellus | `1cf0cd10b17d35e852729962cc1ffaffed94514895972458345e2df34abb2f81` |

The files are unmodified, so the Reserved Font Names may be kept. `client/world/fx_fonts/` holds Latin subsets of Manrope and Lilita One from the Screens v3 bundle, under the same licences (`OFL-manrope.txt`, `OFL-lilita-one.txt` there); the kit reads the full families here.

The settings' legal page should show these three licence texts. Anything the fonts lack falls back to the engine's own font.
