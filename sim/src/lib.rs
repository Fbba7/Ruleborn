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

// `deny` rather than `forbid`, so that the exceptions can be written down and
// argued for instead of the ban being dropped quietly. They are all in
// `ffi.rs`, each is a symbol-name declaration on an export rather than an
// operation, and nothing in the simulation itself is unsafe.
#![deny(unsafe_code)]

pub mod combos;
pub mod era;
pub mod events;
pub mod ffi;
pub mod fixed;
pub mod grid;
pub mod guard;
pub mod heist;
pub mod island;
pub mod laws_table;
pub mod noise;
pub mod path;
pub mod reference;
pub mod replay;
pub mod ruleborn;
pub mod sha256;
pub mod sight;
pub mod stability;

#[cfg(test)]
mod tests;
pub mod rng;
pub mod trig;
pub mod universe;

use fixed::{Ang, Fx};
use grid::{Feature, Grid};
use heist::{Grade, Outcome, Skiff, Standing, Task, Vault, Ward, WardKind};
use combos::Combos;
use laws_table::{note, Chord, Param, Res, LAWS, PARAM_COUNT};
use ruleborn::{Ability, Power, RULEBORN, SAGES};
use events::{Back, Cause, Event, Hurt, Log};

/// The laws the fixture's realm is woven with: three, the most §5.2 allows at
/// realm level 5, all three whole-parameter laws so every effect is one the
/// simulation applies. With their pylons.
pub const FIXTURE_LAWS: [(&str, (u16, u16)); 3] = [
    ("haste", (1, 3)),
    ("brittle_stone", (5, 10)),
    ("glowing_dark", (12, 8)),
];

/// The fixture realm's wards: one of each of §10.3's six, in the south half
/// where the planned heist does not go, so the seeded heists meet them and
/// the planned one is unchanged. Six of the eight §5.2 allows at realm 5.
pub const FIXTURE_WARDS: [(WardKind, (u16, u16)); 6] = [
    (WardKind::TimeSnare, (3, 9)),
    (WardKind::GravityWell, (9, 10)),
    (WardKind::StaticCoil, (1, 12)),
    (WardKind::LanternGlare, (6, 11)),
    (WardKind::CrystalWall, (8, 11)),
    (WardKind::ThornHedge, (4, 11)),
];

/// A realm's rule sheet for one tick: every parameter as an exact ratio, the
/// product of the unbroken laws that set it. §7.3: "laws change a realm's rule
/// sheet rather than containing special cases".
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Sheet {
    factors: [(i64, i64); PARAM_COUNT],
    set: [bool; PARAM_COUNT],
}

impl Sheet {
    pub fn plain() -> Sheet {
        Sheet { factors: [(1, 1); PARAM_COUNT], set: [false; PARAM_COUNT] }
    }

    /// A parameter as (numerator, denominator); (1, 1) if no law sets it.
    pub fn factor(&self, p: Param) -> (i64, i64) {
        self.factors[p as usize]
    }

    /// A flag's value if a law sets it. §7.3 flags are set, not multiplied.
    pub fn flag(&self, p: Param) -> Option<i64> {
        self.set[p as usize].then(|| self.factors[p as usize].0 / self.factors[p as usize].1)
    }

    /// Whether any unbroken law sets the parameter: for a row whose value is
    /// a share or a time, where `flag`'s whole number would read 0.5 as 0.
    pub fn is_set(&self, p: Param) -> bool {
        self.set[p as usize]
    }

    /// A time the sheet gives in seconds, in ticks, or `None` if unset.
    pub fn ticks(&self, p: Param) -> Option<u32> {
        let (n, d) = self.factors[p as usize];
        self.set[p as usize].then(|| (TICKS_PER_SECOND as i64 * n / d) as u32)
    }

    fn apply(&mut self, p: Param, n: i64, d: i64) {
        let i = p as usize;
        // A regrow time takes the shortest applied, not the product (G24,
        // decided): Bloom's 10 s and Crystal growth's 8 s make 8 s, not 80.
        // The sim builds one regrowth, Bloom's cut hedge; Crystal growth's
        // walls regrowing as clear crystal are not built (it is not a launch
        // law, §26.1).
        if p == Param::RegrowSeconds && self.set[i] {
            let (a, b) = self.factors[i];
            if n * b < a * d {
                let g = gcd(n.abs(), d).max(1);
                self.factors[i] = (n / g, d / g);
            }
            return;
        }
        let (a, b) = self.factors[i];
        let (a, b) = (a * n, b * d);
        let g = gcd(a.abs(), b).max(1);
        self.factors[i] = (a / g, b / g);
        self.set[i] = true;
    }
}

/// §8.2's harmonies, by the kind of effect each strengthens — "on both
/// laws", so only the parameters the harmonising laws themselves set. Glow's
/// longer light and Hush's closer hiding are not parameters of a law and are
/// applied where sight is (`sight_at`, `sees_geometry`); Veil's illusions and
/// disguises have no launch law to lengthen (G25).
const HARMONY_KINDS: [(u8, &[Param]); 5] = [
    // "Movement effects 25% stronger."
    (note::FLOW, &[Param::CrewSpeed, Param::GuardSpeed, Param::LoadedSpeed,
                   Param::LargeSpeed, Param::SmallSpeed]),
    // "Slowing and pulling 25% stronger."
    (note::WEIGHT, &[Param::CrewSpeed, Param::GuardSpeed, Param::LoadedSpeed,
                     Param::LargeSpeed, Param::SmallSpeed]),
    // "Damage and stuns 25% stronger."
    (note::SPARK, &[Param::Damage, Param::StructureDamage, Param::ChainShare,
                    Param::TouchStunSeconds]),
    // "Regrowth and healing 25% stronger."
    (note::BLOOM, &[Param::AllyHealing, Param::StructureHealing, Param::RegrowSeconds]),
    // "Returns and repeats 25% sooner or stronger."
    (note::ECHO, &[Param::RevivalReturn, Param::Rebound]),
];

/// A law's parameter under the harmonies on its `shared` notes. "25%
/// stronger" is read as the change made 25% larger: a multiplier's distance
/// from 1 grows by a quarter (Haste's 1.25 becomes 1.3125, Slow rivers' 0.5
/// becomes 0.375), a share or a time grows by a quarter, and a wait shrinks
/// by a fifth, so it comes a quarter sooner. One harmony a note, however many
/// laws share it.
fn harmonised(p: Param, n: i64, d: i64, shared: u8) -> (i64, i64) {
    let applies = HARMONY_KINDS.iter().any(|&(nt, ps)| shared & nt != 0 && ps.contains(&p));
    if !applies {
        return (n, d);
    }
    match p {
        Param::RegrowSeconds => (4 * n, 5 * d),
        Param::CrewSpeed | Param::GuardSpeed | Param::LoadedSpeed | Param::LargeSpeed
        | Param::SmallSpeed | Param::Damage | Param::StructureDamage => ((5 * n - d).max(0), 4 * d),
        _ => (5 * n, 4 * d),
    }
}

fn gcd(a: i64, b: i64) -> i64 {
    if b == 0 { a } else { gcd(b, a % b) }
}

/// A law woven into the realm, and its pylon.
#[derive(Clone, Debug)]
pub struct Law {
    /// Its row in `laws_table::LAWS`.
    pub def: usize,
    pub pylon: grid::TileIndex,
    pub health: i32,
    pub broken_at: Option<u32>,
    /// Switched off by the Archivist's Suspend until this tick (§11.7).
    pub suspended_until: u32,
    /// Turned into its opposite by the Tinkerer's Invert until this tick
    /// (§11.7, `opposite`).
    pub inverted_until: u32,
}

/// The Sage on a heist (§11.7): which of `ruleborn::SAGES`, each power's uses
/// left, and the tick its cooldown ends.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SageOnHeist {
    pub sage: u8,
    pub uses: [u8; 3],
    pub cooling_until: u32,
}

fn scale(x: Fx, (n, d): (i64, i64)) -> Fx {
    x.mul(Fx::from_ratio(n, d))
}
use replay::{Command, Heist, Kind};
use rng::{Rng, Stream};

/// The realm the fixture is built on. §5.2: level 5 is 14 by 14, the largest.
pub const FIXTURE_REALM_LEVEL: u8 = 5;

/// §24.10: "Tick rate — 30 a second, fixed."
pub const TICKS_PER_SECOND: u32 = 30;

/// §12.17: "Each guard carries a suspicion value from 0 to 1000."
pub const SUSPICION_MAX: i32 = 1000;

/// §12.17's states, at the thresholds the document states.
pub const SUSPICIOUS_AT: i32 = 200;
pub const INVESTIGATING_AT: i32 = 600;
pub const ALERTED_AT: i32 = 1000;

/// §12.17: near fills in about half a second, mid in about a second, far in
/// just under three. At 30 ticks a second that is 67, 33 and 12 a tick.
pub const FILL_NEAR: i32 = 67;
pub const FILL_MID: i32 = 33;
pub const FILL_FAR: i32 = 12;

/// §12.17: "It empties more slowly than it fills — about 1.7 seconds":
/// 1000 / 51 ticks.
pub const DECAY_PER_TICK: i32 = 20;

/// §12.17's modifiers on the fill rate, as (numerator, denominator). They
/// multiply together and the one division happens last, so crouched in the
/// dark is exactly a quarter rather than a half of a half rounded twice.
///
///   "Being crouched halves how fast you are noticed, running raises it by
///   three quarters, an unlit tile halves it again" — and spec/detection.md:
///   "Inside the peripheral arc, outside the cone: x 0.5".
pub const CROUCHED: (i32, i32) = (1, 2);
pub const RUNNING: (i32, i32) = (7, 4);
pub const UNLIT: (i32, i32) = (1, 2);
pub const PERIPHERAL: (i32, i32) = (1, 2);

/// §12.17 (v3.7), "A realm’s watch": "at realm level 1 suspicion fills at 0.6
/// of the rates above; at level 2 every zone reaches 0.75 as far, and at level
/// 3 0.7 as far; from level 4 guards see and notice at full strength." By realm
/// level 1 to 5: (suspicion fill, sight), each a ratio. `content_gate.py`
/// checks it against `design_facts.REALM_WATCH`.
pub const REALM_WATCH: [((i32, i32), (i64, i64)); 5] = [
    ((3, 5), (1, 1)),
    ((1, 1), (3, 4)),
    ((1, 1), (7, 10)),
    ((1, 1), (1, 1)),
    ((1, 1), (1, 1)),
];

/// How fast a crouched or running crew member moves against §11.1's speed.
///
/// §12.17 (v3.3, G13): "crouched, a crew member moves at half its role's
/// speed (11.1), and running, at double". These were the simulation's own
/// reading before the document stated them, and the document took the same
/// two numbers. The Python harness took a different reading — its crouch is
/// §11.1's full speed — and has not moved yet (D56).
pub const CROUCH_PACE: (i64, i64) = (1, 2);
pub const RUN_PACE: (i64, i64) = (2, 1);

/// §11.1's five roles. The discriminant is the role's row in `ROLES`, which
/// is §12.17's table, and §12.17 lists them in a different order from §11.1.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Role {
    Scout = 0,
    Warden = 1,
    Breaker = 2,
    Carrier = 3,
    Mender = 4,
}

/// A character's Size band (§11.2, v3.4): small, standard or large, derived
/// from its proportions. A crew member with a kind (§12.5's manifest) has its
/// kind's band (`ruleborn::RULEBORN`); a guard, and a crew member played by
/// role, reads by role: every large ruleborn is a Warden and every other role
/// has small and standard members, so a role reads as large if it is the
/// Warden and as standard otherwise.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Size {
    Small,
    Standard,
    Large,
}

/// §7.3's Health and Speed rows, "read by size": Density's figures for the
/// large and small bands, (1, 1) for standard or with no law set.
fn by_size(sheet: &Sheet, size: Size, large: Param, small: Param) -> (i64, i64) {
    match size {
        Size::Large => sheet.factor(large),
        Size::Small => sheet.factor(small),
        Size::Standard => (1, 1),
    }
}

/// Full health for a role under a sheet: its §11.1 health, read by size.
pub fn full_health(sheet: &Sheet, role: Role) -> i32 {
    full_health_of(sheet, role, role.size())
}

/// The same for a character whose size band is its kind's, not its role's.
pub fn full_health_of(sheet: &Sheet, role: Role, size: Size) -> i32 {
    let (n, d) = by_size(sheet, size, Param::LargeHealth, Param::SmallHealth);
    (role.health() as i64 * n / d) as i32
}

/// The two Revival shapes the launch laws use (§7.3): return once at N% of
/// full health, or swap with the nearest ally, who takes N% of the blow.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Revival {
    Return(i64, i64),
    Swap(i64, i64),
}

impl Role {
    /// See `Size`.
    pub fn size(self) -> Size {
        if self == Role::Warden { Size::Large } else { Size::Standard }
    }

    fn from_row(row: usize) -> Role {
        [Role::Scout, Role::Warden, Role::Breaker, Role::Carrier, Role::Mender][row % 5]
    }

    /// §11.1's speed column, in tenths of a tile a second.
    pub fn speed_tenths(self) -> i64 {
        match self {
            Role::Scout => 45,
            Role::Breaker => 32,
            Role::Carrier => 36,
            Role::Warden => 26,
            Role::Mender => 34,
        }
    }

    /// §11.1's Health, Power and Carry columns.
    pub fn health(self) -> i32 {
        match self {
            Role::Scout => 120,
            Role::Breaker => 180,
            Role::Carrier => 160,
            Role::Warden => 420,
            Role::Mender => 130,
        }
    }

    pub fn power(self) -> i32 {
        match self {
            Role::Scout => 12,
            Role::Breaker => 40,
            Role::Carrier => 8,
            Role::Warden => 20,
            Role::Mender => 6,
        }
    }

    pub fn carry(self) -> i32 {
        match self {
            Role::Scout => 104,
            Role::Breaker => 104,
            Role::Carrier => 300,
            Role::Warden => 138,
            Role::Mender => 104,
        }
    }

    /// Per tick.
    pub fn speed(self) -> Fx {
        Fx::from_ratio(self.speed_tenths(), 10 * TICKS_PER_SECOND as i64)
    }
}

/// Where the fixture's Vault stands.
pub const VAULT_AT: (u16, u16) = (11, 5);

/// A fixture crew's roles, in §11.1's order.
const CREW: [Role; 5] = [Role::Scout, Role::Breaker, Role::Carrier, Role::Warden, Role::Mender];

/// How a crew member moves. §12.17 prices all three for eyes and ears.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Gait {
    #[default]
    Walk = 0,
    Crouch = 1,
    Run = 2,
}

impl Gait {
    fn from_command(x: i16) -> Option<Gait> {
        match x {
            0 => Some(Gait::Walk),
            1 => Some(Gait::Crouch),
            2 => Some(Gait::Run),
            _ => None,
        }
    }

    pub fn pace(self) -> (i64, i64) {
        match self {
            Gait::Walk => (1, 1),
            Gait::Crouch => CROUCH_PACE,
            Gait::Run => RUN_PACE,
        }
    }

    pub fn noticed(self) -> (i32, i32) {
        match self {
            Gait::Walk => (1, 1),
            Gait::Crouch => CROUCHED,
            Gait::Run => RUNNING,
        }
    }

    pub fn sound(self) -> noise::Sound {
        match self {
            Gait::Walk => noise::Sound::Walking,
            Gait::Crouch => noise::Sound::CrouchedWalk,
            Gait::Run => noise::Sound::Running,
        }
    }
}

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
    pub role: Role,
    pub at: Point,
    pub facing: Ang,
    pub cone: Ang,
    pub near: Fx,
    pub mid: Fx,
    pub far: Fx,
    /// §12.17's "corner of the eye": the whole arc, like `cone`.
    pub peripheral: Ang,
    pub turn_per_tick: Ang,
    /// §11.1's speed for its role, per tick, for the states that walk.
    pub speed: Fx,
    /// §11.1: "When guarding at home, every role fights with its power and
    /// health."
    pub power: i32,
    /// Ticks into the current swing. §12.8: "every guard attack shows a
    /// 0.8-second wind-up"; the hit lands at the end of it.
    pub swing: u32,
    pub health: i32,
    /// Stunned by an ambush until this tick. A stunned guard does nothing:
    /// it does not see, hear, move, change state or swing.
    pub stunned_until: u32,
    /// §12.8: "A knocked-out guard stays down unless a law brings it back."
    pub knocked_out: bool,
    /// Whether another guard has found it, which is what moves the realm
    /// alarm: "once per knocked-out guard discovered".
    pub found: bool,
    pub suspicion: i32,
    /// §12.17's six states. See `guard.rs`.
    pub state: guard::State,
    /// The tick the current state was entered, for the half-second hold.
    pub state_since: u32,
    /// Its post. Returning walks here; Unaware holds it.
    pub home: grid::TileIndex,
    /// Where it is walking, computed once when a state that walks is entered.
    pub route: Vec<grid::TileIndex>,
    pub along: usize,
    /// The spot it is interested in: where it last saw someone, or where a
    /// sound came from.
    pub interest: Option<grid::TileIndex>,
    /// Whether it saw a raider this tick. Alerted falls to Searching "after
    /// losing sight", which needs this and not suspicion.
    pub saw: bool,
    /// Where it heard something this tick, if it did.
    heard: Option<grid::TileIndex>,
    /// Delay's rises still to land, as (tick, state): under Delay a guard's
    /// step up to Suspicious, Investigating or Alerted lands its delay after
    /// the step was earned (G23, decided).
    pub rising: Vec<(u32, guard::State)>,
    /// When it reached the spot it was investigating, for the ten seconds.
    arrived_at: Option<u32>,
    /// Static's charge, in tiles walked, and the tile it was last on.
    pub charge: u32,
    last_tile: Option<grid::TileIndex>,
    /// Whether a Revival source has already covered one of its knockouts:
    /// "the highest N applies, and only once" (§7.3).
    pub revived: bool,
    /// The tile it was on before `last_tile`, for Mirage.
    prev_tile: Option<grid::TileIndex>,
    /// Slowed by Shattered glass's shards until this tick.
    pub slowed_until: u32,
    /// Whether Soul tether has let it swap after returning.
    pub tethered: bool,
    /// The crew member it noticed most this tick, for the event log's cause
    /// (`events::Cause::Saw`). Not state: nothing reads it back.
    pub seen: Option<u8>,
}

impl Guard {
    /// Neither knocked out nor stunned: able to see, hear, move and act.
    pub fn awake(&self, now: u32) -> bool {
        !self.knocked_out && now >= self.stunned_until
    }

    fn next_step(&self, grid: &Grid) -> Option<Point> {
        let tile = *self.route.get(self.along)?;
        let (x, y) = grid.centre(tile);
        Some(Point { x, y })
    }
}

/// §12.17's five guard rows: role, cone in degrees, then near, mid and far in
/// half metres (so 1.5 m is 3), turn in degrees a tick, and the corner of the
/// eye in degrees. Kept as data so the reinforcing Warden at alarm 5 is built
/// from the same row as the first.
const ROLES: [(u32, i32, i64, i64, i64, i32, i32); 5] = [
    (0, 45, 4, 8, 12, 6, 110),    // Scout    0-2 / 2-4 / 4-6 m
    (1, 40, 3, 6, 9, 3, 90),      // Warden   0-1.5 / 1.5-3 / 3-4.5 m
    (2, 35, 3, 5, 7, 8, 70),      // Breaker  0-1.5 / 1.5-2.5 / 2.5-3.5 m
    (3, 30, 2, 4, 6, 4, 60),      // Carrier  0-1 / 1-2 / 2-3 m
    (4, 40, 3, 5, 0, 4, 100),     // Mender   0-1.5 / 1.5-2.5 m, no far zone
];
const WARDEN: usize = 1;

/// A held post's facing (G56) as the angle a guard looks along: north, the
/// way every post faced before facings were set, is 270°, since y runs
/// south.
pub fn facing_angle(facing: u8) -> Ang {
    Ang::from_degrees([270, 0, 90, 180][(facing & 3) as usize])
}

fn make_guard(id: u32, row: usize, post: grid::TileIndex, grid: &Grid) -> Guard {
    let (_, cone, near, mid, far, turn, peripheral) = ROLES[row];
    let (x, y) = grid.centre(post);
    Guard {
        id,
        role: Role::from_row(row),
        at: Point { x, y },
        facing: Ang::from_degrees(270),
        cone: Ang::from_degrees(cone),
        near: Fx::from_ratio(near, 2),
        mid: Fx::from_ratio(mid, 2),
        far: Fx::from_ratio(far, 2),
        peripheral: Ang::from_degrees(peripheral),
        turn_per_tick: Ang::from_degrees(turn),
        speed: Role::from_row(row).speed(),
        power: Role::from_row(row).power(),
        swing: 0,
        health: Role::from_row(row).health(),
        stunned_until: 0,
        knocked_out: false,
        found: false,
        suspicion: 0,
        state: guard::State::Unaware,
        state_since: 0,
        home: post,
        route: Vec::new(),
        along: 0,
        interest: None,
        saw: false,
        heard: None,
        rising: Vec::new(),
        arrived_at: None,
        charge: 0,
        last_tile: Some(post),
        revived: false,
        prev_tile: None,
        slowed_until: 0,
        tethered: false,
        seen: None,
    }
}

/// A raider. Where it is going is set by a command, never stored in a replay:
/// §24.10's "commands, never state".
#[derive(Clone, Debug)]
pub struct Raider {
    pub id: u32,
    pub role: Role,
    pub at: Point,
    /// §11.1's speed for its role, per tick, before gait, ground and laws.
    pub speed: Fx,
    /// The route computed when the last command was given, and how far along
    /// it the crew member is. §12.18: "The command, never the path" — this is
    /// recomputed from the command on every machine, never transmitted.
    ///
    /// It is computed **once**, when the command lands. §12.18: "no automatic
    /// re-routing around a guard the player walked them into." A crew member
    /// walked into a dead end stays in it until told otherwise, and that is
    /// the rule, not a limitation.
    pub route: Vec<grid::TileIndex>,
    pub along: usize,
    pub gait: Gait,
    pub health: i32,
    /// What it carries, and how full the player asked it to load, in per cent
    /// of §11.1's Carry.
    pub carried: i32,
    pub target_fill: i32,
    pub task: Task,
    /// The guard an Attack task is aimed at.
    pub target: u32,
    /// Ticks into the current swing, at the Vault or at a guard.
    pub swing: u32,
    pub standing: Standing,
    /// Frozen — by a Time Snare, a Gravity Well's hold or a Lantern Glare's
    /// blind — until this tick: it neither moves nor acts.
    pub frozen_until: u32,
    /// Levels dropped this tick, for §12.17's landing noise.
    pub landed: u8,
    /// Launched by a bounce mushroom this tick: "the landing can be heard 4
    /// tiles away".
    pub bounced: bool,
    /// Whether an ice sheet has already carried it its one tile past where it
    /// stopped, so the stop after that one holds.
    pub skid: bool,
    /// On a Rambler's charge: "Speed ×2" until its line is run.
    pub charging: bool,
    /// Broke something this tick by a charge: "Breaking something — 5 m".
    pub smashed: bool,
    /// How many ticks it has stood still, for Stillness.
    pub still_for: u32,
    /// When it went down, and how long an ally has been reviving it.
    pub down_since: u32,
    pub revive: u32,
    /// The tile its route starts from, which is the way a Frictionless slide
    /// is going on a one-tile route.
    pub came_from: grid::TileIndex,
    /// Static's charge, in tiles walked, and the tile it was last on.
    pub charge: u32,
    last_tile: Option<grid::TileIndex>,
    /// Whether a Revival source has already covered one of its knockouts.
    pub revived: bool,
    /// The tile it was on before `last_tile`, for Mirage.
    prev_tile: Option<grid::TileIndex>,
    /// Slowed by Shattered glass's shards until this tick.
    pub slowed_until: u32,
    /// Whether Soul tether has let it swap after returning.
    pub tethered: bool,
    /// Drifting echoes: a returned echo may pass over one wall, once.
    pub wall_pass: bool,
    /// Its kind's index in `ruleborn::RULEBORN`, from §12.5's manifest; none
    /// for a crew member played by role.
    pub kind: Option<u8>,
    /// Its size band: its kind's, or its role's (`Size`).
    pub size: Size,
    /// §12.6's ability: uses left, the tick its lockout ends, whether it is
    /// one of the (at most four) ready, the tick it last became free to be
    /// ready, for the order the waiting ones get their turn, and the tick its
    /// running effect ends.
    pub uses: u8,
    pub locked_until: u32,
    pub ready: bool,
    pub free_since: u32,
    pub effect_until: u32,
    /// The health it lost each tick of the last five seconds, for the
    /// Hourkeeper's rewind, by tick.
    pub lost: Vec<i32>,
    /// What hurt it last, for the event log (`events::Hurt`).
    pub hurt_by: Hurt,
    /// The Prism mite's split (§11.11): on the mite, its other half's index
    /// and the tick they rejoin; on that half, the mite it came from. A half
    /// is a raider of its own, with its own commands (its index on the
    /// wire), and never one of the crew the outcome counts.
    pub twin: Option<usize>,
    pub split_until: u32,
    pub half_of: Option<usize>,
}

impl Raider {
    /// Its full health under a sheet, by its own size band.
    pub fn full(&self, sheet: &Sheet) -> i32 {
        full_health_of(sheet, self.role, self.size)
    }

    /// Whether its kind's ability is `ability` and is running now.
    pub fn running(&self, ability: Ability, now: u32) -> bool {
        now < self.effect_until
            && self.kind.is_some_and(|k| RULEBORN[k as usize].ability == ability)
    }

    pub fn active(&self) -> bool {
        self.standing == Standing::Active
    }

    /// Active and not frozen: able to move, swing, load or disarm.
    pub fn acting(&self, now: u32) -> bool {
        self.active() && now >= self.frozen_until
    }

    /// Standing still: no route, or at the end of it.
    pub fn still(&self) -> bool {
        self.along >= self.route.len()
    }
}

/// A bridge over a gap — a Rootrunner's roots, a Tinkerer's plank: the gap
/// tiles it covers, the end it was laid from, and the tick it goes.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Bridge {
    pub tiles: Vec<grid::TileIndex>,
    pub back: grid::TileIndex,
    pub until: u32,
}

/// A law that holds inside a circle rather than over the realm (§7.3: "Apply
/// terrain, then zones (wards and raider casts)"): a raider's cast, centred
/// where it was placed, or the Wanderer's Copy, around every crew member on
/// its feet. `ZONED` says which of its law's lines a zone carries.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Zone {
    /// Its law's row in `laws_table::LAWS`.
    pub def: usize,
    /// Its centre; `None` for a law carried around the crew.
    pub at: Option<Point>,
    pub until: u32,
}

/// The lines of a law a zone carries: those read for one place or one
/// character — how fast whoever is inside moves, how far it is seen and how
/// soon, whether stillness or walls hide it, how far its sounds carry, and
/// what its blows deal. A line that holds for the realm or the heist as a
/// whole — the clock, a delay, regrowth, revival, the alarm's reach, light
/// bands, healing over time, health — is the realm's alone, so a zone of a
/// law made only of those does nothing (G81).
pub const ZONED: [Param; 12] = [
    Param::CrewSpeed, Param::GuardSpeed, Param::LoadedSpeed, Param::LargeSpeed,
    Param::SmallSpeed, Param::SightRange, Param::HideBehindWalls, Param::StillIsInvisible,
    Param::SuspicionFill, Param::NoiseRadius, Param::Damage, Param::StructureDamage,
];

/// The sheet at a point: the realm's, with every zone covering the point
/// laid on top, once each — a law carried around the crew holds once however
/// many crew members stand near. With no zone covering it, the realm's sheet
/// itself.
fn zoned<'a>(sheet: &'a Sheet, circles: &[(usize, Vec<Point>)], at: Point)
    -> std::borrow::Cow<'a, Sheet> {
    let reach = Fx::from_int(ruleborn::CAST_TILES);
    let mut out = std::borrow::Cow::Borrowed(sheet);
    for (def, centres) in circles {
        if centres.iter().any(|c| c.distance(at) <= reach) {
            let s = out.to_mut();
            for &(p, n, d) in LAWS[*def].params {
                if ZONED.contains(&p) {
                    s.apply(p, n, d);
                }
            }
        }
    }
    out
}

/// A Glass golem's crystal wall: the tiles it stands on, until a tick.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Wall {
    pub tiles: Vec<grid::TileIndex>,
    pub until: u32,
}

/// The whole simulated world. Vectors indexed by id, never a map.
#[derive(Clone, Debug)]
pub struct World {
    pub tick: u32,
    pub guards: Vec<Guard>,
    pub raiders: Vec<Raider>,
    /// The realm alarm, 0 to 6. §12.17: "climbs from 0 to 6 — once every
    /// thirty seconds and once per knocked-out guard discovered".
    pub alarm: i32,
    /// Knocked-out guards found by other guards. Always zero until the crew
    /// can knock anyone out; held so the alarm's rule is whole rather than
    /// half-written.
    pub knockouts_discovered: i32,
    /// Where a reinforcing Warden arrives, and whether one has.
    pub entrance: grid::TileIndex,
    pub reinforced: bool,
    /// Whether alarm level 6 has sent every guard Searching yet.
    pub all_searching: bool,
    /// "Alarm spreads by distance": (tick due, guard index, the spot), kept in
    /// that order so the same spreads land in the same order everywhere.
    spreads: Vec<(u32, usize, grid::TileIndex)>,
    /// The realm's tiles. §12.18's "terrain, laws and building are per tile".
    pub grid: Grid,
    /// The input log, in tick order, and how far through it the tick loop is.
    /// Held rather than consumed, so the same log can be replayed again.
    commands: Vec<Command>,
    next_command: usize,
    /// The island's wards (§10.3), and each Lantern Glare's reveal: the tile
    /// that set it off and the tick it ends, so two Glares in one heist each
    /// show the crew around their own tile.
    pub wards: Vec<Ward>,
    pub glares: Vec<(grid::TileIndex, u32)>,
    /// The realm's laws and their pylons, and this tick's sheet from them.
    pub laws: Vec<Law>,
    pub sheet: Sheet,
    /// How far the heist clock has run, in thousandths of a tick. Haste runs
    /// it "25% faster in this realm", so it is not the tick count.
    pub clock_run: u64,
    pub vault: Vault,
    pub skiff: Option<Skiff>,
    /// How long a called skiff takes to come: §5.4's 20 seconds to the
    /// Heart, which a one-island heist is played on, and 5 to an outer realm
    /// (`universe`).
    pub skiff_ticks: u32,
    /// The Wanderer's Rift opened here: its tile and the tick it shuts, for
    /// the crossing to carry the crew through (`universe`); and whether there
    /// is a realm the crew has been in to open one to, which only a heist
    /// across a universe has.
    pub rift_open: Option<(grid::TileIndex, u32)>,
    pub rift_back: bool,
    /// Loot dropped by a crew member knocked down: (tile, units). §12.20:
    /// "Drops its loot on the tile." Picking it up again is not built.
    pub dropped: Vec<(grid::TileIndex, i32)>,
    /// The heist clock, in ticks. §12.6: "Anyone still inside when the clock
    /// ends is caught and drops what it carries." `run` sets it from the
    /// replay; a world made directly has no end.
    pub clock: u32,
    /// Whether any guard has reached Alerted, which "raises the alarm" —
    /// §12.9's line between Clean and Loud. Not the realm alarm, which climbs
    /// every thirty seconds whatever the crew does.
    pub alarm_raised: bool,
    /// Ward effects triggered and not yet landed, under Delay (§7.3's Time
    /// row): (tick due, ward, the crew member who set it off), in the order
    /// they were triggered.
    pub delayed: Vec<(u32, usize, usize)>,
    /// §8: which combinations of the realm's standing laws sound this tick.
    pub combos: Combos,
    /// The heist's stream for §8's unpredictable effects, from its seed.
    rng: Rng,
    /// Gusts and lulls (Flow against Weight): everyone's speed this period.
    pub gust: (i64, i64),
    /// A light over the whole realm until a tick — bright or dark — from
    /// Flicker (Glow against Hush) or Tempest's lightning.
    pub light: Option<(bool, u32)>,
    /// Wildfire (Bloom against Spark): tiles burning until a tick.
    pub burning: Vec<(grid::TileIndex, u32)>,
    /// Déjà vu (Echo against Veil): the tick it comes, and whether it has.
    pub deja_vu: Option<u32>,
    pub deja_vu_spent: bool,
    /// Shattered glass: tiles with shards on them.
    pub shards: Vec<grid::TileIndex>,
    /// Quicksand: hidden pits.
    pub pits: Vec<grid::TileIndex>,
    /// Cracked gardens: structures broken while it sounds, each leaving
    /// Essence for the owner.
    pub cracked: u32,
    /// §18.3's era of the week, first on the sheet (§7.3); from the replay.
    pub era: Option<era::Era>,
    /// §5.4's landing spot, once the input log has landed the crew. Until
    /// then the crew stands where `on_ground` put it, which a replay the
    /// server accepts never simulates past tick 0 (`verify_on`).
    pub landing: Option<grid::TileIndex>,
    /// §12.17's realm's watch for this realm's level: (suspicion fill, sight).
    /// "The watch belongs to the realm, not the guard."
    pub watch: ((i32, i32), (i64, i64)),
    /// Each crew member's health when this tick began, and when its damage
    /// was last shared out: the Mossbear's root halves, and the Soulmender's
    /// link shares, what was lost since (`shield`).
    start_health: Vec<i32>,
    shared_at: Vec<i32>,
    /// The Sage on this heist, from the manifest, and what its powers left
    /// running: Tailwind's end, Renew's start, the Decoy's sapling (tile,
    /// planted, gone), and the tick Reveal last showed the wards.
    pub sage: Option<SageOnHeist>,
    pub tailwind_until: u32,
    pub renew_from: Option<u32>,
    pub decoy: Option<(grid::TileIndex, u32, u32)>,
    pub wards_shown_at: Option<u32>,
    /// §24.10's event log, outside the checksum (`events`), the cause the
    /// next guard state change is logged with, and how many knocked-out
    /// guards had been found when the alarm last moved.
    pub log: Log,
    why: Cause,
    found_logged: i32,
    /// Bell posts rung: each "raises the realm's alarm one level (12.17)".
    /// Under Delay a ring lands late, at the ticks in `bells_due`.
    pub bells_rung: i32,
    bells_due: Vec<u32>,
    /// The bridges standing over gaps.
    pub bridges: Vec<Bridge>,
    /// The Glass golems' crystal walls standing.
    pub walls: Vec<Wall>,
    /// The casts the manifest carries (law rows), which have been used (a
    /// bit each: §12.5 bills only a cast used), and the zones in force, with
    /// their circles this tick.
    pub casts: Vec<u8>,
    pub casts_used: u8,
    pub zones: Vec<Zone>,
    circles: Vec<(usize, Vec<Point>)>,
    /// The Lantern wisps' reveals running: (crew member, until). Each shows
    /// what is hidden within `ruleborn::REVEAL_TILES` of the wisp as it goes.
    pub reveals: Vec<(usize, u32)>,
    /// §6.2's features that act on what is around them, found on the grid
    /// at the start of each tick: lantern posts (each with whether a crystal
    /// outcrop beside it carries its light further), ember vents, static
    /// stones and hot springs.
    lanterns: Vec<(grid::TileIndex, bool)>,
    vents: Vec<grid::TileIndex>,
    stones: Vec<grid::TileIndex>,
    springs: Vec<grid::TileIndex>,
}

impl World {
    /// The spike's fixture: five guards on §12.17's five role rows, a crew
    /// in §11.1's roles. Every number here is the document's except the two
    /// gait speeds, which it does not give (`CROUCH_PACE`, `RUN_PACE`).
    ///
    /// The seed is accepted and not read. Nothing §12.17 describes draws from
    /// it — "nothing here is random" — and the systems that may (§24.7's
    /// seeded generator is for loot and island generation) are not built.
    /// `the_seed_cannot_change_what_a_guard_does` holds that in place.
    pub fn new(_seed: u64, crew: u8, commands: Vec<Command>) -> World {
        World::on_ground(&island::Island::fixture(), crew, commands)
    }

    /// An island's ground, guards, Vault and crew: everything but its laws and
    /// wards, which `from_island` adds as the heist it is. `new` is this on
    /// the fixture realm, which is what the tests that weave their own laws
    /// build on.
    pub fn on_ground(island: &island::Island, crew: u8, commands: Vec<Command>) -> World {
        debug_assert!(
            commands.windows(2).all(|w| w[0].tick <= w[1].tick),
            "the input log has to be in tick order or the inputs phase is not a phase");
        let grid = island.ground();
        let tile = |(x, y): (u8, u8)| grid.index(x as u16, y as u16).unwrap_or(0);
        let guards: Vec<Guard> = island.guards
            .iter()
            .enumerate()
            .map(|(id, post)| {
                let mut g = make_guard(id as u32, post.row as usize, tile((post.x, post.y)), &grid);
                g.facing = facing_angle(post.facing);
                g
            })
            .collect();
        let entrance = tile(island.entrance);
        let vault_tile = tile(island.vault);

        let mut raiders = Vec::with_capacity(crew as usize);
        for i in 0..crew as i32 {
            let role = CREW[i as usize % CREW.len()];
            raiders.push(Raider {
                id: i as u32,
                role,
                at: {
                    let (x, y) = grid.centre(grid.index(i as u16, 0).unwrap_or(0));
                    Point { x, y }
                },
                speed: role.speed(),
                route: Vec::new(),
                along: 0,
                gait: Gait::Walk,
                health: role.health(),
                carried: 0,
                target_fill: 100,
                task: Task::None,
                target: 0,
                swing: 0,
                standing: Standing::Active,
                still_for: 0,
                landed: 0,
                bounced: false,
                skid: false,
                charging: false,
                smashed: false,
                frozen_until: 0,
                down_since: 0,
                revive: 0,
                came_from: grid.index(i as u16, 0).unwrap_or(0),
                charge: 0,
                last_tile: grid.index(i as u16, 0),
                revived: false,
                prev_tile: None,
                slowed_until: 0,
                tethered: false,
                wall_pass: false,
                kind: None,
                size: role.size(),
                uses: 0,
                locked_until: 0,
                ready: false,
                free_since: 0,
                effect_until: 0,
                lost: vec![0; ruleborn::REWIND_TICKS],
                hurt_by: Hurt::Law,
                twin: None,
                split_until: 0,
                half_of: None,
            });
        }
        World {
            tick: 0,
            guards,
            raiders,
            alarm: 0,
            knockouts_discovered: 0,
            entrance,
            reinforced: false,
            all_searching: false,
            spreads: Vec::new(),
            grid,
            commands,
            next_command: 0,
            wards: Vec::new(),
            glares: Vec::new(),
            laws: Vec::new(),
            sheet: Sheet::plain(),
            clock_run: 0,
            vault: Vault {
                tile: vault_tile,
                health: heist::VAULT_HEALTH_PER_LEVEL * island.vault_level as i32,
                exposed: island.exposed as i32,
                opened_at: None,
            },
            skiff: None,
            dropped: Vec::new(),
            clock: u32::MAX,
            alarm_raised: false,
            delayed: Vec::new(),
            combos: Combos::default(),
            rng: Rng::new(0, Stream::Laws),
            gust: (1, 1),
            light: None,
            burning: Vec::new(),
            deja_vu: None,
            deja_vu_spent: false,
            shards: Vec::new(),
            pits: Vec::new(),
            cracked: 0,
            era: None,
            landing: None,
            watch: REALM_WATCH[(island.realm_level.clamp(1, 5) - 1) as usize],
            start_health: Vec::new(),
            shared_at: Vec::new(),
            sage: None,
            tailwind_until: 0,
            renew_from: None,
            decoy: None,
            wards_shown_at: None,
            log: Log::default(),
            why: Cause::Table,
            found_logged: 0,
            bells_rung: 0,
            bells_due: Vec::new(),
            bridges: Vec::new(),
            walls: Vec::new(),
            reveals: Vec::new(),
            casts: Vec::new(),
            casts_used: 0,
            zones: Vec::new(),
            circles: Vec::new(),
            lanterns: Vec::new(),
            vents: Vec::new(),
            stones: Vec::new(),
            springs: Vec::new(),
            skiff_ticks: heist::SKIFF_HEART_TICKS,
            rift_open: None,
            rift_back: false,
        }
    }

    /// Weave laws into the realm, each with a pylon on the given tile. §24.11:
    /// a heist "records the exact set of laws it was made under", so the laws
    /// travel with the heist and `from_heist` weaves them, not `new`.
    pub fn weave(&mut self, laws: &[(&str, (u16, u16))]) {
        for (id, (x, y)) in laws {
            let Some(def) = LAWS.iter().position(|l| l.id == *id) else { continue };
            let Some(pylon) = self.grid.index(*x, *y) else { continue };
            self.grid.place(*x, *y, Feature::Pylon);
            self.laws.push(Law { def, pylon, health: heist::PYLON_HEALTH, broken_at: None,
                                 suspended_until: 0, inverted_until: 0 });
        }
        self.refresh_sheet();
        // Everyone starts the heist at full health as the sheet reads it,
        // so Density's large start larger (§7.3's Health row).
        let sheet = self.sheet;
        for r in self.raiders.iter_mut() {
            r.health = r.full(&sheet);
        }
        for g in self.guards.iter_mut() {
            g.health = full_health(&sheet, g.role);
        }
    }

    /// Place wards on the island. A Crystal Wall is a wall on its tile; the
    /// rest lie on open ground and act through the states phase.
    pub fn place_wards(&mut self, wards: &[(WardKind, (u16, u16))]) {
        for (kind, (x, y)) in wards {
            let Some(tile) = self.grid.index(*x, *y) else { continue };
            if *kind == WardKind::CrystalWall {
                self.grid.place(*x, *y, Feature::CrystalWall);
            }
            self.wards.push(Ward::new(*kind, tile));
        }
    }

    /// §12.5's crew manifest: "The simulation plays each member by its kind's
    /// ability and numbers, not by its role alone." Each member takes its
    /// kind's role (and so §11.1's numbers), its size band and its ability's
    /// two uses. Called before the laws are woven, which set everyone's
    /// health by size. A manifest naming fewer members than the crew leaves
    /// the rest by role; a kind past the table is not one, and is left too.
    pub fn crew_from(&mut self, manifest: &replay::Manifest) {
        for (r, m) in self.raiders.iter_mut().zip(manifest.members.iter()) {
            let Some(k) = RULEBORN.get(m.kind as usize) else { continue };
            r.kind = Some(m.kind);
            r.role = k.role;
            r.size = k.size;
            r.speed = k.role.speed();
            r.health = r.full(&Sheet::plain());
            r.uses = ruleborn::USES;
        }
        self.casts = manifest.casts.clone();
        // §11.7: "A player brings one Sage on each heist", or none.
        self.sage = SAGES.get((manifest.sage as usize).wrapping_sub(1)).map(|s| SageOnHeist {
            sage: manifest.sage - 1,
            uses: [s.powers[0].1, s.powers[1].1, s.powers[2].1],
            cooling_until: 0,
        });
    }

    /// The world a replay describes: the fixture realm, the heist's crew and
    /// commands, its laws, and its clock.
    pub fn from_heist(heist: &Heist) -> World {
        World::from_island(&island::Island::fixture(), heist)
    }

    /// The world a replay describes on the island it names: its ground and
    /// guards, its laws woven and its wards placed, the replay's crew and
    /// commands, and its clock. Whether `island` is the one the replay's
    /// header names is the caller's to check — `verify_on` does.
    pub fn from_island(island: &island::Island, heist: &Heist) -> World {
        let mut world = World::on_ground(island, heist.crew, heist.commands.clone());
        world.rng = Rng::new(heist.seed, Stream::Laws);
        world.era = heist.era;
        if let Some(manifest) = &heist.manifest {
            world.crew_from(manifest);
        }
        let laws: Vec<(&str, (u16, u16))> = island.laws.iter()
            .map(|(id, x, y)| (id.as_str(), (*x as u16, *y as u16)))
            .collect();
        world.weave(&laws);
        let wards: Vec<(heist::WardKind, (u16, u16))> = island.wards.iter()
            .map(|(k, x, y)| (*k, (*x as u16, *y as u16)))
            .collect();
        world.place_wards(&wards);
        world.clock = heist.ticks;
        world
    }

    /// A command given now, as a player's tap is: §24.10's "a move or an
    /// ability with its tick, crew member and target", stamped with the tick
    /// the world is about to run, so it lands in this tick's inputs phase.
    /// The log stays in tick order because a tap can only be now. Returns
    /// false, and changes nothing, once the heist's clock has run out.
    pub fn give(&mut self, actor: u8, kind: Kind, x: i16, y: i16) -> bool {
        if self.tick >= self.clock {
            return false;
        }
        self.commands.push(Command { tick: self.tick, actor, kind, x, y });
        true
    }

    /// The input log so far: what a device records and the server replays.
    pub fn commands(&self) -> &[Command] {
        &self.commands
    }

    /// Replace the input log, for a test that builds its world by hand.
    #[cfg(test)]
    pub(crate) fn commands_for_test(&mut self, commands: Vec<Command>) {
        self.commands = commands;
        self.next_command = 0;
    }

    /// One tick, in §24.10's six phases. Returns the checksum after it.
    pub fn step(&mut self) -> u64 {
        self.start_health = self.raiders.iter().map(|r| r.health).collect();
        self.shared_at = self.start_health.clone();
        self.phase_inputs();
        self.phase_laws();
        self.phase_perception();
        self.phase_movement();
        self.phase_noise();
        self.phase_states();
        // What each crew member lost this tick, kept five seconds for the
        // Hourkeeper (§11.11). Healing in the same tick is not netted off:
        // "all the health it lost".
        let slot = self.tick as usize % ruleborn::REWIND_TICKS;
        for (r, &was) in self.raiders.iter_mut().zip(self.start_health.iter()) {
            r.lost[slot] = (was - r.health).max(0);
        }
        // "every crew member's position once a second" (§24.10), while it is
        // on the island.
        if self.tick % TICKS_PER_SECOND == 0 {
            let to_wire = |v: Fx| v.mul(Fx::from_int(256)).to_int().clamp(-32768, 32767) as i16;
            for r in self.raiders.iter().filter(|r| matches!(r.standing,
                                                              Standing::Active | Standing::Down)) {
                self.log.positions.push((self.tick, r.id as u8, to_wire(r.at.x), to_wire(r.at.y)));
            }
        }
        self.tick += 1;
        self.checksum()
    }

    /// Inputs. §24.10 puts this phase first, and first is the point: every
    /// command for this tick is applied before anything reads the world, so
    /// no part of the tick sees a half-applied input.
    fn phase_inputs(&mut self) {
        self.ready_abilities();
        self.inputs();
        self.sapling();
    }

    fn inputs(&mut self) {
        // The landing comes before every other input of tick 0, wherever
        // the log's order puts it: a move given at tick 0 is a move from the
        // landing spot.
        if self.tick == 0 {
            let landings: Vec<Command> = self.commands.iter()
                .take_while(|c| c.tick == 0)
                .filter(|c| c.kind == Kind::Land)
                .copied()
                .collect();
            for command in landings {
                self.land(command);
            }
        }
        while self.next_command < self.commands.len()
            && self.commands[self.next_command].tick == self.tick
        {
            let command = self.commands[self.next_command];
            self.next_command += 1;
            // The landing is the whole crew's, and was applied above.
            if command.kind == Kind::Land {
                continue;
            }
            if command.kind == Kind::Ability {
                self.fire(command);
                continue;
            }
            if command.kind == Kind::Sage {
                self.call(command);
                continue;
            }
            if command.kind == Kind::Cast {
                self.cast(command);
                continue;
            }
            let Some(raider) = self.raiders.get_mut(command.actor as usize) else {
                continue;                 // a command for a crew member who is
                                          // not here is dropped, not fatal: the
                                          // server re-simulates untrusted logs
            };
            // Down, caught or gone: nothing to command.
            if !raider.active() {
                continue;
            }
            match command.kind {
                Kind::MoveTo => {
                    let (x, y) = command.target();
                    // Inside a tunnel there is no turning back: the new route
                    // starts at the far mouth, and the tunnel is walked first.
                    let inside = underground(&self.grid, raider);
                    let from = match inside {
                        Some((_, far)) => Some(far),
                        None => self.grid.tile_at(raider.at.x, raider.at.y),
                    };
                    let to = self.grid.tile_at(x, y);
                    // A destination off the grid or inside a wall is not
                    // re-aimed at the nearest open tile. §12.18: "the crew
                    // never makes a decision the player did not make."
                    raider.route = match (from, to) {
                        (Some(a), Some(b)) if raider.wall_pass => {
                            match path::find_over_wall(&self.grid, a, b) {
                                Some((route, used)) => {
                                    raider.wall_pass &= !used;
                                    route
                                }
                                None => Vec::new(),
                            }
                        }
                        (Some(a), Some(b)) => path::find_through(&self.grid, a, b)
                            .unwrap_or_default(),
                        _ => Vec::new(),
                    };
                    raider.along = 0;
                    raider.came_from = from.unwrap_or(raider.came_from);
                    if let Some((near, far)) = inside {
                        raider.route.insert(0, far);
                        raider.came_from = near;
                    }
                    raider.skid = false;
                    raider.charging = false;
                }
                // An unknown gait is dropped like an unknown crew member.
                Kind::Gait => {
                    if let Some(gait) = Gait::from_command(command.x) {
                        raider.gait = gait;
                    }
                }
                // On an ice sheet "stopping takes 1 tile": the tile it is
                // heading for is still reached.
                Kind::Halt => {
                    let here = self.grid.tile_at(raider.at.x, raider.at.y);
                    let on_ice = here.is_some_and(|t| self.grid.feature(t)
                        == Some(Feature::IceSheet));
                    if on_ice && raider.along < raider.route.len() && !raider.skid {
                        raider.route.truncate(raider.along + 1);
                        raider.skid = true;
                    } else {
                        raider.route.clear();
                        raider.along = 0;
                    }
                }
                Kind::Crack => raider.task = Task::Crack,
                Kind::Attack => {
                    raider.task = Task::Attack;
                    raider.target = command.x.max(0) as u32;
                }
                Kind::Drop => {
                    let share = (command.x as i32).clamp(0, 100);
                    let dropped = raider.carried * share / 100;
                    if dropped > 0 {
                        raider.carried -= dropped;
                        if let Some(t) = self.grid.tile_at(raider.at.x, raider.at.y) {
                            self.dropped.push((t, dropped));
                        }
                    }
                }
                Kind::Drag => {
                    raider.task = Task::Drag;
                    raider.target = command.x.max(0) as u32;
                }
                Kind::Disarm => {
                    let (x, y) = command.target();
                    if let Some(tile) = self.grid.tile_at(x, y) {
                        raider.task = Task::Disarm;
                        raider.target = tile;
                    }
                }
                Kind::Break => {
                    let (x, y) = command.target();
                    if let Some(tile) = self.grid.tile_at(x, y) {
                        raider.task = Task::Break;
                        raider.target = tile;
                    }
                }
                Kind::Load => {
                    raider.task = Task::Load;
                    raider.target_fill = (command.x as i32).clamp(0, 100);
                }
                // One skiff, called once; an inland tile, or a wall, is not a
                // place a skiff can come, and the call is dropped.
                Kind::Land | Kind::Ability | Kind::Sage | Kind::Cast => {}
                Kind::Skiff => {
                    let (x, y) = command.target();
                    if let Some(tile) = self.grid.tile_at(x, y) {
                        if self.skiff.is_none() && self.grid.is_edge(tile)
                            && self.grid.at(tile).passable()
                        {
                            self.skiff = Some(Skiff {
                                tile,
                                arrives: self.tick + self.skiff_ticks,
                            });
                        }
                    }
                }
            }
        }
    }

    /// §12.6's ready rule, before this tick's inputs: "At most four
    /// abilities are ready at once. In a crew of five the rightmost
    /// portrait's ability waits, and becomes ready the moment any other
    /// ability's use is taken — that ability entering its lockout counts —
    /// and an ability whose lockout ends while four are ready waits its turn;
    /// an ability with no uses left no longer counts." The waiting take their
    /// turn in the order they came free, then portrait order. A crew member
    /// caught or already out can never use its ability again, so it no
    /// longer counts either; one knocked down may yet be revived, and does.
    fn ready_abilities(&mut self) {
        let now = self.tick;
        let mut ready = 0;
        let mut waiting: Vec<(u32, usize)> = Vec::new();
        for (i, r) in self.raiders.iter_mut().enumerate() {
            if r.kind.is_none() {
                continue;
            }
            let free = r.uses > 0 && now >= r.locked_until
                && !matches!(r.standing, Standing::Caught | Standing::Out);
            if !free {
                r.ready = false;
            } else if r.ready {
                ready += 1;
            } else {
                waiting.push((r.free_since, i));
            }
        }
        waiting.sort_unstable();
        for (_, i) in waiting {
            if ready >= ruleborn::MAX_READY {
                break;
            }
            self.raiders[i].ready = true;
            ready += 1;
        }
    }

    /// An Ability command: crew member `actor`'s ability at the target, if
    /// it has a use left, is ready, and can act (§12.7). A use is spent only
    /// when the ability does something: one with no target where it was
    /// aimed, or not built yet (`Ability::built`), is dropped like any
    /// command that cannot be carried out.
    fn fire(&mut self, command: Command) {
        let now = self.tick;
        let ri = command.actor as usize;
        let Some(r) = self.raiders.get(ri) else { return };
        let Some(k) = r.kind else { return };
        if !(r.acting(now) && r.ready && r.uses > 0) {
            return;
        }
        let ability = RULEBORN[k as usize].ability;
        let (x, y) = command.target();
        let aimed = self.grid.tile_at(x, y);
        let done = match ability {
            Ability::Sprint | Ability::Satchel | Ability::Unhindered | Ability::Pound
            | Ability::Root | Ability::StandOver | Ability::Link => true,
            Ability::Burst => {
                self.burst(ri);
                true
            }
            Ability::Bloom => {
                self.bloom(ri);
                true
            }
            Ability::Rewind => match aimed.and_then(|t| self.ally_on(ri, t)) {
                Some(ai) => {
                    self.rewind(ai);
                    true
                }
                None => false,
            },
            Ability::Freeze => aimed.is_some_and(|t| self.freeze(t)),
            Ability::CrystalWall => match (self.grid.tile_at(r.at.x, r.at.y), aimed) {
                (Some(f), Some(t)) => self.raise_wall(f, t),
                _ => false,
            },
            // "Reveals every hidden ward, hidden guard and illusion within 6
            // tiles for 6 s", around the wisp as it goes (`revealed`).
            Ability::Reveal => {
                self.reveals.push((ri, now + ruleborn::REVEAL_TICKS));
                true
            }
            Ability::Glide => aimed.is_some_and(|t| self.glide(ri, t)),
            Ability::Charge => aimed.is_some_and(|t| self.charge(ri, t)),
            Ability::Split => self.split(ri),
            // "Grows a root bridge over one gap of up to 3 tiles for 8 s",
            // from where the Rootrunner stands toward the gap it is aimed at.
            Ability::RootBridge => {
                let from = self.grid.tile_at(r.at.x, r.at.y);
                match (from, aimed) {
                    (Some(f), Some(t)) => self.lay_bridge(Some(f), t, ruleborn::ROOT_BRIDGE_TILES,
                                                          ruleborn::ROOT_BRIDGE_TICKS),
                    _ => false,
                }
            }
            // The Sparkwright: "Cuts the Sage's cooldown by 10 s, so its next
            // power comes sooner". With no Sage cooling, nothing to cut.
            Ability::Quicken => match &mut self.sage {
                Some(s) if s.cooling_until > now => {
                    s.cooling_until = s.cooling_until.saturating_sub(ruleborn::QUICKEN_TICKS)
                        .max(now);
                    true
                }
                _ => false,
            },
        };
        if !done {
            return;
        }
        self.log.push(now, Event::Ability { crew: ri as u8 });
        let r = &mut self.raiders[ri];
        r.uses -= 1;
        r.ready = false;
        r.locked_until = now + ruleborn::LOCKOUT_TICKS;
        r.free_since = r.locked_until;
        r.effect_until = now + ability.ticks();
        if ability == Ability::Root {
            r.route.clear();
            r.along = 0;
        }
    }

    /// A Sage command: the Sage's power number `actor` at the target, if the
    /// heist carries a Sage, it is not cooling down and the power has a use
    /// left. §11.7: "After using any power the Sage cools down for 20 seconds
    /// before it can use another." A use is spent, and the cooldown starts,
    /// only when the power does something; one that cannot is dropped like
    /// any command that cannot be carried out.
    fn call(&mut self, command: Command) {
        let now = self.tick;
        let Some(sage) = self.sage else { return };
        let i = command.actor as usize;
        if i >= 3 || now < sage.cooling_until || sage.uses[i] == 0 {
            return;
        }
        let power = SAGES[sage.sage as usize].powers[i].0;
        let (x, y) = command.target();
        let aimed = self.grid.tile_at(x, y);
        let done = match power {
            // "switch off one law in the current realm for 10 s": the law
            // whose pylon it is aimed at, standing and not already off.
            Power::Suspend => {
                let law = aimed.and_then(|t| self.laws.iter().position(|l| {
                    l.pylon == t && l.broken_at.is_none() && now >= l.suspended_until
                }));
                if let Some(li) = law {
                    let until = now + ruleborn::SUSPEND_TICKS;
                    self.laws[li].suspended_until = until;
                    self.log.push(now, Event::LawOff { law: li as u16, until });
                }
                law.is_some()
            }
            // "show every ward in the realm": what the device draws, kept in
            // the simulation so the replay shows it at the same tick.
            Power::Reveal => {
                self.wards_shown_at = Some(now);
                true
            }
            // "bring a knocked-out character back at 40%".
            Power::Recall => {
                let down = aimed.and_then(|t| self.raiders.iter().position(|r| {
                    r.standing == Standing::Down && self.grid.tile_at(r.at.x, r.at.y) == Some(t)
                }));
                if let Some(ri) = down {
                    let sheet = self.sheet;
                    let r = &mut self.raiders[ri];
                    let (n, d) = ruleborn::RECALL_RETURN;
                    r.health = ((r.full(&sheet) as i64 * n / d) as i32).max(1);
                    r.standing = Standing::Active;
                    r.revive = 0;
                    self.log.push(now, Event::Back { crew: ri as u8, how: Back::Recall });
                }
                down.is_some()
            }
            // "disable a ward for 12 s", as the Stillwatch's freeze holds one.
            Power::Jam => {
                let ward = aimed.and_then(|t| self.wards.iter().position(|w| w.tile == t && w.live()));
                if let Some(wi) = ward {
                    let w = &mut self.wards[wi];
                    w.held_until = w.held_until.max(now + ruleborn::JAM_TICKS);
                }
                ward.is_some()
            }
            Power::Renew => {
                self.renew_from = Some(now);
                true
            }
            // "plant a sapling guards chase for 8 s", on open ground.
            Power::Decoy => match aimed {
                Some(t) if self.grid.at(t).passable() => {
                    self.decoy = Some((t, now, now + ruleborn::DECOY_TICKS));
                    true
                }
                _ => false,
            },
            Power::Tailwind => {
                self.tailwind_until = now + ruleborn::TAILWIND_TICKS;
                true
            }
            // "open a two-way rift between two realms already visited for
            // 20 s": on the open tile aimed at, to a realm the crew has been
            // in — none on a heist of one island. Where it leads, and the
            // crew going through it, are the crossing's (`universe`).
            Power::Rift => match aimed {
                Some(t) if self.rift_back && self.grid.standable(t) => {
                    self.rift_open = Some((t, now + ruleborn::RIFT_TICKS));
                    true
                }
                _ => false,
            },
            // "lay a 4-tile shortcut over a gap for 15 s": across the gap the
            // tile aimed at is in, along its row if that is short enough,
            // else its column.
            Power::Plank => aimed.is_some_and(|t| self.lay_bridge(None, t, ruleborn::PLANK_TILES,
                                                                  ruleborn::PLANK_TICKS)),
            // "join two points up to 6 tiles apart for 20 s": the two banks
            // of the gap the tile aimed at is in, as the Plank finds them.
            Power::VineBridge => aimed.is_some_and(|t| {
                self.lay_bridge(None, t, ruleborn::VINE_BRIDGE_TILES - 1, ruleborn::VINE_BRIDGE_TICKS)
            }),
            // "take one enemy law and carry it around the crew for the rest
            // of the heist": the law whose pylon it is aimed at, standing,
            // carried as a zone around every crew member on its feet, in the
            // cast's circle. The realm keeps it: a copy, not a theft.
            Power::Copy => {
                let law = aimed.and_then(|t| self.laws.iter().position(|l| {
                    l.pylon == t && l.broken_at.is_none()
                }));
                if let Some(li) = law {
                    self.zones.push(Zone { def: self.laws[li].def, at: None, until: u32::MAX });
                }
                law.is_some()
            }
            // "turn a law into its opposite for 10 s": the law whose pylon it
            // is aimed at, standing, not off and not already turned.
            Power::Invert => {
                let law = aimed.and_then(|t| self.laws.iter().position(|l| {
                    l.pylon == t && l.broken_at.is_none() && now >= l.suspended_until
                        && now >= l.inverted_until
                }));
                if let Some(li) = law {
                    let until = now + ruleborn::INVERT_TICKS;
                    self.laws[li].inverted_until = until;
                    self.log.push(now, Event::LawTurned { law: li as u16, until });
                }
                law.is_some()
            }
        };
        if done {
            if let Some(s) = self.sage.as_mut() {
                s.uses[i] -= 1;
                s.cooling_until = now + ruleborn::SAGE_COOLDOWN_TICKS;
            }
            self.log.push(now, Event::Power { power: i as u8 });
        }
    }

    /// The Decoy's sapling: every guard not yet chasing the crew is drawn to
    /// it as a sound draws one, when it is planted and each second after,
    /// until it goes.
    fn sapling(&mut self) {
        let now = self.tick;
        let Some((tile, planted, gone)) = self.decoy else { return };
        if now >= gone {
            self.decoy = None;
        } else if (now - planted) % TICKS_PER_SECOND == 0 {
            for gi in 0..self.guards.len() {
                self.lure(gi, tile);
            }
        }
    }

    /// Another crew member standing on tile `t`, able to be helped: the
    /// lowest id, as every tie in the simulation breaks.
    fn ally_on(&self, ri: usize, t: grid::TileIndex) -> Option<usize> {
        self.raiders.iter().enumerate().position(|(i, o)| {
            i != ri && o.active() && self.grid.tile_at(o.at.x, o.at.y) == Some(t)
        })
    }

    /// The Emberling: "Bursts, dealing triple its Power at once to every ward
    /// and pylon within 1 tile" — measured centre to centre, as every radius
    /// here is. A structure hit, so a law on structure damage reads it.
    fn burst(&mut self, ri: usize) {
        let now = self.tick;
        let at = self.raiders[ri].at;
        let (sn, sd) = zoned(&self.sheet, &self.circles, at).factor(Param::StructureDamage);
        let hit = (self.raiders[ri].role.power() as i64 * ruleborn::BURST_POWER * sn / sd) as i32;
        let near = |grid: &Grid, t: grid::TileIndex| {
            let (x, y) = grid.centre(t);
            at.distance(Point { x, y }) <= Fx::from_int(ruleborn::BURST_TILES)
        };
        let cracking = self.combos.resonance(Res::CrackedGardens) as u32;
        for li in 0..self.laws.len() {
            if self.laws[li].broken_at.is_none() && near(&self.grid, self.laws[li].pylon) {
                let law = &mut self.laws[li];
                law.health -= hit;
                if law.health <= 0 {
                    law.health = 0;
                    law.broken_at = Some(now);
                    self.cracked += cracking;
                    self.log.push(now, Event::Pylon { law: li as u16 });
                }
            }
        }
        for wi in 0..self.wards.len() {
            if self.wards[wi].live() && near(&self.grid, self.wards[wi].tile) {
                let w = &mut self.wards[wi];
                w.health -= hit;
                if w.health <= 0 {
                    w.health = 0;
                    w.broken = true;
                    w.broken_at = Some(now);
                    self.cracked += cracking;
                    if w.kind == WardKind::CrystalWall {
                        let t = w.tile;
                        self.grid.clear(t);
                    }
                }
            }
        }
    }

    /// The Bloomling: "Heals every ally within 3 tiles by 15% of its full
    /// health, at once." An ally is another crew member, standing.
    fn bloom(&mut self, ri: usize) {
        let at = self.raiders[ri].at;
        let sheet = self.sheet;
        let (n, d) = ruleborn::BLOOM_HEAL;
        for (i, o) in self.raiders.iter_mut().enumerate() {
            if i != ri && o.active()
                && at.distance(o.at) <= Fx::from_int(ruleborn::BLOOM_TILES)
            {
                let full = o.full(&sheet);
                o.health = (o.health + full * n / d).min(full);
            }
        }
    }

    /// The Hourkeeper: "Gives one ally back all the health it lost in the
    /// last 5 s." What it got back is not lost any more, so a second rewind
    /// in the same five seconds gives nothing twice.
    fn rewind(&mut self, ai: usize) {
        let sheet = self.sheet;
        let r = &mut self.raiders[ai];
        let back: i32 = r.lost.iter().sum();
        let full = r.full(&sheet);
        r.health = (r.health + back).min(full);
        r.lost.iter_mut().for_each(|l| *l = 0);
    }

    /// The Stillwatch: "Freezes one guard or ward for 2.5 s: it cannot move,
    /// act, see or grow suspicious." A guard on the tile first, standing,
    /// lowest id; else a ward there that still works. A frozen guard is
    /// stunned, which already stops all four; a frozen ward does nothing.
    fn freeze(&mut self, t: grid::TileIndex) -> bool {
        let until = self.tick + ruleborn::FREEZE_TICKS;
        let guard = self.guards.iter().position(|g| {
            !g.knocked_out && self.grid.tile_at(g.at.x, g.at.y) == Some(t)
        });
        if let Some(gi) = guard {
            let g = &mut self.guards[gi];
            g.stunned_until = g.stunned_until.max(until);
            return true;
        }
        if let Some(w) = self.wards.iter_mut().find(|w| w.tile == t && w.live()) {
            w.held_until = w.held_until.max(until);
            return true;
        }
        false
    }

    /// Damage taken since it was last shared, read again by two abilities.
    /// The Mossbear rooted takes "half damage". While a Soulmender's link
    /// runs, "every hit on one of them is shared evenly across all": what
    /// the standing crew lost is pooled and split evenly, the remainder to
    /// the lowest ids. Run before knockouts are settled, so a share can save
    /// the one the hit fell on, and again after anything that hurts later in
    /// the tick. A tick with neither running changes nothing.
    fn shield(&mut self) {
        let now = self.tick;
        if self.shared_at.len() != self.raiders.len() {
            return;
        }
        let linked = self.raiders.iter().any(|r| r.active() && r.running(Ability::Link, now));
        for (r, &was) in self.raiders.iter_mut().zip(self.shared_at.iter()) {
            let lost = was - r.health;
            if lost > 0 && r.running(Ability::Root, now) {
                let (n, d) = ruleborn::ROOT_DAMAGE;
                r.health = was - (lost as i64 * n / d) as i32;
            }
        }
        if linked {
            let crew: Vec<usize> = (0..self.raiders.len())
                .filter(|&i| self.raiders[i].active() && self.shared_at[i] > 0)
                .collect();
            let pooled: i32 = crew.iter()
                .map(|&i| (self.shared_at[i] - self.raiders[i].health).max(0))
                .sum();
            if pooled > 0 && !crew.is_empty() {
                let each = pooled / crew.len() as i32;
                let extra = pooled % crew.len() as i32;
                for (k, &i) in crew.iter().enumerate() {
                    let gained = (self.raiders[i].health - self.shared_at[i]).max(0);
                    let share = each + (k < extra as usize) as i32;
                    self.raiders[i].health = self.shared_at[i] + gained - share;
                }
            }
        }
        self.shared_at = self.raiders.iter().map(|r| r.health).collect();
    }

    /// §5.4's landing: "The crew lands on any edge tile of any outer realm
    /// the raider chooses" — the whole crew on the one spot, at tick 0,
    /// before anything reads the world. "A landing skiff can be heard:
    /// guards within 6 tiles of the landing spot start at 250 of 1,000
    /// suspicion (12.17), unless the spot is in fog, darkness or tall grass."
    /// Darkness is the unlit modifier perception uses, so a spot that hides
    /// a crew member from a guard's eyes also hides the skiff from its ears.
    /// "Within 6 tiles" is walked, as §12.17 says every sound travels: "Sound
    /// follows the walkable path rather than passing through walls", and a
    /// realm law's noise radius stretches it as it stretches every sound. A
    /// guard asleep at the start does not hear it.
    /// A second landing, a late one, or one on a tile that is not an open
    /// edge tile is dropped like any command that cannot be carried out.
    fn land(&mut self, command: Command) {
        if self.tick != 0 || self.landing.is_some() {
            return;
        }
        let (x, y) = command.target();
        let Some(tile) = self.grid.tile_at(x, y) else { return };
        if !self.grid.is_edge(tile) || !self.grid.at(tile).passable() {
            return;
        }
        self.landing = Some(tile);
        let (cx, cy) = self.grid.centre(tile);
        let spot = Point { x: cx, y: cy };
        for r in self.raiders.iter_mut() {
            r.at = spot;
            r.came_from = tile;
            r.last_tile = Some(tile);
            r.route.clear();
            r.along = 0;
        }
        let hidden = matches!(self.grid.feature(tile), Some(Feature::FogBank | Feature::TallGrass))
            || self.unlit(tile);
        if hidden {
            return;
        }
        let reach = self.landing_reach();
        let field = noise::field(&self.grid, tile, reach);
        let (grid, now) = (&self.grid, self.tick);
        for g in self.guards.iter_mut() {
            let heard = grid.tile_at(g.at.x, g.at.y)
                .is_some_and(|at| field[at as usize] != noise::UNHEARD);
            if heard && g.awake(now) {
                g.suspicion = g.suspicion.max(heist::LANDING_SUSPICION);
            }
        }
    }

    /// Laws. The sheet for this tick, from every law whose pylon still
    /// stands, so a pylon broken during a tick switches its law off from the
    /// next — the same tick on every machine. Parameters the simulation cannot
    /// apply yet are carried on the sheet and read by nothing; the content
    /// gate lists them.
    fn phase_laws(&mut self) {
        self.rejoin();
        self.find_terrain();
        self.stand_bridges();
        self.stand_walls();
        let now = self.tick;
        self.reveals.retain(|&(_, until)| now < until);
        self.refresh_sheet();
        self.zones.retain(|z| now < z.until);
        let crew: Vec<Point> = self.raiders.iter().filter(|r| r.active()).map(|r| r.at).collect();
        self.circles = self.zones.iter()
            .map(|z| (z.def, z.at.map_or_else(|| crew.clone(), |c| vec![c])))
            .collect();
        self.combinations();
        // A law switched off by its pylon takes its extra health with it:
        // nobody stands above the full health the sheet now reads.
        let sheet = self.sheet;
        for r in self.raiders.iter_mut() {
            r.health = r.health.min(r.full(&sheet));
        }
        for g in self.guards.iter_mut() {
            g.health = g.health.min(full_health(&sheet, g.role));
        }
        self.grid.free_climb = self.sheet.flag(Param::ClimbLevels).is_some_and(|v| v >= 1)
            || self.sheet.flag(Param::LeapObstacles).is_some_and(|v| v >= 1);
        self.grid.leap = self.sheet.flag(Param::LeapObstacles).is_some_and(|v| v >= 1);
        // "the heist clock runs 25% faster in this realm"
        let (n, d) = self.sheet.factor(Param::ClockRate);
        self.clock_run += (1000 * n / d) as u64;
    }

    /// §8's effects that come on a clock or at random, in a fixed order
    /// within the tick: the dissonances, then the chords.
    fn combinations(&mut self) {
        let now = self.tick;
        let c = self.combos;
        // Gusts and lulls (Flow against Weight): "everyone's speed changes by
        // ±20% at random every 10 seconds" — a coin for up or down.
        let gust = if !c.dissonance(note::FLOW) {
            (1, 1)
        } else if now > 0 && now % heist::GUST_TICKS == 0 {
            if self.rng.below(2) == 0 { (6, 5) } else { (4, 5) }
        } else {
            self.gust
        };
        if gust != self.gust {
            self.gust = gust;
            self.refresh_sheet();
        }
        // A light over the whole realm ends, then may start again.
        if self.light.is_some_and(|(_, until)| now >= until) {
            self.light = None;
        }
        // Flicker (Glow against Hush): bright or dark, a coin again.
        if c.dissonance(note::GLOW) && now > 0 && now % heist::FLICKER_TICKS == 0 {
            let bright = self.rng.below(2) == 0;
            self.light = Some((bright, now + heist::FLICKER_HOLD_TICKS));
        }
        // Tempest's lightning lights the whole realm for a second.
        if c.chord(Chord::Tempest) && now > 0 && now % heist::TEMPEST_TICKS == 0 {
            self.light = Some((true, now + heist::TEMPEST_FLASH_TICKS));
        }
        // Wildfire's flames go out.
        self.burning.retain(|&(_, until)| now < until);
        // Déjà vu (Echo against Veil): "once per heist, an illusion of the
        // crew appears somewhere else and draws guards".
        if c.dissonance(note::ECHO) && !self.deja_vu_spent {
            let at = *self.deja_vu.get_or_insert_with(|| {
                now + 1 + self.rng.below(heist::DEJA_VU_WINDOW_TICKS) as u32
            });
            if at == now {
                self.deja_vu_spent = true;
                if let Some(tile) = self.open_tile() {
                    for gi in 0..self.guards.len() {
                        self.lure(gi, tile);
                    }
                }
            }
        }
        // Fair lights: "floating lights form illusions of crew members that
        // draw guards away" — one at a time, drawing the nearest guard.
        if c.chord(Chord::FairLights) && now > 0 && now % heist::FAIR_LIGHTS_TICKS == 0 {
            if let Some(tile) = self.open_tile() {
                let (x, y) = self.grid.centre(tile);
                let spot = Point { x, y };
                let nearest = (0..self.guards.len())
                    .filter(|&gi| self.guards[gi].awake(now)
                        && self.guards[gi].state != guard::State::Alerted)
                    .min_by_key(|&gi| (self.guards[gi].at.distance(spot).0, gi));
                if let Some(gi) = nearest {
                    self.lure(gi, tile);
                }
            }
        }
        // Deep sleep: "every 20 seconds each guard dozes for 3 seconds".
        if c.chord(Chord::DeepSleep) && now > 0 && now % heist::DEEP_SLEEP_TICKS == 0 {
            for g in self.guards.iter_mut().filter(|g| !g.knocked_out) {
                g.stunned_until = g.stunned_until.max(now + heist::DOZE_TICKS);
            }
        }
        // Hidden garden: "tall grass spreads one tile a minute across the
        // realm" — to every open, bare tile beside it.
        if c.chord(Chord::HiddenGarden) && now > 0 && now % heist::HIDDEN_GARDEN_TICKS == 0 {
            let grow: Vec<grid::TileIndex> = (0..self.grid.len() as grid::TileIndex)
                .filter(|&t| self.bare(t) && self.grid.neighbours(t).iter().flatten()
                    .any(|&n| self.grid.feature(n) == Some(Feature::TallGrass)))
                .collect();
            for t in grow {
                let (x, y) = self.grid.coords(t);
                self.grid.place(x, y, Feature::TallGrass);
            }
        }
        // Quicksand: the pits open the first tick the chord sounds.
        if c.chord(Chord::Quicksand) && self.pits.is_empty() {
            for _ in 0..heist::QUICKSAND_PITS {
                if let Some(t) = self.open_tile() {
                    self.pits.push(t);
                }
            }
        }
    }

    /// Open ground with nothing on it: no feature, no ward, no pit, and not
    /// the crew's landing spot (§5.4). Where grass may spread and an
    /// illusion or a pit may form.
    fn bare(&self, t: grid::TileIndex) -> bool {
        self.grid.at(t).passable() && self.grid.feature(t).is_none()
            && self.landing != Some(t)
            && !self.wards.iter().any(|w| w.tile == t)
            && !self.pits.contains(&t)
    }

    /// A random bare tile: one draw, then the first bare tile from there on,
    /// wrapping, so the draw count never depends on the ground.
    fn open_tile(&mut self) -> Option<grid::TileIndex> {
        let n = self.grid.len() as u64;
        let start = self.rng.below(n);
        (0..n).map(|k| ((start + k) % n) as grid::TileIndex).find(|&t| self.bare(t))
    }

    /// An illusion or a sound on `tile` draws a guard: one below
    /// Investigating starts investigating it, one investigating turns to it,
    /// and an Alerted guard, chasing the crew itself, is not fooled.
    fn lure(&mut self, gi: usize, tile: grid::TileIndex) {
        let g = &self.guards[gi];
        if !g.awake(self.tick) || g.state.rank() > guard::State::Investigating.rank() {
            return;
        }
        self.guards[gi].interest = Some(tile);
        if self.guards[gi].state == guard::State::Investigating {
            self.aim(gi, Some(tile));
        } else {
            self.rise_because(gi, guard::State::Investigating, Cause::Lured);
        }
    }

    /// `rise`, logged with its cause; under Delay the rise lands later, and
    /// is logged then as the table's.
    fn rise_because(&mut self, gi: usize, state: guard::State, cause: Cause) {
        self.why = cause;
        self.rise(gi, state);
        self.why = Cause::Table;
    }

    /// A guard triggered into `state` by something other than its own
    /// suspicion — a lure, the alarm's spread: at once, or under Delay queued
    /// to land "3 seconds after" (G23), as a rise on suspicion is.
    fn rise(&mut self, gi: usize, state: guard::State) {
        match self.sheet.ticks(Param::EffectDelaySeconds) {
            Some(delay) => {
                let at = self.tick + delay;
                let g = &mut self.guards[gi];
                if !g.rising.iter().any(|&(_, s)| s.rank() >= state.rank()) {
                    g.rising.push((at, state));
                }
            }
            None => self.enter(gi, state),
        }
    }

    fn refresh_sheet(&mut self) {
        // A suspended law is off "for 10 s", its combinations with it (§11.7).
        let now = self.tick;
        let standing: Vec<usize> = self.laws.iter()
            .filter(|l| l.broken_at.is_none() && now >= l.suspended_until)
            .map(|l| l.def).collect();
        self.combos = Combos::of(&standing);
        let mut sheet = Sheet::plain();
        // §7.3: "Apply the Era, then the Grand Law, then crown laws, then the
        // realm's laws".
        for (p, n, d) in era::first_lines(self.era) {
            sheet.apply(p, n, d);
        }
        let turned: Vec<usize> = self.laws.iter()
            .filter(|l| l.broken_at.is_none() && now >= l.suspended_until && now < l.inverted_until)
            .map(|l| l.def).collect();
        for &def in &standing {
            if era::suspends(self.era, LAWS[def].id) {
                continue;
            }
            let shared = LAWS[def].notes & self.combos.harmonies;
            for &(p, n, d) in LAWS[def].params {
                let (n, d) = era::line(self.era, LAWS[def].school, p, n, d);
                let (n, d) = harmonised(p, n, d, shared);
                // The Tinkerer's Invert: the line's opposite, or nothing for
                // a line that has none.
                if turned.contains(&def) {
                    if let Some((n, d)) = opposite(p, n, d) {
                        sheet.apply(p, n, d);
                    }
                    continue;
                }
                sheet.apply(p, n, d);
            }
        }
        // Everyone's speed: Gusts and lulls, and Tempest's "everyone moves
        // 20% faster".
        let mut everyone = self.gust;
        if self.combos.chord(Chord::Tempest) {
            everyone = (everyone.0 * 6, everyone.1 * 5);
        }
        if everyone.0 != everyone.1 {
            sheet.apply(Param::CrewSpeed, everyone.0, everyone.1);
            sheet.apply(Param::GuardSpeed, everyone.0, everyone.1);
        }
        self.sheet = sheet;
    }

    /// Perception. §12.17: three graded zones inside a cone, filling at
    /// different rates, a weaker corner of the eye, and four modifiers.
    fn phase_perception(&mut self) {
        let now = self.tick;
        for gi in 0..self.guards.len() {
            if !self.guards[gi].awake(now) {
                continue;                     // down or stunned: sees nothing
            }
            // §12.17: the realm alarm climbs "once per knocked-out guard
            // discovered". Found by being seen, exactly as a raider is.
            for other in 0..self.guards.len() {
                if other != gi && self.guards[other].knocked_out && !self.guards[other].found
                    && self.sees_body(gi, self.guards[other].at)
                {
                    self.guards[other].found = true;
                    self.knockouts_discovered += 1;
                }
            }
            let mut gain = 0i32;
            // The raider noticed most this tick, ties to the lower id, so a
            // guard's interest is the same spot on every machine.
            let mut most: Option<(i32, grid::TileIndex)> = None;
            let mut who: Option<u8> = None;
            for ri in 0..self.raiders.len() {
                let Some((per_tick, to)) = self.noticed(gi, ri) else { continue };
                gain += per_tick;
                if most.is_none_or(|(g, _)| per_tick > g) {
                    most = Some((per_tick, to));
                    who = Some(ri as u8);
                }
            }
            // No jitter. §12.17: "nothing here is random: a player who scouts
            // an island can predict exactly what will happen." The spike's
            // first version added a random -1 to +1 a tick here, to put the
            // generator on the hot path, and in doing so broke the one
            // promise this section makes about itself.
            // Lantern Glare: it shows the crew, as if in the near zone,
            // looking at the tile that set it off — to every guard within
            // 4 m of that tile (F33, decided), a reach Whispers and the other
            // laws that widen the alarm leave alone (F52, decided); §10.3
            // still reads "every guard in the realm".
            if self.raiders.iter().any(|r| r.active()) {
                let reach = self.glare_reach();
                if let Some(spot) = self.glares.iter()
                    .filter(|&&(_, until)| now < until)
                    .map(|&(s, _)| s)
                    .find(|&s| {
                        let (x, y) = self.grid.centre(s);
                        self.guards[gi].at.distance(Point { x, y }) <= reach
                    })
                {
                    gain = gain.max(FILL_NEAR);
                    if most.is_none() {
                        most = Some((FILL_NEAR, spot));
                    }
                }
            }
            let guard = &mut self.guards[gi];
            guard.saw = most.is_some();
            guard.seen = who;
            if let Some((_, at)) = most {
                guard.interest = Some(at);
            }
            if gain > 0 {
                guard.suspicion = (guard.suspicion + gain).min(SUSPICION_MAX);
            } else {
                let (n, d) = self.sheet.factor(Param::SuspicionDecay);
                // From alarm level 1, "Suspicion empties at half its rate".
                let halve = if self.alarm >= guard::DECAY_HALVED_AT { 2 } else { 1 };
                guard.suspicion = (guard.suspicion
                    - DECAY_PER_TICK * n as i32 / (d as i32 * halve)).max(0);
            }
            // §12.13's closest call: "the tick a guard came nearest to
            // Alerted", counting only guards not already there.
            let (s, state) = (guard.suspicion, guard.state);
            if state != guard::State::Alerted && s > 0
                && self.log.closest.is_none_or(|(_, _, best)| s > best)
            {
                self.log.closest = Some((now, gi as u16, s));
            }
        }
    }

    /// How much one guard notices one raider this tick, and on which tile, or
    /// `None` if it does not. Pure: it reads the world and changes nothing,
    /// so the perception phase's order of guards cannot change its answer.
    pub fn noticed(&self, gi: usize, ri: usize) -> Option<(i32, grid::TileIndex)> {
        let guard = &self.guards[gi];
        let raider = &self.raiders[ri];
        if !raider.active() || !guard.awake(self.tick) {
            return None;
        }
        // Stillness: "Anyone standing still for 1.5 seconds becomes
        // invisible to guards."
        let here = zoned(&self.sheet, &self.circles, raider.at);
        if here.flag(Param::StillIsInvisible) == Some(1)
            && raider.still_for >= heist::STILL_TICKS
        {
            return None;
        }
        // A tunnel: "Nobody can see into it."
        if underground(&self.grid, raider).is_some() {
            return None;
        }
        // In range and in the cone is not enough: something between may
        // stop sight, checked below, last, because it is the costly test.
        // Mirage: "anything moving appears one tile from where it really
        // is" — a guard sees a walking crew member on the tile it just left.
        let seen_at = match raider.prev_tile {
            Some(t) if self.combos.chord(Chord::Mirage) && !raider.still() => {
                let (x, y) = self.grid.centre(t);
                Point { x, y }
            }
            _ => raider.at,
        };
        let (d, in_cone, from, to) = self.sees_geometry(gi, seen_at)?;
        if self.below_sight(from, to) {
            return None;
        }
        // A lantern post: "Lights 3 tiles: nothing hides inside the light".
        let lit = self.lantern_lit(to);
        // "Standing still in tall grass makes you invisible until a
        // guard walks into the tile."
        if raider.still() && from != to && !lit
            && self.grid.feature(to) == Some(Feature::TallGrass)
        {
            return None;
        }
        match self.grid.feature(to) {
            // A thicket, a shade canopy, a hot spring's steam: "hides anyone
            // inside beyond N tiles".
            Some(f) if !lit && f.hides_beyond().is_some_and(|n| d > Fx::from_int(n)) => {
                return None;
            }
            // A bush "hides one still character completely".
            Some(Feature::Bush) if !lit && raider.still()
                && self.raiders.iter().filter(|o| o.active()
                    && self.grid.tile_at(o.at.x, o.at.y) == Some(to)).count() == 1 =>
            {
                return None;
            }
            _ => {}
        }
        if !self.line_clear(from, to) {
            return None;
        }
        let sight = self.sight_at(to);
        // Beyond mid is the far zone, which height stretches or removes.
        let zone = if d <= scale(guard.near, sight) {
            FILL_NEAR
        } else if d <= scale(guard.mid, sight) {
            FILL_MID
        } else {
            FILL_FAR
        };
        let (mut num, mut den) = raider.gait.noticed();
        let (fn_, fd) = here.factor(Param::SuspicionFill);
        num *= fn_ as i32 * self.watch.0 .0;
        den *= fd as i32 * self.watch.0 .1;
        if self.unlit(to) && !lit {
            num *= UNLIT.0;
            den *= UNLIT.1;
        }
        // Scree: "Guards within 4 tiles notice 25% faster."
        if self.grid.feature(to) == Some(Feature::Scree)
            && guard.at.distance(raider.at) <= Fx::from_int(grid::SCREE_TILES)
        {
            num *= grid::SCREE_FILL.0;
            den *= grid::SCREE_FILL.1;
        }
        if !in_cone {
            num *= PERIPHERAL.0;
            den *= PERIPHERAL.1;
        }
        let per_tick = zone * num / den;
        Some((per_tick, to))
    }

    /// The tiles a guard's cone reaches, walls and laws included: what §21.12
    /// draws for the selected guard ("A tile is inside or outside"). Each
    /// tile's centre is put to the same geometry and sight line `noticed`
    /// uses, so the drawing cannot disagree with the rule. The corner of the
    /// eye is left out, since §21.12 draws the cone; a sleeping or stunned
    /// guard sees nothing.
    pub fn seen_tiles(&self, gi: usize) -> Vec<grid::TileIndex> {
        let Some(guard) = self.guards.get(gi) else { return Vec::new() };
        if !guard.awake(self.tick) {
            return Vec::new();
        }
        let mut out = Vec::new();
        for i in 0..self.grid.len() {
            let tile = i as grid::TileIndex;
            let (x, y) = self.grid.centre(tile);
            let Some((_, in_cone, from, to)) = self.sees_geometry(gi, Point { x, y }) else {
                continue;
            };
            if in_cone && self.line_clear(from, to) && !self.below_sight(from, to) {
                out.push(tile);
            }
        }
        out
    }

    /// Whether a guard sees a body. §12.8 (v3.3): "a body is seen exactly as
    /// a still crew member lying on its tile would be, so tall grass, a bush,
    /// fog or a tunnel hides it" — so it is `noticed`'s rules for a still
    /// raider, Stillness included, since a body has never moved.
    fn sees_body(&self, gi: usize, at: Point) -> bool {
        if zoned(&self.sheet, &self.circles, at).flag(Param::StillIsInvisible) == Some(1) {
            return false;
        }
        let Some((_, _, from, to)) = self.sees_geometry(gi, at) else { return false };
        if from != to && self.grid.feature(to) == Some(Feature::TallGrass) {
            return false;
        }
        !self.below_sight(from, to) && self.line_clear(from, to)
    }

    /// What ground hides from a guard looking down. An arch "blocks sight
    /// from above": a guard higher than the tile under it cannot see in.
    /// And "guards can't see the foot of their own cliff": a guard above a
    /// tile cannot see it when the tile before it on the line of sight is a
    /// drop — higher than it, no higher than the guard, and not a ramp.
    fn below_sight(&self, from: grid::TileIndex, to: grid::TileIndex) -> bool {
        let (lf, lt) = (self.grid.level(from), self.grid.level(to));
        if lf <= lt {
            return false;
        }
        if self.grid.feature(to) == Some(Feature::Arch) {
            return true;
        }
        let line = sight::line(&self.grid, from, to);
        line.len() >= 2 && {
            let edge = line[line.len() - 2];
            let le = self.grid.level(edge);
            le > lt && le <= lf && !self.grid.is_climbable(edge)
        }
    }

    /// The body a raider is dragging, if it is: a Drag task on a knocked-out
    /// guard lying on its tile or beside it. Beside is how a drag starts; once
    /// moving, the body is on the dragger's tile.
    fn dragging(&self, ri: usize) -> Option<usize> {
        let r = &self.raiders[ri];
        if r.task != Task::Drag || !r.acting(self.tick) {
            return None;
        }
        let gi = r.target as usize;
        let g = self.guards.get(gi).filter(|g| g.knocked_out)?;
        let body = self.grid.tile_at(g.at.x, g.at.y)?;
        let here = self.grid.tile_at(r.at.x, r.at.y)?;
        (body == here || self.grid.adjacent(body, here)).then_some(gi)
    }

    /// Whether sight passes between two tiles. Glass: "Walls become
    /// see-through: nobody can hide behind them".
    fn line_clear(&self, from: grid::TileIndex, to: grid::TileIndex) -> bool {
        let (x, y) = self.grid.centre(to);
        zoned(&self.sheet, &self.circles, Point { x, y }).flag(Param::HideBehindWalls) == Some(0)
            || sight::visible(&self.grid, from, to)
    }

    /// Distance, whether in the cone proper, and the two tiles — or `None`
    /// if the point is out of reach or outside both arcs.
    fn sees_geometry(&self, gi: usize, at: Point)
        -> Option<(Fx, bool, grid::TileIndex, grid::TileIndex)> {
        let guard = &self.guards[gi];
        let d = guard.at.distance(at);
        // A law may shorten sight — Glowing dark halves it, Sleepwalk closes
        // the guards' eyes — so every range is read through the sheet.
        if zoned(&self.sheet, &self.circles, guard.at).factor(Param::SightRange).0 == 0 {
            return None;
        }
        let from = self.grid.tile_at(guard.at.x, guard.at.y)?;
        let to = self.grid.tile_at(at.x, at.y)?;
        let reach = scale(self.outer_zone(gi, from, to), self.sight_at(to));
        // Hiding a tile closer (a Hush harmony) and seeing two tiles less
        // (Iron bell) are the same thing: whoever is looked at stands that
        // much further off, for the range and for which zone it is in.
        let bearing_d = d;
        let d = d + Fx::from_int(self.hiding_tiles());
        if d > reach {
            return None;
        }
        // The corner of the eye uses the same zones at half the rate.
        // §12.17 says only "weak peripheral awareness"; the half is
        // spec/detection.md's, and content/detection.json's.
        // At no distance there is no bearing — `bearing_to` answers east —
        // and a guard standing on someone sees them. The first version let
        // an Alerted guard converge onto a raider's own spot and lose it.
        let bearing = guard.at.bearing_to(at);
        let off = bearing.delta(guard.facing).0.abs();
        let in_cone = bearing_d.0 == 0 || off <= guard.cone.0 / 2;
        if !in_cone && off > guard.peripheral.0 / 2 {
            return None;
        }
        Some((d, in_cone, from, to))
    }

    /// §7.3's Sight row for someone standing on `tile` this tick: the sheet's
    /// range, and Aurora's bands. "Inside a band everyone can be seen from
    /// twice as far; between bands, vision halves." A band is
    /// `AURORA_BAND_ROWS` rows deep and crosses the realm north to south,
    /// entering and leaving it whole, once every period — so every row is
    /// lit once a sweep, and the period is the law's "every 10 seconds".
    fn sight_at(&self, tile: grid::TileIndex) -> (i64, i64) {
        let (x, y) = self.grid.centre(tile);
        let (n, d) = zoned(&self.sheet, &self.circles, Point { x, y }).factor(Param::SightRange);
        // The realm's watch scales every zone, as a law that shortens sight does.
        let (n, d) = (n * self.watch.1 .0, d * self.watch.1 .1);
        match self.in_band(tile) {
            None => (n, d),
            Some(true) => (n * 2, d),
            Some(false) => (n, d * 2),
        }
    }

    /// Whether a tile is inside Aurora's band this tick, or `None` with no
    /// band in the realm. A Glow harmony makes the band two rows deeper:
    /// "light and reveal ranges 2 tiles longer".
    fn in_band(&self, tile: grid::TileIndex) -> Option<bool> {
        let period = self.sheet.ticks(Param::LightBandSeconds)?.max(1) as i64;
        let w = heist::AURORA_BAND_ROWS
            + if self.combos.harmony(note::GLOW) { heist::GLOW_HARMONY_ROWS } else { 0 };
        let rows = self.grid.height as i64;
        let top = (self.tick as i64 % period) * (rows + w) / period - w;
        let y = self.grid.coords(tile).1 as i64;
        Some(top <= y && y < top + w)
    }

    /// The last tick any Lantern Glare still shows the crew, or 0.
    pub fn revealed_until(&self) -> u32 {
        self.glares.iter().map(|&(_, until)| until).max().unwrap_or(0)
    }

    /// How far the alarm spreads: §12.17's "guards within four metres",
    /// stretched by the sheet — Whispers sets the range to the whole
    /// universe (999). A Lantern Glare does not follow it: its reach is a
    /// fixed `guard::GLARE_METRES` (F52).
    fn spread_reach(&self) -> Fx {
        let (an, ad) = self.sheet.factor(Param::AlarmRange);
        // From alarm level 4 "The alarm spreads twice as far".
        let base = if self.alarm >= guard::SPREAD_DOUBLED_AT {
            guard::SPREAD_METRES * 2
        } else {
            guard::SPREAD_METRES
        };
        Fx::from_int((base as i64 * an / ad).min(1 << 20) as i32)
    }

    /// How far a Lantern Glare shows the crew: "within 4 m of it ... (8 m from
    /// alarm level 4, 12.17)" (§10.3), a reach the laws that widen the alarm
    /// leave alone (F52).
    fn glare_reach(&self) -> Fx {
        Fx::from_int(if self.alarm >= guard::SPREAD_DOUBLED_AT {
            guard::GLARE_METRES * 2
        } else {
            guard::GLARE_METRES
        })
    }

    /// How long an Investigating guard searches the spot: "ten seconds", and
    /// from alarm level 3 "20 seconds instead of 10".
    fn search_spot_ticks(&self) -> u32 {
        if self.alarm >= guard::SEARCH_LONGER_AT {
            guard::SEARCH_SPOT_LONG_TICKS
        } else {
            guard::SEARCH_SPOT_TICKS
        }
    }

    /// Whether a tile is dark this tick (§12.17's unlit modifier): its ground,
    /// unless a light is over the whole realm — Flicker's bright or dark
    /// seconds, Tempest's lightning — or Northern lights makes the bands
    /// "the only light".
    /// §5.4: how far a landing is heard, in walked tiles: six, stretched by
    /// a law's noise radius. What a landing picker says beside each spot.
    pub fn landing_reach(&self) -> u16 {
        let (ln, ld) = self.sheet.factor(Param::NoiseRadius);
        (heist::LANDING_HEARD_TILES as i64 * ln / ld).clamp(0, u16::MAX as i64 - 1) as u16
    }

    fn unlit(&self, tile: grid::TileIndex) -> bool {
        if let Some((bright, _)) = self.light {
            return !bright;
        }
        if self.combos.resonance(Res::NorthernLights) {
            return self.in_band(tile) != Some(true);
        }
        self.grid.is_unlit(tile)
    }

    /// Night runners' "darkness": the realm Glowing dark makes dark, save
    /// where a light falls — a bright flash, or Northern lights' bands.
    fn in_darkness(&self, tile: grid::TileIndex) -> bool {
        if let Some((bright, _)) = self.light {
            return !bright;
        }
        if self.combos.resonance(Res::NorthernLights) {
            return self.in_band(tile) != Some(true);
        }
        true
    }

    /// §8's speed changes that depend on where someone stands this tick:
    /// Night runners ("anyone in darkness moves 30% faster"), Mangrove banks
    /// ("river banks ... slow crews by a further 20%" — a bank is a tile
    /// beside water) and Shattered glass's shards. `crew` says which side.
    fn pace_here(&self, tile: Option<grid::TileIndex>, crew: bool, slowed_until: u32)
        -> (i64, i64) {
        let (mut n, mut d) = (1i64, 1i64);
        let Some(t) = tile else { return (n, d) };
        if self.combos.resonance(Res::NightRunners) && self.in_darkness(t) {
            n *= heist::NIGHT_RUNNERS_PACE.0;
            d *= heist::NIGHT_RUNNERS_PACE.1;
        }
        if crew && self.combos.resonance(Res::MangroveBanks)
            && self.grid.surface(t) != grid::Surface::Water
            && self.grid.neighbours(t).iter().flatten()
                .any(|&o| self.grid.surface(o) == grid::Surface::Water)
        {
            n *= heist::MANGROVE_PACE.0;
            d *= heist::MANGROVE_PACE.1;
        }
        if self.tick < slowed_until {
            n *= heist::SHARD_PACE.0;
            d *= heist::SHARD_PACE.1;
        }
        (n, d)
    }

    /// Tiles a guard's sight falls short by: a Hush harmony's "hiding works
    /// 1 tile closer to guards" and Iron bell's "see 2 tiles less".
    fn hiding_tiles(&self) -> i32 {
        let mut t = 0;
        if self.combos.harmony(note::HUSH) {
            t += heist::HUSH_HARMONY_TILES;
        }
        if self.combos.chord(Chord::IronBell) {
            t += heist::IRON_BELL_TILES;
        }
        t
    }

    /// How far a guard's outermost zone reaches toward a tile. §12.17: "A guard
    /// standing a level higher sees a metre further; one standing below loses
    /// its far zone entirely." A metre per level of the difference.
    fn outer_zone(&self, gi: usize, from: grid::TileIndex, to: grid::TileIndex) -> Fx {
        let g = &self.guards[gi];
        let (hg, ht) = (self.grid.level(from) as i32, self.grid.level(to) as i32);
        let outer = if g.far.0 > 0 { g.far } else { g.mid };
        if hg > ht {
            outer + Fx::from_int((hg - ht) * heist::HIGHER_GROUND_METRES)
        } else if hg < ht {
            g.mid
        } else {
            outer
        }
    }

    /// Movement. Raiders walk their route; guards sweep their cone.
    fn phase_movement(&mut self) {
        // Which bodies are being dragged, decided before anyone moves, so the
        // answer does not depend on the order raiders are taken in.
        let drags: Vec<Option<usize>> = (0..self.raiders.len())
            .map(|ri| self.dragging(ri)).collect();
        let slide = self.sheet.flag(Param::Slide) == Some(1);
        let rebound = self.sheet.is_set(Param::Rebound);
        let charging = self.sheet.is_set(Param::TouchStunSeconds);
        // Where each stands decides §8's pace changes, read before anyone
        // moves, like the drags.
        let now = self.tick;
        let crew_pace: Vec<(i64, i64)> = self.raiders.iter()
            .map(|r| {
                let (n, d) = self.pace_here(crew_tile(&self.grid, r), true, r.slowed_until);
                // The Stormhound's sprint: "60% faster for 4 s".
                let (n, d) = if r.running(Ability::Sprint, now) {
                    (n * ruleborn::SPRINT_PACE.0, d * ruleborn::SPRINT_PACE.1)
                } else {
                    (n, d)
                };
                // The Rambler's charge: "Speed ×2" while it runs its line.
                let (n, d) = if r.charging {
                    (n * ruleborn::CHARGE_PACE.0, d * ruleborn::CHARGE_PACE.1)
                } else {
                    (n, d)
                };
                // The Wanderer's Tailwind: "crew moves 40% faster for 6 s".
                if now < self.tailwind_until {
                    (n * ruleborn::TAILWIND_PACE.0, d * ruleborn::TAILWIND_PACE.1)
                } else {
                    (n, d)
                }
            })
            .collect();
        let guard_pace: Vec<(i64, i64)> = self.guards.iter()
            .map(|g| self.pace_here(self.grid.tile_at(g.at.x, g.at.y), false, g.slowed_until))
            .collect();
        // Tiles walked into this tick, for the features that act on whoever
        // enters them: (crew member, the tile, the tile it came from).
        let mut entered: Vec<(usize, grid::TileIndex, grid::TileIndex)> = Vec::new();
        for (ri, raider) in self.raiders.iter_mut().enumerate() {
            raider.landed = 0;
            raider.bounced = false;
            raider.still_for = if raider.still() && raider.active() {
                raider.still_for.saturating_add(1)
            } else {
                0
            };
            // The Mossbear "cannot move while rooted".
            if raider.still() || !raider.acting(self.tick)
                || raider.running(Ability::Root, self.tick)
            {
                continue;
            }
            // In a tunnel, the ground overhead is not underfoot: the walk is
            // the mouth's.
            let here = crew_tile(&self.grid, raider);
            // "At crouching speed", whatever gait the player last chose.
            let gait = if drags[ri].is_some() { Gait::Crouch } else { raider.gait };
            let sheet = zoned(&self.sheet, &self.circles, raider.at);
            let step = step_with(&self.grid, &sheet, raider, gait, here,
                                 raider.carried > 0, crew_pace[ri],
                                 raider.running(Ability::Unhindered, self.tick));
            let was = raider.along;
            let (at, along) = walk_route(&self.grid, raider.at, &raider.route, raider.along, step);
            raider.at = at;
            raider.along = along;
            if along >= raider.route.len() {
                raider.charging = false;
            }
            if let Some(gi) = drags[ri] {
                self.guards[gi].at = at;           // the body comes along
            }
            // Frictionless: reaching the end of a route is not stopping.
            if slide && was < raider.route.len() && along >= raider.route.len() {
                if let Some(next) = slide_on(&self.grid, &self.guards, raider, rebound) {
                    raider.route.push(next);
                }
            }
            // An ice sheet: "stopping takes 1 tile". A route that ends on ice
            // carries on one tile the way it was going, once.
            if !slide && !raider.skid && was < raider.route.len()
                && along >= raider.route.len()
                && raider.route.last().is_some_and(|&t| self.grid.feature(t)
                    == Some(Feature::IceSheet))
            {
                raider.skid = true;
                if let Some(next) = slide_on(&self.grid, &self.guards, raider, false) {
                    raider.route.push(next);
                }
            }
            // Dropped a level or more this tick: §12.17's landing noise.
            let there = crew_tile(&self.grid, raider);
            raider.landed = match (here, there) {
                (Some(a), Some(b)) => (self.grid.level(a) - self.grid.level(b)).max(0) as u8,
                _ => 0,
            };
            if let (Some(a), Some(b)) = (here, there) {
                if a != b {
                    entered.push((ri, b, a));
                }
            }
        }
        for (ri, tile, from) in entered {
            match self.grid.feature(tile) {
                // A marsh's "footprints stay for 10 seconds"; a flower meadow
                // "shows footprints for 10 seconds". Nothing in the heist
                // reads a footprint until a Trails law does, and none ships
                // at launch (§7.3): they are drawn, from the log.
                Some(Feature::Marsh) | Some(Feature::FlowerMeadow) => {
                    self.log.push(now, Event::Print { crew: ri as u8, tile: tile as u16 });
                }
                Some(Feature::BellPost) => self.ring(ri, tile),
                Some(Feature::BounceMushroom) => self.bounce(ri, from, tile),
                _ => {}
            }
        }
        // A guard that is not walking turns steadily at its role's rate, one
        // way, so a player watching it can say where it will face next. The
        // first version chose the direction at random each tick, which
        // §12.17 forbids for the same reason as the jitter above.
        let sweep = 1;
        for (gi, guard) in self.guards.iter_mut().enumerate() {
            if !guard.awake(now) {
                continue;
            }
            let sheet = zoned(&self.sheet, &self.circles, guard.at);
            let mut walk = scale(guard.speed, sheet.factor(Param::GuardSpeed)); // §11.1's, by role
            let size = by_size(&sheet, guard.role.size(), Param::LargeSpeed,
                               Param::SmallSpeed);
            if size != (1, 1) {
                walk = scale(walk, size);
            }
            if guard_pace[gi] != (1, 1) {
                walk = scale(walk, guard_pace[gi]);
            }
            use guard::State::*;
            match guard.state {
                // "Patrols or holds its post" — the fixture holds, facing the
                // way it was posted. The first version turned it at its full
                // turn rate, a Scout through 240 degrees a second, which is a
                // maximum, not an idle glance — and left no back to ambush.
                Unaware => {}
                // "Wider, faster searching" has no figure; Searching turns.
                Searching => {
                    guard.facing = Ang(guard.facing.0 + guard.turn_per_tick.0 * sweep).wrapped();
                }
                // "Stops, turns toward it."
                Suspicious => {
                    if let Some(spot) = guard.interest {
                        let (x, y) = self.grid.centre(spot);
                        guard.facing = guard.at.bearing_to(Point { x, y });
                    }
                }
                // These walk a route, facing the way they go.
                Investigating | Alerted | Returning => {
                    match guard.next_step(&self.grid) {
                        Some(target) => {
                            guard.facing = guard.at.bearing_to(target);
                            let (at, along) =
                                walk_route(&self.grid, guard.at, &guard.route, guard.along, walk);
                            guard.at = at;
                            guard.along = along;
                        }
                        None => {
                            // Arrived. Investigating starts its ten seconds
                            // here. Alerted has "converged" and faces what it
                            // converged on — turning away from a crew beside
                            // it would lose sight, drop it to Searching and
                            // restart its swing, which the first version did
                            // once a second. Everyone else looks about.
                            if guard.state == Investigating && guard.arrived_at.is_none() {
                                guard.arrived_at = Some(self.tick);
                            }
                            match (guard.state, guard.interest) {
                                (Alerted, Some(spot)) => {
                                    let (x, y) = self.grid.centre(spot);
                                    let p = Point { x, y };
                                    if p != guard.at {
                                        guard.facing = guard.at.bearing_to(p);
                                    }
                                }
                                _ => {
                                    guard.facing = Ang(guard.facing.0
                                        + guard.turn_per_tick.0 * sweep).wrapped();
                                }
                            }
                        }
                    }
                }
            }
        }
        self.static_touches(charging);
        if self.tick % (TICKS_PER_SECOND * grid::RAPIDS_SECONDS) == 0 {
            self.rapids();
        }
    }

    /// Rapids: "Pushes anyone 1 tile a second downstream" — on each whole
    /// second, whoever stands on rapids, crew and guards, goes one tile the
    /// way they run, if a step that way can be taken (TD.38). Where it was
    /// going stands: the route is recomputed from where the water left it,
    /// as a gravity well's pull does, because the order was the tile.
    fn rapids(&mut self) {
        let downstream = |grid: &Grid, at: Point| -> Option<(grid::TileIndex, grid::TileIndex)> {
            let tile = grid.tile_at(at.x, at.y)?;
            if grid.feature(tile) != Some(Feature::Rapids) {
                return None;
            }
            let mut next = tile;
            for _ in 0..grid::RAPIDS_TILES {
                let on = grid.ahead(next, grid.facing(next))?;
                if !grid.can_step(next, on) {
                    break;
                }
                next = on;
            }
            (next != tile).then_some((tile, next))
        };
        for ri in 0..self.raiders.len() {
            let r = &self.raiders[ri];
            if !r.active() || underground(&self.grid, r).is_some() {
                continue;
            }
            let Some((tile, next)) = downstream(&self.grid, r.at) else { continue };
            let goal = r.route.last().copied().filter(|&g| g != next);
            let route = goal.and_then(|g| path::find_through(&self.grid, next, g))
                .unwrap_or_default();
            let (x, y) = self.grid.centre(next);
            let r = &mut self.raiders[ri];
            r.at = Point { x, y };
            r.route = route;
            r.along = 0;
            r.came_from = tile;
        }
        for gi in 0..self.guards.len() {
            let g = &self.guards[gi];
            if g.knocked_out {
                continue;
            }
            let Some((_, next)) = downstream(&self.grid, g.at) else { continue };
            let goal = g.route.get(g.along..).and_then(|r| r.last().copied())
                .filter(|&t| t != next);
            let (x, y) = self.grid.centre(next);
            self.guards[gi].at = Point { x, y };
            if goal.is_some() {
                self.aim(gi, goal);
            }
        }
    }

    /// Static (§7.3's Stun row): "moving builds charge; after 5 tiles, the
    /// next touch stuns". Charge is counted a tile at a time while the law
    /// holds. A charged character touches another on its own tile or the
    /// next; the one it touches is stunned and the charge is spent. The crew
    /// is taken in id order, then the guards, and each touches the nearest
    /// it can, ties to the crew and the lower id, so the same stuns land in
    /// the same order everywhere. Allies are touched too: "crews that bunch
    /// up get stunned together".
    fn static_touches(&mut self, charging: bool) {
        let now = self.tick;
        // Who stepped onto a new tile this tick: (is a guard, index, tile).
        let mut entered: Vec<(bool, usize, grid::TileIndex)> = Vec::new();
        for (i, r) in self.raiders.iter_mut().enumerate() {
            // Under a tunnel's roof nothing on the ground is stepped on.
            let t = crew_tile(&self.grid, r);
            if t != r.last_tile {
                r.prev_tile = r.last_tile;
                r.last_tile = t;
                if charging && r.active() {
                    r.charge += 1;
                }
                if let (Some(t), true) = (t, r.active()) {
                    entered.push((false, i, t));
                }
            }
        }
        for (i, g) in self.guards.iter_mut().enumerate() {
            let t = self.grid.tile_at(g.at.x, g.at.y);
            if t != g.last_tile {
                g.prev_tile = g.last_tile;
                g.last_tile = t;
                if charging && !g.knocked_out {
                    g.charge += 1;
                }
                if let (Some(t), true) = (t, !g.knocked_out) {
                    entered.push((true, i, t));
                }
            }
        }
        for (guard, i, t) in entered {
            self.entered(guard, i, t);
        }
        let Some(stun) = self.sheet.ticks(Param::TouchStunSeconds) else { return };
        // Everyone who can touch or be touched: (is a guard, index, position).
        let bodies: Vec<(bool, usize, Point)> = self.raiders.iter().enumerate()
            .filter(|(_, r)| r.active()).map(|(i, r)| (false, i, r.at))
            .chain(self.guards.iter().enumerate()
                .filter(|(_, g)| !g.knocked_out).map(|(i, g)| (true, i, g.at)))
            .collect();
        for &(guard, i, at) in &bodies {
            let charge = if guard { self.guards[i].charge } else { self.raiders[i].charge };
            if charge < heist::STATIC_TILES {
                continue;
            }
            let here = self.grid.tile_at(at.x, at.y);
            let touched = bodies.iter()
                .filter(|&&(g2, j, p)| (g2, j) != (guard, i)
                    && here.zip(self.grid.tile_at(p.x, p.y))
                        .is_some_and(|(a, b)| self.grid.adjacent(a, b)))
                .min_by_key(|&&(_, _, p)| at.distance(p).0);
            let Some(&(g2, j, p)) = touched else { continue };
            self.hold(g2, j, now + stun);
            self.spark_on(self.grid.tile_at(p.x, p.y));
            // Rebound (Flow Echo Spark): "every stun bounces on to the
            // nearest enemy" — within the reach a chain jumps, once.
            if self.combos.chord(Chord::Rebound) {
                let enemy = bodies.iter()
                    .filter(|&&(g3, _, q)| g3 != g2
                        && p.distance(q) <= Fx::from_int(heist::CHAIN_TILES))
                    .min_by_key(|&&(_, k, q)| (p.distance(q).0, k));
                if let Some(&(g3, k, q)) = enemy {
                    self.hold(g3, k, now + stun);
                    self.spark_on(self.grid.tile_at(q.x, q.y));
                }
            }
            if guard {
                self.guards[i].charge = 0;
            } else {
                self.raiders[i].charge = 0;
            }
        }
    }

    /// Hold a character still until `until`: a stunned guard, a frozen crew
    /// member.
    fn hold(&mut self, guard: bool, i: usize, until: u32) {
        if guard {
            let g = &mut self.guards[i];
            g.stunned_until = g.stunned_until.max(until);
        } else {
            let r = &mut self.raiders[i];
            r.frozen_until = r.frozen_until.max(until);
        }
    }

    /// What a tile does to whoever steps onto it: Shattered glass's shards
    /// slow it, a Honey trap hedge beside it sticks it for a second, and a
    /// Quicksand pit drops it a level — a landing's noise, and a second to
    /// climb out.
    fn entered(&mut self, guard: bool, i: usize, t: grid::TileIndex) {
        let now = self.tick;
        if self.shards.contains(&t) {
            let until = now + heist::SHARD_TICKS;
            if guard {
                self.guards[i].slowed_until = until;
            } else {
                self.raiders[i].slowed_until = until;
            }
        }
        if self.combos.resonance(Res::HoneyTrap) {
            let sticky = |w: &Ward| w.kind == WardKind::ThornHedge && w.live() && w.regrown
                && (w.tile == t || self.grid.neighbours(t).contains(&Some(w.tile)));
            if self.wards.iter().any(sticky) {
                self.hold(guard, i, now + heist::HONEY_TICKS);
            }
        }
        if self.pits.contains(&t) {
            self.hold(guard, i, now + heist::PIT_HOLD_TICKS);
            if !guard {
                self.raiders[i].landed = self.raiders[i].landed.max(1);
            }
        }
    }

    /// Wildfire (Bloom against Spark): "hedges and grass hit by any spark
    /// effect burn for 5 seconds". A spark effect is a Spark law's landing on
    /// someone — a chain's jump, a static stun — or a hit on a hedge made
    /// harder by one (Brittle stone).
    fn spark_on(&mut self, tile: Option<grid::TileIndex>) {
        let Some(t) = tile else { return };
        if !self.combos.dissonance(note::BLOOM) {
            return;
        }
        let burns = self.grid.feature(t) == Some(Feature::TallGrass)
            || self.wards.iter().any(|w| w.tile == t && w.kind == WardKind::ThornHedge && w.live());
        if burns {
            self.burning.retain(|&(b, _)| b != t);
            self.burning.push((t, self.tick + heist::BURN_TICKS));
        }
    }

    /// Noise. §12.17: a sound carries a walkable distance, and a guard that
    /// hears one turns toward "the way around, not toward you" and starts
    /// investigating — the table's "600, or on hearing something".
    ///
    /// A raider makes the sound of its gait while it is walking a route; one
    /// standing still is silent. Raiders are taken in id order and each guard
    /// keeps the nearest sound it heard, ties to the earlier raider, so two
    /// sounds at the same distance resolve the same way everywhere.
    fn phase_noise(&mut self) {
        for guard in self.guards.iter_mut() {
            guard.heard = None;
        }
        let mut nearest: Vec<Option<(u16, grid::TileIndex, Option<grid::TileIndex>)>> =
            vec![None; self.guards.len()];
        for raider in self.raiders.iter() {
            // A hit on the Vault is §12.17's "Breaking something — 5 m",
            // made on the tick the hit lands (the states phase lands it).
            // A hit on the Vault or on a pylon is breaking something. The two
            // structures are told apart by the task; the tile beside is the
            // same test.
            let beside = |tile: grid::TileIndex| self.grid.tile_at(raider.at.x, raider.at.y)
                .is_some_and(|t| self.grid.neighbours(tile).contains(&Some(t)));
            let landing = raider.active() && raider.swing + 1 >= heist::HIT_TICKS;
            // A hit on the Vault is heard by no guard (F35); a pylon or a ward
            // broken still is.
            let breaking = raider.smashed || landing && match raider.task {
                heist::Task::Break => beside(raider.target) && (self.laws.iter()
                    .any(|l| l.pylon == raider.target && l.broken_at.is_none())
                    || self.wards.iter().any(|w| w.tile == raider.target && w.live())),
                _ => false,
            };
            let landing = match raider.landed {
                0 => None,
                1 => Some(noise::Sound::LandingOne),
                2 => Some(noise::Sound::LandingTwo),
                _ => Some(noise::Sound::LandingThree),
            };
            let landing = if raider.bounced { Some(noise::Sound::Bounce) } else { landing };
            if !breaking && landing.is_none() && (raider.still() || !raider.active()) {
                continue;                             // standing still is silent
            }
            let Some(source) = self.grid.tile_at(raider.at.x, raider.at.y) else { continue };
            // What it is walking on decides how far its gait carries. A
            // landing or a break is louder than any gait and is the sound made.
            let gait = if raider.task == heist::Task::Drag
                && self.guards.get(raider.target as usize).is_some_and(|g| g.knocked_out)
                && self.grid.tile_at(raider.at.x, raider.at.y) == self.guards
                    .get(raider.target as usize)
                    .and_then(|g| self.grid.tile_at(g.at.x, g.at.y))
            {
                Gait::Crouch                       // a body is dragged crouched
            } else {
                raider.gait
            };
            let footstep = !breaking && landing.is_none();
            // Wild hunt: "anyone running makes no noise at all".
            if footstep && gait == Gait::Run && self.combos.chord(Chord::WildHunt) {
                continue;
            }
            let sound = if breaking {
                noise::Sound::Breaking
            } else {
                landing.unwrap_or(gait.sound())
            };
            // From alarm level 2 "every noise ... carries 1 m further, except
            // a crouched step on moss".
            let surface = self.grid.surface(source);
            let (sx, sy) = self.grid.centre(source);
            let carry = zoned(&self.sheet, &self.circles, Point { x: sx, y: sy }).factor(Param::NoiseRadius);
            let mut reach = sound.steps_further(surface, carry,
                                                alarm_noise_extra(self.alarm, sound, surface));
            // Deep sleep's flowers muffle footsteps; Iron bell's every step
            // echoes, "guards hear 2 tiles further".
            if footstep && self.combos.chord(Chord::DeepSleep) {
                reach = reach.saturating_sub(heist::MUFFLED_STEPS);
            }
            if self.combos.chord(Chord::IronBell) {
                reach += heist::IRON_BELL_TILES as u16;
            }
            let field = noise::field(&self.grid, source, reach);
            for (gi, guard) in self.guards.iter().enumerate() {
                if !guard.awake(self.tick) {
                    continue;
                }
                let Some(at) = self.grid.tile_at(guard.at.x, guard.at.y) else { continue };
                let d = field[at as usize];
                if d == noise::UNHEARD {
                    continue;
                }
                if nearest[gi].is_none_or(|(best, _, _)| d < best) {
                    nearest[gi] = Some((d, source, noise::way_around(&self.grid, &field, at)));
                }
            }
        }
        for r in self.raiders.iter_mut() {
            r.smashed = false;
        }
        for (gi, heard) in nearest.into_iter().enumerate() {
            let Some((_, source, step)) = heard else { continue };
            let guard = &mut self.guards[gi];
            guard.heard = Some(source);
            // Turn toward the way around. Behind a wall that is along the
            // wall to its gap; in the open it is toward the raider.
            let look = step.unwrap_or(source);
            let (x, y) = self.grid.centre(look);
            guard.facing = guard.at.bearing_to(Point { x, y });
        }
    }

    /// States. §12.17's table, the spread of an alarm by distance, and the
    /// realm alarm with its one stated consequence.
    fn phase_states(&mut self) {
        use guard::State::*;
        let now = self.tick;

        // Spreads that are due. They were queued in (tick, guard) order and
        // are taken in that order.
        let due: Vec<_> = self.spreads.iter().copied().filter(|s| s.0 <= now).collect();
        self.spreads.retain(|s| s.0 > now);
        for (_, gi, spot) in due {
            if self.guards[gi].awake(now) && self.guards[gi].state.rank() < Investigating.rank() {
                self.guards[gi].interest = Some(spot);
                self.rise_because(gi, Investigating, Cause::Spread);
            }
        }

        for gi in 0..self.guards.len() {
            if !self.guards[gi].awake(now) {
                continue;
            }
            let g = &self.guards[gi];
            let current = g.state;
            let held = now.saturating_sub(g.state_since);
            let by_suspicion = guard::State::from_suspicion(g.suspicion);
            let mut next = current;
            // Why it would rise, for the log: what it saw this tick, else
            // what it heard.
            let seen_cause = match (g.saw, g.seen) {
                (true, Some(ri)) => Some(Cause::Saw(ri)),
                (true, None) => Some(Cause::Glare),
                _ => None,
            };
            let heard_cause = g.heard.is_some().then_some(Cause::Heard);

            // Hearing: "600, or on hearing something". Never a step down.
            if let Some(spot) = g.heard {
                if current.rank() < Investigating.rank() {
                    next = Investigating;
                    self.guards[gi].interest = Some(spot);
                }
            }
            // Rising on suspicion is immediate — except under Delay, where
            // "guards change state 3 seconds after they are triggered" (G23,
            // decided): a rise is queued, and lands at its tick unless the
            // guard has already risen as far. A rise queued before Delay's
            // pylon broke still lands at its tick. Falling is never delayed.
            if by_suspicion.rank() > next.rank() {
                next = by_suspicion;
            }
            let delay = self.sheet.ticks(Param::EffectDelaySeconds);
            if delay.is_some() || !self.guards[gi].rising.is_empty() {
                let g = &mut self.guards[gi];
                match delay {
                    Some(delay) if next.rank() > current.rank()
                        && !g.rising.iter().any(|&(_, s)| s.rank() >= next.rank()) =>
                    {
                        g.rising.push((now + delay, next));
                    }
                    _ => {}
                }
                let landed = g.rising.iter().filter(|&&(t, _)| t <= now)
                    .map(|&(_, s)| s).max_by_key(|s| s.rank());
                g.rising.retain(|&(t, _)| t > now);
                // Under Delay a fresh rise waits; without it (the pylon
                // broken) it is immediate, and a queued one can only add.
                let now_at = if delay.is_some() { current } else { next };
                next = match landed {
                    Some(s) if s.rank() > now_at.rank() => s,
                    _ => now_at,
                };
                g.rising.retain(|&(_, s)| s.rank() > next.rank());
            }
            // Falling waits half a second, then follows the table.
            if next == current && held >= guard::HOLD_TICKS {
                let g = &self.guards[gi];
                next = match current {
                    Suspicious if by_suspicion == Unaware => Unaware,
                    Investigating => match g.arrived_at {
                        Some(t) if now - t >= self.search_spot_ticks()
                            && by_suspicion.rank() < Suspicious.rank() => Returning,
                        _ => Investigating,
                    },
                    Alerted if !g.saw => Searching,
                    Searching if held >= guard::SEARCHING_TICKS => Returning,
                    Returning if g.along >= g.route.len() => Unaware,
                    other => other,
                };
            }
            // Alerted converges on where it last saw someone; a new sighting
            // on a different tile re-aims it.
            if next == Alerted && current == Alerted {
                let g = &self.guards[gi];
                if g.saw && g.interest.is_some() && g.route.last() != g.interest.as_ref() {
                    self.aim(gi, g.interest);
                }
            }
            if next != current {
                self.why = if next.rank() > current.rank() && by_suspicion.rank() >= next.rank() {
                    seen_cause.or(heard_cause).unwrap_or(Cause::Table)
                } else if next.rank() > current.rank() {
                    heard_cause.or(seen_cause).unwrap_or(Cause::Table)
                } else {
                    Cause::Table
                };
                self.enter(gi, next);
            }
        }

        // The realm alarm: one level every thirty seconds, one per knocked-out
        // guard discovered, never above six.
        // Bells rung under Delay land when their ring comes.
        let due = self.bells_due.iter().filter(|&&t| t <= now).count() as i32;
        self.bells_due.retain(|&t| t > now);
        self.bells_rung += due * grid::BELL_LEVELS;
        let before = self.alarm;
        self.alarm = ((now / guard::ALARM_STEP_TICKS) as i32 + self.knockouts_discovered
            + self.bells_rung).min(guard::ALARM_MAX);
        if self.alarm > before {
            let found = self.knockouts_discovered > self.found_logged;
            for level in before + 1..=self.alarm {
                self.log.push(now, Event::Alarm { level: level as u8, found });
            }
        }
        self.found_logged = self.knockouts_discovered;
        // "At 5 another Warden arrives at an entrance."
        if self.alarm >= guard::REINFORCE_AT && !self.reinforced {
            self.reinforced = true;
            let id = self.guards.len() as u32;
            let mut warden = make_guard(id, WARDEN, self.entrance, &self.grid);
            warden.state_since = now;
            self.guards.push(warden);
            self.log.push(now, Event::Reinforced { guard: id as u16 });
        }
        // At 6 "Every guard in the realm enters Searching", once, as the
        // level is reached: a guard already Alerted keeps chasing.
        if self.alarm >= guard::ALL_SEARCH_AT && !self.all_searching {
            self.all_searching = true;
            for gi in 0..self.guards.len() {
                let g = &self.guards[gi];
                if g.awake(now) && !matches!(g.state, Alerted | Searching) {
                    self.why = Cause::Alarm;
                    self.enter(gi, Searching);
                }
            }
        }

        self.settle();
    }

    /// The rest of the states phase: every rule that moves a crew member
    /// between Active, Down, Caught and Out, and the Vault between sealed and
    /// open. In this order, so that a hit, a revive and a boarding on the
    /// same tick resolve the same way everywhere:
    ///
    ///   guards' hits → knockouts → revives and captures → the Vault →
    ///   loading → the skiff → the clock
    fn settle(&mut self) {
        let now = self.tick;

        // §12.20: an Alerted guard hits a crew member beside it once every
        // 0.8 seconds for its Power. The wind-up runs while anyone is in
        // reach and restarts when nobody is; the hit lands on the lowest id
        // in reach, so "one at a time" is the order everywhere.
        for gi in 0..self.guards.len() {
            let g = &self.guards[gi];
            let in_reach = if g.state == guard::State::Alerted && g.awake(now) {
                self.grid.tile_at(g.at.x, g.at.y).and_then(|gt| {
                    self.raiders.iter().position(|r| {
                        r.active() && self.grid.tile_at(r.at.x, r.at.y)
                            .is_some_and(|rt| self.grid.adjacent(gt, rt))
                    })
                })
            } else {
                None
            };
            let g = &mut self.guards[gi];
            match in_reach {
                None => g.swing = 0,
                Some(ri) => {
                    g.swing += 1;
                    if g.swing >= heist::HIT_TICKS {
                        g.swing = 0;
                        let (n, d) = zoned(&self.sheet, &self.circles, g.at).factor(Param::Damage);
                        let power = g.power as i64 * n / d;
                        self.raiders[ri].hurt_by = Hurt::Guard(gi as u16);
                        self.strike_raider(ri, power as i32, true);
                    }
                }
            }
        }

        // §12.20: the crew hits back, "at any moment", once every 0.8
        // seconds for its Power, at the guard it was told to attack. §12.8:
        // a guard that has not noticed the crew is ambushed — stunned for two
        // seconds for triple Power or half its full health, whichever is
        // greater — and a stunned guard still has not noticed, so "two
        // ambush hits knock out a guard of equal level". Any other hit sends
        // its suspicion "straight to 1000".
        for ri in 0..self.raiders.len() {
            let r = &self.raiders[ri];
            if r.task != Task::Attack {
                continue;                     // its swing, if any, is at the Vault
            }
            let gi = r.target as usize;
            let reach = r.acting(now)
                && self.guards.get(gi).is_some_and(|g| {
                    !g.knocked_out
                        && self.grid.tile_at(g.at.x, g.at.y)
                            .zip(self.grid.tile_at(r.at.x, r.at.y))
                            .is_some_and(|(a, b)| self.grid.adjacent(a, b))
                });
            if !reach {
                self.raiders[ri].swing = 0;
                continue;
            }
            self.raiders[ri].swing += 1;
            // Against an Unaware guard the swing is a takedown, and lands at
            // two seconds; against any other, at the ordinary 0.8. A guard
            // that notices mid-takedown has, by then, a swing past 0.8 on it,
            // which lands at once as an ordinary hit.
            let unaware = self.guards[gi].state == guard::State::Unaware;
            let due = if unaware { heist::TAKEDOWN_TICKS } else { heist::HIT_TICKS };
            if self.raiders[ri].swing < due {
                continue;
            }
            self.raiders[ri].swing = 0;
            let (dn, dd) = zoned(&self.sheet, &self.circles, self.raiders[ri].at).factor(Param::Damage);
            let power = (self.raiders[ri].role.power() as i64 * dn / dd) as i32;
            let blow = if unaware {
                // "It deals exactly what the guard has left."
                self.guards[gi].health
            } else {
                self.guards[gi].suspicion = SUSPICION_MAX;
                power
            };
            self.strike_guard(gi, blow, true);
        }

        self.wards_act();
        if now % TICKS_PER_SECOND == 0 && self.sheet.is_set(Param::TouchDamage) {
            self.thorns();
        }

        self.shield();

        // "A crew member at zero health drops its loot on the tile." Echoes
        // returns it at once, loot already dropped, the first time only.
        let revival = self.revival();
        let sheet = self.sheet;
        let drifting = self.combos.resonance(Res::DriftingEchoes);
        // The Echoplate standing over the crew: "a crew member knocked out
        // within 3 tiles of it, itself included, returns at once at 40% of
        // its full health (12.20)". Every time, while it stands.
        let over: Vec<Point> = self.raiders.iter()
            .filter(|r| r.active() && r.running(Ability::StandOver, now))
            .map(|r| r.at)
            .collect();
        for raider in self.raiders.iter_mut() {
            if raider.active() && raider.health <= 0
                && over.iter().any(|p| p.distance(raider.at)
                    <= Fx::from_int(ruleborn::STAND_OVER_TILES))
            {
                if raider.carried > 0 {
                    if let Some(t) = self.grid.tile_at(raider.at.x, raider.at.y) {
                        self.dropped.push((t, raider.carried));
                    }
                    raider.carried = 0;
                }
                let (n, d) = ruleborn::STAND_OVER_RETURN;
                raider.health = ((raider.full(&sheet) as i64 * n / d) as i32).max(1);
                let crew = raider.id as u8;
                self.log.push(now, Event::Down { crew, by: raider.hurt_by });
                self.log.push(now, Event::Back { crew, how: Back::Echoplate });
                continue;
            }
            if raider.active() && raider.health <= 0 {
                raider.route.clear();
                raider.along = 0;
                if raider.carried > 0 {
                    if let Some(t) = self.grid.tile_at(raider.at.x, raider.at.y) {
                        self.dropped.push((t, raider.carried));
                    }
                    raider.carried = 0;
                }
                self.log.push(now, Event::Down { crew: raider.id as u8, by: raider.hurt_by });
                match revival {
                    Some(Revival::Return(n, d)) if !raider.revived => {
                        raider.revived = true;
                        raider.health = ((raider.full(&sheet) as i64 * n / d) as i32).max(1);
                        // Drifting echoes: the echo may float over one wall.
                        raider.wall_pass = drifting;
                        self.log.push(now, Event::Back { crew: raider.id as u8, how: Back::Law });
                    }
                    _ => {
                        raider.health = 0;
                        raider.standing = Standing::Down;
                        raider.down_since = now;
                        raider.revive = 0;
                    }
                }
            }
        }

        let ghost_tide = self.combos.chord(Chord::GhostTide);
        // "An ally standing adjacent revives it in 3 seconds, a Mender in
        // 1.5", else "ten seconds before capture". The helper is the lowest
        // id beside it; with none, the revive starts again.
        for ri in 0..self.raiders.len() {
            if self.raiders[ri].standing != Standing::Down {
                continue;
            }
            let here = self.grid.tile_at(self.raiders[ri].at.x, self.raiders[ri].at.y);
            let helper = self.raiders.iter().enumerate().find(|(oi, o)| {
                *oi != ri && o.active()
                    && here.zip(self.grid.tile_at(o.at.x, o.at.y))
                        .is_some_and(|(a, b)| self.grid.adjacent(a, b))
            }).map(|(_, o)| o.role);
            let r = &mut self.raiders[ri];
            match helper {
                Some(role) => {
                    r.revive += 1;
                    let need = if role == Role::Mender {
                        heist::MENDER_REVIVE_TICKS
                    } else {
                        heist::REVIVE_TICKS
                    };
                    if r.revive >= need {
                        let (n, d) = heist::REVIVE_HEALTH;
                        r.health = (r.full(&self.sheet) * n / d).max(1);
                        r.standing = Standing::Active;
                        r.revive = 0;
                        self.log.push(now, Event::Back { crew: r.id as u8, how: Back::Ally });
                        continue;
                    }
                }
                None => r.revive = 0,
            }
            if now - r.down_since >= heist::DOWN_TICKS {
                if ghost_tide {
                    // Ghost tide (Flow Echo Hush): "knocked-out characters
                    // drift back to where they entered the realm instead of
                    // being caught" — to the landing spot (§5.4), on its
                    // feet at the revive health. A world built by hand,
                    // which never landed, sends it where `on_ground` put it.
                    let (n, d) = heist::REVIVE_HEALTH;
                    let tile = self.landing
                        .unwrap_or_else(|| self.grid.index(r.id as u16, 0).unwrap_or(0));
                    let (x, y) = self.grid.centre(tile);
                    r.at = Point { x, y };
                    r.came_from = tile;
                    r.last_tile = Some(tile);
                    r.route.clear();
                    r.along = 0;
                    r.health = (r.full(&self.sheet) * n / d).max(1);
                    r.standing = Standing::Active;
                    r.revive = 0;
                    self.log.push(now, Event::Back { crew: r.id as u8, how: Back::GhostTide });
                } else {
                    r.standing = Standing::Caught;
                    self.log.push(now, Event::Caught { crew: r.id as u8, clock: false });
                }
            }
        }

        // The Vault. A crew member told to crack, standing beside it, swings
        // every 0.8 seconds for its Power, a Breaker for double.
        if self.vault.opened_at.is_none() {
            // §11.1 (v3.3), the assist bonus: "While two or more characters
            // work the same object, every hit on it deals 25% more. It does
            // not stack." Counted before anyone swings, so it does not depend
            // on the order the crew is taken in.
            let vault = self.vault.tile;
            let working = self.raiders.iter().filter(|r| {
                r.task == Task::Crack && r.acting(now)
                    && self.grid.tile_at(r.at.x, r.at.y)
                        .is_some_and(|t| self.grid.neighbours(vault).contains(&Some(t)))
            }).count();
            let (an, ad) = if working >= 2 { heist::ASSIST_BONUS } else { (1, 1) };
            for raider in self.raiders.iter_mut() {
                let beside = self.grid.tile_at(raider.at.x, raider.at.y)
                    .is_some_and(|t| self.grid.neighbours(self.vault.tile).contains(&Some(t)));
                if raider.task != Task::Crack {
                    continue;                 // its swing, if any, is at a guard
                }
                if !(raider.acting(now) && beside) {
                    raider.swing = 0;
                    continue;
                }
                raider.swing += 1;
                if raider.swing >= heist::HIT_TICKS {
                    raider.swing = 0;
                    let (n, d) = if raider.role == Role::Breaker {
                        heist::BREAKER_VAULT_DAMAGE
                    } else {
                        (1, 1)
                    };
                    let (sn, sd) = zoned(&self.sheet, &self.circles, raider.at).factor(Param::StructureDamage);
                    // The Quarryback's pound: "its hits on the Vault, pylons
                    // and wards deal 50% more".
                    let (pn, pd) = if raider.running(Ability::Pound, now) {
                        ruleborn::POUND_HIT
                    } else {
                        (1, 1)
                    };
                    self.vault.health -= (raider.role.power() as i64 * n as i64 * sn * an * pn
                        / (d as i64 * sd * ad * pd)) as i32;
                }
            }
            // No guard hears the Vault (F35, decided): v3.4's call "every 5
            // seconds of cracking" to every guard within 5 m of the walk is
            // gone, and so is the hit's own noise. A guard beside it still
            // sees the crew.
            if self.vault.health <= 0 {
                self.vault.health = 0;
                self.vault.opened_at = Some(now);
                self.log.push(now, Event::Vault);
                // Cracked gardens: "broken structures leave Essence that the
                // owner collects after the heist" — the Vault among them.
                self.cracked += self.combos.resonance(Res::CrackedGardens) as u32;
            }
        } else {
            // §12.19: "Every role can load, at 30 units a second", to the
            // target, until the bag is full or the exposed share is gone. In
            // id order, so who gets the last units is the same everywhere.
            let per_tick = heist::LOAD_PER_SECOND / TICKS_PER_SECOND as i32;
            for ri in 0..self.raiders.len() {
                let raider = &self.raiders[ri];
                let beside = self.grid.tile_at(raider.at.x, raider.at.y)
                    .is_some_and(|t| self.grid.neighbours(self.vault.tile).contains(&Some(t)));
                if !(raider.acting(now) && raider.task == Task::Load && beside) {
                    continue;
                }
                // §12.6: "the crew loads to whatever that target and the
                // remaining clock afford". It stops when the clock left no
                // longer covers getting out — the walk to the skiff, or the
                // skiff's own arrival if that is later.
                if !self.clock_affords(ri) {
                    continue;
                }
                let raider = &mut self.raiders[ri];
                let target = raider.role.carry() * raider.target_fill / 100;
                // The Skyskipper's satchel: "loads at 60 a second instead of
                // 30 for 5 s".
                let rate = if raider.running(Ability::Satchel, now) {
                    per_tick * ruleborn::SATCHEL_RATE
                } else {
                    per_tick
                };
                let take = rate.min(target - raider.carried).min(self.vault.exposed);
                if take > 0 {
                    raider.carried += take;
                    self.vault.exposed -= take;
                }
            }
        }

        // Law Pylons (§12.6), struck like the Vault by whoever was told to
        // break one, from beside it; Breakers double (§11.1: "Double damage to
        // wards, pylons and the Vault"). At zero its law is off from the next
        // tick for the rest of the heist, and its page is the crew's.
        // Who is working which structure, before anyone swings: the assist
        // bonus is per object.
        let breakers: Vec<Option<grid::TileIndex>> = self.raiders.iter().map(|r| {
            let beside = self.grid.tile_at(r.at.x, r.at.y)
                .is_some_and(|t| self.grid.neighbours(r.target).contains(&Some(t)));
            (r.task == Task::Break && r.acting(now) && beside).then_some(r.target)
        }).collect();
        for ri in 0..self.raiders.len() {
            let r = &self.raiders[ri];
            if r.task != Task::Break {
                continue;
            }
            // A hedge is "cut through in 3 seconds" by anyone; a boulder a
            // Breaker "smashes in about 6 seconds", and nobody else can.
            let need = match self.grid.feature(r.target) {
                Some(Feature::Hedge) => Some(grid::HEDGE_CUT_SECONDS * TICKS_PER_SECOND),
                Some(Feature::Boulder) if r.role == Role::Breaker => {
                    Some(grid::BOULDER_SMASH_SECONDS * TICKS_PER_SECOND)
                }
                Some(Feature::Boulder) => Some(0),
                _ => None,
            };
            if let Some(need) = need {
                let beside = self.grid.tile_at(r.at.x, r.at.y)
                    .is_some_and(|t| self.grid.neighbours(r.target).contains(&Some(t)));
                if need == 0 || !beside || !r.acting(now) {
                    self.raiders[ri].swing = 0;
                    continue;
                }
                self.raiders[ri].swing += 1;
                if self.raiders[ri].swing >= need {
                    let t = self.raiders[ri].target;
                    self.grid.clear(t);
                    self.raiders[ri].swing = 0;
                    self.raiders[ri].task = Task::None;
                }
                continue;
            }
            let r = &self.raiders[ri];
            let li = self.laws.iter().position(|l| l.pylon == r.target && l.broken_at.is_none());
            let wi = self.wards.iter().position(|w| w.tile == r.target && w.live());
            let beside = self.grid.tile_at(r.at.x, r.at.y)
                .is_some_and(|t| self.grid.neighbours(r.target).contains(&Some(t)));
            if (li.is_none() && wi.is_none()) || !beside || !r.acting(now) {
                self.raiders[ri].swing = 0;
                continue;
            }
            self.raiders[ri].swing += 1;
            if self.raiders[ri].swing < heist::HIT_TICKS {
                continue;
            }
            self.raiders[ri].swing = 0;
            let role = self.raiders[ri].role;
            let (n, d) = if role == Role::Breaker { heist::BREAKER_VAULT_DAMAGE } else { (1, 1) };
            let (sn, sd) = zoned(&self.sheet, &self.circles, self.raiders[ri].at)
                .factor(Param::StructureDamage);
            let together = breakers.iter().filter(|t| **t == Some(self.raiders[ri].target)).count();
            let (an, ad) = if together >= 2 { heist::ASSIST_BONUS } else { (1, 1) };
            let (pn, pd) = if self.raiders[ri].running(Ability::Pound, now) {
                ruleborn::POUND_HIT
            } else {
                (1, 1)
            };
            let hit = (role.power() as i64 * n as i64 * sn * an * pn
                / (d as i64 * sd * ad * pd)) as i32;
            let cracking = self.combos.resonance(Res::CrackedGardens);
            if let Some(li) = li {
                let law = &mut self.laws[li];
                law.health -= hit;
                if law.health <= 0 {
                    law.health = 0;
                    law.broken_at = Some(now);
                    self.cracked += cracking as u32;
                    self.log.push(now, Event::Pylon { law: li as u16 });
                }
            } else if let Some(wi) = wi {
                // Shattered glass (Glass + Brittle stone): "glass walls break
                // in one hit, leaving shards". The Crystal Wall is the one
                // wall that breaks.
                let shatter = self.combos.resonance(Res::ShatteredGlass)
                    && self.wards[wi].kind == WardKind::CrystalWall;
                // A hit made harder by a Spark law sets a hedge alight
                // under Wildfire.
                if self.wards[wi].kind == WardKind::ThornHedge
                    && self.sheet.is_set(Param::StructureDamage)
                {
                    self.spark_on(Some(self.wards[wi].tile));
                }
                // §11.1: "Double damage to wards". A broken Crystal Wall is
                // open ground again.
                let w = &mut self.wards[wi];
                w.health -= if shatter { w.health } else { hit };
                if w.health <= 0 {
                    w.health = 0;
                    w.broken = true;
                    w.broken_at = Some(now);
                    self.cracked += cracking as u32;
                    if w.kind == WardKind::CrystalWall {
                        let t = w.tile;
                        self.grid.clear(t);
                        if shatter {
                            self.shards.push(t);
                        }
                    }
                }
                // Bounce (§7.3's Contact row): "walls and wards bounce back
                // 50% of what hits them". A Warden absorbs it.
                if self.sheet.is_set(Param::Rebound) && role != Role::Warden {
                    let (rn, rd) = self.sheet.factor(Param::Rebound);
                    self.raiders[ri].health -= (hit as i64 * rn / rd) as i32;
                    self.raiders[ri].hurt_by = Hurt::Law;
                }
            }
        }

        // Healing laws, once a second (§7): Kinship — "characters standing
        // next to an ally heal each other 1.5% a second" — and Regrowth —
        // "buildings, wards and guards heal 2% of their health each second".
        // A share of full health, rounded down. Nothing broken or knocked out
        // comes back: a law that revives is a different rule.
        if now % TICKS_PER_SECOND == 0 {
            self.heal();
            self.terrain_acts();
            self.shield();
        }
        // The Gardener's Renew: "heal the crew 30% over 5 s" — a fifth of it
        // at each of the five seconds after.
        if let Some(from) = self.renew_from {
            let k = now - from;
            if k > 0 && k % TICKS_PER_SECOND == 0 && k <= ruleborn::RENEW_SECONDS * TICKS_PER_SECOND {
                let (n, d) = ruleborn::RENEW_HEAL;
                let sheet = self.sheet;
                for r in self.raiders.iter_mut().filter(|r| r.active()) {
                    let full = r.full(&sheet);
                    r.health = (r.health + full * n / (d * ruleborn::RENEW_SECONDS as i32))
                        .min(full);
                }
            }
        }
        // Bloom: "cut hedges regrow after 10 seconds", whole and live.
        // Briar maze (Thorns + Bloom): "cut hedges regrow thorny and one tile
        // wider" — a second hedge on the first bare side, north, east,
        // south, west.
        if let Some(after) = self.sheet.ticks(Param::RegrowSeconds) {
            let mut grown = Vec::new();
            for w in self.wards.iter_mut() {
                if w.kind == WardKind::ThornHedge && w.broken
                    && w.broken_at.is_some_and(|t| now >= t + after)
                {
                    *w = heist::Ward { armed_at: w.armed_at, disarmed: w.disarmed, regrown: true,
                                       ..heist::Ward::new(w.kind, w.tile) };
                    grown.push(w.tile);
                }
            }
            if self.combos.resonance(Res::BriarMaze) {
                for t in grown {
                    let side = self.grid.neighbours(t).into_iter().flatten()
                        .find(|&n| self.bare(n));
                    if let Some(n) = side {
                        self.wards.push(heist::Ward { regrown: true,
                            ..heist::Ward::new(WardKind::ThornHedge, n) });
                    }
                }
            }
        }
        // Wildfire's flames hurt anyone inside, once a second.
        if now % TICKS_PER_SECOND == 0 && !self.burning.is_empty() {
            self.burn();
            self.shield();
        }

        // §5.4: "The crew must hold the spot until it arrives." Anyone on the
        // spot once it has arrived is aboard, with what it carries banked.
        if let Some(skiff) = self.skiff {
            if now >= skiff.arrives {
                for raider in self.raiders.iter_mut() {
                    if raider.active()
                        && self.grid.tile_at(raider.at.x, raider.at.y) == Some(skiff.tile)
                    {
                        raider.standing = Standing::Out;
                        raider.route.clear();
                        raider.along = 0;
                        self.log.push(now, Event::Out { crew: raider.id as u8,
                                                        carried: raider.carried });
                    }
                }
            }
        }

        // §12.6: "Anyone still inside when the clock ends is caught and drops
        // what it carries."
        if self.clock_run >= self.clock as u64 * 1000 {
            for raider in self.raiders.iter_mut() {
                if matches!(raider.standing, Standing::Active | Standing::Down) {
                    raider.standing = Standing::Caught;
                    self.log.push(now, Event::Caught { crew: raider.id as u8, clock: true });
                    if raider.carried > 0 {
                        if let Some(t) = self.grid.tile_at(raider.at.x, raider.at.y) {
                            self.dropped.push((t, raider.carried));
                        }
                        raider.carried = 0;
                    }
                }
            }
        }
    }

    /// §10.3's wards: disarming, then the triggered wards (the first crew
    /// member in the area, in id order), the Static Coil's pulse and the
    /// Thorn Hedge's thorns. Damage is a share of the target's full health,
    /// rounded down.
    fn wards_act(&mut self) {
        let now = self.tick;
        // Disarming (v3.3): standing on the ward's own tile, still, for
        // fifteen seconds at every level, silent. A frozen or blinded
        // disarmer is still on the tile, so its progress waits rather than
        // resets; "stepping off starts it again". v3.4 (G16, brief 37):
        // "while it disarms, the ward's sensor ignores that crew member" —
        // below, a raider standing on the tile it was sent to disarm does
        // not trip it. The walk there is not covered, so a Well or a Glare
        // still fires on a disarmer crossing its reach (G18).
        for wi in 0..self.wards.len() {
            let w = &self.wards[wi];
            if !w.live() || w.kind.passive() {
                continue;
            }
            let on = self.raiders.iter().position(|r| {
                r.task == Task::Disarm && r.target == w.tile && r.active()
                    && self.grid.tile_at(r.at.x, r.at.y) == Some(w.tile)
            });
            let Some(ri) = on else {
                self.wards[wi].disarm = 0;
                continue;
            };
            let r = &self.raiders[ri];
            if !r.acting(now) || !r.still() {
                continue;
            }
            let w = &mut self.wards[wi];
            w.disarm += 1;
            if w.disarm >= w.disarm_ticks() {
                w.disarmed = true;
            }
        }

        // Effects triggered under Delay land now, in the order they were set
        // off, whether or not the ward has since been broken or disarmed.
        let due: Vec<(u32, usize, usize)> =
            self.delayed.iter().filter(|e| e.0 == now).copied().collect();
        self.delayed.retain(|e| e.0 != now);
        for (_, wi, first) in due {
            self.fire_ward(wi, first);
        }

        // Clockwork (Weight Spark Echo): "every 15 seconds all wards in the
        // realm trigger together". Each live triggered ward fires as if set
        // off and resets; a Time Snare catches whoever stands on it, and with
        // nobody there catches nobody. A Static Coil's pulse, every three
        // seconds, already falls on every fifteenth.
        if self.combos.chord(Chord::Clockwork) && now > 0 && now % heist::CLOCKWORK_TICKS == 0 {
            for wi in 0..self.wards.len() {
                let (kind, tile, live) = (self.wards[wi].kind, self.wards[wi].tile, self.wards[wi].live());
                let live = live && now >= self.wards[wi].held_until;
                if !live || !matches!(kind, WardKind::TimeSnare | WardKind::GravityWell
                                      | WardKind::LanternGlare) {
                    continue;
                }
                let on = self.raiders.iter()
                    .position(|r| r.active() && self.grid.tile_at(r.at.x, r.at.y) == Some(tile));
                self.wards[wi].armed_at = now + kind.reset_ticks();
                let first = match (kind, on) {
                    (WardKind::TimeSnare, None) => continue,
                    (_, on) => on.unwrap_or(0),
                };
                match self.sheet.ticks(Param::EffectDelaySeconds) {
                    Some(delay) => self.delayed.push((now + delay, wi, first)),
                    None => self.fire_ward(wi, first),
                }
            }
        }

        let tile_of = |p: Point, g: &Grid| g.tile_at(p.x, p.y);
        for wi in 0..self.wards.len() {
            let w = self.wards[wi].clone();
            // A ward the Stillwatch froze does nothing until it thaws.
            if !w.live() || now < w.held_until {
                continue;
            }
            let (wx, wy) = self.grid.centre(w.tile);
            let centre = Point { x: wx, y: wy };
            let within = |p: Point, r: i32| p.distance(centre) <= Fx::from_int(r);
            match w.kind {
                WardKind::StaticCoil if now > 0 && now % heist::COIL_PERIOD_TICKS == 0 => {
                    let (n, d) = heist::COIL_DAMAGE;
                    let (sn, sd) = era::ward_strength(self.era, WardKind::StaticCoil);
                    let (n, d) = (n as i64 * sn, d as i64 * sd);
                    for r in self.raiders.iter_mut() {
                        if r.active() && within(r.at, heist::COIL_RADIUS) {
                            r.health -= (r.full(&self.sheet) as i64 * n / d) as i32;
                            r.hurt_by = Hurt::Ward(wi as u16);
                            self.log.push(now, Event::Ward { ward: wi as u16, crew: r.id as u8 });
                        }
                    }
                }
                WardKind::ThornHedge if now % TICKS_PER_SECOND == 0 => {
                    let (n, d) = heist::HEDGE_DAMAGE;
                    for r in self.raiders.iter_mut() {
                        if r.active() && tile_of(r.at, &self.grid) == Some(w.tile) {
                            r.health -= r.full(&self.sheet) * n / d;
                            r.hurt_by = Hurt::Ward(wi as u16);
                        }
                    }
                }
                WardKind::TimeSnare | WardKind::GravityWell | WardKind::LanternGlare
                    if now >= w.armed_at =>
                {
                    let disarming = |r: &Raider| r.task == Task::Disarm && r.target == w.tile
                        && tile_of(r.at, &self.grid) == Some(w.tile);
                    let trips = |r: &Raider| r.active() && !disarming(r) && match w.kind {
                        WardKind::GravityWell => within(r.at, heist::WELL_RADIUS),
                        WardKind::LanternGlare => within(r.at, heist::GLARE_RADIUS),
                        _ => tile_of(r.at, &self.grid) == Some(w.tile),
                    };
                    let Some(first) = self.raiders.iter().position(trips) else { continue };
                    self.wards[wi].armed_at = now + w.kind.reset_ticks();
                    // Delay (§7.3's Time row): "wards ... take effect 3 seconds
                    // after they are triggered". The ward resets from the trip.
                    match self.sheet.ticks(Param::EffectDelaySeconds) {
                        Some(delay) => self.delayed.push((now + delay, wi, first)),
                        None => self.fire_ward(wi, first),
                    }
                }
                _ => {}
            }
        }
    }

    /// What a triggered ward does when it lands, set off by crew member
    /// `first`: at once, or under Delay when its time comes.
    fn fire_ward(&mut self, wi: usize, first: usize) {
        let now = self.tick;
        self.log.push(now, Event::Ward { ward: wi as u16, crew: first as u8 });
        let w = self.wards[wi].clone();
        let (wx, wy) = self.grid.centre(w.tile);
        let centre = Point { x: wx, y: wy };
        let within = |p: Point, r: i32| p.distance(centre) <= Fx::from_int(r);
        match w.kind {
            WardKind::TimeSnare => {
                self.raiders[first].frozen_until = now + heist::SNARE_FREEZE_TICKS;
            }
            WardKind::GravityWell => {
                // Everyone within the radius to the centre, held. Where they
                // were going stands: the route is recomputed from the well to
                // the same tile, because the order was the tile, not the path.
                for ri in 0..self.raiders.len() {
                    let r = &self.raiders[ri];
                    if !(r.active() && within(r.at, heist::WELL_RADIUS)) {
                        continue;
                    }
                    let goal = r.route.last().copied();
                    let route = goal.and_then(|g| path::find_through(&self.grid, w.tile, g))
                        .unwrap_or_default();
                    let r = &mut self.raiders[ri];
                    r.at = centre;
                    r.route = route;
                    r.along = 0;
                    r.came_from = w.tile;
                    r.frozen_until = now + heist::WELL_HOLD_TICKS;
                }
            }
            _ => {
                // Lantern Glare: the guards within reach are shown the crew,
                // and the crew is blinded. A spent Glare's reveal is dropped.
                self.glares.retain(|&(_, until)| now < until);
                self.glares.push((w.tile, now + heist::GLARE_REVEAL_TICKS));
                for r in self.raiders.iter_mut().filter(|r| r.active()) {
                    r.frozen_until = r.frozen_until.max(now + heist::GLARE_BLIND_TICKS);
                }
            }
        }
    }

    /// §7.3's Revival row this tick. "When several Revival sources cover one
    /// knockout, the highest N applies"; a tie goes to the return. Lantern
    /// festival is a source: "each character returns once at the revive
    /// health, 30% of its role's health".
    fn revival(&self) -> Option<Revival> {
        let get = |p| self.sheet.is_set(p).then(|| self.sheet.factor(p));
        let mut ret = get(Param::RevivalReturn);
        // Echoing Skies is a source like any other: the highest N applies.
        if let Some((en, ed)) = era::revival_return(self.era) {
            if ret.is_none_or(|(n, d)| en * d > n * ed) {
                ret = Some((en, ed));
            }
        }
        if self.combos.chord(Chord::LanternFestival) {
            let (ln, ld) = heist::LANTERN_RETURN;
            if ret.is_none_or(|(n, d)| ln * d > n * ld) {
                ret = Some((ln, ld));
            }
        }
        match (ret, get(Param::RevivalSwap)) {
            (Some((rn, rd)), Some((sn, sd))) if sn * rd > rn * sd => Some(Revival::Swap(sn, sd)),
            (Some((n, d)), _) => Some(Revival::Return(n, d)),
            (None, Some((n, d))) => Some(Revival::Swap(n, d)),
            (None, None) => None,
        }
    }

    /// Whether one about to be knocked out swaps with its nearest ally, and
    /// the share of the blow the ally takes: Soul swap's, once, like every
    /// Revival source — or, with Soul tether, once more for one already
    /// returned: "a returned echo can swap places with an ally once". The
    /// second value says which was spent.
    fn swap_share(&self, revived: bool, tethered: bool) -> Option<((i64, i64), bool)> {
        match self.revival() {
            Some(Revival::Swap(n, d)) if !revived => Some(((n, d), false)),
            _ if revived && !tethered && self.combos.resonance(Res::SoulTether)
                && self.sheet.is_set(Param::RevivalSwap) =>
            {
                Some((self.sheet.factor(Param::RevivalSwap), true))
            }
            _ => None,
        }
    }

    fn pos(&self, guard: bool, i: usize) -> Point {
        if guard { self.guards[i].at } else { self.raiders[i].at }
    }

    /// Able to be struck, swapped with or jumped to: an active crew member, a
    /// guard not knocked out.
    fn standing(&self, guard: bool, i: usize) -> bool {
        if guard { !self.guards[i].knocked_out } else { self.raiders[i].active() }
    }

    /// Soul swap for character `i` on the struck side, about to take `blow`:
    /// trade places with the nearest ally, ties to the lower id, and return
    /// the ally and the share it takes. Twin souls (Soul swap + Kinship):
    /// "characters who swap places heal each other 20%", after the blow.
    fn soul_swap(&mut self, guard: bool, i: usize, blow: i32) -> Option<(usize, i32)> {
        let (health, revived, tethered) = if guard {
            let g = &self.guards[i];
            (g.health, g.revived, g.tethered)
        } else {
            let r = &self.raiders[i];
            (r.health, r.revived, r.tethered)
        };
        if blow < health {
            return None;
        }
        let ((n, d), tether) = self.swap_share(revived, tethered)?;
        let from = self.pos(guard, i);
        let side = if guard { self.guards.len() } else { self.raiders.len() };
        let ai = (0..side).filter(|&j| j != i && self.standing(guard, j))
            .min_by_key(|&j| (from.distance(self.pos(guard, j)).0, j))?;
        let to = self.pos(guard, ai);
        let share = (blow as i64 * n / d) as i32;
        if guard {
            self.guards[i].at = to;
            self.guards[ai].at = from;
            for k in [i, ai] {
                self.guards[k].route.clear();
                self.guards[k].along = 0;
            }
            if tether { self.guards[i].tethered = true } else { self.guards[i].revived = true }
        } else {
            self.raiders[i].at = to;
            self.raiders[ai].at = from;
            for k in [i, ai] {
                self.raiders[k].route.clear();
                self.raiders[k].along = 0;
            }
            if tether { self.raiders[i].tethered = true } else { self.raiders[i].revived = true }
        }
        Some((ai, share))
    }

    /// Twin souls' heal for the two who swapped, after the blow.
    fn twin_souls(&mut self, guard: bool, a: usize, b: usize) {
        if !self.combos.resonance(Res::TwinSouls) {
            return;
        }
        let (n, d) = heist::TWIN_SOULS_HEAL;
        let sheet = self.sheet;
        for k in [a, b] {
            if guard {
                let g = &mut self.guards[k];
                let full = full_health(&sheet, g.role);
                g.health = (g.health + full * n / d).min(full);
            } else {
                let r = &mut self.raiders[k];
                let full = r.full(&sheet);
                r.health = (r.health + full * n / d).min(full);
            }
        }
    }

    /// A blow on crew member `ri`: Soul swap first, then the blow, then Chain
    /// lightning. A knockout is settled after the combat phase, as always.
    fn strike_raider(&mut self, ri: usize, blow: i32, chain: bool) {
        let (hit, dealt) = match self.soul_swap(false, ri, blow) {
            Some((ai, share)) => {
                self.raiders[ai].health -= share;
                self.twin_souls(false, ri, ai);
                (ai, share)
            }
            None => {
                self.raiders[ri].health -= blow;
                (ri, blow)
            }
        };
        if chain {
            self.chain_from(false, ri, hit, dealt);
        }
    }

    /// A blow on guard `gi`, by the same rules, and a knockout at once.
    fn strike_guard(&mut self, gi: usize, blow: i32, chain: bool) {
        let (hit, dealt) = match self.soul_swap(true, gi, blow) {
            Some((ai, share)) => {
                self.guards[ai].health -= share;
                self.twin_souls(true, gi, ai);
                (ai, share)
            }
            None => {
                self.guards[gi].health -= blow;
                (gi, blow)
            }
        };
        for k in [gi, hit] {
            if !self.guards[k].knocked_out && self.guards[k].health <= 0 {
                self.knock_out_guard(k);
            }
        }
        if chain {
            self.chain_from(true, gi, hit, dealt);
        }
    }

    /// Chain lightning's jump from whoever took a hit: "every hit jumps to a
    /// second target within 3 tiles at 50% strength", to the nearest of the
    /// struck one's side, ties to the lower id. Storm grid (Chain lightning
    /// + Static): "chains jump to three targets" — each from the last, each
    /// at the jump's share of the hit. A jump on a guard is a hit, and sends
    /// its suspicion straight to 1000. A jump never starts a chain of its own.
    fn chain_from(&mut self, guard: bool, first: usize, hit: usize, dealt: i32) {
        if !self.sheet.is_set(Param::ChainShare) {
            return;
        }
        let (n, d) = self.sheet.factor(Param::ChainShare);
        let share = (dealt as i64 * n / d) as i32;
        let jumps = if self.combos.resonance(Res::StormGrid) { heist::STORM_GRID_TARGETS } else { 1 };
        let side = if guard { self.guards.len() } else { self.raiders.len() };
        let mut done = vec![first, hit];
        let mut from = hit;
        for _ in 0..jumps {
            let at = self.pos(guard, from);
            let next = (0..side)
                .filter(|&j| !done.contains(&j) && self.standing(guard, j)
                    && at.distance(self.pos(guard, j)) <= Fx::from_int(heist::CHAIN_TILES))
                .min_by_key(|&j| (at.distance(self.pos(guard, j)).0, j));
            let Some(j) = next else { break };
            let p = self.pos(guard, j);
            self.spark_on(self.grid.tile_at(p.x, p.y));
            if guard {
                self.guards[j].suspicion = SUSPICION_MAX;
                self.strike_guard(j, share, false);
            } else {
                self.strike_raider(j, share, false);
            }
            done.push(j);
            from = j;
        }
    }

    /// A guard at zero health is knocked out (§12.8) — unless a Revival
    /// source returns it, the first time only.
    fn knock_out_guard(&mut self, gi: usize) {
        let revival = self.revival();
        let full = full_health(&self.sheet, self.guards[gi].role);
        let g = &mut self.guards[gi];
        g.swing = 0;
        g.route.clear();
        g.along = 0;
        if let Some(Revival::Return(n, d)) = revival {
            if !g.revived {
                g.revived = true;
                g.health = ((full as i64 * n / d) as i32).max(1);
                return;
            }
        }
        g.health = 0;
        g.knocked_out = true;
        self.log.push(self.tick, Event::GuardDown { guard: gi as u16 });
    }

    /// The Featherkin's glide: "3 tiles in one move, crossing a gap and
    /// rising or dropping one height level on the way". Straight along a row
    /// or a column to the tile aimed at, at most 3 tiles off, over open ground
    /// and gaps but not walls, no tile of it more than a level above or below
    /// where it took off, onto ground it can stand on. It glides at its own
    /// pace and stops there.
    fn glide(&mut self, ri: usize, to: grid::TileIndex) -> bool {
        let grid = &self.grid;
        let r = &self.raiders[ri];
        let Some(from) = grid.tile_at(r.at.x, r.at.y) else { return false };
        let Some((dx, dy, n)) = straight(grid, from, to) else { return false };
        if n > ruleborn::GLIDE_TILES || !grid.standable(to) {
            return false;
        }
        let route: Vec<grid::TileIndex> = (1..=n).filter_map(|k| offset(grid, from, dx * k, dy * k))
            .collect();
        let level = grid.level(from);
        let ok = route.iter().all(|&t| (grid.standable(t) || grid.is_gap(t))
            && (grid.is_gap(t) || (grid.level(t) - level).abs() <= ruleborn::GLIDE_LEVELS));
        if !ok {
            return false;
        }
        let r = &mut self.raiders[ri];
        r.route = route;
        r.along = 0;
        r.came_from = from;
        true
    }

    /// The Rambler's charge: "Charges 4 tiles in a straight line and breaks
    /// the first wall, hedge or boulder in its way"; on its rule sheet,
    /// "Speed ×2" and "the first breakable terrain it meets takes its full
    /// health". Along the row or column of the tile aimed at, 4 tiles at
    /// most: a hedge or a boulder it meets first is broken, a Crystal Wall
    /// takes its full health and breaks if that is enough, and the charge
    /// runs on through; anything else, or a second obstacle, ends it before.
    fn charge(&mut self, ri: usize, to: grid::TileIndex) -> bool {
        let now = self.tick;
        let r = &self.raiders[ri];
        let full = r.full(&self.sheet);
        let Some(from) = self.grid.tile_at(r.at.x, r.at.y) else { return false };
        let Some((dx, dy, _)) = straight(&self.grid, from, to) else { return false };
        let mut route = Vec::new();
        let mut last = from;
        let mut broke = false;
        for k in 1..=ruleborn::CHARGE_TILES {
            let Some(t) = offset(&self.grid, from, dx * k, dy * k) else { break };
            if self.grid.can_step(last, t) {
                route.push(t);
                last = t;
                continue;
            }
            if broke {
                break;
            }
            match self.grid.feature(t) {
                Some(Feature::Hedge) | Some(Feature::Boulder) => self.grid.clear(t),
                _ => {
                    let Some(wi) = self.wards.iter().position(|w| w.tile == t && w.live()
                        && w.kind == WardKind::CrystalWall) else { break };
                    let w = &mut self.wards[wi];
                    w.health -= full;
                    if w.health > 0 {
                        broke = true;
                        self.raiders[ri].smashed = true;
                        break;
                    }
                    w.health = 0;
                    w.broken = true;
                    w.broken_at = Some(now);
                    self.grid.clear(t);
                }
            }
            broke = true;
            self.raiders[ri].smashed = true;
            if !self.grid.can_step(last, t) {
                break;
            }
            route.push(t);
            last = t;
        }
        if route.is_empty() && !broke {
            return false;
        }
        let r = &mut self.raiders[ri];
        r.route = route;
        r.along = 0;
        r.came_from = from;
        r.charging = !r.route.is_empty();
        true
    }

    /// A Cast command: the manifest's cast number `actor`, not yet used,
    /// centred on the tile aimed at. §12.5: "A cast brings one of your own
    /// unlocked laws into their universe: it covers a circle of 4 tiles for 10
    /// seconds" — its zoned lines (`ZONED`) on top of the realm's for whoever
    /// is inside, from the tile's centre. Whether the law is the raider's own
    /// is the server's to check against the Codex it holds; the simulation
    /// plays what the manifest carries.
    fn cast(&mut self, command: Command) {
        let now = self.tick;
        let i = command.actor as usize;
        let Some(&def) = self.casts.get(i) else { return };
        if self.casts_used & (1 << i) != 0 || self.raiders.iter().all(|r| !r.active()) {
            return;
        }
        let (x, y) = command.target();
        let Some(t) = self.grid.tile_at(x, y) else { return };
        let (cx, cy) = self.grid.centre(t);
        self.casts_used |= 1 << i;
        self.zones.push(Zone { def: def as usize, at: Some(Point { x: cx, y: cy }),
                               until: now + ruleborn::CAST_TICKS });
        self.log.push(now, Event::Cast { cast: i as u8, law: def as u16 });
    }

    /// The Prism mite: "Splits into two mites for 8 s, each with half its
    /// load and half its health; they can go different ways, a caught mite
    /// loses only its half, and they rejoin when it ends." The other half is
    /// a raider of its own, appended, so its index is the next on the wire:
    /// it goes on where the mite was going until told otherwise, has no
    /// ability of its own, and the larger half of an odd health or load stays
    /// with the mite. One split at a time, and no more raiders than a command
    /// can name.
    fn split(&mut self, ri: usize) -> bool {
        let now = self.tick;
        let r = &self.raiders[ri];
        if r.twin.is_some() || r.half_of.is_some() || self.raiders.len() >= ruleborn::MAX_RAIDERS {
            return false;
        }
        let ti = self.raiders.len();
        let mut half = r.clone();
        half.id = ti as u32;
        half.kind = None;
        half.uses = 0;
        half.ready = false;
        half.effect_until = 0;
        half.twin = None;
        half.split_until = 0;
        half.half_of = Some(ri);
        half.health = r.health / 2;
        half.carried = r.carried / 2;
        let r = &mut self.raiders[ri];
        r.health -= half.health;
        r.carried -= half.carried;
        r.twin = Some(ti);
        r.split_until = now + ruleborn::SPLIT_TICKS;
        // Halving is not a hit: what this tick began with is what each half
        // has now, so a Soulmender's link shares nothing of it.
        let health = r.health;
        if let Some(h) = self.start_health.get_mut(ri) {
            *h = health;
        }
        if let Some(h) = self.shared_at.get_mut(ri) {
            *h = health;
        }
        self.start_health.push(half.health);
        self.shared_at.push(half.health);
        self.raiders.push(half);
        true
    }

    /// The Prism mite's halves rejoin when the split ends. Both on their
    /// feet: the half folds into the mite where the mite stands, health and
    /// load added back. The half down or caught: it is gone, and its half of
    /// the load with it ("a caught mite loses only its half"). The mite down
    /// or caught and the half on its feet: the half carries on as the mite,
    /// where it is, with what it has — so a caught half is lost whichever
    /// half it was. The mite already aboard the skiff: the half goes on alone
    /// until it is out or caught, and what it brings out is banked. A half
    /// already aboard has banked its load and stays aboard.
    fn rejoin(&mut self) {
        let now = self.tick;
        for ri in 0..self.raiders.len() {
            let Some(ti) = self.raiders[ri].twin else { continue };
            if now < self.raiders[ri].split_until {
                continue;
            }
            self.raiders[ri].twin = None;
            let (mite, half) = (self.raiders[ri].standing, self.raiders[ti].standing);
            match (mite, half) {
                (_, Standing::Out) | (Standing::Out, Standing::Active) => {}
                (Standing::Active, Standing::Active) => {
                    let (health, carried) = (self.raiders[ti].health, self.raiders[ti].carried);
                    let full = self.raiders[ri].full(&self.sheet);
                    let r = &mut self.raiders[ri];
                    r.health = (r.health + health).min(full);
                    r.carried += carried;
                    self.retire(ti);
                }
                (Standing::Down | Standing::Caught, Standing::Active) => {
                    let mut carried_on = self.raiders[ti].clone();
                    let r = &self.raiders[ri];
                    carried_on.id = r.id;
                    carried_on.kind = r.kind;
                    carried_on.uses = r.uses;
                    carried_on.ready = r.ready;
                    carried_on.locked_until = r.locked_until;
                    carried_on.free_since = r.free_since;
                    carried_on.effect_until = r.effect_until;
                    carried_on.half_of = None;
                    self.raiders[ri] = carried_on;
                    self.retire(ti);
                    self.log.push(now, Event::Back { crew: ri as u8, how: Back::Split });
                }
                _ => self.retire(ti),
            }
        }
    }

    /// A half folded away: nobody, carrying nothing, going nowhere.
    fn retire(&mut self, ti: usize) {
        let h = &mut self.raiders[ti];
        h.standing = Standing::Gone;
        h.carried = 0;
        h.health = 0;
        h.route.clear();
        h.along = 0;
        h.task = Task::default();
    }

    /// The Glass golem: "Raises a crystal wall 3 tiles long for 6 s: nothing
    /// passes it, and it does not block sight." Across the way from the
    /// golem to the tile aimed at, centred on it: along the column when the
    /// tile lies more east or west of the golem than north or south, else
    /// along the row. It stands on those of its three tiles that are open
    /// ground with nobody and nothing on them — no ward, no bridge, no body
    /// — and is not raised at all if the tile aimed at is not one.
    fn raise_wall(&mut self, from: grid::TileIndex, at: grid::TileIndex) -> bool {
        let ((fx, fy), (ax, ay)) = (self.grid.coords(from), self.grid.coords(at));
        let (dx, dy) = (ax as i32 - fx as i32, ay as i32 - fy as i32);
        if (dx, dy) == (0, 0) {
            return false;
        }
        let (sx, sy) = if dx.abs() >= dy.abs() { (0, 1) } else { (1, 0) };
        let half = ruleborn::WALL_TILES / 2;
        let free = |t: grid::TileIndex| {
            self.grid.at(t).passable() && !self.grid.is_bridged(t)
                && !self.wards.iter().any(|w| w.tile == t)
                && !self.raiders.iter().any(|r| r.standing != Standing::Out
                    && r.standing != Standing::Caught && self.grid.tile_at(r.at.x, r.at.y) == Some(t))
                && !self.guards.iter().any(|g| self.grid.tile_at(g.at.x, g.at.y) == Some(t))
        };
        if !free(at) {
            return false;
        }
        let tiles: Vec<grid::TileIndex> = (-half..=half)
            .filter_map(|k| offset(&self.grid, at, sx * k, sy * k))
            .filter(|&t| free(t))
            .collect();
        for &t in &tiles {
            self.grid.set_raised(t, true);
        }
        self.walls.push(Wall { tiles, until: self.tick + ruleborn::WALL_TICKS });
        true
    }

    /// The walls standing this tick, marked on the grid; a wall whose time is
    /// up goes.
    fn stand_walls(&mut self) {
        let now = self.tick;
        let (ended, live): (Vec<Wall>, Vec<Wall>) = std::mem::take(&mut self.walls)
            .into_iter().partition(|w| w.until <= now);
        for w in &ended {
            for &t in &w.tiles {
                self.grid.set_raised(t, false);
            }
        }
        for w in &live {
            for &t in &w.tiles {
                self.grid.set_raised(t, true);
            }
        }
        self.walls = live;
    }

    /// Whether a Lantern wisp's reveal shows what is hidden on a tile this
    /// tick: within `ruleborn::REVEAL_TILES` of a wisp whose reveal runs,
    /// measured centre to centre from where the wisp is now. What it shows —
    /// the hidden wards (§10.3's "Hidden until revealed or fired"), the
    /// Quicksand's pits — is drawn, not simulated: §7.3's reveal is the view
    /// layer's, and nothing the simulation decides reads it.
    pub fn revealed(&self, tile: grid::TileIndex) -> bool {
        let (x, y) = self.grid.centre(tile);
        let at = Point { x, y };
        self.reveals.iter().any(|&(ri, _)| self.raiders.get(ri)
            .is_some_and(|r| r.at.distance(at) <= Fx::from_int(ruleborn::REVEAL_TILES)))
    }

    /// A bridge over the gap the tile `at` is in: the run of gap tiles through
    /// it along one line, no longer than `most`, with ground to stand on at
    /// both ends. From a crew member's tile the line is the one toward `at`;
    /// with no tile (a Sage's power) the row is tried, then the column.
    fn lay_bridge(&mut self, origin: Option<grid::TileIndex>, at: grid::TileIndex,
                  most: usize, ticks: u32) -> bool {
        let grid = &self.grid;
        if !grid.is_gap(at) || grid.is_bridged(at) {
            return false;
        }
        let axes: Vec<(i32, i32)> = match origin {
            Some(o) => match straight(grid, o, at) {
                Some((dx, dy, _)) => vec![(dx, dy)],
                None => return false,
            },
            None => vec![(1, 0), (0, 1)],
        };
        for (dx, dy) in axes {
            let mut first = at;
            while let Some(p) = offset(grid, first, -dx, -dy).filter(|&p| grid.is_gap(p)) {
                first = p;
            }
            let mut run = vec![first];
            while let Some(n) = offset(grid, *run.last().unwrap(), dx, dy)
                .filter(|&n| grid.is_gap(n))
            {
                run.push(n);
            }
            let near = offset(grid, first, -dx, -dy);
            let far = offset(grid, *run.last().unwrap(), dx, dy);
            if run.len() <= most && near.is_some_and(|t| grid.standable(t))
                && far.is_some_and(|t| grid.standable(t))
            {
                for &t in &run {
                    self.grid.set_bridged(t, true);
                }
                self.bridges.push(Bridge { tiles: run, back: near.unwrap(), until: self.tick + ticks });
                return true;
            }
        }
        false
    }

    /// The bridges standing this tick, marked on the grid; a bridge whose
    /// time is up goes, and whoever is still on it is put back on the end it
    /// was laid from.
    fn stand_bridges(&mut self) {
        let now = self.tick;
        let (ended, live): (Vec<Bridge>, Vec<Bridge>) = std::mem::take(&mut self.bridges)
            .into_iter().partition(|b| b.until <= now);
        for b in &ended {
            for &t in &b.tiles {
                self.grid.set_bridged(t, false);
            }
        }
        for b in &live {
            for &t in &b.tiles {
                self.grid.set_bridged(t, true);
            }
        }
        let grid = &self.grid;
        for b in &ended {
            let (x, y) = grid.centre(b.back);
            let on = |p: Point| grid.tile_at(p.x, p.y).is_some_and(|t| b.tiles.contains(&t)
                && !grid.standable(t));
            for r in self.raiders.iter_mut().filter(|r| on(r.at)) {
                r.at = Point { x, y };
                r.route.clear();
                r.along = 0;
                r.charging = false;
            }
            for g in self.guards.iter_mut().filter(|g| on(g.at)) {
                g.at = Point { x, y };
                g.route.clear();
                g.along = 0;
            }
        }
        self.bridges = live;
    }

    /// A bell post "rings if bumped" and "raises the realm's alarm one level
    /// (12.17)": a crew member walking into its tile bumps it, every time.
    /// Under Delay "the ring comes late", by Delay's own seconds.
    fn ring(&mut self, ri: usize, tile: grid::TileIndex) {
        self.log.push(self.tick, Event::Bell { crew: ri as u8, tile: tile as u16 });
        match self.sheet.ticks(Param::EffectDelaySeconds) {
            Some(delay) => self.bells_due.push(self.tick + delay),
            None => self.bells_rung += grid::BELL_LEVELS,
        }
    }

    /// A bounce mushroom "launches anyone 3 tiles forward, noisily" — 5
    /// under Half gravity — the way it walked in. It lands on the furthest of
    /// those tiles it can stand on, over whatever is between, and walks on
    /// from there to where it was going; with nowhere to land it is not
    /// launched.
    fn bounce(&mut self, ri: usize, from: grid::TileIndex, tile: grid::TileIndex) {
        let ((fx, fy), (tx, ty)) = (self.grid.coords(from), self.grid.coords(tile));
        let (dx, dy) = (tx as i32 - fx as i32, ty as i32 - fy as i32);
        if (dx, dy) == (0, 0) {
            return;
        }
        let reach = if self.grid.leap { grid::MUSHROOM_LEAP_TILES } else { grid::MUSHROOM_TILES };
        let grid = &self.grid;
        let Some(land) = (1..=reach).rev().find_map(|k| {
            let (x, y) = (tx as i32 + dx * k, ty as i32 + dy * k);
            if x < 0 || y < 0 {
                return None;
            }
            grid.index(x as u16, y as u16).filter(|&t| grid.at(t).passable())
        }) else {
            return;
        };
        let drop = (grid.level(tile) - grid.level(land)).max(0) as u8;
        let (x, y) = grid.centre(land);
        let r = &mut self.raiders[ri];
        let goal = r.route.last().copied().filter(|&g| g != tile && g != land);
        r.at = Point { x, y };
        r.route = goal.and_then(|g| path::find_through(&self.grid, land, g)).unwrap_or_default();
        r.along = 0;
        r.came_from = tile;
        r.bounced = true;
        r.landed = drop;
    }

    /// The features that act on what is around them, read off the grid once
    /// a tick, so a hedge cut or grass grown this tick is seen next tick.
    fn find_terrain(&mut self) {
        self.lanterns.clear();
        self.vents.clear();
        self.stones.clear();
        self.springs.clear();
        for t in 0..self.grid.len() as grid::TileIndex {
            match self.grid.feature(t) {
                Some(Feature::LanternPost) => {
                    let outcrop = self.grid.neighbours(t).iter().flatten()
                        .any(|&n| self.grid.feature(n) == Some(Feature::CrystalOutcrop));
                    self.lanterns.push((t, outcrop));
                }
                Some(Feature::EmberVent) => self.vents.push(t),
                Some(Feature::StaticStone) => self.stones.push(t),
                Some(Feature::HotSpring) => self.springs.push(t),
                _ => {}
            }
        }
    }

    /// Whether a tile is in a light nothing hides inside: a lantern post's 3
    /// tiles, 2 more past a crystal outcrop beside it, or an ember vent's 2
    /// in the second it bursts. Measured centre to centre.
    fn lantern_lit(&self, tile: grid::TileIndex) -> bool {
        let (x, y) = self.grid.centre(tile);
        let at = Point { x, y };
        let near = |t: grid::TileIndex, r: i32| {
            let (cx, cy) = self.grid.centre(t);
            at.distance(Point { x: cx, y: cy }) <= Fx::from_int(r)
        };
        let bursting = self.tick % (grid::EMBER_SECONDS * TICKS_PER_SECOND) < TICKS_PER_SECOND
            && self.tick >= grid::EMBER_SECONDS * TICKS_PER_SECOND;
        self.lanterns.iter().any(|&(t, outcrop)| {
            near(t, grid::LANTERN_TILES + if outcrop { grid::OUTCROP_EXTRA_TILES } else { 0 })
        }) || (bursting && self.vents.iter().any(|&t| near(t, grid::EMBER_LIGHT_TILES)))
    }

    /// §6.2's features that act once a second: a hot spring "heals 2% health
    /// a second while standing in it, for both sides"; an ember vent's
    /// "bursts of flame every 8 seconds" hurt anyone on it, and a static
    /// stone "zaps anyone within 1 tile every 4 seconds". §6.2 gives neither
    /// hurt a size: the burst takes Wildfire's 5% of full health and the zap
    /// a Static Coil's 8% (register G78).
    fn terrain_acts(&mut self) {
        let now = self.tick;
        let sheet = self.sheet;
        let on = |grid: &Grid, tiles: &[grid::TileIndex], p: Point| {
            grid.tile_at(p.x, p.y).is_some_and(|t| tiles.contains(&t))
        };
        let near = |grid: &Grid, tiles: &[grid::TileIndex], p: Point, r: i32| {
            tiles.iter().any(|&t| {
                let (x, y) = grid.centre(t);
                p.distance(Point { x, y }) <= Fx::from_int(r)
            })
        };
        if !self.springs.is_empty() {
            let (n, d) = grid::SPRING_HEAL;
            for r in self.raiders.iter_mut() {
                if r.active() && on(&self.grid, &self.springs, r.at) {
                    let full = r.full(&sheet);
                    r.health = (r.health + full * n / d).min(full);
                }
            }
            for g in self.guards.iter_mut() {
                if !g.knocked_out && on(&self.grid, &self.springs, g.at) {
                    let full = full_health(&sheet, g.role);
                    g.health = (g.health + full * n / d).min(full);
                }
            }
        }
        let burst = now > 0 && now % (grid::EMBER_SECONDS * TICKS_PER_SECOND) == 0
            && !self.vents.is_empty();
        let zap = now > 0 && now % (grid::STONE_SECONDS * TICKS_PER_SECOND) == 0
            && !self.stones.is_empty();
        if !(burst || zap) {
            return;
        }
        let hurt = |full: i32, at: Point, grid: &Grid, vents: &[grid::TileIndex],
                    stones: &[grid::TileIndex]| {
            let mut h = 0;
            if burst && on(grid, vents, at) {
                h += full * heist::BURN_DAMAGE.0 / heist::BURN_DAMAGE.1;
            }
            if zap && near(grid, stones, at, grid::STONE_TILES) {
                h += full * heist::COIL_DAMAGE.0 / heist::COIL_DAMAGE.1;
            }
            h
        };
        for r in self.raiders.iter_mut().filter(|r| r.active()) {
            let h = hurt(r.full(&sheet), r.at, &self.grid, &self.vents, &self.stones);
            if h > 0 {
                r.health -= h;
                r.hurt_by = Hurt::Law;
            }
        }
        for gi in 0..self.guards.len() {
            let g = &self.guards[gi];
            if g.knocked_out {
                continue;
            }
            let h = hurt(full_health(&sheet, g.role), g.at, &self.grid, &self.vents, &self.stones);
            if h > 0 {
                self.guards[gi].health -= h;
                if self.guards[gi].health <= 0 {
                    self.knock_out_guard(gi);
                }
            }
        }
    }

    /// Thorns (§7.3's Touch damage row): "touching walls or hedges costs 5%
    /// health". The document never says what a touch is (G23); here it is
    /// standing on or beside — a side, not a corner — a wall or a live Thorn
    /// Hedge, and it costs the share of full health once a second, crew and
    /// guards alike: "your own guards cannot hug the hedges either". A wall
    /// is anything that stops walking but the Vault, the pylons and §10.1's
    /// buildings, which are structures, not walls.
    fn thorns(&mut self) {
        let (n, d) = self.sheet.factor(Param::TouchDamage);
        let hedges: Vec<grid::TileIndex> = self.wards.iter()
            .filter(|w| w.kind == WardKind::ThornHedge && w.live()).map(|w| w.tile).collect();
        let grid = &self.grid;
        let thorny = |t: grid::TileIndex| hedges.contains(&t) || (!grid.at(t).passable()
            && !matches!(grid.feature(t), Some(Feature::Vault | Feature::Pylon | Feature::Building)));
        let touching = |p: Point| grid.tile_at(p.x, p.y).is_some_and(|t| {
            thorny(t) || grid.neighbours(t).iter().flatten().any(|&o| thorny(o))
        });
        let crew: Vec<bool> = self.raiders.iter().map(|r| r.active() && touching(r.at)).collect();
        let posts: Vec<bool> = self.guards.iter()
            .map(|g| !g.knocked_out && touching(g.at)).collect();
        let sheet = self.sheet;
        for (r, hurt) in self.raiders.iter_mut().zip(crew) {
            if hurt {
                r.health -= (r.full(&sheet) as i64 * n / d) as i32;
                r.hurt_by = Hurt::Law;
            }
        }
        for (gi, hurt) in posts.into_iter().enumerate() {
            if hurt {
                let g = &mut self.guards[gi];
                g.health -= (full_health(&sheet, g.role) as i64 * n / d) as i32;
                if g.health <= 0 {
                    self.knock_out_guard(gi);
                }
            }
        }
    }

    /// Wildfire: "hurting anyone inside" a burning tile — the Thorn Hedge's
    /// 5% of full health a second, crew and guards alike (G25).
    fn burn(&mut self) {
        let (n, d) = heist::BURN_DAMAGE;
        let sheet = self.sheet;
        let on_fire = |grid: &Grid, burning: &[(grid::TileIndex, u32)], p: Point| {
            grid.tile_at(p.x, p.y).is_some_and(|t| burning.iter().any(|&(b, _)| b == t))
        };
        for r in self.raiders.iter_mut() {
            if r.active() && on_fire(&self.grid, &self.burning, r.at) {
                r.health -= r.full(&sheet) * n / d;
                r.hurt_by = Hurt::Law;
            }
        }
        for gi in 0..self.guards.len() {
            let g = &self.guards[gi];
            if !g.knocked_out && on_fire(&self.grid, &self.burning, g.at) {
                let hurt = full_health(&sheet, g.role) * n / d;
                self.guards[gi].health -= hurt;
                if self.guards[gi].health <= 0 {
                    self.knock_out_guard(gi);
                }
            }
        }
    }

    fn heal(&mut self) {
        let now = self.tick;
        if self.sheet.flag(Param::AllyHealing).is_some() {
            let (n, d) = self.sheet.factor(Param::AllyHealing);
            let tile_of = |p: Point| self.grid.tile_at(p.x, p.y);
            let beside = |a: Option<grid::TileIndex>, b: Option<grid::TileIndex>| {
                a.zip(b).is_some_and(|(a, b)| self.grid.adjacent(a, b))
            };
            // Who stands beside an ally, decided before anyone heals.
            let crew: Vec<bool> = (0..self.raiders.len()).map(|i| {
                let r = &self.raiders[i];
                r.active() && self.raiders.iter().enumerate().any(|(j, o)| {
                    j != i && o.active() && beside(tile_of(r.at), tile_of(o.at))
                })
            }).collect();
            let posts: Vec<bool> = (0..self.guards.len()).map(|i| {
                let g = &self.guards[i];
                g.awake(now) && self.guards.iter().enumerate().any(|(j, o)| {
                    j != i && o.awake(now) && beside(tile_of(g.at), tile_of(o.at))
                })
            }).collect();
            for (r, heal) in self.raiders.iter_mut().zip(crew) {
                if heal {
                    let full = r.full(&self.sheet);
                    r.health = (r.health + (full as i64 * n / d) as i32).min(full);
                }
            }
            for (g, heal) in self.guards.iter_mut().zip(posts) {
                if heal {
                    let full = full_health(&self.sheet, g.role);
                    g.health = (g.health + (full as i64 * n / d) as i32).min(full);
                }
            }
        }
        if self.sheet.flag(Param::StructureHealing).is_some() {
            let (n, d) = self.sheet.factor(Param::StructureHealing);
            let share = |full: i32| (full as i64 * n / d) as i32;
            for g in self.guards.iter_mut().filter(|g| !g.knocked_out) {
                let full = full_health(&self.sheet, g.role);
                g.health = (g.health + share(full)).min(full);
            }
            if self.vault.opened_at.is_none() {
                let full = heist::VAULT_HEALTH_PER_LEVEL;
                self.vault.health = (self.vault.health + share(full)).min(full);
            }
            for law in self.laws.iter_mut().filter(|l| l.broken_at.is_none()) {
                let full = heist::PYLON_HEALTH;
                law.health = (law.health + share(full)).min(full);
            }
            // "Buildings, wards and guards": the wards were left out until
            // the law engine's launch set was finished.
            for w in self.wards.iter_mut().filter(|w| !w.broken) {
                let full = heist::Ward::new(w.kind, w.tile).health;
                w.health = (w.health + share(full)).min(full);
            }
        }
    }

    /// Whether the heist clock still covers getting crew member `ri` out:
    /// walking, loaded, from where it stands to the skiff (or, if none is
    /// called, the nearest edge), and waiting for the skiff if it is later.
    /// Exactly covers — the document gives no margin, so none is added.
    fn clock_affords(&self, ri: usize) -> bool {
        if self.clock == u32::MAX {
            return true;                      // a world with no clock
        }
        let r = &self.raiders[ri];
        let here = match underground(&self.grid, r) {
            Some((_, far)) => Some(far),
            None => self.grid.tile_at(r.at.x, r.at.y),
        };
        let Some(from) = here else { return false };
        let exit = match self.skiff {
            Some(s) => Some(s.tile),
            None => {
                // The nearest edge by the walk, ties to the lower index.
                let field = noise::field(&self.grid, from, u16::MAX - 1);
                (0..self.grid.len() as grid::TileIndex)
                    .filter(|t| self.grid.is_edge(*t) && field[*t as usize] != noise::UNHEARD)
                    .min_by_key(|t| (field[*t as usize], *t))
            }
        };
        let Some(exit) = exit else { return false };
        let route = if exit == from {
            Vec::new()
        } else {
            match path::find_through(&self.grid, from, exit) {
                Some(route) => route,
                None => return false,
            }
        };
        let mut walk: u64 = 0;
        let mut on = from;
        for next in route {
            let (ox, oy) = self.grid.centre(on);
            let sheet = zoned(&self.sheet, &self.circles, Point { x: ox, y: oy });
            let step = step_with(&self.grid, &sheet, r, r.gait, Some(on), true,
                                 self.pace_here(Some(on), true, r.slowed_until),
                                 // A run of a few seconds does not carry
                                 // the whole walk home.
                                 false);
            if step.0 <= 0 {
                return false;
            }
            // Ticks to cross one tile, rounded up: a part-tick is a tick. A
            // tunnel is as many tiles as it is long.
            let t = Fx::ONE.div(step).0;
            let tiles = self.grid.walk_tiles(on, next).max(1) as u64;
            walk += ((t + fixed::FX_ONE - 1) / fixed::FX_ONE) as u64 * tiles;
            on = next;
        }
        let wait = match self.skiff {
            Some(s) => s.arrives.saturating_sub(self.tick) as u64,
            None => self.skiff_ticks as u64,
        };
        let need = walk.max(wait);
        // Clock left, in ticks, at this realm's clock rate.
        let (n, d) = self.sheet.factor(Param::ClockRate);
        let left_milli = (self.clock as u64 * 1000).saturating_sub(self.clock_run);
        let left = left_milli * d as u64 / (1000 * n as u64);
        left > need
    }

    /// §12.9's outcome, from the crew's standings. Meaningful once the clock
    /// has run or everyone is out or caught; before that it says what the
    /// heist would come to if it stopped now.
    pub fn outcome(&self) -> Outcome {
        // What a Prism mite's half brings out is banked; the half is not one
        // of the crew, so it is never counted out, caught or in the mask.
        let banked: i32 = self.raiders.iter()
            .filter(|r| r.standing == Standing::Out).map(|r| r.carried).sum();
        let crew = || self.raiders.iter().enumerate().filter(|(_, r)| r.half_of.is_none());
        let capacity: i32 = crew().map(|(_, r)| r.role.carry()).sum();
        let caught = crew().filter(|(_, r)| r.standing == Standing::Caught).count() as u32;
        let out = crew().filter(|(_, r)| r.standing == Standing::Out).count() as u32;
        let out_mask = crew()
            .filter(|(_, r)| r.standing == Standing::Out).fold(0u8, |m, (i, _)| m | 1 << i);
        let grade = if banked == 0 {
            Grade::Foiled
        } else if out as usize != crew().count() {
            Grade::Partial
        } else if self.alarm_raised {
            Grade::Loud
        } else {
            Grade::Clean
        };
        let pages = self.laws.iter().filter(|l| l.broken_at.is_some()).count() as u32;
        let broken = self.laws.iter().filter(|l| l.broken_at.is_some())
            .fold(0u64, |m, l| m | 1u64 << l.def);
        let left = self.dropped.iter().map(|&(_, n)| n).sum::<i32>()
            + self.raiders.iter().filter(|r| r.standing != Standing::Out).map(|r| r.carried).sum::<i32>();
        Outcome { grade, banked, capacity, caught, out, out_mask, pages, broken, cracked: self.cracked, left,
                  casts_used: self.casts_used }
    }

    /// Enter a state, and do what entering it means.
    pub(crate) fn enter(&mut self, gi: usize, state: guard::State) {
        use guard::State::*;
        let now = self.tick;
        let from = self.guards[gi].state;
        if from != state {
            self.log.push(now, Event::Guard { guard: gi as u16, from, to: state, cause: self.why });
        }
        self.why = Cause::Table;
        {
            let g = &mut self.guards[gi];
            g.state = state;
            g.state_since = now;
            g.arrived_at = None;
        }
        match state {
            Investigating | Alerted => {
                let spot = self.guards[gi].interest;
                self.aim(gi, spot);
            }
            Returning => {
                let home = self.guards[gi].home;
                self.aim(gi, Some(home));
            }
            _ => {
                let g = &mut self.guards[gi];
                g.route.clear();
                g.along = 0;
            }
        }
        // "Calls out ... raises the alarm", and "alarm spreads by distance,
        // not everywhere at once: guards within four metres start
        // investigating half a second later."
        if state == Alerted {
            self.alarm_raised = true;
            let here = self.guards[gi].at;
            let spot = self.grid.tile_at(here.x, here.y);
            let reach = self.spread_reach();
            for other in 0..self.guards.len() {
                if other == gi || self.guards[other].knocked_out
                    || self.guards[other].at.distance(here) > reach {
                    continue;
                }
                if let Some(spot) = spot {
                    self.spreads.push((now + guard::SPREAD_DELAY_TICKS, other, spot));
                }
            }
            self.spreads.sort();
        }
    }

    /// Point a guard's route at a spot, by the same breadth-first walk the
    /// crew uses. A spot it cannot reach leaves it where it is, which is
    /// §12.18's rule for the crew applied to the other side.
    fn aim(&mut self, gi: usize, spot: Option<grid::TileIndex>) {
        let at = self.guards[gi].at;
        let from = self.grid.tile_at(at.x, at.y);
        let route = match (from, spot) {
            (Some(a), Some(b)) => path::find(&self.grid, a, b).unwrap_or_default(),
            _ => Vec::new(),
        };
        let g = &mut self.guards[gi];
        g.route = route;
        g.along = 0;
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
        mix(self.reinforced as i64);
        mix(self.spreads.len() as i64);
        mix(self.clock_run as i64);
        for &(spot, until) in &self.glares {
            mix(spot as i64);
            mix(until as i64);
        }
        for w in self.wards.iter() {
            mix(w.kind as i64);
            mix(w.health as i64);
            mix(w.armed_at as i64);
            mix(w.disarmed as i64 * 2 + w.broken as i64);
            mix(w.disarm as i64);
        }
        for law in self.laws.iter() {
            mix(law.def as i64);
            mix(law.health as i64);
            mix(law.broken_at.map_or(-1, |t| t as i64));
        }
        mix(self.vault.health as i64);
        mix(self.vault.exposed as i64);
        mix(self.vault.opened_at.map_or(-1, |t| t as i64));
        mix(self.skiff.map_or(-1, |s| s.tile as i64));
        mix(self.dropped.len() as i64);
        mix(self.alarm_raised as i64);
        for guard in self.guards.iter() {
            mix(guard.id as i64);
            mix(guard.at.x.0);
            mix(guard.at.y.0);
            mix(guard.facing.0 as i64);
            mix(guard.suspicion as i64);
            mix(guard.state as i64);
            for &(t, s) in &guard.rising {
                mix(t as i64);
                mix(s as i64);
            }
            mix(guard.state_since as i64);
            mix(guard.route.len() as i64);
            mix(guard.along as i64);
            mix(guard.interest.map_or(-1, |t| t as i64));
            mix(guard.swing as i64);
            mix(guard.health as i64);
            mix(guard.stunned_until as i64);
            mix(guard.knocked_out as i64);
            mix(guard.found as i64);
        }
        for raider in self.raiders.iter() {
            mix(raider.id as i64);
            mix(raider.at.x.0);
            mix(raider.at.y.0);
            mix(raider.speed.0);
            mix(raider.route.len() as i64);
            mix(raider.along as i64);
            mix(raider.route.get(raider.along).map_or(-1, |t| *t as i64));
            mix(raider.gait as i64);
            mix(raider.health as i64);
            mix(raider.carried as i64);
            mix(raider.task as i64);
            mix(raider.target as i64);
            mix(raider.swing as i64);
            mix(raider.standing as i64);
            mix(raider.revive as i64);
            mix(raider.still_for as i64);
            mix(raider.frozen_until as i64);
            mix(raider.landed as i64);
            // A crew member played by role has no ability, and its sum is
            // what it was before kinds, so no replay recorded then moves.
            if let Some(k) = raider.kind {
                mix(k as i64);
                mix(raider.uses as i64);
                mix(raider.locked_until as i64);
                mix(raider.ready as i64);
                mix(raider.effect_until as i64);
            }
            // A Prism mite split, and which half is which.
            if raider.twin.is_some() || raider.half_of.is_some() {
                mix(raider.twin.map_or(-1, |t| t as i64));
                mix(raider.split_until as i64);
                mix(raider.half_of.map_or(-1, |t| t as i64));
            }
        }
        for w in self.wards.iter().filter(|w| w.held_until > 0) {
            mix(w.held_until as i64);
        }
        // Bells and ice, only once there are any, so no replay recorded
        // before them moves.
        if self.bells_rung > 0 || !self.bells_due.is_empty() {
            mix(self.bells_rung as i64);
            for &t in &self.bells_due {
                mix(t as i64);
            }
        }
        for r in self.raiders.iter().filter(|r| r.skid || r.bounced || r.charging) {
            mix(r.id as i64);
            mix(r.skid as i64 * 2 + r.bounced as i64 + r.charging as i64 * 4);
        }
        for b in &self.bridges {
            mix(b.until as i64);
            mix(b.back as i64);
            for &t in &b.tiles {
                mix(t as i64);
            }
        }
        // The Sage and what its powers left running; nothing for a heist
        // with no Sage, so no replay recorded before Sages moves.
        if let Some(s) = self.sage {
            mix(s.sage as i64);
            mix(s.uses[0] as i64 * 100 + s.uses[1] as i64 * 10 + s.uses[2] as i64);
            mix(s.cooling_until as i64);
            mix(self.tailwind_until as i64);
            mix(self.renew_from.map_or(-1, |t| t as i64));
            mix(self.decoy.map_or(-1, |(t, from, _)| t as i64 * 100_000 + from as i64));
            mix(self.wards_shown_at.map_or(-1, |t| t as i64));
        }
        for law in self.laws.iter().filter(|l| l.suspended_until > 0) {
            mix(law.suspended_until as i64);
        }
        for law in self.laws.iter().filter(|l| l.inverted_until > 0) {
            mix(law.inverted_until as i64 + 1_000_000);
        }
        if !self.zones.is_empty() || self.casts_used != 0 {
            mix(self.casts_used as i64);
            for z in &self.zones {
                mix(z.def as i64);
                mix(z.until as i64);
                mix(z.at.map_or(-1, |p| p.x.0));
                mix(z.at.map_or(-1, |p| p.y.0));
            }
        }
        for w in &self.walls {
            mix(w.until as i64);
            for &t in &w.tiles {
                mix(t as i64);
            }
        }
        for &(ri, until) in &self.reveals {
            mix(ri as i64 * 1_000_000 + until as i64);
        }
        h
    }
}

/// How far a crew member moves in one tick standing on `here`: §11.1's speed,
/// its gait, the ground, the laws, and — if it is carrying — a law's loaded
/// speed and the Carrier's 15%. One function, so the walk and the estimate of
/// the walk home cannot disagree.
///
/// The tile stood on sets the pace, not the tile being entered: a character
/// is slowed by the mud it is in. Breadth-first chose the route without
/// consulting this, which is §12.18's rule that the crew does not decide — a
/// player who routes through mud walks through mud.
#[cfg(test)]
fn step_for(grid: &Grid, sheet: &Sheet, raider: &Raider, gait: Gait,
            here: Option<grid::TileIndex>, loaded: bool) -> Fx {
    step_with(grid, sheet, raider, gait, here, loaded, (1, 1), false)
}

/// A factor that slows, made 1 when nothing may slow (the Tidewalker's
/// "nothing slows it"); one that speeds stays.
/// The unit step and the distance from `a` to `b`, when they share a row or a
/// column and are not the same tile.
fn straight(grid: &Grid, a: grid::TileIndex, b: grid::TileIndex) -> Option<(i32, i32, i32)> {
    let ((ax, ay), (bx, by)) = (grid.coords(a), grid.coords(b));
    let (dx, dy) = (bx as i32 - ax as i32, by as i32 - ay as i32);
    match (dx, dy) {
        (0, 0) => None,
        (0, d) => Some((0, d.signum(), d.abs())),
        (d, 0) => Some((d.signum(), 0, d.abs())),
        _ => None,
    }
}

/// The tile `dx`, `dy` from `t`, if it is on the grid.
fn offset(grid: &Grid, t: grid::TileIndex, dx: i32, dy: i32) -> Option<grid::TileIndex> {
    let (x, y) = grid.coords(t);
    let (x, y) = (x as i32 + dx, y as i32 + dy);
    if x < 0 || y < 0 {
        return None;
    }
    grid.index(x as u16, y as u16)
}

fn unslowed((n, d): (i64, i64), unhindered: bool) -> (i64, i64) {
    if unhindered && n < d { (1, 1) } else { (n, d) }
}

/// `step_for`, with a factor for where it stands and what it has walked
/// through this tick (`World::pace_here`). `unhindered` is the Tidewalker's
/// ability: "For 6 s nothing slows it: terrain, laws and its own load leave
/// it at full speed." Its gait is the player's choice, not a slowing.
/// The Tinkerer's Invert: "turn a law into its opposite for 10 s, such as
/// Half gravity into heavy gravity" (§11.7). The opposite of one line of a
/// law's rule sheet, read as G81 records: a factor on a measure — a speed, a
/// health, a range, a rate, a damage — is turned over, so 25% faster becomes
/// 20% slower; a switch, a time, a share and Whispers' realm-wide reach have
/// no opposite on the sheet and are off while the law is turned. Half
/// gravity's one line is the leap, so turned it is a realm with no leap;
/// what more heavy gravity would do is not written.
fn opposite(p: Param, n: i64, d: i64) -> Option<(i64, i64)> {
    use Param::*;
    match p {
        CrewSpeed | GuardSpeed | LoadedSpeed | LargeSpeed | SmallSpeed | LargeHealth
        | SmallHealth | SightRange | NoiseRadius | SuspicionFill | SuspicionDecay
        | StructureDamage | Damage | ClockRate | ConeAngle | CarryWeight if n > 0 && d > 0 => {
            Some((d, n))
        }
        _ => None,
    }
}

/// The tunnel a crew member is inside, as (the mouth it went in by, the one
/// it comes out of): on a step between two mouths and on neither's tile. At
/// a mouth it is above ground and seen like anyone; between them, "nobody can
/// see into it" (§6.2, TD.38). Read off its route, so it is never stored.
fn underground(grid: &Grid, r: &Raider) -> Option<(grid::TileIndex, grid::TileIndex)> {
    let far = *r.route.get(r.along)?;
    let near = if r.along > 0 { r.route[r.along - 1] } else { r.came_from };
    let here = grid.tile_at(r.at.x, r.at.y);
    (grid.tunnel_exit(near) == Some(far) && here != Some(near) && here != Some(far))
        .then_some((near, far))
}

/// The tile a crew member's feet are on: where it stands, or inside a tunnel
/// the mouth it went in by, whose ground the tunnel's is.
fn crew_tile(grid: &Grid, r: &Raider) -> Option<grid::TileIndex> {
    match underground(grid, r) {
        Some((near, _)) => Some(near),
        None => grid.tile_at(r.at.x, r.at.y),
    }
}

#[allow(clippy::too_many_arguments)]
fn step_with(grid: &Grid, sheet: &Sheet, raider: &Raider, gait: Gait,
             here: Option<grid::TileIndex>, loaded: bool, extra: (i64, i64),
             unhindered: bool) -> Fx {
    let pace = here.map_or(Fx::ONE, |t| grid.at(t).pace());
    let pace = if unhindered && pace < Fx::ONE { Fx::ONE } else { pace };
    let (num, den) = gait.pace();
    let mut step = scale(raider.speed.mul(pace).mul(Fx::from_ratio(num, den)),
                         unslowed(sheet.factor(Param::CrewSpeed), unhindered));
    let size = unslowed(by_size(sheet, raider.size, Param::LargeSpeed, Param::SmallSpeed),
                        unhindered);
    if size != (1, 1) {
        step = scale(step, size);
    }
    let extra = unslowed(extra, unhindered);
    if extra != (1, 1) {
        step = scale(step, extra);
    }
    if loaded && !unhindered {
        step = scale(step, sheet.factor(Param::LoadedSpeed));
        if raider.role == Role::Carrier {
            let (n, d) = heist::CARRIER_LOADED_PACE;
            step = step.mul(Fx::from_ratio(n, d));
        }
    }
    step
}

/// Contact with friction off (§7.3's Contact row; Frictionless): "anything
/// moving keeps sliding until it hits something". A crew member that reaches
/// the end of its route goes on the way it was going, a tile at a time, until
/// the next tile is one it cannot step onto or a body lies or stands there.
/// The grid's edge is not a wall: a slide stops there.
///
/// With a rebound on the sheet (Bounce: walls "bounce back 50% of what hits
/// them, including characters"), a wall sends the slide back the way it
/// came; a Warden is "heavy enough to absorb a rebound". Only a slide meets a
/// wall, and a slide needs Frictionless, so wherever this happens Pinball
/// sounds too — "sliding characters ricochet off walls without slowing
/// down" — and every wall sends it back, not only the first (G23).
fn slide_on(grid: &Grid, guards: &[Guard], raider: &Raider, rebound: bool)
    -> Option<grid::TileIndex> {
    let n = raider.route.len();
    let last = *raider.route.last()?;
    let prev = if n >= 2 { raider.route[n - 2] } else { raider.came_from };
    let ((lx, ly), (px, py)) = (grid.coords(last), grid.coords(prev));
    let (dx, dy) = (lx as i32 - px as i32, ly as i32 - py as i32);
    if (dx, dy) == (0, 0) {
        return None;
    }
    let body = |t: grid::TileIndex| guards.iter().any(|g| grid.tile_at(g.at.x, g.at.y) == Some(t));
    let beyond = |sx: i32, sy: i32| {
        let (x, y) = (lx as i32 + sx, ly as i32 + sy);
        if x < 0 || y < 0 {
            return None;
        }
        grid.index(x as u16, y as u16)
    };
    let ahead = beyond(dx, dy)?;
    if grid.can_step(last, ahead) {
        return (!body(ahead)).then_some(ahead);
    }
    if !rebound || raider.role == Role::Warden {
        return None;
    }
    beyond(-dx, -dy).filter(|t| grid.can_step(last, *t) && !body(*t))
}

/// Walk `step` tiles along a route from `at`, which is heading for
/// `route[along]`. Returns the new position and index.
///
/// Reaching a tile centre part-way through a tick spends only the distance
/// to it, and the rest of the step carries on toward the next tile. Dropping
/// the remainder — which the first version did — makes every character walk
/// up to one tick a tile slower than §11.1 says, by an amount that depends on
/// how its speed divides a tile: a Scout covered 4.3 tiles a second, not 4.5.
fn walk_route(grid: &Grid, mut at: Point, route: &[grid::TileIndex], mut along: usize,
              step: Fx) -> (Point, usize) {
    let mut left = step;
    while left.0 > 0 {
        let Some(tile) = route.get(along) else { break };
        // A crystal wall raised across a route since it was chosen: "nothing
        // passes it". The walk waits at the wall, as §12.18 does not re-route.
        if grid.is_raised(*tile) {
            break;
        }
        let (x, y) = grid.centre(*tile);
        let target = Point { x, y };
        let d = at.distance(target);
        if d <= left {
            at = target;
            along += 1;
            left = left - d;
            continue;
        }
        let bearing = at.bearing_to(target);
        at = Point {
            x: at.x + trig::cos(bearing).mul(left),
            y: at.y + trig::sin(bearing).mul(left),
        };
        break;
    }
    (at, along)
}

/// Run a heist and return the per-second checksums, which is what §24.10 says
/// is kept: "every tick in memory, one a second kept".
pub fn run(heist: &Heist) -> Vec<u64> {
    let mut world = World::from_heist(heist);
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

/// A heist built from a seed alone, for the cross-target spike: `draw`'s
/// commands on the fixture realm, recorded.
pub fn fixture(seed: u64, ticks: u32, crew: u8) -> Heist {
    record(&island::Island::fixture(), seed, ticks, crew, draw(&island::Island::fixture(), seed, ticks, crew))
}

/// Play a command log on an island and write it down as a replay: the
/// header §24.11 asks for — the seed, the island's hash and the rules
/// version — and the checksum of every second. This is the device's half of
/// §24.12: what it queues and the server re-simulates.
pub fn record(island: &island::Island, seed: u64, ticks: u32, crew: u8,
              commands: Vec<Command>) -> Heist {
    record_in(island, seed, ticks, crew, None, commands)
}

/// `record`, in a week's era (§18.3).
pub fn record_in(island: &island::Island, seed: u64, ticks: u32, crew: u8, era: Option<era::Era>,
                 commands: Vec<Command>) -> Heist {
    record_with(island, seed, ticks, crew, era, None, commands)
}

/// `record_in`, with §12.5's crew manifest when the heist carries one.
pub fn record_with(island: &island::Island, seed: u64, ticks: u32, crew: u8,
                   era: Option<era::Era>, manifest: Option<replay::Manifest>,
                   commands: Vec<Command>) -> Heist {
    let mut heist = Heist {
        seed,
        island: island.digest(),
        rules: rules_version(),
        ticks, crew, era, manifest, commands,
        checksums: Vec::new(),
    };
    heist.checksums = run_on(island, &heist).iter().map(|s| truncate(*s)).collect();
    heist
}

/// A command log drawn from a seed rather than played by a person: the
/// spike needs an input log long enough to matter and identical on every
/// target, and a recorded session would do the same job without being
/// reproducible from eight bytes. §12.6 budgets 15 to 25 decisions in a run,
/// so this draws in that range and spreads them across the ticks. It aims at
/// the island it is given — its Vault, its pylons, its wards, its edges — so
/// the server's tests can play any island with it.
pub fn draw(island: &island::Island, seed: u64, ticks: u32, crew: u8) -> Vec<Command> {
    let mut rng = Rng::new(seed, Stream::Loot);
    let decisions = 15 + rng.below(11) as u32;      // 15 to 25, §12.6
    let side = island.side() as u64;
    let mut commands = Vec::with_capacity(decisions as usize * 2);
    // A tile, as a command aims at it: its centre, at 1/256 of a tile.
    let aim = |x: u64, y: u64| ((x * 256 + 128) as i16, (y * 256 + 128) as i16);
    // The four tiles beside the Vault, north, east, south, west.
    let (vx, vy) = (island.vault.0 as u64, island.vault.1 as u64);
    let beside = [(vx, vy.saturating_sub(1)), (vx + 1, vy), (vx, vy + 1), (vx.saturating_sub(1), vy)];
    for i in 0..decisions {
        let tick = (ticks / decisions) * i + (rng.below(20) as u32);
        let actor = rng.below(crew as u64) as u8;
        let mut push = |kind: Kind, (x, y): (i16, i16)| {
            commands.push(Command { tick, actor, kind, x, y });
        };
        // Most decisions are moves; the rest are §12.6's others — a gait,
        // who cracks, who loads and how full, and where the skiff comes.
        match rng.below(12) {
            0..=5 => {
                // Aimed inside the fixture's realm. A destination off the
                // grid is a command that does nothing, which is legal and
                // tests nothing.
                let x = rng.below(side * 256) as i16;
                let y = rng.below(side * 256) as i16;
                push(Kind::MoveTo, (x, y));
            }
            6 => push(Kind::Gait, (rng.below(3) as i16, 0)),
            7 => {
                let (bx, by) = beside[rng.below(4) as usize];
                push(Kind::MoveTo, aim(bx, by));
                push(Kind::Crack, (0, 0));
            }
            8 => {
                let (bx, by) = beside[rng.below(4) as usize];
                push(Kind::MoveTo, aim(bx, by));
                push(Kind::Load, (50 + rng.below(51) as i16, 0));
            }
            9 if !island.laws.is_empty() => {
                // A pylon: to the tile north of it, and break it.
                let (_, px, py) = island.laws[rng.below(island.laws.len() as u64) as usize];
                push(Kind::MoveTo, aim(px as u64, (py as u64).saturating_sub(1)));
                push(Kind::Break, aim(px as u64, py as u64));
            }
            10 if !island.wards.is_empty() => {
                // A ward: onto its tile, and disarm it (§10.3, v3.3).
                let (_, wx, wy) = island.wards[rng.below(island.wards.len() as u64) as usize];
                push(Kind::MoveTo, aim(wx as u64, wy as u64));
                push(Kind::Disarm, aim(wx as u64, wy as u64));
            }
            _ => {
                // An edge tile: a side, then a place along it.
                let along = rng.below(side);
                let (x, y) = match rng.below(4) {
                    0 => (along, 0),
                    1 => (side - 1, along),
                    2 => (along, side - 1),
                    _ => (0, along),
                };
                push(Kind::Skiff, aim(x, y));
                push(Kind::MoveTo, aim(x, y));
            }
        }
    }
    // §5.4's landing: any open edge tile. Drawn last, so every other
    // command is the one the same seed drew before landings were recorded.
    let landings = island.landings();
    if !landings.is_empty() {
        let (lx, ly) = landings[rng.below(landings.len() as u64) as usize];
        let (x, y) = aim(lx as u64, ly as u64);
        commands.push(Command { tick: 0, actor: 0, kind: Kind::Land, x, y });
    }
    commands.sort_by_key(|c| (c.tick, c.actor, c.kind as u8));
    commands
}

/// A heist planned the way a player would play it, rather than drawn from a
/// seed: three crew cross through the wall's gap, the Breaker cracks while the
/// others wait beside the Vault, everyone loads, and the skiff is called to the
/// nearest edge in time to be there when the bags are full.
///
/// The seeded fixture almost never opens the Vault — random moves rarely put
/// a Breaker beside it for fifteen seconds — so without this no golden replay
/// would carry cracking, loading, banking or a graded outcome.
pub fn planned() -> Heist {
    let t = |seconds: u32| seconds * TICKS_PER_SECOND;
    let at = |x: i16, y: i16| (x * 256 + 128, y * 256 + 128);
    let mut commands = Vec::new();
    let mut say = |tick: u32, actor: u8, kind: Kind, (x, y): (i16, i16)| {
        commands.push(Command { tick, actor, kind, x, y });
    };
    PLAN.iter().for_each(|&(s, actor, kind, x, y)| {
        let target = if matches!(kind, Kind::MoveTo | Kind::Skiff | Kind::Break | Kind::Land) {
            at(x, y)
        } else {
            (x, y)
        };
        say(t(s), actor, kind, target);
    });
    commands.sort_by_key(|c| (c.tick, c.actor, c.kind as u8));
    // §5.4: 150 s + 15 for one link.
    record(&island::Island::fixture(), PLANNED_SEED, t(165), 3, commands)
}

const PLANNED_SEED: u64 = 0x5EED_0F_A_7EA1;

/// The plan: (second, crew member, command, x, y). Crew 0 is a Scout, 1 a
/// Breaker, 2 a Carrier. Guards are numbered by §12.17's rows: 0 the Scout at
/// (2, 10), 1 the Warden on its rise at (5, 12), 2 the Breaker at (9, 4), 3
/// the Carrier at (11, 10) and 4 the Mender at (12, 2), all posted facing
/// north. The realm runs `FIXTURE_LAWS`: Haste, Brittle stone and Glowing dark.
///
/// v3.3 made this a different heist. The ambush is a two-second takedown and
/// a knockout (§12.8), and five seconds of cracking send every guard in the
/// Heart to the Vault (§12.6) — so the crew puts down every guard it can reach
/// unheard, and cracks fast enough that the noise never sounds. (The owner
/// has since decided no guard hears the Vault, F35; the plan still holds.)
///
///   0 s   everyone crouches. The Breaker breaks Haste's pylon beside the
///         landing. The Scout goes down the west edge, outside the Scout
///         guard's cone and the south-west wards, to the moss behind it
///   7 s   the Breaker goes to the moss behind the Breaker guard
///   8 s   the Scout takes the Scout guard down: a knockout at about 11 s
///  13 s   the Scout goes east to the Mender; the Breaker's takedown lands
///         at about 17 s
///  18 s   the Breaker goes round the east edge. The moss behind the Carrier
///         guard is inside the Gravity Well's three tiles, so the well pulls
///         the Breaker in and holds it; the waypoint given during the hold
///         (26 s) takes it round, not through the guard's tile, while the
///         well resets, and the takedown lands at about 32 s
///  20 s   the skiff is called to the east edge beside the Vault
///  33 s   everyone walks to the Vault. The Warden cannot be reached — its
///         rise has one ramp, in front of it — so it is the one guard left
///  36 s   all three crack at once: Brittle stone doubles every hit and the
///         assist bonus adds a quarter (§11.1), and the Vault opens in under
///         five seconds, before the crack noise can call the Warden
///  42 s   everyone loads. The Scout and the Breaker are full in 3.5 s and
///         leave at 46 s; the Carrier, on the Vault's far side from the
///         Warden, fills its 300 and leaves at 53 s
const PLAN: &[(u32, u8, Kind, i16, i16)] = &[
    (0, 0, Kind::Land, 1, 0),
    (0, 0, Kind::Gait, 1, 0),
    (0, 1, Kind::Gait, 1, 0),
    (0, 2, Kind::Gait, 1, 0),
    (0, 0, Kind::MoveTo, 0, 11),
    (0, 1, Kind::MoveTo, 1, 2),
    (0, 2, Kind::MoveTo, 6, 5),
    (0, 1, Kind::Break, 1, 3),
    (7, 1, Kind::MoveTo, 9, 5),
    (7, 1, Kind::Attack, 2, 0),
    (8, 0, Kind::MoveTo, 2, 11),
    (8, 0, Kind::Attack, 0, 0),
    (13, 0, Kind::MoveTo, 12, 3),
    (13, 0, Kind::Attack, 4, 0),
    (18, 1, Kind::MoveTo, 13, 11),
    (20, 0, Kind::Skiff, 13, 5),
    (25, 1, Kind::MoveTo, 11, 11),
    (26, 1, Kind::MoveTo, 9, 11),
    (29, 1, Kind::MoveTo, 11, 11),
    (29, 1, Kind::Attack, 3, 0),
    (33, 0, Kind::Gait, 0, 0),
    (33, 1, Kind::Gait, 0, 0),
    (33, 2, Kind::Gait, 0, 0),
    (33, 0, Kind::MoveTo, 11, 4),
    (33, 1, Kind::MoveTo, 11, 6),
    (33, 2, Kind::MoveTo, 12, 5),
    (36, 0, Kind::Crack, 0, 0),
    (36, 1, Kind::Crack, 0, 0),
    (36, 2, Kind::Crack, 0, 0),
    (42, 0, Kind::Load, 100, 0),
    (42, 1, Kind::Load, 100, 0),
    (42, 2, Kind::Load, 100, 0),
    (46, 0, Kind::MoveTo, 13, 5),
    (46, 1, Kind::MoveTo, 13, 5),
    (53, 2, Kind::MoveTo, 13, 5),
];

/// The golden replays, by what they are drawn from: (name, seed, ticks,
/// crew). Chosen to span what §24.10 and §12.5 allow: the short and long
/// ends of "4,500 to 7,200 ticks", and a crew of three, four and five. The
/// fifth, `planned-clean`, is `planned()`. `bin/golden.rs` writes them and
/// `rules_version` fingerprints the build with them.
pub const GOLDEN: &[(&str, u64, u32, u8)] = &[
    ("short-crew3", 0x0000_0000_0000_0001, 4_500, 3),
    ("long-crew5", 0x5EED_0000_0000_0001, 7_200, 5),
    ("mid-crew4", 0x0BAD_C0FF_EE00_1234, 6_000, 4),
    ("edge-seed-max", u64::MAX, 4_500, 3),
];

/// How much further, in half metres, a sound carries at a realm alarm level:
/// from level 2 "Every noise in the table below carries 1 m further, except a
/// crouched step on moss" (§12.17).
pub fn alarm_noise_extra(alarm: i32, sound: noise::Sound, surface: grid::Surface) -> u16 {
    let quiet = sound == noise::Sound::CrouchedWalk && surface == grid::Surface::Moss;
    if alarm >= guard::NOISE_FURTHER_AT && !quiet { guard::NOISE_FURTHER_HALF_METRES } else { 0 }
}

/// §24.11's rules version: what a replay's `rules` header names, and what
/// the server keeps a build of for as long as any replay needs it — "old
/// replays stay valid forever against the rules they were played under".
///
/// It has to move whenever anything the simulation decides moves, or an old
/// replay would be re-simulated under rules it was not played under. A
/// number bumped by hand would be forgotten, so it is computed: SHA-256 of
///
///   * the law table — every law's id and every parameter it sets, exactly;
///   * a behaviour fingerprint — the digest this build gives each golden
///     heist, drawn from its seed and plan and re-simulated on the fixture.
///
/// So any change the golden replays can see changes the version by itself,
/// and `golden_replays_still_verify` fails until they are re-recorded under
/// it. A change they cannot see does not move it — the same reach the goldens
/// have as a regression test, and the reason to keep adding them.
pub fn rules_version() -> [u8; 32] {
    use std::sync::OnceLock;
    static VERSION: OnceLock<[u8; 32]> = OnceLock::new();
    *VERSION.get_or_init(|| {
        let mut bytes = b"RBR1".to_vec();
        for law in laws_table::LAWS.iter() {
            bytes.extend_from_slice(law.id.as_bytes());
            bytes.push(0);
            bytes.push(law.simulated as u8);
            for (param, n, d) in law.params {
                bytes.push(*param as u8);
                bytes.extend_from_slice(&n.to_le_bytes());
                bytes.extend_from_slice(&d.to_le_bytes());
            }
            bytes.push(law.notes);
            // Its school: Wildgrowth reads it, so a law moved between
            // schools moves the version.
            bytes.extend_from_slice(law.school.as_bytes());
            bytes.push(0xFF);
        }
        // Reaches no golden sees, since the fixture has no ward: a Lantern
        // Glare's (F52), so a Glare that reached further is a rules change.
        bytes.extend_from_slice(&guard::GLARE_METRES.to_le_bytes());
        // §12.17's realm's watch (v3.7): the goldens play realm level 5, at
        // full strength, so a re-tuned watch at levels 1 to 3 is a rules
        // change they cannot see.
        for ((fn_, fd), (sn, sd)) in REALM_WATCH.iter() {
            bytes.extend_from_slice(&fn_.to_le_bytes());
            bytes.extend_from_slice(&fd.to_le_bytes());
            bytes.extend_from_slice(&sn.to_le_bytes());
            bytes.extend_from_slice(&sd.to_le_bytes());
        }
        // §10.1's buildings and their footprints. No golden island has one,
        // so a building re-sized or re-coded is a rules change no golden
        // would see.
        for (id, code, size) in island::BUILDING_CODES.iter() {
            bytes.extend_from_slice(id.as_bytes());
            bytes.push(0);
            bytes.extend_from_slice(&[*code, *size]);
        }
        // §18.3's eras and their figures: a re-figured era is a rules change.
        for (id, figure) in laws_table::ERAS.iter() {
            bytes.extend_from_slice(id.as_bytes());
            bytes.push(0);
            bytes.extend_from_slice(&figure.to_le_bytes());
        }
        // §8's tables: which two laws make each resonance and which notes
        // each chord needs. A re-noted law or a re-paired resonance moves
        // the version even where no golden would notice it.
        for (r, a, b) in laws_table::RESONANCES.iter() {
            bytes.push(*r as u8);
            bytes.extend_from_slice(a.as_bytes());
            bytes.push(0);
            bytes.extend_from_slice(b.as_bytes());
            bytes.push(0);
        }
        for (c, notes) in laws_table::CHORDS.iter() {
            bytes.push(*c as u8);
            bytes.push(*notes);
        }
        // §11.11's kinds and §12.6's ability rules. No golden carries a crew
        // manifest, so a kind given another role, size or ability, or an
        // ability re-numbered, is a rules change no golden would see.
        for k in ruleborn::RULEBORN.iter() {
            bytes.extend_from_slice(k.id.as_bytes());
            bytes.push(0);
            bytes.extend_from_slice(&[k.role as u8, k.size as u8, k.flies as u8,
                                      k.ability as u8, k.ability.built() as u8]);
        }
        for n in ruleborn::NUMBERS {
            bytes.extend_from_slice(&n.to_le_bytes());
        }
        // §6.2's features: each one's code, what it does to feet and eyes,
        // and its numbers. The goldens' fixture has none of the new ones.
        for &(f, id, code) in island::FEATURE_CODES.iter() {
            bytes.extend_from_slice(id.as_bytes());
            bytes.extend_from_slice(&[0, code, f.terrain().passable() as u8,
                                      f.hides_beyond().unwrap_or(-1) as u8]);
            if let grid::Terrain::Pace(p) = f.terrain() {
                bytes.push(p);
            }
        }
        for n in [grid::LANTERN_TILES, grid::OUTCROP_EXTRA_TILES, grid::SCREE_TILES,
                  grid::SCREE_FILL.0, grid::SCREE_FILL.1, grid::SPRING_HEAL.0, grid::SPRING_HEAL.1,
                  grid::EMBER_SECONDS as i32, grid::EMBER_LIGHT_TILES, grid::STONE_SECONDS as i32,
                  grid::STONE_TILES, grid::HEDGE_CUT_SECONDS as i32,
                  grid::BOULDER_SMASH_SECONDS as i32] {
            bytes.extend_from_slice(&n.to_le_bytes());
        }
        // The six with a direction (TD.38): stairs' pace is in the loop above;
        // the rapids' push and a tunnel's reach are here, and the tunnel's
        // mouth, which no feature code carries.
        for n in [grid::RAPIDS_TILES, grid::RAPIDS_SECONDS as i32, grid::TUNNEL_TILES as i32,
                  grid::TUNNEL_MIN_TILES as i32, Feature::Tunnel as i32] {
            bytes.extend_from_slice(&n.to_le_bytes());
        }
        // Which lines of a law a zone — a cast, a Copy — carries.
        for p in ZONED {
            bytes.push(p as u8);
        }
        // §11.7's Sages: each one's powers, their uses and whether built.
        for s in ruleborn::SAGES.iter() {
            bytes.extend_from_slice(s.id.as_bytes());
            bytes.push(0);
            for (p, uses) in s.powers {
                bytes.extend_from_slice(&[p as u8, uses, p.built() as u8]);
            }
        }
        // A heist across a universe (§5.4), which no golden plays: the clock
        // by links, the skiff to an outer realm, a Rift link's 30 seconds shut
        // and the Wanderer's Rift's 20 open, so a change to any is a rules
        // change.
        for n in [universe::HEIST_CLOCK.0, universe::HEIST_CLOCK.1, universe::HEIST_CLOCK.2,
                  heist::SKIFF_OUTER_TICKS, universe::RIFT_CLOSED_TICKS, ruleborn::RIFT_TICKS] {
            bytes.extend_from_slice(&n.to_le_bytes());
        }
        let fixture = island::Island::fixture();
        let bare = |seed: u64, ticks: u32, crew: u8, commands: Vec<Command>| Heist {
            seed, island: [0; 32], rules: [0; 32], ticks, crew, era: None, manifest: None, commands,
            checksums: Vec::new(),
        };
        let mut heists: Vec<Heist> = GOLDEN.iter()
            .map(|(_, seed, ticks, crew)| bare(*seed, *ticks, *crew,
                                               draw(&fixture, *seed, *ticks, *crew)))
            .collect();
        let mut plan: Vec<Command> = PLAN.iter().map(|&(s, actor, kind, x, y)| {
            let (x, y) = if matches!(kind, Kind::MoveTo | Kind::Skiff | Kind::Break | Kind::Land) {
                (x * 256 + 128, y * 256 + 128)
            } else {
                (x, y)
            };
            Command { tick: s * TICKS_PER_SECOND, actor, kind, x, y }
        }).collect();
        plan.sort_by_key(|c| (c.tick, c.actor, c.kind as u8));
        heists.push(bare(PLANNED_SEED, 165 * TICKS_PER_SECOND, 3, plan));
        for heist in &heists {
            bytes.extend_from_slice(&digest_on(&fixture, heist).to_le_bytes());
        }
        sha256::sha256(&bytes)
    })
}

/// Run a heist on an island and return the per-second checksums.
pub fn run_on(island: &island::Island, heist: &Heist) -> Vec<u64> {
    let mut world = World::from_island(island, heist);
    let mut kept = Vec::with_capacity((heist.ticks / TICKS_PER_SECOND) as usize + 1);
    for _ in 0..heist.ticks {
        let sum = world.step();
        if world.tick % TICKS_PER_SECOND == 0 {
            kept.push(sum);
        }
    }
    kept
}

fn digest_on(island: &island::Island, heist: &Heist) -> u64 {
    let mut h: u64 = 0xcbf2_9ce4_8422_2325;
    for sum in run_on(island, heist) {
        for byte in sum.to_le_bytes() {
            h ^= byte as u64;
            h = h.wrapping_mul(0x0000_0100_0000_01b3);
        }
    }
    h
}

/// §24.10's heist length: "A heist is 4,500 to 7,200 ticks".
pub const MIN_TICKS: u32 = 4_500;
pub const MAX_TICKS: u32 = 7_200;

/// Why the server will not accept a replay, before or after re-simulating it.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Refusal {
    /// The header names a different island from the one it is checked on.
    Island,
    /// The header names a rules version this build is not.
    Rules,
    /// §12.5: "A crew of 3 to 5".
    Crew,
    /// Outside §24.10's 4,500 to 7,200 ticks.
    Length,
    /// Not in tick order, or a command past the end of the heist.
    Log,
    /// Not one checksum a second. A replay with none would otherwise verify
    /// against anything.
    Checksums,
    /// §5.4: the crew never landed — no landing at tick 0 on an open edge
    /// tile. Without one it would start where `on_ground` puts it, unheard.
    Landing,
    /// The re-simulation and the replay part company at this second.
    Diverged(usize),
}

/// What the server does with a replay (§24.12's "Validate"): check that it
/// names this island and these rules, that it is the shape §24.10 gives a
/// heist, re-simulate it, and compare every second. The outcome is the
/// re-simulation's, never anything the device claims — the replay carries no
/// outcome at all, only commands and checksums.
pub fn verify_on(island: &island::Island, heist: &Heist) -> Result<heist::Outcome, Refusal> {
    verified(island, heist).map(|world| world.outcome())
}

/// `verify_on` with the heist's `Report` beside its verdict: one
/// re-simulation for both (TD.39).
pub fn verify_report(island: &island::Island, heist: &Heist) -> Result<(heist::Outcome, Report), Refusal> {
    verified(island, heist).map(|world| (world.outcome(), world.report(island)))
}

/// The world a replay plays to its end on its island, every second's
/// checksum compared on the way.
fn verified(island: &island::Island, heist: &Heist) -> Result<World, Refusal> {
    if heist.island != island.digest() {
        return Err(Refusal::Island);
    }
    if heist.rules != rules_version() {
        return Err(Refusal::Rules);
    }
    if !(3..=5).contains(&heist.crew) {
        return Err(Refusal::Crew);
    }
    // Quiet Week's heists are longer than §24.10's longest (F49).
    if !(MIN_TICKS..=MAX_TICKS + era::extra_ticks(heist.era)).contains(&heist.ticks) {
        return Err(Refusal::Length);
    }
    if !heist.commands.windows(2).all(|w| w[0].tick <= w[1].tick)
        || heist.commands.iter().any(|c| c.tick >= heist.ticks)
    {
        return Err(Refusal::Log);
    }
    if heist.checksums.len() != (heist.ticks / TICKS_PER_SECOND) as usize {
        return Err(Refusal::Checksums);
    }
    let mut world = World::from_island(island, heist);
    let mut second = 0usize;
    for _ in 0..heist.ticks {
        let sum = world.step();
        if world.tick == 1 && world.landing.is_none() {
            return Err(Refusal::Landing);
        }
        if world.tick % TICKS_PER_SECOND == 0 {
            if truncate(sum) != heist.checksums[second] {
                return Err(Refusal::Diverged(second + 1));
            }
            second += 1;
        }
    }
    Ok(world)
}

/// What a verified heist's event log says for the defender's report and
/// Profile's records (§13.2, §23.2, TD.39). §13.2 defines each for one raid:
/// "held is the seconds from the first landing to the last crew member's
/// escape or capture; seen is each place a guard reached Alerted …; fired is
/// each ward set off, bell rung". Beside them: where the crew landed, how
/// high the realm alarm climbed, how many of the island's posts never
/// noticed anyone and how many were Alerted, and the posts whose guards
/// caught anyone. Read from `events::Log`, outside the checksum, so it is
/// the same wherever the replay is re-simulated.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Report {
    pub landing: Option<(u8, u8)>,
    /// Seconds from the landing to the last crew member out or caught; the
    /// whole clock if one was still inside when it ran out.
    pub held: u16,
    pub alarm: u8,
    pub bells: u16,
    pub slept: u8,
    pub alerted: u8,
    /// (crew member, x, y): where a crew member stood when a guard reached
    /// Alerted on seeing it, each place once.
    pub seen: Vec<(u8, u8, u8)>,
    /// (ward, x, y, times it fired).
    pub fired: Vec<(heist::WardKind, u8, u8, u16)>,
    /// (post's role row, x, y): the island's posts whose guards caught a
    /// crew member; row 255 for alarm level 5's Warden, at its entrance.
    pub caught_by: Vec<(u8, u8, u8)>,
}

impl Report {
    /// The report's wire form, as `rb_verify` writes it after the verdict:
    /// landing x, y (255, 255 for none), held u16 LE, alarm, bells (to 255),
    /// slept, alerted; then a count and (crew, x, y) each seen, a count and (ward
    /// code, x, y, times to 255) each fired, a count and (row, x, y) each
    /// captor.
    pub fn encode(&self) -> Vec<u8> {
        let (lx, ly) = self.landing.unwrap_or((255, 255));
        let mut out = vec![lx, ly];
        out.extend_from_slice(&self.held.to_le_bytes());
        out.extend_from_slice(&[self.alarm, self.bells.min(255) as u8, self.slept, self.alerted]);
        out.push(self.seen.len() as u8);
        self.seen.iter().for_each(|&(c, x, y)| out.extend_from_slice(&[c, x, y]));
        out.push(self.fired.len() as u8);
        self.fired.iter().for_each(|&(k, x, y, n)| out.extend_from_slice(&[k as u8, x, y, n.min(255) as u8]));
        out.push(self.caught_by.len() as u8);
        self.caught_by.iter().for_each(|&(r, x, y)| out.extend_from_slice(&[r, x, y]));
        out
    }
}

impl World {
    /// `Report` from this world's log, the island it was played on beside it.
    pub fn report(&self, island: &island::Island) -> Report {
        use events::{Cause, Event, Hurt};
        let at = |t: grid::TileIndex| {
            let (x, y) = self.grid.coords(t);
            (x as u8, y as u8)
        };
        let mut r = Report { landing: self.landing.map(at), ..Report::default() };
        let mut noticed = std::collections::BTreeSet::new();
        let mut alerted = std::collections::BTreeSet::new();
        let mut fired: Vec<(u16, u16)> = Vec::new();
        let mut captors: Vec<u16> = Vec::new();
        let mut last = 0u32;
        let mut done = std::collections::BTreeSet::new();
        for (i, &(t, e)) in self.log.events.iter().enumerate() {
            match e {
                Event::Guard { guard, to, cause, .. } => {
                    if cause != Cause::Table {
                        noticed.insert(guard);
                    }
                    if to == guard::State::Alerted {
                        alerted.insert(guard);
                    }
                    if let (guard::State::Alerted, Cause::Saw(c)) = (to, cause) {
                        let place = self.log.positions.iter().rev().find(|p| p.0 <= t && p.1 == c)
                            .map(|p| ((p.2.max(0) / 256) as u8, (p.3.max(0) / 256) as u8));
                        if let Some((x, y)) = place.filter(|&(x, y)| !r.seen.iter().any(|s| (s.1, s.2) == (x, y))) {
                            r.seen.push((c, x, y));
                        }
                    }
                }
                Event::Alarm { level, .. } => r.alarm = r.alarm.max(level),
                Event::Bell { .. } => r.bells += 1,
                Event::Ward { ward, .. } => match fired.iter_mut().find(|f| f.0 == ward) {
                    Some(f) => f.1 += 1,
                    None => fired.push((ward, 1)),
                },
                Event::Out { crew, .. } => {
                    last = last.max(t);
                    done.insert(crew);
                }
                Event::Caught { crew, .. } => {
                    last = last.max(t);
                    done.insert(crew);
                    let captor = self.log.events[..i].iter().rev().find_map(|&(_, d)| match d {
                        Event::Down { crew: c, by: Hurt::Guard(g) } if c == crew => Some(g),
                        _ => None,
                    });
                    if let Some(g) = captor.filter(|g| !captors.contains(g)) {
                        captors.push(g);
                    }
                }
                _ => {}
            }
        }
        // Everyone out or caught before the clock: the last of them; else
        // the clock itself.
        let ended = if done.len() >= self.raiders.len() { last } else { self.clock };
        r.held = (ended / TICKS_PER_SECOND).min(u16::MAX as u32) as u16;
        let posts = island.guards.len();
        r.slept = (0..posts as u16).filter(|g| !noticed.contains(g)).count() as u8;
        r.alerted = alerted.len() as u8;
        r.fired = fired.iter().filter_map(|&(w, n)| self.wards.get(w as usize).map(|ward| {
            let (x, y) = at(ward.tile);
            (ward.kind, x, y, n)
        })).collect();
        r.caught_by = captors.iter().filter_map(|&g| match island.guards.get(g as usize) {
            Some(p) => Some((p.row, p.x, p.y)),
            None => self.guards.get(g as usize).map(|w| {
                let (x, y) = at(w.home);
                (255, x, y)
            }),
        }).collect();
        r
    }
}

// The WebAssembly surface is `ffi.rs`.
