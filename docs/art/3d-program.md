# The 3D program: every 3D screen and every launch character

The owner's bar: better than Clash of Clans, and at least three times better than the Screens v3 design. Today's client draws the world in 3D, but at placeholder quality: a chibi stand-in for every character, box-and-ball features, and a flat island. This program replaces all of it with the design's own sculpts, kit and diorama, carried into Godot and then pushed past them.

Work is split into tracks, each run by an agent on its own branch, merged into `claude/videogame-project-analysis-ewkkk2` by the integrator. The third wave adds two interface tracks (T9, T10): the owner judged the game about halfway to the quality wanted in its interface and design, and Screens v3's design system had not yet reached the client.

## What "done" looks like

- Every character in §21.9's launch list is the design's sculpt, rigged and animated in Godot: the 18 ruleborn, the 4 launch Sages, the 3 visitors and the 3 paradox-born. The three anomalies, the three law creatures and the seven realms' wildlife come from the same harness. Each has its forms (Hush, Spark, Echo) and its guard form. Each meets §21.3's budget: 3,000–6,000 triangles, and the Character screen uses the same model.
- Every screen that draws a realm draws it as the design's diorama: home and universe map, realm view, scout, defence curation, rehearsal, terrain editor (builder), planner, landing picker, heist, replay, result, observatory. Each draws the simulation's truth (`RulebornReplay`, 1 tile = 1 m) and nothing invented.
- Every still beats the matching design still in `art/design/stills/`, judged side by side at phone size and as a grayscale thumbnail (§21.10). The design's own 28 screens are rendered in `art/design/stills/screens/`.
- Every screen's interface is the design's own system (§21.8): its surfaces, typefaces, icons, components and motion, held to the measured rules.
- §21.3 holds on the phone renderer (Compatibility, `gl_compatibility`): a realm takes 25,000–40,000 triangles on the home camera and up to about 60,000 in a heist, with under 150 draw calls. There is no full-screen post-processing on the phone. Effects are particles, vertex animation and screen-space tints.

## The look (§21.1–21.3, the rule every track works to)

- **Style:** picture-book dioramas floating in a violet sky. Shapes are chunky, soft-edged and toy-like. Islands get warm light, with cool shadows beneath. Every animation carries gentle physical humour.
- **Silhouette first:** every character, building and law signature must read as a dark shape at 32 points tall.
- **Shading:** one toon look, from the design's diorama:
  - a four-step ramp [62, 140, 215, 255];
  - +10% saturation;
  - shadows tinted toward violet;
  - a soft rim light;
  - 1.5-pixel ink outlines (`#1A0C14`) in screen space, already in `client/world/outline.gdshader`.
- **Character outlines conflict between sources.** Character bodies keep the sculpt's painted vertex colour with its baked occlusion, lit by the same ramp. The design's handoff notes say the owner had the character outline removed, but §21.3 asks for one. Make it one constant, default it to §21.3, and record the choice in the track notes.
- **Colour and texture:**
  - school colours and neutrals from §21.2 (`client/scripts/palette.gd`), with realm palettes in §21.4;
  - hand-painted gradient textures only, never photographic;
  - everything generated in code (§21.11): meshes, shaders and palettes. The design's modules are code, so exporting them keeps to this.
- **Scale:** one tile is one metre. Ruleborn stand 0.5–1.4 m, Sages about 1.5 m, buildings 2–6 m. A realm is 10–14 tiles across, with a rim of cliffs and hanging roots.
- **Cameras:**
  - home: orthographic, 35° pitch, turned in 90° steps, three zooms;
  - heist: a closer follow camera at 50° showing about 12 tiles across;
  - a one-second swoop between realms.

## Sources

- `art/design/`: the design's own sculpt and rig modules, the diorama, and the target stills (see its README).
- `docs/analysis/screens-v3/3d-pipeline.md`: everything measured, how each piece reaches Godot, the traps, and the budgets.
- `docs/analysis/screens-v3/handoff/source/CHARACTERS.md`: the roster and what each module exports.
- The design document (`docs/design/ruleborn-game-design-v3.7.txt`): §21.1–21.12 (art), §21.6 (each kind's look, height and forms), §21.4 (realms), §21.5 (buildings and their four levels), §21.7 (laws on screen), §21.12 (guard sight).

## Seeing your work

- `bash tools/render/shoot.sh <shot script> <out.png> [W H]` renders a still from the real client under Xvfb, using Mesa and the Compatibility renderer. It runs a `--import` first, so new `class_name`s resolve.
- Shot scripts live in `client/tests/shots/`. `world_shot.gd` is a heist on a dressed island. `heist_shot.gd` is the whole heist screen. Add one per screen and per character turntable.
- Every round, compare your still with the design's. Put both side by side, at phone size and in grayscale. Write down what is worse and fix that first.
- Commit the stills you judge by to `docs/art/shots/<track>/` as PNGs under 400 KB, so the owner can see progress on the branch.

## Rules every track keeps

- Stay inside your track's files (table below). If you need a change in another track's file, make the smallest possible hook and say so in your notes. The integrator merges.
- The client's rules hold:
  - GDScript warnings are errors: type every variable and loop iterator, and shadow nothing.
  - gdlint must pass, including class-definitions order and at most 20 public methods per class.
  - `class_name`s must not form load cycles between static initialisers, which hangs the load.
- The 3D draws only what `RulebornReplay`, `RulebornIsland` and the screens' state give it. A rule the simulation decides is never decided again in the client.
- Each track writes `docs/art/tracks/<track>.md`: what was done, the stills, what is still worse than the design, and the next steps.
- Before the final push, `bash tools/check_all.sh` must print "All checks passed". Push to your track branch only. Never push to the main development branch.

## Tracks

| Track | Branch | Owns (new files allowed under these) | Delivers |
|---|---|---|---|
| T1 Characters (continued from wave 2 on `claude/3d-characters-2`) | `claude/3d-characters` | `tools/art/`, `client/art/creatures/`, `client/world/creature*.gd`, `client/world/creature*.gdshader`, `client/tests/shots/creature_*.gd`, `client/tests/creature_tests.gd` | The export harness: the design's modules, run headless, become `.glb` files with budgets enforced. All 43 characters are exported. A `CreatureModel` node plays clips by the design's names, and the creature material implements the ramp, rim, wrap, fur shells and glow. Turntables are compared with `stills/portraits`. |
| T2 Look | `claude/3d-look` | `client/world/world_look.gd`, `island_builder.gd`, `realm_palette.gd`, `sky.gdshader`, `toon*.gdshader*`, `outline.gdshader`, new `client/world/look_*.gd` | The island as in the diorama: a polar top with a noisy edge, painted grass, rim bands, a strata rock cone, hanging roots, fringes and vines. Scatter is MultiMesh grass, flowers and pebbles. The sky comes per realm and by the hour, with clouds. Per-realm light tables are added, with fog, a vignette as a screen-space tint, and shadows tuned. |
| T3 Kit | `claude/3d-kit` | `client/world/realm_kit.gd`, `building_kit.gd`, `piece_kit.gd`, `water.gdshader`, `geo.gd`, new `client/world/kit_*.gd` | All 39 terrain features with their realm variants and idle animations, and water and lava. The 17 buildings get §21.5's four levels from the diorama's `makeB2`/`makeB`, plus the Heart citadel and walls. The Vault, pylons and the 6 wards × 2 levels are included. Hero features are inked. |
| T4 Universe | `claude/3d-universe` | `client/world/universe_view.gd`, new `client/world/link_*.gd`, `skiff_*.gd`, `star*.gd`, `client/scripts/home.gd`, `universe_screen.gd`, `map_screen.gd`, `client/tests/shots/universe_*.gd` | The home and universe map as the design draws them. Islands hang in a vertical column over a galaxy sky. Links are drawn as stone bridge, rope bridge, chute and rift. Skiffs carry sails and trails. Pins are projected UI. The camera has the three zooms, and a cloud wipe runs between realms. |
| T5 Heist | `claude/3d-screens` | `client/world/world_view.gd`, `actor_builder.gd`, new `client/world/fx_*.gd`, `client/world/law_fx*.gd` (from wave 3), `client/scripts/heist_screen.gd`, `heist_hud.gd`, `replay_screen.gd`, `result_screen.gd` | The heist and replay as the deepest screens: world-anchored HUD (bars, pips, the VAULT tag, pop-up numbers), guard sight per §21.12, law effects for §21.7's launch laws, grabs, alarms, knock-outs and crossings, the follow camera with pinch, twist and tap zoom, and a game HUD per §21.8. |
| T6 Realm screens | `claude/3d-screens-world` | `client/scripts/realm_screen.gd`, `scout_screen.gd`, `curation_screen.gd`, `builder_screen.gd`, `planner_screen.gd`, `observatory_screen.gd`, `defences_screen.gd`, new `client/world/overlay_*.gd` and `stage_*.gd` | Every other screen that shows a realm, in 3D: the realm view with buildings and workers, the scout report, defence curation and rehearsal with the 9×9 overlay, the terrain editor, the planner and landing picker, and the Observatory's live island thumbnails. |
| T7 Character screens | `claude/3d-character-screens` | `client/scripts/character_screen.gd`, `roster_screen.gd`, `sage_hall_screen.gd`, `forms_screen.gd`, `hatch_screen.gd`, `first_screen.gd`, new `client/world/stage_hero*.gd` and `portrait*.gd` | A hero stage for one character (lit pedestal, turntable, actions), portraits rendered from the models for every card, and the Character screen, roster, Sage hall, Forms, Hatch and first launch as game UI around them, with T1's models merged in as they land. |
| T8 Law effects (retired after wave 2; its files pass to T5) | `claude/3d-law-fx` | `client/world/law_fx*.gd` | The 24 launch law signatures and those after launch, harmonies, dissonances, chords and paradoxes, gaits on T1's models, and the previews on the law card, Weaving and Harmony. |
| T9 UI kit | `claude/ui-kit` | `client/scripts/ui.gd`, `client/ui/**`, `tools/ui/`, `client/tests/ui_kit_tests.gd`, `client/tests/shots/ui_*.gd` | Screens v3's design system in Godot (§21.8): tokens, the `rb_box` shader and its materials, the three typefaces with a licence ledger, the theme, the icon set, the components (buttons, cards, sheets, headers, hub control, nav bar, pills, chips, badges, bars, banners, dialogs) and motion, with `UI.*` drawing the new look so every screen inherits it. |
| T10 Screens | `claude/ui-screens` | `client/scripts/` codex, lab, law, weaving, harmony, workshop, track, shop, settings, profile, share, social, friends and age screens, their presenters, `client/app/router.gd`, new `client/scripts/screen_*.gd`, `client/tests/shots/screen_*.gd` | Every menu and meta screen to the design's own layout on T9's kit, the nav bar and hubs, judged against `art/design/stills/screens/`. |
| T11 Sign-in | `claude/auth` | `server/src/tokens.mjs`, `server/src/auth*.mjs`, `server/src/googleapi.mjs`, the session parts of `server/src/http.mjs` and `server/src/service.mjs`, `client/features/auth/`, `client/scripts/auth_*.gd`, `docs/security/auth.md` | Signing in and out to market-standard security: platform proofs, short-lived access tokens with rotating refresh, sign-out everywhere, and the account panel in Settings. |
| T12 Security review | `claude/security-review` | `docs/security/review.md`, `server/test/security_*.test.mjs` | An adversarial review of the whole app, each finding pinned by a test, fixed in place when small and sent to its owner otherwise. |
| Integrator | `claude/videogame-project-analysis-ewkkk2` | everything else | Merges the tracks, swaps T1's creatures into T5's actors, runs the checks, and keeps the audit and roadmap current. |

A second wave follows the first merge. It covers characters in every screen (crew, guards, workers, Sages in the Sage hall), forms and the guard form, the Character screen hero view, portraits rendered from the models, the rest of the screens, performance, and an adversarial art review against the design stills.
