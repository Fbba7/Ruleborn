//! §8: what the laws in a realm do together. Harmonies (a shared note),
//! dissonances (opposite notes), signature resonances (two named laws) and
//! chords (three notes carried by three distinct laws).
//!
//! Worked out each tick from the laws whose pylons stand, by the laws phase,
//! so breaking a pylon silences everything its law was part of from the next
//! tick — the same rule as the law itself. What each one does is in `lib.rs`,
//! beside the system it changes; this module only says which ones sound.
//!
//! What they cost — a harmony's 15% off, a dissonance's 25% on, a resonance's
//! 20% off, a chord's 10% off and its draw — is the universe's stability,
//! which the economy settles when a realm is woven, not the heist. A chord
//! "sounds whenever three distinct laws in one realm carry its notes and the
//! universe can pay its draw" (§8.6); whether it can pay is the economy's to
//! check when the island is published, and the simulation plays what it is
//! given (G25).

use crate::laws_table::{note, Chord, Res, CHORDS, LAWS, RESONANCES};

/// Which combinations sound this tick.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Combos {
    /// Notes carried by two or more of the realm's laws.
    pub harmonies: u8,
    /// One bit per pair in `note::OPPOSITES`, in its order.
    pub dissonances: u8,
    /// One bit per `Res`.
    pub resonances: u64,
    /// One bit per `Chord`.
    pub chords: u16,
}

impl Combos {
    /// From the realm's standing laws, as rows of `LAWS`, in weaving order.
    pub fn of(laws: &[usize]) -> Combos {
        let mut out = Combos::default();
        for bit in 0..8 {
            let n = 1u8 << bit;
            if laws.iter().filter(|&&l| LAWS[l].notes & n != 0).count() >= 2 {
                out.harmonies |= n;
            }
        }
        for (i, &(a, b)) in note::OPPOSITES.iter().enumerate() {
            // Two different laws, one carrying each. No law carries two
            // opposite notes (§8.8), but the rule does not lean on that.
            let clash = laws.iter().enumerate().any(|(i1, &l1)| {
                LAWS[l1].notes & a != 0
                    && laws.iter().enumerate().any(|(i2, &l2)| i2 != i1 && LAWS[l2].notes & b != 0)
            });
            if clash {
                out.dissonances |= 1 << i;
            }
        }
        let has = |id: &str| laws.iter().any(|&l| LAWS[l].id == id);
        for &(r, a, b) in RESONANCES.iter() {
            if has(a) && has(b) {
                out.resonances |= 1 << r as u32;
            }
        }
        for &(c, notes) in CHORDS.iter() {
            if carried_by_three(laws, notes) {
                out.chords |= 1 << c as u32;
            }
        }
        out
    }

    pub fn harmony(&self, n: u8) -> bool {
        self.harmonies & n != 0
    }

    /// The dissonance between `a` and its opposite, whichever way round.
    pub fn dissonance(&self, a: u8) -> bool {
        note::OPPOSITES.iter().enumerate()
            .any(|(i, &(x, y))| (x == a || y == a) && self.dissonances & (1 << i) != 0)
    }

    pub fn resonance(&self, r: Res) -> bool {
        self.resonances & (1 << r as u32) != 0
    }

    pub fn chord(&self, c: Chord) -> bool {
        self.chords & (1 << c as u32) != 0
    }
}

/// §8.8: "a chord now requires three distinct laws contributing the three
/// notes" — three laws, each carrying a different one of the chord's notes.
/// A law with two of them still counts once.
fn carried_by_three(laws: &[usize], notes: u8) -> bool {
    let each: Vec<u8> = (0..8).map(|b| 1u8 << b).filter(|n| notes & n != 0).collect();
    if each.len() != 3 {
        return false;
    }
    let n = laws.len();
    for i in 0..n {
        for j in 0..n {
            for k in 0..n {
                if i == j || j == k || i == k {
                    continue;
                }
                let (a, b, c) = (LAWS[laws[i]].notes, LAWS[laws[j]].notes, LAWS[laws[k]].notes);
                if a & each[0] != 0 && b & each[1] != 0 && c & each[2] != 0 {
                    return true;
                }
            }
        }
    }
    false
}
