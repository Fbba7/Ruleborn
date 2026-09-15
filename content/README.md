# Content tables

The laws, notes, resonances, chords, terrain features and ruleborn from the
design document, as structured data. §24 says content should live in data tables
so balance ships without an app update; these are the first of them.

```bash
python3 tools/extract_content.py    # regenerate from the design document
python3 tools/validate_content.py   # schema + cross-reference checks
```

| File | Entries | Source |
| --- | --- | --- |
| `notes.json` | 8 | §8.1 |
| `laws.json` | 48 | §7.7, the full sheets |
| `resonances.json` | 44 | §8.4 |
| `chords.json` | 12 | §8.5 |
| `terrain.json` | 39 | §6.2 |
| `ruleborn.json` | 18 | §11.11, cross-checked against §11.2 |

## Two rules

**Extraction only.** Nothing in `extract_content.py` invents or corrects a value.
Where the document contradicts itself, both readings are kept and the entry is
marked `needs_decision` with the audit register id — so the conflict is visible
in the data rather than silently resolved by whichever section parsed last. Every
ruleborn carries a `conflict_severity` of `role` (material: three creatures) or
`wording` (fifteen more).

**The document is the input, never the output.** When a contradiction is settled,
the fix belongs in the design document; re-running the extractor reproduces it.
Do not hand-edit these files.

## What the validator checks

It separates **errors** (malformed data — always a bug, non-zero exit) from
**open** items (known contradictions, each tagged with its register id, expected
until the document is reconciled).

Errors include: counts against §26.1's launch table; every required law field
present; notes drawn from the eight and never paired with their own opposite;
note opposition symmetric in both directions; resonances referencing two real,
distinct laws with no pair duplicated; **declared shared notes actually shared by
the two laws**; chords carrying three distinct, non-opposite notes; terrain
unlock counts matching §6.3's own table; three ruleborn per school.

## What this confirmed about the document

Worth recording, because the analysis is otherwise mostly critical. The content
layer is in better shape than the prose:

- All 44 hand-authored resonances declare shared notes that **exactly** match the
  notes their two laws carry. Zero errors across 44 entries.
- Every one of the 48 laws appears in at least one resonance — no orphans.
- All 48 movement signatures and all 48 world signatures are distinct.
- No law lacks a weakness, and no weakness is reused — §7.7 says "a law without a
  weakness is not shipped", and that standard is met.
- Every law has both a raider use and a defender use — §7.7's "a law that cannot
  be used by both sides is not finished" is met too.
- §6.3's terrain unlock table reconciles exactly with §6.2's 39 features.
- Chord note demand is deliberately even (each note 4 or 5 times across 12).

The faults the validator finds are all in the places the document specified
something twice, or claimed something the content does not deliver — never in the
content's internal craft.
