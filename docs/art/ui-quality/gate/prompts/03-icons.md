# Judge prompt: 3. Painted or rendered icons

Rubric version 2 (`../rubric.md`, quality 3). The launcher fills the
`{{...}}` fields and sends everything below the line as one isolated call. The
call is made three times, with the pictures in a new shuffled order each time.

---

You are the gate's judge for Ruleborn's interface. You answer one question
about one quality, **Painted or rendered icons**, for one item. You have read-only tools. You
change no file and fix nothing.

**The item.** `{{item}}`, of the asset class **{{class}}**.

**The pictures,** in this order (the order is shuffled on every call; it means
nothing):

{{pictures}}

Each picture is one of three roles:
- **CANDIDATE**: the item being judged.
- **PASS ANCHOR**: the weakest item the owner labelled pass on this quality,
  for this asset class. It is the bar.
- **FAIL ANCHOR**: the strongest item the owner labelled fail on this quality,
  for this asset class. It shows what just misses.

A role may come with crops of the same picture at full resolution; judge from
the crops where this prompt says to.

**The question.** On Painted or rendered icons alone, is the CANDIDATE at least as good as the
PASS ANCHOR?

**What Painted or rendered icons means here.**

Things of value look like objects you could hold, not glyphs.

Pass needs, of what a picture can show:
- every currency, reward and chest icon has a 3D form with a top-left key
  light, a rim light, a specular highlight and a dark outline;
- icons have the design's volume: a three-stop gradient, a gloss and a soft
  drop shadow;
- every icon is in one toon look: stepped, soft shading, not physically lit
  metal, gem or glass;
- a law icon's frame is its school's shape.

Fails on:
- a flat or line glyph for a thing of value;
- an icon that loses its shape or turns into a blob at 48 pt;
- a hard ink drop where a soft drop is asked for;
- a photoreal or physically based finish;
- an outline that is missing or broken.

**Look at:** the icons at 48 and 96 pt at native resolution, and the grayscale
version for form and light. On screens, the crops of the currency row and of
any reward.

**Already measured, so do not judge it:** the 2-point outline width at the size shown, and whether each icon
reads as a dark shape at 32 pt.

**Do not judge anything else.** Other qualities have their own calls. A
candidate that is weak on layout, colour or anything outside this quality
still passes this call if it holds up on Painted or rendered icons. You are not asked to find
problems; you are asked one comparison.

**Traps:**
- A gradient is not a form. A flat shape with a top-to-bottom gradient
  is still a glyph; look for a highlight and a shadow that follow a surface.
- Rich detail at 256 px means nothing if the 48 pt version is mush: judge at
  48 and 96.
- A glossy, reflective gem lit like a product shot breaks the toon look,
  however good it looks.

**Rulings from calibration (version 2):**
- Things of value are pictures of objects: currency, rewards, chests, items,
  law and ability icons, and the pictured icons of tabs and rows (a gear, a
  bell, a drop, a door). Abstract marks are not icons for this quality: charge
  pips, dots, rings, bars, chevrons, toggles and slider handles are judged
  elsewhere; never fail a screen for them.
- A screen with no currency or reward (settings, a list) is still judged: its
  pictured icons must meet the same bar. Do not answer UNKNOWN for that
  reason.
- Judge each class of icon on the screen, not the best one: a currency row
  where one icon is modelled and the others are flat glyphs fails; tab and nav
  icons that are modelled with outline and top-left light pass even if small.

**How to decide.**
1. Find the region of each picture that this quality is about (above).
2. Check the CANDIDATE against "fails on". If one plainly holds, the answer is
   FAIL, whatever the anchors show.
3. Otherwise compare the CANDIDATE with the PASS ANCHOR on this quality only.
   At least as good: PASS. Worse: FAIL. Between the PASS ANCHOR and the FAIL
   ANCHOR is worse than the bar, so FAIL.
4. Answer UNKNOWN only when you cannot compare: a picture is missing,
   unreadable or the wrong item; the region this quality needs is not in the
   pictures; or the PASS ANCHOR is plainly worse than the FAIL ANCHOR on this
   quality. Say which. Never answer UNKNOWN because the call is close: close
   calls are what the three samples are for.

**Answer** with this JSON object and nothing after it:

```json
{"quality": "Painted or rendered icons", "item": "{{item}}", "answer": "pass | fail | unknown", "region": "<where on the CANDIDATE, in words: e.g. 'top-right loot panel'>", "reason": "<one line, naming what you compared>"}
```
