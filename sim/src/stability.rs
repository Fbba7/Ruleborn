//! §5.5's stability, priced once (TD.14): the universe's capacity, each
//! woven law's cost with every term §5.5 and §8 give it, the chords that
//! sound and their draw, and the strain and its band. The server charges
//! what this prices, through the WebAssembly (`ffi::rb_stability`), and the
//! client shows what this prices, through the extension, so the two never
//! disagree by a point.
//!
//! "Cost of a law = base cost × tier (1.0, 1.3 or 1.6) × 2 if crowned × 0.8
//! in a realm of its school × 0.85 for each harmony × 0.8 for each signature
//! resonance × 0.9 in a chord × 1.25 for a dissonance". How each term counts
//! is §5.5's own paragraph, the reading v3.7 wrote for C48:
//!
//! * a harmony "counts once per shared note": a law pays 0.85 once for each
//!   of its notes another law in the realm also carries;
//! * a dissonance likewise: 1.25 once for each of its notes whose opposite
//!   another law in the realm carries (§8.3, "raises both laws' cost");
//! * a signature resonance "stacks like a harmony's": 0.8 for each one the
//!   law is in;
//! * a chord: 0.9 for each sounding chord one of whose notes the law carries
//!   (§8.5: "lowers the cost of all three laws by 10%") — the laws carrying
//!   its notes, which are the three when no fourth carries one, the case
//!   the document prices;
//! * "a crown law is priced once, by the Heart's laws and its own crowning":
//!   in the Heart's company, where no school discounts it, and crown laws
//!   count in every realm's company (§8.2).
//!
//! An era's price changes are applied here too (§18.3): Heavy Stars' Motion
//! laws at 30% less, High Tide's Slow rivers at nothing.
//!
//! "A chord sounds only while woven laws and every sounding chord's draw
//! together stay within capacity" (§8.6): chords are taken in the realms'
//! order and the chord table's, each sounding if it keeps the total within
//! capacity with the ones before it. An undiscovered chord still sounds and
//! is priced (§5.5); naming it is the Lab's.
//!
//! In integers, as the whole crate is (§24.10): a cost is kept in millionths
//! of a point. Each factor is applied as its exact ratio to a value held in
//! millionths of a millionth, truncating, and the result is rounded half up
//! to millionths — the same digits on every processor, and within a
//! millionth of the exact product, which every price in the document is
//! (§8.5's example comes out at 6.8, 8.67 and 11.968 exactly).

use crate::combos::carried_by_three;
use crate::era::Era;
use crate::laws_table::{note, Chord, CHORDS, LAWS, RESONANCES};

/// §5.5: "Keeper's Spire (30 + 8 × Spire level) + every Anchor Stone (8 + 5
/// × its level), raised 8% for each epoch after the first".
pub const SPIRE_STABILITY: (u32, u32) = (30, 8);
pub const ANCHOR_STABILITY: (u32, u32) = (8, 5);
pub const EPOCH_CAPACITY_RAISE: (u32, u32) = (8, 100);
/// §5.5's factors, as ratios.
pub const TIER_COST: [(u32, u32); 3] = [(10, 10), (13, 10), (16, 10)];
pub const CROWN_COST: (u32, u32) = (2, 1);
pub const OWN_SCHOOL_COST: (u32, u32) = (8, 10);
pub const HARMONY_COST: (u32, u32) = (85, 100);
pub const RESONANCE_COST: (u32, u32) = (8, 10);
pub const CHORD_COST: (u32, u32) = (9, 10);
pub const DISSONANCE_COST: (u32, u32) = (125, 100);
/// §8.5: a sounding chord's draw.
pub const CHORD_DRAW: u32 = 192;
/// §5.5's bands from Steady on, where each starts, in percent of capacity.
pub const STRAIN_BANDS: [u32; 6] = [40, 70, 90, 100, 110, 125];
/// §7.4's schools, in the order the wire names them.
pub const SCHOOLS: [&str; 6] = ["Motion", "Matter", "Time", "Energy", "Life", "Spirit"];

/// A point, in the millionths every cost is kept in.
pub const POINT: u64 = 1_000_000;
/// The finer unit factors are applied in, millionths of a millionth.
const FINE: u128 = 1_000_000_000_000;

/// The Heart's realm index, and the crown's.
pub const HEART: u8 = 0;
pub const CROWN: u8 = 255;

/// One woven law: its row in `LAWS`, its tier (1 to 3), and its realm — the
/// Heart 0, outer realms by their index, the crown `CROWN`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Woven {
    pub law: usize,
    pub tier: u8,
    pub realm: u8,
}

/// What a woven law costs, in millionths of a point, and why: how many of
/// each term it pays, and which notes harmonise and which clash, as bits of
/// `note`.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Line {
    pub cost: u64,
    pub harmonies: u8,
    pub resonances: u8,
    pub chords: u8,
    pub dissonances: u8,
    pub harmony_notes: u8,
    pub dissonance_notes: u8,
}

/// The universe priced: each woven law's line in the order given, the
/// chords that sound, their draw, the total and the capacity (millionths of
/// a point), strain in millionths of capacity, and the band (0 Quiet to 6
/// Breaking).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Priced {
    pub lines: Vec<Line>,
    pub chords: Vec<(u8, Chord)>,
    pub draw: u64,
    pub total: u64,
    pub capacity: u64,
    pub strain: u64,
    pub band: u8,
}

fn times(v: u128, (n, d): (u32, u32)) -> u128 {
    v * n as u128 / d as u128
}

/// §5.5's capacity, in millionths of a point.
pub fn capacity(spire: u8, anchors: &[u8], epoch: u8) -> u64 {
    let base = SPIRE_STABILITY.0 + SPIRE_STABILITY.1 * spire as u32
        + anchors.iter().map(|&l| ANCHOR_STABILITY.0 + ANCHOR_STABILITY.1 * l as u32).sum::<u32>();
    let raise = EPOCH_CAPACITY_RAISE.1 + EPOCH_CAPACITY_RAISE.0 * epoch.saturating_sub(1) as u32;
    base as u64 * POINT * raise as u64 / EPOCH_CAPACITY_RAISE.1 as u64
}

/// §5.5's band for `total` against `capacity`, 0 Quiet to 6 Breaking.
pub fn band(total: u64, capacity: u64) -> u8 {
    STRAIN_BANDS.iter().filter(|&&b| total as u128 * 100 >= b as u128 * capacity as u128).count() as u8
}

/// The realm whose company prices `w`: the Heart's for a crown law.
fn home(w: &Woven) -> u8 {
    if w.realm == CROWN { HEART } else { w.realm }
}

/// The laws in realm `r`'s company: its own and the crown's.
fn company(laws: &[Woven], r: u8) -> Vec<usize> {
    (0..laws.len()).filter(|&i| laws[i].realm == r || laws[i].realm == CROWN).collect()
}

/// The realms with laws, in order, the Heart first.
fn realms(laws: &[Woven]) -> Vec<u8> {
    let mut out: Vec<u8> = laws.iter().map(home).collect();
    out.sort_unstable();
    out.dedup();
    out
}

/// Each law's line, given the chords that sound.
fn lines(laws: &[Woven], schools: &[Option<&str>], era: Option<Era>, sounding: &[(u8, Chord)]) -> Vec<Line> {
    laws.iter().enumerate().map(|(i, w)| {
        let law = &LAWS[w.law];
        let r = home(w);
        let others: Vec<usize> = company(laws, r).into_iter().filter(|&j| j != i).collect();
        let carried = |n: u8| others.iter().any(|&j| LAWS[laws[j].law].notes & n != 0);
        let mut line = Line::default();
        for bit in 0..8 {
            let n = 1u8 << bit;
            if law.notes & n == 0 {
                continue;
            }
            if carried(n) {
                line.harmonies += 1;
                line.harmony_notes |= n;
            }
            let opposite = note::OPPOSITES.iter()
                .find_map(|&(a, b)| if a == n { Some(b) } else if b == n { Some(a) } else { None });
            if opposite.is_some_and(carried) {
                line.dissonances += 1;
                line.dissonance_notes |= n;
            }
        }
        line.resonances = RESONANCES.iter().filter(|(_, a, b)| {
            let other = if *a == law.id { *b } else if *b == law.id { *a } else { return false };
            others.iter().any(|&j| LAWS[laws[j].law].id == other)
        }).count() as u8;
        line.chords = sounding.iter().filter(|(realm, c)| {
            *realm == r && CHORDS.iter().any(|(k, notes)| k == c && law.notes & notes != 0)
        }).count() as u8;
        let mut v = law.cost as u128 * FINE;
        v = times(v, TIER_COST[(w.tier.clamp(1, 3) - 1) as usize]);
        if w.realm == CROWN {
            v = times(v, CROWN_COST);
        } else if schools.get(r as usize).copied().flatten() == Some(law.school) {
            v = times(v, OWN_SCHOOL_COST);
        }
        match era {
            Some(Era::HeavyStars) if law.school == "Motion" => {
                v = times(v, ((100 - Era::HeavyStars.figure()) as u32, 100));
            }
            Some(Era::HighTide) if law.id == "slow_rivers" => v = 0,
            _ => {}
        }
        for (count, factor) in [(line.harmonies, HARMONY_COST), (line.resonances, RESONANCE_COST),
                                (line.chords, CHORD_COST), (line.dissonances, DISSONANCE_COST)] {
            for _ in 0..count {
                v = times(v, factor);
            }
        }
        let unit = FINE / POINT as u128;
        line.cost = ((v + unit / 2) / unit) as u64;
        line
    }).collect()
}

fn total(lines: &[Line], chords: usize) -> u64 {
    lines.iter().map(|l| l.cost).sum::<u64>() + CHORD_DRAW as u64 * POINT * chords as u64
}

/// The universe priced. `schools[r]` is realm `r`'s school, the Heart's
/// `None`; `laws` everything woven, the crown's with realm `CROWN`;
/// `capacity` in millionths of a point.
pub fn price(laws: &[Woven], schools: &[Option<&str>], capacity: u64, era: Option<Era>) -> Priced {
    let mut sounding: Vec<(u8, Chord)> = Vec::new();
    for r in realms(laws) {
        let rows: Vec<usize> = company(laws, r).into_iter().map(|i| laws[i].law).collect();
        for &(c, notes) in CHORDS.iter() {
            if !carried_by_three(&rows, notes) {
                continue;
            }
            let mut with = sounding.clone();
            with.push((r, c));
            if total(&lines(laws, schools, era, &with), with.len()) <= capacity {
                sounding = with;
            }
        }
    }
    let lines = lines(laws, schools, era, &sounding);
    let draw = CHORD_DRAW as u64 * POINT * sounding.len() as u64;
    let total = total(&lines, sounding.len());
    let strain = if capacity > 0 { (total as u128 * POINT as u128 / capacity as u128) as u64 } else { 0 };
    Priced { lines, chords: sounding, draw, total, capacity, strain, band: band(total, capacity) }
}

/// A law's row in `LAWS`, by id.
pub fn law_row(id: &str) -> Option<usize> {
    LAWS.iter().position(|l| l.id == id)
}

/// The wire form `ffi::rb_stability` reads: Spire level u8, epoch u8, era
/// u8 (0 none), anchor count u8 and each Anchor Stone's level u8, realm
/// count u8 and each realm's school u8 (an index into `SCHOOLS`, 255 for
/// none: the Heart's), law count u8 and each law's row u8, tier u8 and realm
/// u8 (`CROWN` for the crown). Answered with `encode`; None if it does not
/// read.
pub fn decode(b: &[u8]) -> Option<(Vec<Woven>, Vec<Option<&'static str>>, u64, Option<Era>)> {
    let mut at = 0usize;
    let mut next = || -> Option<u8> {
        let v = *b.get(at)?;
        at += 1;
        Some(v)
    };
    let spire = next()?;
    let epoch = next()?;
    let era = Era::from_u8(next()?)?;
    let anchors: Vec<u8> = (0..next()?).map(|_| next()).collect::<Option<_>>()?;
    let schools: Vec<Option<&'static str>> = (0..next()?)
        .map(|_| next().map(|v| SCHOOLS.get(v as usize).copied()))
        .collect::<Option<_>>()?;
    let n = next()?;
    let mut laws = Vec::with_capacity(n as usize);
    for _ in 0..n {
        let (law, tier, realm) = (next()? as usize, next()?, next()?);
        if law >= LAWS.len() || !(1..=3).contains(&tier) {
            return None;
        }
        laws.push(Woven { law, tier, realm });
    }
    Some((laws, schools, capacity(spire, &anchors, epoch), era))
}

/// `Priced` on the wire: band u8, chord count u8 and each sounding chord's
/// realm u8 and row in `CHORDS` u8; capacity, draw, total and strain as u64,
/// little-endian; then each law's cost u64 and its harmonies, resonances,
/// chords, dissonances, harmonising notes and clashing notes, u8 each.
pub fn encode(p: &Priced) -> Vec<u8> {
    let mut out = vec![p.band, p.chords.len() as u8];
    for (realm, c) in &p.chords {
        out.push(*realm);
        out.push(CHORDS.iter().position(|(k, _)| k == c).unwrap_or(0) as u8);
    }
    for v in [p.capacity, p.draw, p.total, p.strain] {
        out.extend_from_slice(&v.to_le_bytes());
    }
    for l in &p.lines {
        out.extend_from_slice(&l.cost.to_le_bytes());
        out.extend_from_slice(&[l.harmonies, l.resonances, l.chords, l.dissonances, l.harmony_notes,
                                l.dissonance_notes]);
    }
    out
}

/// TD.14's gate, as cases the server's and the client's tests price again
/// through their own bindings and compare: every launch law alone in a realm
/// of its school and crowned, alone under each era that changes a price, and
/// every pair of them in one realm. Written to `sim/stability_cases.json` by
/// `STABILITY_CASES=write cargo test stability_cases`; each case is the wire
/// form `decode` reads, as numbers, and what `price` answers, in millionths.
pub fn cases() -> String {
    let launch: Vec<usize> = (0..LAWS.len()).filter(|&i| LAWS[i].launch).collect();
    let school = |i: usize| SCHOOLS.iter().position(|s| *s == LAWS[i].school).unwrap() as u8;
    // Spire 5 and two Anchor Stones at 3: 70 + 46 = 116.
    let head = |era: u8| vec![5u8, 1, era, 2, 3, 3];
    let mut wires: Vec<Vec<u8>> = Vec::new();
    for &i in &launch {
        let mut b = head(0);
        b.extend_from_slice(&[2, 255, school(i), 1, i as u8, 1, 1]);
        wires.push(b);
        let mut b = head(0);
        b.extend_from_slice(&[1, 255, 1, i as u8, 2, CROWN]);
        wires.push(b);
        for era in [Era::HeavyStars, Era::HighTide] {
            let mut b = head(era as u8);
            b.extend_from_slice(&[2, 255, 255, 1, i as u8, 3, 1]);
            wires.push(b);
        }
    }
    for (x, &a) in launch.iter().enumerate() {
        for &b2 in &launch[x + 1..] {
            let mut b = head(0);
            b.extend_from_slice(&[2, 255, 255, 2, a as u8, 1, 1, b2 as u8, 1, 1]);
            wires.push(b);
        }
    }
    let rows: Vec<String> = wires.iter().map(|wire| {
        let (laws, schools, cap, era) = decode(wire).expect("a case reads");
        let p = price(&laws, &schools, cap, era);
        let costs: Vec<String> = p.lines.iter().map(|l| l.cost.to_string()).collect();
        let nums: Vec<String> = wire.iter().map(|v| v.to_string()).collect();
        format!("  {{\"wire\": [{}], \"costs\": [{}], \"total\": {}, \"band\": {}}}",
                nums.join(", "), costs.join(", "), p.total, p.band)
    }).collect();
    let ids: Vec<String> = LAWS.iter().map(|l| format!("\"{}\"", l.id)).collect();
    format!("{{\n \"_what\": \"TD.14's cases, costs in millionths of a point: sim/src/stability.rs writes them; \
             server/test/stability.test.mjs and client/tests/stability_tests.gd price each again and must agree\",\n \
             \"laws\": [{}],\n \"cases\": [\n{}\n ]\n}}\n",
            ids.join(", "), rows.join(",\n"))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn w(id: &str, tier: u8, realm: u8) -> Woven {
        Woven { law: law_row(id).unwrap(), tier, realm }
    }

    /// `points` whole and `millionths` more.
    fn pts(points: u64, millionths: u64) -> u64 {
        points * POINT + millionths
    }

    #[test]
    fn capacity_is_5_5s_spire_and_anchor_stones() {
        // §8.5's day 41: Spire 5, and five Anchor Stones at 5, 5, 4, 4 and 3.
        assert_eq!(capacity(5, &[5, 5, 4, 4, 3], 1), pts(215, 0));
        // §5.5's maximum: "a Spire at level 10 and seven Anchor Stones at
        // level 10 give 516 stability", and 8% more an epoch on.
        assert_eq!(capacity(10, &[10; 7], 1), pts(516, 0));
        assert_eq!(capacity(10, &[10; 7], 2), pts(557, 280_000));
    }

    /// §8.5's worked example: "Slow rivers and Thorns woven in the Heart with
    /// Bloom crowned, completing Deep sleep. Two harmonies and two signature
    /// resonances cut it and the crown doubles Bloom: 6.8 + 8.67 + 11.97 =
    /// 27.44", and at 215 the chord cannot sound: "24.69 + 192 = 216.69
    /// against 215".
    #[test]
    fn the_cheapest_chord_is_priced_as_8_5_prices_it() {
        let laws = [w("slow_rivers", 1, HEART), w("thorns", 1, HEART), w("bloom", 1, CROWN)];
        let p = price(&laws, &[None], capacity(5, &[5, 5, 4, 4, 3], 1), None);
        assert!(p.chords.is_empty(), "within 215 the chord stays silent");
        let costs: Vec<u64> = p.lines.iter().map(|l| l.cost).collect();
        assert_eq!(costs, vec![pts(6, 800_000), pts(8, 670_000), pts(11, 968_000)]);
        assert_eq!(p.total, pts(27, 438_000));
        assert_eq!((p.lines[1].harmonies, p.lines[1].resonances), (2, 1), "Thorns shares Weight and Bloom");
        assert_eq!(p.lines[1].harmony_notes, note::WEIGHT | note::BLOOM);
        assert_eq!((p.lines[2].harmonies, p.lines[2].resonances), (1, 2), "Bloom: Mangrove banks and Briar maze");
        let sounding = price(&laws, &[None], pts(217, 0), None);
        assert_eq!(sounding.chords.len(), 1, "at 217 it sounds: 0.9 × 27.44 + 192 = 216.69");
        assert_eq!(sounding.total, pts(216, 694_200));
        assert!(sounding.lines.iter().all(|l| l.chords == 1));
    }

    #[test]
    fn a_harmony_counts_once_per_shared_note() {
        // Three laws on Flow (Bounce, Half gravity, Tilt): each pays 0.85 once.
        let three = price(&[w("bounce", 1, 1), w("half_gravity", 1, 1), w("tilt", 1, 1)], &[None, None],
                          u64::MAX / 200, None);
        assert!(three.lines.iter().all(|l| l.harmonies == 1));
        assert_eq!(three.lines[1].cost, pts(10, 200_000), "12 × 0.85");
        // Two laws sharing two notes pay it twice: the first such pair in the
        // table.
        let pair = (0..LAWS.len()).flat_map(|a| (a + 1..LAWS.len()).map(move |b| (a, b)))
            .find(|&(a, b)| (LAWS[a].notes & LAWS[b].notes).count_ones() == 2)
            .expect("two laws that share two notes");
        let two = price(&[Woven { law: pair.0, tier: 1, realm: 1 }, Woven { law: pair.1, tier: 1, realm: 1 }],
                        &[None, None], u64::MAX / 200, None);
        assert_eq!((two.lines[0].harmonies, two.lines[1].harmonies), (2, 2), "{pair:?}");
    }

    #[test]
    fn tier_crown_school_dissonance_and_eras_price_as_5_5_and_18_3_say() {
        let alone = |id: &str, tier: u8, realm: u8, schools: &[Option<&str>], era| {
            price(&[w(id, tier, realm)], schools, u64::MAX / 200, era).lines[0].cost
        };
        assert_eq!(alone("half_gravity", 1, 1, &[None, Some("Motion")], None), pts(9, 600_000), "its school");
        assert_eq!(alone("half_gravity", 3, 1, &[None, None], None), pts(19, 200_000), "tier III");
        assert_eq!(alone("half_gravity", 2, CROWN, &[None], None), pts(31, 200_000), "crowned, no school");
        assert_eq!(alone("half_gravity", 1, 1, &[None, None], Some(Era::HeavyStars)), pts(8, 400_000));
        assert_eq!(alone("slow_rivers", 1, 1, &[None, None], Some(Era::HighTide)), 0);
        // Flow against Weight: Half gravity and Slow rivers clash, 1.25 each.
        let clash = price(&[w("half_gravity", 1, 1), w("slow_rivers", 1, 1)], &[None, None], u64::MAX / 200, None);
        assert!(clash.lines.iter().all(|l| l.dissonances == 1));
        assert_eq!(clash.lines[0].dissonance_notes, note::FLOW);
        assert_eq!(clash.lines[1].cost, pts(12, 500_000));
    }

    #[test]
    fn strain_falls_in_5_5s_seven_bands() {
        let c = pts(100, 0);
        let bands: Vec<u8> = [0, 39, 40, 70, 90, 99, 100, 110, 124, 125, 200].iter().map(|&s| band(pts(s, 0), c)).collect();
        assert_eq!(bands, vec![0, 0, 1, 2, 3, 3, 4, 5, 5, 6, 6]);
        let p = price(&[w("half_gravity", 1, 1)], &[None, None], pts(24, 0), None);
        assert_eq!((p.strain, p.band), (POINT / 2, 1));
    }

    #[test]
    fn stability_cases_match_the_file() {
        let path = concat!(env!("CARGO_MANIFEST_DIR"), "/stability_cases.json");
        let text = cases();
        if std::env::var("STABILITY_CASES").as_deref() == Ok("write") {
            std::fs::write(path, &text).unwrap();
        }
        let kept = std::fs::read_to_string(path).unwrap_or_default();
        assert!(kept == text, "sim/stability_cases.json differs: STABILITY_CASES=write cargo test stability_cases");
    }

    #[test]
    fn the_wire_reads_back() {
        let wire = [5u8, 1, 0, 2, 3, 3, 2, 255, 2, 2, law_row("slow_rivers").unwrap() as u8, 1, 1,
                    law_row("tidemark").unwrap() as u8, 2, CROWN];
        let (laws, schools, cap, era) = decode(&wire).unwrap();
        assert_eq!(laws.len(), 2);
        assert_eq!(schools, vec![None, Some("Time")]);
        assert_eq!((cap, era), (pts(116, 0), None));
        let out = encode(&price(&laws, &schools, cap, era));
        assert_eq!(out.len(), 2 + 32 + 14 * 2);
        assert!(decode(&wire[..wire.len() - 1]).is_none(), "a short wire does not read");
    }
}
