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
pub mod grid;
pub mod guard;
pub mod heist;
pub mod laws_table;
pub mod noise;
pub mod path;
pub mod replay;
pub mod sight;

#[cfg(test)]
mod tests;
pub mod rng;
pub mod trig;

use fixed::{Ang, Fx};
use grid::{Feature, Grid, Surface, Terrain};
use heist::{Grade, Outcome, Skiff, Standing, Task, Vault, Ward, WardKind};
use laws_table::{Param, LAWS};

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
    factors: [(i64, i64); 20],
    set: [bool; 20],
}

impl Sheet {
    pub fn plain() -> Sheet {
        Sheet { factors: [(1, 1); 20], set: [false; 20] }
    }

    /// A parameter as (numerator, denominator); (1, 1) if no law sets it.
    pub fn factor(&self, p: Param) -> (i64, i64) {
        self.factors[p as usize]
    }

    /// A flag's value if a law sets it. §7.3 flags are set, not multiplied.
    pub fn flag(&self, p: Param) -> Option<i64> {
        self.set[p as usize].then(|| self.factors[p as usize].0 / self.factors[p as usize].1)
    }

    fn apply(&mut self, p: Param, n: i64, d: i64) {
        let i = p as usize;
        let (a, b) = self.factors[i];
        let (a, b) = (a * n, b * d);
        let g = gcd(a.abs(), b).max(1);
        self.factors[i] = (a / g, b / g);
        self.set[i] = true;
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

impl Role {
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
    /// When it reached the spot it was investigating, for the ten seconds.
    arrived_at: Option<u32>,
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
        arrived_at: None,
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
    /// How many ticks it has stood still, for Stillness.
    pub still_for: u32,
    /// When it went down, and how long an ally has been reviving it.
    pub down_since: u32,
    pub revive: u32,
}

impl Raider {
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
    /// "Alarm spreads by distance": (tick due, guard index, the spot), kept in
    /// that order so the same spreads land in the same order everywhere.
    spreads: Vec<(u32, usize, grid::TileIndex)>,
    /// The realm's tiles. §12.18's "terrain, laws and building are per tile".
    pub grid: Grid,
    /// The input log, in tick order, and how far through it the tick loop is.
    /// Held rather than consumed, so the same log can be replayed again.
    commands: Vec<Command>,
    next_command: usize,
    /// The island's wards (§10.3), and a Lantern Glare's reveal: every guard
    /// shown the crew until `revealed_until`, looking at `reveal_spot`.
    pub wards: Vec<Ward>,
    pub revealed_until: u32,
    pub reveal_spot: Option<grid::TileIndex>,
    /// The realm's laws and their pylons, and this tick's sheet from them.
    pub laws: Vec<Law>,
    pub sheet: Sheet,
    /// How far the heist clock has run, in thousandths of a tick. Haste runs
    /// it "25% faster in this realm", so it is not the tick count.
    pub clock_run: u64,
    pub vault: Vault,
    pub skiff: Option<Skiff>,
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
        debug_assert!(
            commands.windows(2).all(|w| w[0].tick <= w[1].tick),
            "the input log has to be in tick order or the inputs phase is not a phase");
        // §5.2's realm 5 is 14x14, the largest, so the spike uses it. The
        // features are §6.2's, chosen because they pull feet and eyes apart:
        //
        //   a ruin wall with one gap    blocks both; the gap makes a route
        //                               bend, so the neighbour order and the
        //                               tie-breaking are observable
        //   a rock pillar               blocks both, in open ground
        //   a fence                     blocks walking, "doesn't block sight"
        //   a fog bank                  walkable, blocks sight through it
        //   mud and a fast path         §6.2's "40% slower" and "15% faster"
        let mut grid = Grid::for_realm_level(FIXTURE_REALM_LEVEL);
        for y in 0..grid.height {
            if y != 6 {
                grid.place(7, y, Feature::RuinWall);
            }
        }
        grid.place(4, 5, Feature::RockPillar);
        for x in 9..12 {
            grid.place(x, 7, Feature::Fence);
        }
        grid.place(5, 8, Feature::FogBank);
        grid.place(6, 8, Feature::FogBank);
        grid.set(3, 3, Terrain::Pace(60));
        grid.set(10, 9, Terrain::Pace(115));
        // §12.17's remaining modifiers, each where a route or a guard meets it:
        //   tall grass west of the wall   invisible if still, until a guard
        //                                 walks into the tile
        //   a gravel run through the gap  louder, at the one place every
        //                                 crossing has to use
        //   moss in the south-east        quieter
        //   a dark corner by the entrance "an unlit tile halves it again"
        for x in 1..4 {
            grid.place(x, 7, Feature::TallGrass);
        }
        for x in 5..10 {
            grid.set_surface(x, 6, Surface::Gravel);
        }
        for x in 8..11 {
            grid.set_surface(x, 12, Surface::Moss);
        }
        // Moss behind two posts. A crouched walk carries 1 m and the tile
        // behind a guard is 1 m away, so the last step of any approach on
        // plain ground is heard; on moss a crouched walk carries nothing.
        // Without these §12.8's ambush has no way in (see the README).
        grid.set_surface(9, 5, Surface::Moss);
        grid.set_surface(12, 3, Surface::Moss);
        for y in 10..14 {
            for x in 10..14 {
                grid.darken(x, y);
            }
        }
        // A rise for the Warden's post: §6.2's raised ground, one level, with a
        // ramp up from the north. From up there it sees a metre further toward
        // anyone below (§12.17); a raider up there hides its far zone from the
        // guards below.
        for y in 12..14 {
            for x in 4..7 {
                grid.set_height(x, y, 1);
            }
        }
        grid.make_climbable(5, 11);
        // The Vault, past the wall's gap and the gravel, between the Breaker's
        // post and the Mender's: the fixture realm is the Heart.
        grid.place(VAULT_AT.0, VAULT_AT.1, Feature::Vault);

        // Guards on tile centres, on both sides of the wall, so that the
        // wall, the fence and the fog each stand between some guard and some
        // route. Every guard is inside the grid: a guard off it would see
        // nothing and make its whole row of §12.17's table untested.
        let posts: [(u16, u16); 5] = [(2, 10), (5, 12), (9, 4), (11, 10), (12, 2)];
        let guards: Vec<Guard> = posts
            .iter()
            .enumerate()
            .map(|(row, (px, py))| {
                make_guard(row as u32, row, grid.index(*px, *py).unwrap_or(0), &grid)
            })
            .collect();
        // The fixture's entrance, where §12.17's reinforcing Warden arrives:
        // the far corner from the crew's start, on the guards' side.
        let entrance = grid.index(grid.width - 1, grid.height - 1).unwrap_or(0);
        let vault_tile = grid.index(VAULT_AT.0, VAULT_AT.1).unwrap_or(0);

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
                frozen_until: 0,
                down_since: 0,
                revive: 0,
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
            spreads: Vec::new(),
            grid,
            commands,
            next_command: 0,
            wards: Vec::new(),
            revealed_until: 0,
            reveal_spot: None,
            laws: Vec::new(),
            sheet: Sheet::plain(),
            clock_run: 0,
            vault: Vault {
                tile: vault_tile,
                health: heist::VAULT_HEALTH_PER_LEVEL,
                exposed: heist::FIXTURE_EXPOSED,
                first_hit: None,
                opened_at: None,
            },
            skiff: None,
            dropped: Vec::new(),
            clock: u32::MAX,
            alarm_raised: false,
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
            self.laws.push(Law { def, pylon, health: heist::PYLON_HEALTH, broken_at: None });
        }
        self.refresh_sheet();
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

    /// The world a replay describes: the fixture realm, the heist's crew and
    /// commands, its laws, and its clock.
    pub fn from_heist(heist: &Heist) -> World {
        let mut world = World::new(heist.seed, heist.crew, heist.commands.clone());
        world.weave(&FIXTURE_LAWS);
        world.place_wards(&FIXTURE_WARDS);
        world.clock = heist.ticks;
        world
    }

    /// Replace the input log, for a test that builds its world by hand.
    #[cfg(test)]
    pub(crate) fn commands_for_test(&mut self, commands: Vec<Command>) {
        self.commands = commands;
        self.next_command = 0;
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
            // Down, caught or gone: nothing to command.
            if !raider.active() {
                continue;
            }
            match command.kind {
                Kind::MoveTo => {
                    let (x, y) = command.target();
                    let from = self.grid.tile_at(raider.at.x, raider.at.y);
                    let to = self.grid.tile_at(x, y);
                    // A destination off the grid or inside a wall is not
                    // re-aimed at the nearest open tile. §12.18: "the crew
                    // never makes a decision the player did not make."
                    raider.route = match (from, to) {
                        (Some(a), Some(b)) => path::find(&self.grid, a, b)
                            .unwrap_or_default(),
                        _ => Vec::new(),
                    };
                    raider.along = 0;
                }
                // An unknown gait is dropped like an unknown crew member.
                Kind::Gait => {
                    if let Some(gait) = Gait::from_command(command.x) {
                        raider.gait = gait;
                    }
                }
                Kind::Halt => {
                    raider.route.clear();
                    raider.along = 0;
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
                Kind::Skiff => {
                    let (x, y) = command.target();
                    if let Some(tile) = self.grid.tile_at(x, y) {
                        if self.skiff.is_none() && self.grid.is_edge(tile)
                            && self.grid.at(tile).passable()
                        {
                            self.skiff = Some(Skiff {
                                tile,
                                arrives: self.tick + heist::SKIFF_HEART_TICKS,
                            });
                        }
                    }
                }
            }
        }
    }

    /// Laws. The sheet for this tick, from every law whose pylon still
    /// stands, so a pylon broken during a tick switches its law off from the
    /// next — the same tick on every machine. Parameters the simulation cannot
    /// apply yet are carried on the sheet and read by nothing; the content
    /// gate lists them.
    fn phase_laws(&mut self) {
        self.refresh_sheet();
        self.grid.free_climb = self.sheet.flag(Param::ClimbLevels).is_some_and(|v| v >= 1)
            || self.sheet.flag(Param::LeapObstacles).is_some_and(|v| v >= 1);
        // "the heist clock runs 25% faster in this realm"
        let (n, d) = self.sheet.factor(Param::ClockRate);
        self.clock_run += (1000 * n / d) as u64;
    }

    fn refresh_sheet(&mut self) {
        let mut sheet = Sheet::plain();
        for law in self.laws.iter().filter(|l| l.broken_at.is_none()) {
            for &(p, n, d) in LAWS[law.def].params {
                sheet.apply(p, n, d);
            }
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
                    && self.sees(gi, self.guards[other].at).is_some()
                {
                    self.guards[other].found = true;
                    self.knockouts_discovered += 1;
                }
            }
            let mut gain = 0i32;
            // The raider noticed most this tick, ties to the lower id, so a
            // guard's interest is the same spot on every machine.
            let mut most: Option<(i32, grid::TileIndex)> = None;
            for ri in 0..self.raiders.len() {
                let Some((per_tick, to)) = self.noticed(gi, ri) else { continue };
                gain += per_tick;
                if most.is_none_or(|(g, _)| per_tick > g) {
                    most = Some((per_tick, to));
                }
            }
            // No jitter. §12.17: "nothing here is random: a player who scouts
            // an island can predict exactly what will happen." The spike's
            // first version added a random -1 to +1 a tick here, to put the
            // generator on the hot path, and in doing so broke the one
            // promise this section makes about itself.
            // Lantern Glare: "shows the crew to every guard in the realm" —
            // as if in its near zone, looking at the tile that set it off.
            if now < self.revealed_until && self.raiders.iter().any(|r| r.active()) {
                if let Some(spot) = self.reveal_spot {
                    gain = gain.max(FILL_NEAR);
                    if most.is_none() {
                        most = Some((FILL_NEAR, spot));
                    }
                }
            }
            let guard = &mut self.guards[gi];
            guard.saw = most.is_some();
            if let Some((_, at)) = most {
                guard.interest = Some(at);
            }
            if gain > 0 {
                guard.suspicion = (guard.suspicion + gain).min(SUSPICION_MAX);
            } else {
                let (n, d) = self.sheet.factor(Param::SuspicionDecay);
                guard.suspicion = (guard.suspicion - DECAY_PER_TICK * n as i32 / d as i32).max(0);
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
        if self.sheet.flag(Param::StillIsInvisible) == Some(1)
            && raider.still_for >= heist::STILL_TICKS
        {
            return None;
        }
        // In range and in the cone is not enough: something between may
        // stop sight, checked below, last, because it is the costly test.
        let (d, in_cone, from, to) = self.sees_geometry(gi, raider.at)?;
        // "Standing still in tall grass makes you invisible until a
        // guard walks into the tile."
        if raider.still() && from != to
            && self.grid.feature(to) == Some(Feature::TallGrass)
        {
            return None;
        }
        if !self.line_clear(from, to) {
            return None;
        }
        let sight = self.sheet.factor(Param::SightRange);
        // Beyond mid is the far zone, which height stretches or removes.
        let zone = if d <= scale(guard.near, sight) {
            FILL_NEAR
        } else if d <= scale(guard.mid, sight) {
            FILL_MID
        } else {
            FILL_FAR
        };
        let (mut num, mut den) = raider.gait.noticed();
        let (fn_, fd) = self.sheet.factor(Param::SuspicionFill);
        num *= fn_ as i32;
        den *= fd as i32;
        if self.grid.is_unlit(to) {
            num *= UNLIT.0;
            den *= UNLIT.1;
        }
        if !in_cone {
            num *= PERIPHERAL.0;
            den *= PERIPHERAL.1;
        }
        let per_tick = zone * num / den;
        Some((per_tick, to))
    }

    /// Whether a guard can see a point at all: in reach, in the cone or the
    /// corner of the eye, and not behind anything that stops sight. Returns
    /// the tile seen. Used for finding knocked-out guards.
    fn sees(&self, gi: usize, at: Point) -> Option<grid::TileIndex> {
        let (_, _, from, to) = self.sees_geometry(gi, at)?;
        self.line_clear(from, to).then_some(to)
    }

    /// Whether sight passes between two tiles. Glass: "Walls become
    /// see-through: nobody can hide behind them".
    fn line_clear(&self, from: grid::TileIndex, to: grid::TileIndex) -> bool {
        self.sheet.flag(Param::HideBehindWalls) == Some(0) || sight::visible(&self.grid, from, to)
    }

    /// Distance, whether in the cone proper, and the two tiles — or `None`
    /// if the point is out of reach or outside both arcs.
    fn sees_geometry(&self, gi: usize, at: Point)
        -> Option<(Fx, bool, grid::TileIndex, grid::TileIndex)> {
        let guard = &self.guards[gi];
        let d = guard.at.distance(at);
        // A law may shorten sight — Glowing dark halves it, Sleepwalk closes
        // the guards' eyes — so every range is read through the sheet.
        let sight = self.sheet.factor(Param::SightRange);
        if sight.0 == 0 {
            return None;
        }
        let from = self.grid.tile_at(guard.at.x, guard.at.y)?;
        let to = self.grid.tile_at(at.x, at.y)?;
        let reach = scale(self.outer_zone(gi, from, to), sight);
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
        let in_cone = d.0 == 0 || off <= guard.cone.0 / 2;
        if !in_cone && off > guard.peripheral.0 / 2 {
            return None;
        }
        Some((d, in_cone, from, to))
    }

    /// How far a guard's outermost zone reaches toward a tile. §12.17: "A guard
    /// standing a level higher sees a metre further; one standing below loses
    /// its far zone entirely." A metre per level of the difference.
    fn outer_zone(&self, gi: usize, from: grid::TileIndex, to: grid::TileIndex) -> Fx {
        let g = &self.guards[gi];
        let (hg, ht) = (self.grid.height(from) as i32, self.grid.height(to) as i32);
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
        for raider in self.raiders.iter_mut() {
            raider.landed = 0;
            raider.still_for = if raider.still() && raider.active() {
                raider.still_for.saturating_add(1)
            } else {
                0
            };
            if raider.still() || !raider.acting(self.tick) {
                continue;
            }
            let here = self.grid.tile_at(raider.at.x, raider.at.y);
            let step = step_for(&self.grid, &self.sheet, raider, here, raider.carried > 0);
            let (at, along) = walk_route(&self.grid, raider.at, &raider.route, raider.along, step);
            raider.at = at;
            raider.along = along;
            // Dropped a level or more this tick: §12.17's landing noise.
            let there = self.grid.tile_at(at.x, at.y);
            raider.landed = match (here, there) {
                (Some(a), Some(b)) => self.grid.height(a).saturating_sub(self.grid.height(b)),
                _ => 0,
            };
        }
        // A guard that is not walking turns steadily at its role's rate, one
        // way, so a player watching it can say where it will face next. The
        // first version chose the direction at random each tick, which
        // §12.17 forbids for the same reason as the jitter above.
        let sweep = 1;
        let now = self.tick;
        let guard_speed = self.sheet.factor(Param::GuardSpeed);
        for guard in self.guards.iter_mut() {
            if !guard.awake(now) {
                continue;
            }
            let walk = scale(guard.speed, guard_speed);         // §11.1's, by role
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
            let breaking = landing && match raider.task {
                heist::Task::Crack => self.vault.opened_at.is_none() && beside(self.vault.tile),
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
            if !breaking && landing.is_none() && (raider.still() || !raider.active()) {
                continue;                             // standing still is silent
            }
            let Some(source) = self.grid.tile_at(raider.at.x, raider.at.y) else { continue };
            // What it is walking on decides how far its gait carries. A
            // landing or a break is louder than any gait and is the sound made.
            let sound = if breaking {
                noise::Sound::Breaking
            } else {
                landing.unwrap_or(raider.gait.sound())
            };
            let reach = sound.steps_scaled(self.grid.surface(source),
                                           self.sheet.factor(Param::NoiseRadius));
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
                self.enter(gi, Investigating);
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

            // Hearing: "600, or on hearing something". Never a step down.
            if let Some(spot) = g.heard {
                if current.rank() < Investigating.rank() {
                    next = Investigating;
                    self.guards[gi].interest = Some(spot);
                }
            }
            // Rising on suspicion is immediate.
            if by_suspicion.rank() > next.rank() {
                next = by_suspicion;
            }
            // Falling waits half a second, then follows the table.
            if next == current && held >= guard::HOLD_TICKS {
                let g = &self.guards[gi];
                next = match current {
                    Suspicious if by_suspicion == Unaware => Unaware,
                    Investigating => match g.arrived_at {
                        Some(t) if now - t >= guard::SEARCH_SPOT_TICKS
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
                self.enter(gi, next);
            }
        }

        // The realm alarm: one level every thirty seconds, one per knocked-out
        // guard discovered, never above six.
        self.alarm = ((now / guard::ALARM_STEP_TICKS) as i32 + self.knockouts_discovered)
            .min(guard::ALARM_MAX);
        // "At 5 another Warden arrives at an entrance."
        if self.alarm >= guard::REINFORCE_AT && !self.reinforced {
            self.reinforced = true;
            let id = self.guards.len() as u32;
            let mut warden = make_guard(id, WARDEN, self.entrance, &self.grid);
            warden.state_since = now;
            self.guards.push(warden);
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
                        let (n, d) = self.sheet.factor(Param::Damage);
                        let power = g.power as i64 * n / d;
                        self.raiders[ri].health -= power as i32;
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
            if self.raiders[ri].swing < heist::HIT_TICKS {
                continue;
            }
            self.raiders[ri].swing = 0;
            let (dn, dd) = self.sheet.factor(Param::Damage);
            let power = (self.raiders[ri].role.power() as i64 * dn / dd) as i32;
            let g = &mut self.guards[gi];
            let unaware = now < g.stunned_until || g.state == guard::State::Unaware;
            if unaware {
                let (pn, pd) = heist::AMBUSH_POWER;
                let (hn, hd) = heist::AMBUSH_HEALTH_FLOOR;
                let full = g.role.health();
                g.health -= (power * pn / pd).max(full * hn / hd);
                g.stunned_until = now + heist::AMBUSH_STUN_TICKS;
                // "A stun ... during it cancels the attack."
                g.swing = 0;
            } else {
                g.health -= power;
                g.suspicion = SUSPICION_MAX;
            }
            if g.health <= 0 {
                g.health = 0;
                g.knocked_out = true;
                g.swing = 0;
                g.route.clear();
                g.along = 0;
            }
        }
        // A guard coming out of a stun has been hit: it wakes at 1000.
        for g in self.guards.iter_mut() {
            if !g.knocked_out && g.stunned_until != 0 && now + 1 == g.stunned_until {
                g.suspicion = SUSPICION_MAX;
            }
        }

        self.wards_act();

        // "A crew member at zero health drops its loot on the tile."
        for raider in self.raiders.iter_mut() {
            if raider.active() && raider.health <= 0 {
                raider.health = 0;
                raider.standing = Standing::Down;
                raider.down_since = now;
                raider.revive = 0;
                raider.route.clear();
                raider.along = 0;
                if raider.carried > 0 {
                    if let Some(t) = self.grid.tile_at(raider.at.x, raider.at.y) {
                        self.dropped.push((t, raider.carried));
                    }
                    raider.carried = 0;
                }
            }
        }

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
                        r.health = (r.role.health() * n / d).max(1);
                        r.standing = Standing::Active;
                        r.revive = 0;
                        continue;
                    }
                }
                None => r.revive = 0,
            }
            if now - r.down_since >= heist::DOWN_TICKS {
                r.standing = Standing::Caught;
            }
        }

        // The Vault. A crew member told to crack, standing beside it, swings
        // every 0.8 seconds for its Power, a Breaker for double.
        if self.vault.opened_at.is_none() {
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
                    let (sn, sd) = self.sheet.factor(Param::StructureDamage);
                    self.vault.health -=
                        (raider.role.power() as i64 * n as i64 * sn / (d as i64 * sd)) as i32;
                    self.vault.first_hit.get_or_insert(now);
                }
            }
            // "Cracking is loud: every 5 seconds adds 100 suspicion to every
            // guard in the Heart."
            if let Some(t) = self.vault.first_hit {
                if now > t && (now - t) % heist::CRACK_NOISE_TICKS == 0 {
                    for g in self.guards.iter_mut().filter(|g| g.awake(now)) {
                        g.suspicion = (g.suspicion + heist::CRACK_NOISE).min(SUSPICION_MAX);
                    }
                }
            }
            if self.vault.health <= 0 {
                self.vault.health = 0;
                self.vault.opened_at = Some(now);
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
                let take = per_tick.min(target - raider.carried).min(self.vault.exposed);
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
        for ri in 0..self.raiders.len() {
            let r = &self.raiders[ri];
            if r.task != Task::Break {
                continue;
            }
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
            let (sn, sd) = self.sheet.factor(Param::StructureDamage);
            let hit = (role.power() as i64 * n as i64 * sn / (d as i64 * sd)) as i32;
            if let Some(li) = li {
                let law = &mut self.laws[li];
                law.health -= hit;
                if law.health <= 0 {
                    law.health = 0;
                    law.broken_at = Some(now);
                }
            } else if let Some(wi) = wi {
                // §11.1: "Double damage to wards". A broken Crystal Wall is
                // open ground again.
                let w = &mut self.wards[wi];
                w.health -= hit;
                if w.health <= 0 {
                    w.health = 0;
                    w.broken = true;
                    if w.kind == WardKind::CrystalWall {
                        let t = w.tile;
                        self.grid.clear(t);
                    }
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

    /// §10.3's wards, as spec/wards.md reads them: disarming, then the
    /// triggered wards (the first crew member in the area, in id order), the
    /// Static Coil's pulse and the Thorn Hedge's thorns. Damage is a share of
    /// the target's full health, rounded down.
    fn wards_act(&mut self) {
        let now = self.tick;
        // Disarming: from beside the ward, standing still, silent. Moving
        // does not advance it; progress lapses after five seconds untouched.
        for ri in 0..self.raiders.len() {
            let r = &self.raiders[ri];
            if r.task != Task::Disarm || !r.acting(now) || !r.still() {
                continue;
            }
            let here = self.grid.tile_at(r.at.x, r.at.y);
            let Some(wi) = self.wards.iter().position(|w| {
                w.tile == r.target && w.live() && !w.kind.passive()
                    && here.is_some_and(|t| self.grid.neighbours(w.tile).contains(&Some(t)))
            }) else { continue };
            let w = &mut self.wards[wi];
            if now.saturating_sub(w.disarm_touched) > heist::DISARM_KEEP_TICKS {
                w.disarm = 0;
            }
            w.disarm += 1;
            w.disarm_touched = now;
            if w.disarm >= w.disarm_ticks() {
                w.disarmed = true;
            }
        }

        let tile_of = |p: Point, g: &Grid| g.tile_at(p.x, p.y);
        for wi in 0..self.wards.len() {
            let w = self.wards[wi].clone();
            if !w.live() {
                continue;
            }
            let (wx, wy) = self.grid.centre(w.tile);
            let centre = Point { x: wx, y: wy };
            let within = |p: Point, r: i32| p.distance(centre) <= Fx::from_int(r);
            match w.kind {
                WardKind::StaticCoil if now > 0 && now % heist::COIL_PERIOD_TICKS == 0 => {
                    let (n, d) = heist::COIL_DAMAGE;
                    for r in self.raiders.iter_mut() {
                        if r.active() && within(r.at, heist::COIL_RADIUS) {
                            r.health -= r.role.health() * n / d;
                        }
                    }
                }
                WardKind::ThornHedge if now % TICKS_PER_SECOND == 0 => {
                    let (n, d) = heist::HEDGE_DAMAGE;
                    for r in self.raiders.iter_mut() {
                        if r.active() && tile_of(r.at, &self.grid) == Some(w.tile) {
                            r.health -= r.role.health() * n / d;
                        }
                    }
                }
                WardKind::TimeSnare | WardKind::GravityWell | WardKind::LanternGlare
                    if now >= w.armed_at =>
                {
                    let trips = |r: &Raider| r.active() && match w.kind {
                        WardKind::GravityWell => within(r.at, heist::WELL_RADIUS),
                        _ => tile_of(r.at, &self.grid) == Some(w.tile),
                    };
                    let Some(first) = self.raiders.iter().position(trips) else { continue };
                    self.wards[wi].armed_at = now + w.kind.reset_ticks();
                    match w.kind {
                        WardKind::TimeSnare => {
                            self.raiders[first].frozen_until = now + heist::SNARE_FREEZE_TICKS;
                        }
                        WardKind::GravityWell => {
                            // Everyone within the radius to the centre, held.
                            // Where they were going stands: the route is
                            // recomputed from the well to the same tile,
                            // because the order was the tile, not the path.
                            for ri in 0..self.raiders.len() {
                                let r = &self.raiders[ri];
                                if !(r.active() && within(r.at, heist::WELL_RADIUS)) {
                                    continue;
                                }
                                let goal = r.route.last().copied();
                                let route = goal.and_then(|g| path::find(&self.grid, w.tile, g))
                                    .unwrap_or_default();
                                let r = &mut self.raiders[ri];
                                r.at = centre;
                                r.route = route;
                                r.along = 0;
                                r.frozen_until = now + heist::WELL_HOLD_TICKS;
                            }
                        }
                        _ => {
                            // Lantern Glare: every guard is shown the crew,
                            // and the crew is blinded.
                            self.revealed_until = now + heist::GLARE_REVEAL_TICKS;
                            self.reveal_spot = Some(w.tile);
                            for r in self.raiders.iter_mut().filter(|r| r.active()) {
                                r.frozen_until = r.frozen_until.max(now + heist::GLARE_BLIND_TICKS);
                            }
                        }
                    }
                }
                _ => {}
            }
        }
    }

    fn heal(&mut self) {
        let now = self.tick;
        if self.sheet.flag(Param::AllyRegen).is_some() {
            let (n, d) = self.sheet.factor(Param::AllyRegen);
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
                    let full = r.role.health();
                    r.health = (r.health + (full as i64 * n / d) as i32).min(full);
                }
            }
            for (g, heal) in self.guards.iter_mut().zip(posts) {
                if heal {
                    let full = g.role.health();
                    g.health = (g.health + (full as i64 * n / d) as i32).min(full);
                }
            }
        }
        if self.sheet.flag(Param::StructureRegen).is_some() {
            let (n, d) = self.sheet.factor(Param::StructureRegen);
            let share = |full: i32| (full as i64 * n / d) as i32;
            for g in self.guards.iter_mut().filter(|g| !g.knocked_out) {
                let full = g.role.health();
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
        let Some(from) = self.grid.tile_at(r.at.x, r.at.y) else { return false };
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
            match path::find(&self.grid, from, exit) {
                Some(route) => route,
                None => return false,
            }
        };
        let mut walk: u64 = 0;
        let mut on = from;
        for next in route {
            let step = step_for(&self.grid, &self.sheet, r, Some(on), true);
            if step.0 <= 0 {
                return false;
            }
            // Ticks to cross one tile, rounded up: a part-tick is a tick.
            let t = Fx::ONE.div(step).0;
            walk += ((t + fixed::FX_ONE - 1) / fixed::FX_ONE) as u64;
            on = next;
        }
        let wait = match self.skiff {
            Some(s) => s.arrives.saturating_sub(self.tick) as u64,
            None => heist::SKIFF_HEART_TICKS as u64,
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
        let banked: i32 = self.raiders.iter()
            .filter(|r| r.standing == Standing::Out).map(|r| r.carried).sum();
        let capacity: i32 = self.raiders.iter().map(|r| r.role.carry()).sum();
        let caught = self.raiders.iter().filter(|r| r.standing == Standing::Caught).count() as u32;
        let out = self.raiders.iter().filter(|r| r.standing == Standing::Out).count() as u32;
        let grade = if banked == 0 {
            Grade::Foiled
        } else if out as usize != self.raiders.len() {
            Grade::Partial
        } else if self.alarm_raised {
            Grade::Loud
        } else {
            Grade::Clean
        };
        let pages = self.laws.iter().filter(|l| l.broken_at.is_some()).count() as u32;
        Outcome { grade, banked, capacity, caught, out, pages }
    }

    /// Enter a state, and do what entering it means.
    pub(crate) fn enter(&mut self, gi: usize, state: guard::State) {
        use guard::State::*;
        let now = self.tick;
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
            // Whispers sets the range to the whole universe (999).
            let (an, ad) = self.sheet.factor(Param::AlarmRange);
            let reach = Fx::from_int((guard::SPREAD_METRES as i64 * an / ad).min(1 << 20) as i32);
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
        mix(self.revealed_until as i64);
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
fn step_for(grid: &Grid, sheet: &Sheet, raider: &Raider, here: Option<grid::TileIndex>,
            loaded: bool) -> Fx {
    let pace = here.map_or(Fx::ONE, |t| grid.at(t).pace());
    let (num, den) = raider.gait.pace();
    let mut step = scale(raider.speed.mul(pace).mul(Fx::from_ratio(num, den)),
                         sheet.factor(Param::CrewSpeed));
    if loaded {
        step = scale(step, sheet.factor(Param::LoadedSpeed));
        if raider.role == Role::Carrier {
            let (n, d) = heist::CARRIER_LOADED_PACE;
            step = step.mul(Fx::from_ratio(n, d));
        }
    }
    step
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
    let side = Grid::for_realm_level(FIXTURE_REALM_LEVEL).width as u64;
    let mut commands = Vec::with_capacity(decisions as usize * 2);
    // A tile, as a command aims at it: its centre, at 1/256 of a tile.
    let aim = |x: u64, y: u64| ((x * 256 + 128) as i16, (y * 256 + 128) as i16);
    // The four tiles beside the Vault, north, east, south, west.
    let (vx, vy) = (VAULT_AT.0 as u64, VAULT_AT.1 as u64);
    let beside = [(vx, vy - 1), (vx + 1, vy), (vx, vy + 1), (vx - 1, vy)];
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
            9 => {
                // A pylon: to the tile north of it, and break it.
                let (_, (px, py)) = FIXTURE_LAWS[rng.below(FIXTURE_LAWS.len() as u64) as usize];
                push(Kind::MoveTo, aim(px as u64, py as u64 - 1));
                push(Kind::Break, aim(px as u64, py as u64));
            }
            10 => {
                // A ward: to the tile north of it, and disarm it.
                let (_, (wx, wy)) = FIXTURE_WARDS[rng.below(FIXTURE_WARDS.len() as u64) as usize];
                push(Kind::MoveTo, aim(wx as u64, wy as u64 - 1));
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
    commands.sort_by_key(|c| (c.tick, c.actor, c.kind as u8));

    let mut heist = Heist {
        seed,
        // The island stands in for §24.8's content hash. The rules are the
        // real thing: a digest of the laws the heist was made under (§24.11).
        island: digest_bytes(seed, 0x15_1A_4D),
        rules: rules_digest(&FIXTURE_LAWS),
        ticks, crew, commands,
        checksums: Vec::new(),
    };
    heist.checksums = run(&heist).iter().map(|s| truncate(*s)).collect();
    heist
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
        let target = if matches!(kind, Kind::MoveTo | Kind::Skiff | Kind::Break) {
            at(x, y)
        } else {
            (x, y)
        };
        say(t(s), actor, kind, target);
    });
    commands.sort_by_key(|c| (c.tick, c.actor, c.kind as u8));
    let mut heist = Heist {
        seed: 0x5EED_0F_A_7EA1,
        island: digest_bytes(0, 0x15_1A_4D),
        rules: rules_digest(&FIXTURE_LAWS),
        ticks: t(165),                    // §5.4: 150 s + 15 for one link
        crew: 3,
        commands,
        checksums: Vec::new(),
    };
    heist.checksums = run(&heist).iter().map(|s| truncate(*s)).collect();
    heist
}

/// The plan: (second, crew member, command, x, y). Crew 0 is a Scout, 1 a
/// Breaker, 2 a Carrier. Guards are numbered by §12.17's rows: 2 is the
/// Breaker at (9, 4) and 4 the Mender at (12, 2), both posted facing north.
/// The realm runs `FIXTURE_LAWS`: Haste, Brittle stone and Glowing dark.
///
///   0 s   everyone crouches. The Breaker breaks Haste's pylon beside the
///         landing, out of every guard's hearing — Haste runs the heist clock
///         a quarter fast, and that is worth a detour (§12.6). The Scout goes
///         round to the moss behind the Breaker guard; the Carrier waits by
///         the gap
///   7 s   the Breaker follows the Scout
///  18 s   both attack at once: the Scout's ambush stuns it, the Breaker's
///         lands while it is still stunned, and two ambush hits knock it out
///  20 s   the same two go round to the moss behind the Mender guard
///  26 s   and ambush it the same way
///  29 s   all three walk to the Vault and crack — Brittle stone doubles
///         every hit — and the skiff is called to the east edge beside it
///  40 s   the Vault is open: everyone loads to full
///  52 s   everyone walks to the skiff
const PLAN: &[(u32, u8, Kind, i16, i16)] = &[
    (0, 0, Kind::Gait, 1, 0),
    (0, 1, Kind::Gait, 1, 0),
    (0, 2, Kind::Gait, 1, 0),
    (0, 0, Kind::MoveTo, 9, 5),
    (0, 1, Kind::MoveTo, 1, 2),
    (0, 2, Kind::MoveTo, 7, 6),
    (0, 1, Kind::Break, 1, 3),
    (7, 1, Kind::MoveTo, 9, 5),
    (18, 0, Kind::Attack, 2, 0),
    (18, 1, Kind::Attack, 2, 0),
    (20, 0, Kind::MoveTo, 12, 3),
    (20, 1, Kind::MoveTo, 12, 3),
    (26, 0, Kind::Attack, 4, 0),
    (26, 1, Kind::Attack, 4, 0),
    (29, 0, Kind::Gait, 0, 0),
    (29, 1, Kind::Gait, 0, 0),
    (29, 2, Kind::Gait, 0, 0),
    (29, 0, Kind::MoveTo, 11, 4),
    (29, 1, Kind::MoveTo, 12, 5),
    (29, 2, Kind::MoveTo, 10, 5),
    (29, 0, Kind::Crack, 0, 0),
    (29, 1, Kind::Crack, 0, 0),
    (29, 2, Kind::Crack, 0, 0),
    (29, 0, Kind::Skiff, 13, 5),
    (40, 0, Kind::Load, 100, 0),
    (40, 1, Kind::Load, 100, 0),
    (40, 2, Kind::Load, 100, 0),
    (52, 0, Kind::MoveTo, 13, 5),
    (52, 1, Kind::MoveTo, 13, 5),
    (52, 2, Kind::MoveTo, 13, 5),
];

/// §24.11: "Every island and every replay records the exact set of laws it
/// was made under." FNV-1a over each law's id and pylon, in weaving order,
/// spread to 32 bytes: a replay made under different laws carries a
/// different header.
pub fn rules_digest(laws: &[(&str, (u16, u16))]) -> [u8; 32] {
    let mut h: u64 = 0xcbf2_9ce4_8422_2325;
    for (id, (x, y)) in laws {
        for byte in id.bytes().chain(x.to_le_bytes()).chain(y.to_le_bytes()) {
            h ^= byte as u64;
            h = h.wrapping_mul(0x0000_0100_0000_01b3);
        }
    }
    digest_bytes(h, 0x2D_1E_5F)
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
