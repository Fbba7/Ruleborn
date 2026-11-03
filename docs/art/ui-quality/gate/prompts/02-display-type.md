# Judge prompt: 2. Display type

Rubric version 2 (`../rubric.md`, quality 2). The launcher fills the
`{{...}}` fields and sends everything below the line as one isolated call. The
call is made three times, with the pictures in a new shuffled order each time.

---

You are the gate's judge for Ruleborn's interface. You answer one question
about one quality, **Display type**, for one item. You have read-only tools. You
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

**The question.** On Display type alone, is the CANDIDATE at least as good as the
PASS ANCHOR?

**What Display type means here.**

Words and numbers on art read as part of the game: heavy, inked and
sized to be read at a glance.

Pass needs, of what a picture can show:
- every word over art (a scene, a texture, a gradient) has a dark ink outline
  all round, at least 1.5 pt or 12% of its size wide;
- big numbers have a hard drop and a gradient fill as well as the outline;
- headers and numbers of the same rank share one heavy treatment across the
  screen.

Fails on:
- any word over art without an outline, or an outline that breaks, thins or
  merges into the art behind it;
- a drop shadow standing in for an outline (a drop shadow does not count);
- a header or number style that differs from the others of its rank.

**Look at:** the full-resolution crops of headers and numbers only, one per text
rank. Body text on a plain card is not over art and needs no outline.

**Already measured, so do not judge it:** which font each label uses (labels and changing numbers are meant
to be Manrope with tabular figures, so do not fail a label for not being a
heavy display face), text sizes, opacity and the secondary-text colour.

**Do not judge anything else.** Other qualities have their own calls. A
candidate that is weak on layout, colour or anything outside this quality
still passes this call if it holds up on Display type. You are not asked to find
problems; you are asked one comparison.

**Traps:**
- The design asks for Manrope on labels and changing numbers, with an
  outline. A stroked Manrope label passes this quality; an unstroked heavy
  face over art fails it.
- Words on a solid plate or card are not over art. Words straight over the
  world or a textured image are.
- At 200% text, check that the outline scaled with the word.

**Rulings from calibration (version 2):**
- Over art means over the world, a scene, or a textured surface (wood grain,
  pebbled leather, stone). A word on a card, a plate or a button, including
  over that card's own gloss band or body gradient, is not over art and needs
  no outline. In high contrast, words on solid plates need none either.
- Big numbers are the screen's headline figures: a timer, a reward total, the
  currency counts on home. They need the outline, the hard drop and the
  gradient fill wherever they sit, on a plate too; a plain flat headline
  figure fails. Secondary figures (a +46 beside the total, a 3 / 4 count on a
  card) are a lower rank and follow the label rule.
- Text that is clipped or overlapped by an icon, so that a word or number
  loses glyphs, fails.

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
{"quality": "Display type", "item": "{{item}}", "answer": "pass | fail | unknown", "region": "<where on the CANDIDATE, in words: e.g. 'top-right loot panel'>", "reason": "<one line, naming what you compared>"}
```
