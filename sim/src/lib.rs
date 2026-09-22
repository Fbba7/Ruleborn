//! The heist simulation core. §24.7: "written once, in a library with no
//! engine dependencies, and both the phone and the server run that same
//! compiled logic."
//!
//! This is the determinism spike (T3.1), not the game. It implements enough of
//! a heist to exercise every operation that can diverge between targets —
//! fixed-point multiply and divide, square roots, trigonometry, a seeded
//! generator, and ordered iteration over entities — and produces a checksum
//! per tick. If two targets agree on the checksum after seven thousand ticks
//! of that, they agree on the arithmetic the real simulation is built from.
//!
//! What it deliberately does not do: render, allocate after set-up, read a
//! clock, consult the environment, or use a hash map. §24.10: "Iterating a map
//! in whatever order it happens to be in is one of the three classic causes of
//! divergence."
//!
//! The tick is six phases in the order §24.10 fixes:
//!
//!   inputs → laws → perception → movement → noise → states → checksum
//!
//! and the order is not a style choice. Perception before movement means a
//! guard sees where a raider *was* at the start of the tick, which is the same
//! on every machine; perception after movement would make the result depend on
//! which entity was updated first.

// `deny` rather than `forbid`, so that the one exception below can be written
// down and argued for instead of the ban being dropped quietly. There is
// exactly one, it is a symbol-name declaration rather than an operation, and
// nothing in the simulation itself is unsafe.
#![deny(unsafe_code)]

pub mod fixed;
pub mod replay;

#[cfg(test)]
mod tests;
pub mod rng;
pub mod trig;

use fixed::{Ang, Fx};
use replay::{Command, Heist, Kind};
use rng::{Rng, Stream};

/// §24.10: "Tick rate — 30 a second, fixed."
pub const TICKS_PER_SECOND: u32 = 30;

/// §12.17: "Each guard carries a suspicion value from 0 to 1000."
pub const SUSPICION_MAX: i32 = 1000;

/// §12.17's states, at the thresholds the document states.
pub const SUSPICIOUS_AT: i32 = 200;
pub const INVESTIGATING_AT: i32 = 600;
pub const ALERTED_AT: i32 = 1000;

/// A point, in tiles. §21.1: "One tile is one metre."
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct Point {
    pub x: Fx,
    pub y: Fx,
}

impl Point {
    /// Distance, via an integer square root of the fixed-point square.
    pub fn distance(self, other: Point) -> Fx {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        (dx.mul(dx) + dy.mul(dy)).sqrt()
    }

    /// The angle from self to other, as a fraction of a turn.
    ///
    /// Derived by bisection against the table rather than by an `atan2`,
    /// because there is no portable integer `atan2` and bisection over a
    /// monotone quarter is exact: at most sixteen comparisons, the same
    /// sixteen everywhere.
    pub fn bearing_to(self, other: Point) -> Ang {
        let dx = other.x - self.x;
        let dy = other.y - self.y;
        if dx.0 == 0 && dy.0 == 0 {
            return Ang::ZERO;
        }
        // Find the angle in 0..ANG_TURN whose (cos, sin) points the same way,
        // by bisecting on the sign of the cross product.
        let (mut lo, mut hi) = (0i32, fixed::ANG_TURN);
        for _ in 0..17 {
            let mid = lo + (hi - lo) / 2;
            let cross = trig::cos(Ang(mid)).mul(dy) - trig::sin(Ang(mid)).mul(dx);
            if cross.0 > 0 {
                lo = mid;
            } else {
                hi = mid;
            }
            if hi - lo <= 1 {
                break;
            }
        }
        Ang(lo)
    }
}

/// A guard. §12.17 gives each role a cone, three graded zones and a turn rate.
#[derive(Clone, Debug)]
pub struct Guard {
    pub id: u32,
    pub at: Point,
    pub facing: Ang,
    pub cone: Ang,
    pub near: Fx,
    pub mid: Fx,
    pub far: Fx,
    pub turn_per_tick: Ang,
    pub suspicion: i32,
}

/// A raider. Where it is going is set by a command, never stored in a replay:
/// §24.10's "commands, never state".
#[derive(Clone, Debug)]
pub struct Raider {
    pub id: u32,
    pub at: Point,
    pub speed: Fx,
    /// Where it was last told to go. `None` is standing still.
    pub going_to: Option<Point>,
    pub crouching: bool,
}

/// The whole simulated world. Vectors indexed by id, never a map.
#[derive(Clone, Debug)]
pub struct World {
    pub tick: u32,
    pub guards: Vec<Guard>,
    pub raiders: Vec<Raider>,
    pub alarm: i32,
    /// The input log, in tick order, and how far through it the tick loop is.
    /// Held rather than consumed, so the same log can be replayed again.
    commands: Vec<Command>,
    next_command: usize,
    perception: Rng,
    movement: Rng,
    noise: Rng,
}

impl World {
    /// The spike's fixture: five guards on §12.17's five role rows, three
    /// raiders on a route across them. Every number here is the document's.
    pub fn new(seed: u64, crew: u8, commands: Vec<Command>) -> World {
        debug_assert!(
            commands.windows(2).all(|w| w[0].tick <= w[1].tick),
            "the input log has to be in tick order or the inputs phase is not a phase");
        // role, cone°, near, mid, far (metres), turn °/tick — §12.17's table.
        let roles: [(i32, i32, i32, i32, i32, i32); 5] = [
            (0, 45, 2, 4, 6, 6),      // Scout
            (1, 40, 3, 6, 9, 3),      // Warden   (1.5/3/4.5, doubled below)
            (2, 35, 3, 5, 7, 8),      // Breaker  (1.5/2.5/3.5)
            (3, 30, 2, 4, 6, 4),      // Carrier  (1/2/3)
            (4, 40, 3, 5, 0, 4),      // Mender   (1.5/2.5, no far zone)
        ];
        let mut guards = Vec::with_capacity(5);
        for (i, (id, cone, near, mid, far, turn)) in roles.iter().enumerate() {
            guards.push(Guard {
                id: *id as u32,
                // Spread along a line, at half-metre spacing from the halved
                // zone figures above, so the fixture uses the document's
                // numbers without needing fractions in this table.
                at: Point {
                    x: Fx::from_int(4 + 5 * i as i32),
                    y: Fx::from_int(8),
                },
                facing: Ang::from_degrees(270),
                cone: Ang::from_degrees(*cone),
                near: Fx::from_ratio(*near as i64, 2),
                mid: Fx::from_ratio(*mid as i64, 2),
                far: Fx::from_ratio(*far as i64, 2),
                turn_per_tick: Ang::from_degrees(*turn),
                suspicion: 0,
            });
        }
        let mut raiders = Vec::with_capacity(crew as usize);
        for i in 0..crew as i32 {
            raiders.push(Raider {
                id: i as u32,
                at: Point { x: Fx::from_int(i), y: Fx::ZERO },
                // §12.18's walk is 3 tiles a second; per tick that is 1/10.
                speed: Fx::from_ratio(1, 10),
                going_to: None,
                crouching: false,
            });
        }
        World {
            tick: 0,
            guards,
            raiders,
            alarm: 0,
            commands,
            next_command: 0,
            perception: Rng::new(seed, Stream::Perception),
            movement: Rng::new(seed, Stream::Movement),
            noise: Rng::new(seed, Stream::Noise),
        }
    }

    /// One tick, in §24.10's six phases. Returns the checksum after it.
    pub fn step(&mut self) -> u64 {
        self.phase_inputs();
        self.phase_laws();
        self.phase_perception();
        self.phase_movement();
        self.phase_noise();
        self.phase_states();
        self.tick += 1;
        self.checksum()
    }

    /// Inputs. §24.10 puts this phase first, and first is the point: every
    /// command for this tick is applied before anything reads the world, so
    /// no part of the tick sees a half-applied input.
    fn phase_inputs(&mut self) {
        while self.next_command < self.commands.len()
            && self.commands[self.next_command].tick == self.tick
        {
            let command = self.commands[self.next_command];
            self.next_command += 1;
            let Some(raider) = self.raiders.get_mut(command.actor as usize) else {
                continue;                 // a command for a crew member who is
                                          // not here is dropped, not fatal: the
                                          // server re-simulates untrusted logs
            };
            match command.kind {
                Kind::MoveTo => {
                    let (x, y) = command.target();
                    raider.going_to = Some(Point { x, y });
                }
                Kind::Crouch => raider.crouching = command.x != 0,
                Kind::Halt => raider.going_to = None,
            }
        }
    }

    /// Laws. The spike carries one: a realm law that slows everything by a
    /// tenth every other second, which is enough to put a fixed-point multiply
    /// on the hot path where a law would be.
    fn phase_laws(&mut self) {
        if self.tick % (TICKS_PER_SECOND * 2) != 0 {
            return;
        }
        let slow = Fx::from_ratio(9, 10);
        for raider in self.raiders.iter_mut() {
            raider.speed = raider.speed.mul(slow);
            // A floor, so the law cannot drive speed to zero over a long run
            // and make the rest of the tick trivial.
            if raider.speed < Fx::from_ratio(1, 100) {
                raider.speed = Fx::from_ratio(1, 10);
            }
        }
    }

    /// Perception. §12.17: three graded zones inside a cone, filling at
    /// different rates; crouching halves how fast you are noticed.
    fn phase_perception(&mut self) {
        for gi in 0..self.guards.len() {
            let mut gain = 0i32;
            for ri in 0..self.raiders.len() {
                let guard = &self.guards[gi];
                let raider = &self.raiders[ri];
                let d = guard.at.distance(raider.at);
                if guard.far.0 > 0 && d > guard.far {
                    continue;
                }
                if d > guard.mid && guard.far.0 == 0 {
                    continue;
                }
                let bearing = guard.at.bearing_to(raider.at);
                let off = bearing.delta(guard.facing).0.abs();
                if off > guard.cone.0 / 2 {
                    continue;
                }
                // §12.17: near fills in about half a second, mid in about a
                // second, far in just under three. At 30 ticks a second that
                // is 67, 33 and 12 suspicion a tick.
                let per_tick = if d <= guard.near {
                    67
                } else if d <= guard.mid {
                    33
                } else {
                    12
                };
                let halved = if raider.crouching { per_tick / 2 } else { per_tick };
                gain += halved;
            }
            // One draw a tick whether or not anything was seen, so the stream
            // advances at the same rate regardless of the world's state. A
            // stream that advances only on some ticks makes every later draw
            // depend on the whole history, which is a needless coupling.
            let jitter = (self.perception.below(3) as i32) - 1;
            let guard = &mut self.guards[gi];
            if gain > 0 {
                guard.suspicion = (guard.suspicion + gain + jitter).min(SUSPICION_MAX);
            } else {
                // §12.17: "It empties more slowly than it fills — about 1.7
                // seconds" — 1000 / 51 ticks.
                guard.suspicion = (guard.suspicion - 20).max(0);
            }
        }
    }

    /// Movement. Raiders walk their route; guards sweep their cone.
    fn phase_movement(&mut self) {
        for raider in self.raiders.iter_mut() {
            let Some(target) = raider.going_to else { continue };
            let d = raider.at.distance(target);
            if d <= raider.speed {
                raider.at = target;
                raider.going_to = None;   // arrived; the next command decides
                continue;
            }
            let bearing = raider.at.bearing_to(target);
            raider.at = Point {
                x: raider.at.x + trig::cos(bearing).mul(raider.speed),
                y: raider.at.y + trig::sin(bearing).mul(raider.speed),
            };
        }
        let sweep = (self.movement.below(2) as i32) * 2 - 1;   // -1 or +1
        for guard in self.guards.iter_mut() {
            guard.facing = Ang(guard.facing.0 + guard.turn_per_tick.0 * sweep).wrapped();
        }
    }

    /// Noise. §12.17 makes ground type and gait audible; the spike draws one
    /// value a tick and adds it to the nearest guard, which is enough to put
    /// the stream and the ordering on the hot path.
    fn phase_noise(&mut self) {
        let loud = self.noise.below(100) < 10;
        if !loud || self.raiders.is_empty() {
            return;
        }
        let source = self.raiders[(self.tick as usize) % self.raiders.len()].at;
        // Nearest by distance, ties broken by id: §24.10's "entities by
        // number" is what makes a tie resolve the same way everywhere.
        let mut best: Option<(Fx, usize)> = None;
        for (i, guard) in self.guards.iter().enumerate() {
            let d = guard.at.distance(source);
            match best {
                Some((bd, _)) if bd <= d => {}
                _ => best = Some((d, i)),
            }
        }
        if let Some((_, i)) = best {
            self.guards[i].suspicion = (self.guards[i].suspicion + 40).min(SUSPICION_MAX);
        }
    }

    /// States. The realm alarm climbs when any guard is alerted.
    fn phase_states(&mut self) {
        let alerted = self.guards.iter().filter(|g| g.suspicion >= ALERTED_AT).count();
        if alerted > 0 {
            self.alarm = (self.alarm + alerted as i32).min(6 * 30);
        } else if self.tick % TICKS_PER_SECOND == 0 {
            self.alarm = (self.alarm - 1).max(0);
        }
    }

    /// §24.10: "Checksums — every tick in memory, one a second kept."
    ///
    /// FNV-1a over every field that decides an outcome, in id order. A hash
    /// with a fixed basis and prime is the same on every target; the point is
    /// not cryptographic strength but that two machines mixing the same bytes
    /// in the same order get the same answer.
    pub fn checksum(&self) -> u64 {
        let mut h: u64 = 0xcbf2_9ce4_8422_2325;
        let mut mix = |value: i64| {
            for byte in value.to_le_bytes() {
                h ^= byte as u64;
                h = h.wrapping_mul(0x0000_0100_0000_01b3);
            }
        };
        mix(self.tick as i64);
        mix(self.alarm as i64);
        for guard in self.guards.iter() {
            mix(guard.id as i64);
            mix(guard.at.x.0);
            mix(guard.at.y.0);
            mix(guard.facing.0 as i64);
            mix(guard.suspicion as i64);
        }
        for raider in self.raiders.iter() {
            mix(raider.id as i64);
            mix(raider.at.x.0);
            mix(raider.at.y.0);
            mix(raider.speed.0);
            mix(raider.going_to.map_or(0, |p| p.x.0));
            mix(raider.going_to.map_or(0, |p| p.y.0));
            mix(raider.crouching as i64);
        }
        h
    }
}

/// Run a heist and return the per-second checksums, which is what §24.10 says
/// is kept: "every tick in memory, one a second kept".
pub fn run(heist: &Heist) -> Vec<u64> {
    let mut world = World::new(heist.seed, heist.crew, heist.commands.clone());
    let mut kept = Vec::with_capacity((heist.ticks / TICKS_PER_SECOND) as usize + 1);
    for _ in 0..heist.ticks {
        let sum = world.step();
        if world.tick % TICKS_PER_SECOND == 0 {
            kept.push(sum);
        }
    }
    kept
}

/// Re-simulate a heist and check it against the checksums it carries.
///
/// This is what the server does with a replay, and §24.10 says what a
/// mismatch buys: "the first mismatched second narrows a divergence to thirty
/// ticks". So the answer is not a boolean \u2014 it is *which second*.
pub fn verify(heist: &Heist) -> Result<(), usize> {
    let kept = run(heist);
    for (i, expected) in heist.checksums.iter().enumerate() {
        match kept.get(i) {
            Some(actual) if truncate(*actual) == *expected => {}
            _ => return Err(i + 1),        // seconds are one-based for a human
        }
    }
    Ok(())
}

/// The low bytes of a checksum, which is what a replay stores. `replay.rs`
/// says why it is not all eight.
pub fn truncate(sum: u64) -> u32 {
    sum as u32
}

/// The one number two targets have to agree on: a hash over every kept sum.
pub fn digest(heist: &Heist) -> u64 {
    let mut h: u64 = 0xcbf2_9ce4_8422_2325;
    for sum in run(heist) {
        for byte in sum.to_le_bytes() {
            h ^= byte as u64;
            h = h.wrapping_mul(0x0000_0100_0000_01b3);
        }
    }
    h
}

/// A heist built from a seed alone, for the cross-target spike.
///
/// The commands are drawn from the seed rather than played by a person: the
/// spike needs an input log long enough to matter and identical on every
/// target, and a recorded session would do the same job without being
/// reproducible from eight bytes. §12.6 budgets 15 to 25 decisions in a run,
/// so this draws in that range and spreads them across the ticks.
pub fn fixture(seed: u64, ticks: u32, crew: u8) -> Heist {
    let mut rng = Rng::new(seed, Stream::Loot);
    let decisions = 15 + rng.below(11) as u32;      // 15 to 25, §12.6
    let mut commands = Vec::with_capacity(decisions as usize * 2);
    for i in 0..decisions {
        let tick = (ticks / decisions) * i + (rng.below(20) as u32);
        let actor = rng.below(crew as u64) as u8;
        commands.push(Command {
            tick,
            actor,
            kind: Kind::MoveTo,
            x: rng.below(24 * 256) as i16,
            y: rng.below(14 * 256) as i16,
        });
        if rng.below(3) == 0 {
            commands.push(Command {
                tick, actor, kind: Kind::Crouch,
                x: rng.below(2) as i16, y: 0,
            });
        }
    }
    commands.sort_by_key(|c| (c.tick, c.actor, c.kind as u8));

    let mut heist = Heist {
        seed,
        // The island and the rule set stand in for §24.8's content hashes.
        // What matters for the spike is that they are pinned and travel with
        // the replay (§24.11), not what they are digests of.
        island: digest_bytes(seed, 0x15_1A_4D),
        rules: digest_bytes(seed, 0x2D_1E_5F),
        ticks, crew, commands,
        checksums: Vec::new(),
    };
    heist.checksums = run(&heist).iter().map(|s| truncate(*s)).collect();
    heist
}

fn digest_bytes(seed: u64, salt: u64) -> [u8; 32] {
    let mut out = [0u8; 32];
    let mut rng = Rng::new(seed ^ salt, Stream::Loot);
    for chunk in out.chunks_mut(8) {
        chunk.copy_from_slice(&rng.next_u64().to_le_bytes());
    }
    out
}

// --------------------------------------------------------------------------
// The WebAssembly surface. §24.7: the same library, compiled for the server.
// --------------------------------------------------------------------------

/// Exported to WebAssembly so the server can run the identical logic. No
/// allocator crossing the boundary, no strings: one call in, one number out.
///
/// The `unsafe` is the export itself: Rust requires it because two libraries
/// could claim the same symbol, and the linker's behaviour would then be
/// undefined. It is a declaration about a name, not an operation on memory,
/// and it is the only one in the crate.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_digest(seed_hi: u32, seed_lo: u32, ticks: u32) -> u64 {
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    digest(&fixture(seed, ticks, 3))
}
