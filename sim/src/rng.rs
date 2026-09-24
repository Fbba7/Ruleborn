//! Randomness. §24.7: "A 64-bit heist seed expanded through SplitMix64 into
//! xoshiro256++, with a separate stream per subsystem. Both are pure integer
//! operations, identical on every machine."
//!
//! Two properties matter here and neither is statistical quality:
//!
//! 1. **The same sequence on every target.** Wrapping `u64` arithmetic, xor and
//!    rotate are defined identically by the language. Nothing here consults a
//!    clock, an address, or the operating system.
//!
//! 2. **A separate stream per subsystem.** If perception and movement drew from
//!    one stream, adding a single perception roll would shift every later
//!    movement roll, and a replay recorded before the change would diverge for
//!    a reason that has nothing to do with the change. Streams make each
//!    subsystem's draws independent of how many draws the others made.

/// SplitMix64, used only to expand one seed into the four words xoshiro needs.
/// §24.7 names it for exactly this.
pub struct SplitMix64(pub u64);

impl SplitMix64 {
    pub fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
        z ^ (z >> 31)
    }
}

/// Which subsystem a stream belongs to. Adding a variant is safe; reordering
/// or renumbering one changes every seed derived from it, so the numbers are
/// written out rather than left to the compiler.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
#[repr(u64)]
pub enum Stream {
    /// Retired, like Noise: §12.17 says "nothing here is random". The spike
    /// drew suspicion jitter and a guard's turning direction from these two,
    /// and both contradicted it.
    Perception = 1,
    Movement = 2,
    /// Retired: §12.17's noise has no dice in it. The number stays taken, so
    /// no later stream can reuse it and silently share a seed with old replays.
    Noise = 3,
    Loot = 4,
    /// §8's effects that the document makes unpredictable: gusts, flicker,
    /// déjà vu, fair lights and quicksand. Drawn only while one sounds, in a
    /// fixed order within the tick, so a realm without them draws nothing.
    Laws = 5,
}

/// xoshiro256++ 1.0. Pure integer operations.
#[derive(Clone, Debug)]
pub struct Rng {
    s: [u64; 4],
}

impl Rng {
    /// One stream of one heist. The stream id is mixed into the seed before
    /// expansion so that two streams of the same heist share no state.
    pub fn new(heist_seed: u64, stream: Stream) -> Rng {
        let mut sm = SplitMix64(heist_seed ^ (stream as u64).wrapping_mul(0x9E37_79B9_7F4A_7C15));
        let s = [sm.next(), sm.next(), sm.next(), sm.next()];
        // All-zero state is the one state xoshiro cannot leave. SplitMix64
        // reaching it is astronomically unlikely and not impossible, and "very
        // unlikely" is not a property a deterministic core should rely on.
        if s == [0, 0, 0, 0] {
            return Rng { s: [1, 2, 3, 4] };
        }
        Rng { s }
    }

    pub fn next_u64(&mut self) -> u64 {
        let result = self.s[0]
            .wrapping_add(self.s[3])
            .rotate_left(23)
            .wrapping_add(self.s[0]);
        let t = self.s[1] << 17;
        self.s[2] ^= self.s[0];
        self.s[3] ^= self.s[1];
        self.s[1] ^= self.s[2];
        self.s[0] ^= self.s[3];
        self.s[2] ^= t;
        self.s[3] = self.s[3].rotate_left(45);
        result
    }

    /// A number in `0..n`, without modulo bias.
    ///
    /// The rejection loop matters for determinism as well as for fairness: a
    /// biased `% n` would still be deterministic, but Lemire's method without
    /// the correction consumes a variable number of draws depending on the
    /// value, and the corrected version consumes the same number for the same
    /// sequence on every target. This one is plain rejection, which is easier
    /// to read and just as portable.
    pub fn below(&mut self, n: u64) -> u64 {
        debug_assert!(n > 0, "below(0) has no answer");
        if n.is_power_of_two() {
            return self.next_u64() & (n - 1);
        }
        let limit = u64::MAX - (u64::MAX % n) - 1;
        loop {
            let x = self.next_u64();
            if x <= limit {
                return x % n;
            }
        }
    }
}
