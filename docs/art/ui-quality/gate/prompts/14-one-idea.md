# Judge prompt: 14. One art-direction idea

Rubric version 3 (`../rubric.md`, quality 14). The launcher fills the
`{{...}}` fields and sends everything below the line as one isolated call. The
call is made three times, with the pictures in a new shuffled order each time.

---

You are the gate's judge for Ruleborn's interface. You answer one question
about one quality, **One art-direction idea**, for one item. You have read-only tools. You
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

**The question.** On One art-direction idea alone, is the CANDIDATE at least as good as the
PASS ANCHOR?

**What One art-direction idea means here.**

Every part of the interface follows from one idea: the game's
direction, picture-book dioramas floating in a violet sky, with chunky,
soft-edged, toy-like shapes, warm light and cool shadows, inked outlines and
one toon look (as the approved style board states it).

Pass needs, of what a picture can show:
- every component on the screen expresses that idea: frames, pills, buttons,
  icons and type look like they come from the same toy box as the islands;
- nothing reads as borrowed from another style.

Fails on:
- a screen where some components are toy-like and others are web or app
  chrome;
- a piece in a different idiom: a thin line icon, a glass card with blur, a
  photographic texture, a sci-fi glow;
- a screen that would not be recognised as this game with its world hidden.

**Look at:** the whole still at 960 px. Cover the world in your mind: does the
interface alone say which game this is?

**Already measured, so do not judge it:** nothing; this quality is judged whole.

**Do not judge anything else.** Other qualities have their own calls. A
candidate that is weak on layout, colour or anything outside this quality
still passes this call if it holds up on One art-direction idea. You are not asked to find
problems; you are asked one comparison.

**Traps:**
- Richness is not unity: a screen full of fine materials in three
  idioms fails.
- A plain screen can pass if every plain part is plain in the game's way
  (chunky, inked, soft-edged).
- Do not judge layout, colour roles or type sizes here; those are other
  calls.

**Rulings from calibration (version 2):**
- High contrast: opaque dark cards with a light outline about 3 pt wide are
  the game's own high-contrast form (§21.8), not app chrome. Judge a high-
  contrast still on its controls, icons and type.
- A plain card is not app chrome by itself. It fails only when drawn in
  another idiom: a hairline stroke with a blur, a stock toggle, a thin flat
  slider bar, a native list row.
- A screen laid out as a standard app list (rows of label with switch or
  slider) in the game's colours fails, even if its buttons are chunky.

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
{"quality": "One art-direction idea", "item": "{{item}}", "answer": "pass | fail | unknown", "region": "<where on the CANDIDATE, in words: e.g. 'top-right loot panel'>", "reason": "<one line, naming what you compared>"}
```
