# Roadmap

The page to check progress on: **https://claude.ai/artifact/Yb1WxZ2eJCCbByitnd7fJf**

`index.html` in this directory is generated. Do not edit it.

```bash
python3 tools/build_roadmap.py     # regenerate from tools/roadmap.py
```

## How to read it

Every stage lists what finishes it, who it is waiting on, and what to look at to
check the claim. Three things are deliberate:

**Progress is computed, not claimed.** A task that maps onto register items takes
its numbers from `tools/audit_register.py`. Nothing on the page says "80% done";
it says "7 of 9 drafted, 0 signed off", and the register decides both figures.

**Drafted is not signed off.** The two bars are different colours for that
reason. Everything produced so far is a proposal in this repository; the design
document itself is untouched, which is what task T1.6 is for. A roadmap that
counted drafting as progress would be measuring effort.

**"Waiting on you" is at the top.** The single most useful thing a roadmap can
tell you is which items nobody else can move — a recruitment drive, a sign-off,
a judgement about your own game.

## Where the statuses come from

| Status | Means |
| --- | --- |
| `done` | Finished and verified |
| `doing` | Under way now |
| `ready` | Nothing blocks it; it can start today |
| `blocked` | Waiting on another task on this page |
| `yours` | Waiting on you — a decision, a recruitment drive, a sign-off |

`build_roadmap.py` refuses to build a roadmap that contradicts itself: a task
cannot be `ready` while it waits on something unfinished, cannot be `blocked` by
nothing, and cannot be `waiting on you` while owned by anyone else.

## Its relationship to the rest

| | |
| --- | --- |
| `docs/analysis/07-recommended-next-steps.md` | The prose argument for this ordering, with the reasoning behind each stage |
| `docs/audit/` | The register the progress bars count |
| `docs/design/spec/` | The drafted resolutions that T1.4 signs off |
