//! §13.3's reference crew, inside the simulation (D66, TD.16).
//!
//! §13.3: "A hold is a rate over many raids, so it is measured on the
//! server — 800 raids of the competent reference crew, queued and cached by
//! the island's digest". The competent crew is the harness's
//! (tools/heist_harness/policy.py `Competent`), played here on the
//! simulation itself through the same commands a player gives, so a heist it
//! plays is a replay like any other:
//!
//! - It lands at a spot within six tiles of the shortest walk to the Vault, a
//!   spot the skiff is heard at counted six tiles longer (§5.4), the one its
//!   seed draws — so 800 raids differ by where they come in — and the whole
//!   crew crouches (§12.17).
//! - It plans one route a leg, round every tile a guard's cone reaches and
//!   every live ward's sensor as it reads them when it plans (the scout report,
//!   §12.3), through them only when there is no way round, and walks it a
//!   checkpoint at a time: every third tile. At a checkpoint whose next tile
//!   a cone now reaches, it plans again.
//! - Beside the Vault it cracks, then loads to §12.19's break-even, 70% of
//!   the bag, and leaves: when the crew is loaded, when the Vault is empty,
//!   when a guard is Alerted and anyone carries anything, or when the clock
//!   left is no more than the way in took and 15%, and the skiff's time to
//!   come (`watches_clock`).
//! - It calls the skiff to the open edge tile nearest the first of it to
//!   leave, and every member walks there.
//!
//! The crew is §11.1's by role (no manifest), as the harness's is. Nothing
//! but the landing draws a number: one island, seed and clock give one heist.

use crate::grid::TileIndex;
use crate::guard::State;
use crate::fixed::Fx;
use crate::heist::{self, Grade, Outcome, WardKind};
use crate::island::Island;
use crate::rng::{Rng, Stream};
use crate::replay::{Heist, Kind};
use crate::{era, record_with, rules_version, Point, World};

/// §12.19's break-even, in per cent of the bag.
pub const BREAKEVEN_FILL: i32 = 70;
/// A checkpoint every this many tiles of route (the harness's).
const CHECKPOINT_EVERY: usize = 3;
/// It leaves with this much of the way in still on the clock: 115%.
const CLOCK_MARGIN: (u32, u32) = (115, 100);
/// The crew acts once this many ticks: a player's taps, not a reflex.
const ACT_EVERY: u32 = 10;
/// A landing a guard can hear (§5.4) is worth this many tiles of walk.
const HEARD_LANDING: usize = 6;
/// The landings a competent crew weighs: within this many tiles of the best.
const LANDING_SLACK: usize = 6;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Leg {
    In,
    Vault,
    Out,
}

struct Member {
    route: Vec<TileIndex>,
    next: usize,
    leg: Leg,
    cracking: bool,
    loading: bool,
}

/// A tile's centre, as a command aims at it.
fn aim(world: &World, t: TileIndex) -> (i16, i16) {
    let (x, y) = world.grid.coords(t);
    ((x as i32 * 256 + 128) as i16, (y as i32 * 256 + 128) as i16)
}

/// The shortest walk from `from` to `to` that keeps off `avoid`, but for
/// `to` itself; `None` if there is none. Breadth first in §12.18's fixed
/// neighbour order, as `path::find` is.
fn route_avoiding(world: &World, from: TileIndex, to: TileIndex, avoid: &[bool]) -> Option<Vec<TileIndex>> {
    let grid = &world.grid;
    if from == to {
        return Some(Vec::new());
    }
    let mut came: Vec<Option<TileIndex>> = vec![None; grid.len()];
    let mut seen = vec![false; grid.len()];
    let mut frontier = std::collections::VecDeque::new();
    seen[from as usize] = true;
    frontier.push_back(from);
    while let Some(t) = frontier.pop_front() {
        for n in grid.neighbours(t).into_iter().flatten() {
            if seen[n as usize] || !grid.can_step(t, n) || (n != to && avoid[n as usize]) {
                continue;
            }
            seen[n as usize] = true;
            came[n as usize] = Some(t);
            if n == to {
                let mut out = vec![to];
                let mut at = to;
                while let Some(p) = came[at as usize] {
                    if p == from {
                        break;
                    }
                    out.push(p);
                    at = p;
                }
                out.reverse();
                return Some(out);
            }
            frontier.push_back(n);
        }
    }
    None
}

/// What the crew keeps off when it plans: each awake guard's cone and each
/// live ward's tile, as they stand now.
fn threats(world: &World) -> (Vec<bool>, Vec<bool>) {
    let mut cones = vec![false; world.grid.len()];
    for gi in 0..world.guards.len() {
        if world.guards[gi].knocked_out {
            continue;
        }
        for t in world.seen_tiles(gi) {
            cones[t as usize] = true;
        }
    }
    // Each live ward's sensor: a Lantern Glare's, a Gravity Well's and a
    // Static Coil's reach, measured between tile centres as the ward
    // measures, and the tile of the rest (§10.3).
    let mut wards = vec![false; world.grid.len()];
    for w in world.wards.iter().filter(|w| w.live()) {
        let reach = match w.kind {
            WardKind::LanternGlare => heist::GLARE_RADIUS,
            WardKind::GravityWell => heist::WELL_RADIUS,
            WardKind::StaticCoil => heist::COIL_RADIUS,
            _ => 0,
        };
        let (wx, wy) = world.grid.centre(w.tile);
        let centre = Point { x: wx, y: wy };
        for t in 0..world.grid.len() as TileIndex {
            let (x, y) = world.grid.centre(t);
            if t == w.tile || (reach > 0 && Point { x, y }.distance(centre) <= Fx::from_int(reach)) {
                wards[t as usize] = true;
            }
        }
    }
    (cones, wards)
}

/// The route for one leg: round cones and wards, else round wards, else
/// any.
fn plan(world: &World, from: TileIndex, to: TileIndex) -> Vec<TileIndex> {
    let (cones, wards) = threats(world);
    let both: Vec<bool> = cones.iter().zip(&wards).map(|(a, b)| *a || *b).collect();
    let none = vec![false; world.grid.len()];
    route_avoiding(world, from, to, &both)
        .or_else(|| route_avoiding(world, from, to, &wards))
        .or_else(|| route_avoiding(world, from, to, &none))
        .unwrap_or_default()
}

/// The open tiles beside the Vault, in §12.18's neighbour order.
fn beside_vault(world: &World) -> Vec<TileIndex> {
    world.grid.neighbours(world.vault.tile).into_iter().flatten()
        .filter(|&t| world.grid.standable(t)).collect()
}

fn tile_of(world: &World, i: usize) -> Option<TileIndex> {
    let r = &world.raiders[i];
    world.grid.tile_at(r.at.x, r.at.y)
}

/// One heist of the competent reference crew on `island`: its replay.
pub fn competent(island: &Island, seed: u64, ticks: u32, crew: u8, era: Option<era::Era>) -> Heist {
    let world = play(island, seed, ticks, crew, era);
    record_with(island, seed, ticks, crew, era, None, world.commands().to_vec())
}

/// The heist played to its end, the world as the clock left it: what
/// `competent` records and `hold` reads the outcome of.
pub fn play(island: &Island, seed: u64, ticks: u32, crew: u8, era: Option<era::Era>) -> World {
    let blank = Heist { seed, island: island.digest(), rules: rules_version(), ticks, crew, era, manifest: None,
                        commands: Vec::new(), checksums: Vec::new() };
    let mut world = World::from_island(island, &blank);
    let n = crew as usize;
    let mut members: Vec<Member> = (0..n)
        .map(|_| Member { route: Vec::new(), next: 0, leg: Leg::In, cracking: false, loading: false })
        .collect();
    // Where to land: one of the spots within `LANDING_SLACK` tiles of the
    // shortest walk to beside the Vault, a heard spot counted six tiles
    // longer, drawn from the seed — the one thing a raid's seed decides, so
    // §13.3's raids differ by where they come in.
    let goals = beside_vault(&world);
    let mut spots: Vec<(usize, TileIndex)> = Vec::new();
    for (x, y) in island.landings() {
        let Some(t) = world.grid.index(x as u16, y as u16) else { continue };
        let walk = goals.iter().filter_map(|&g| crate::path::find(&world.grid, t, g)).map(|r| r.len()).min();
        let Some(walk) = walk else { continue };
        spots.push((walk + if island.landing_covered(x, y) { 0 } else { HEARD_LANDING }, t));
    }
    let Some(shortest) = spots.iter().map(|s| s.0).min() else { return world };
    spots.retain(|s| s.0 <= shortest + LANDING_SLACK);
    let mut rng = Rng::new(seed, Stream::Loot);
    let landing = spots[rng.below(spots.len() as u64) as usize].1;
    let (lx, ly) = aim(&world, landing);
    world.give(0, Kind::Land, lx, ly);
    for i in 0..n {
        world.give(i as u8, Kind::Gait, 1, 0);
    }
    let mut cracked_at: Option<u32> = None;
    let mut leaving = false;
    let mut skiff: Option<TileIndex> = None;
    for _ in 0..ticks {
        if world.tick > 0 && world.tick % ACT_EVERY == 0 {
            act(&mut world, &mut members, &goals, &mut cracked_at, &mut leaving, &mut skiff);
        }
        world.step();
    }
    world
}

fn act(world: &mut World, members: &mut [Member], goals: &[TileIndex], cracked_at: &mut Option<u32>,
       leaving: &mut bool, skiff: &mut Option<TileIndex>) {
    let now = world.tick;
    let carrying = world.raiders.iter().take(members.len()).any(|r| r.carried > 0);
    // Flee at the first Alerted guard, once there is anything to take home.
    if !*leaving && carrying && world.guards.iter().any(|g| g.state == State::Alerted) {
        *leaving = true;
    }
    // Out of time: the way out is the way in and 15% more, and the skiff's
    // own time to come (§5.4).
    if !*leaving {
        if let Some(at) = *cracked_at {
            let left = world.clock.saturating_sub(now);
            if left <= at * CLOCK_MARGIN.0 / CLOCK_MARGIN.1 + crate::heist::SKIFF_HEART_TICKS {
                *leaving = true;
            }
        }
    }
    // Loaded as the simulation loads: to the target's whole units.
    let loaded = |w: &World, i: usize| {
        let r = &w.raiders[i];
        r.carried >= r.role.carry() * BREAKEVEN_FILL / 100
    };
    if !*leaving && world.vault.opened_at.is_some() {
        let crew_in = (0..members.len()).filter(|&i| world.raiders[i].active()).collect::<Vec<_>>();
        if world.vault.exposed <= 0 || (!crew_in.is_empty() && crew_in.iter().all(|&i| loaded(world, i))) {
            *leaving = true;
        }
    }
    for i in 0..members.len() {
        if !world.raiders[i].acting(now) {
            continue;
        }
        let Some(here) = tile_of(world, i) else { continue };
        if *leaving && members[i].leg != Leg::Out {
            members[i].leg = Leg::Out;
            members[i].route.clear();
            members[i].next = 0;
            if skiff.is_none() {
                let mut best: Option<(usize, TileIndex)> = None;
                for t in 0..world.grid.len() as TileIndex {
                    if !world.grid.is_edge(t) || !world.grid.at(t).passable() {
                        continue;
                    }
                    if let Some(r) = crate::path::find(&world.grid, here, t) {
                        if best.is_none_or(|(b, _)| r.len() < b) {
                            best = Some((r.len(), t));
                        }
                    }
                }
                if let Some((_, t)) = best {
                    let (x, y) = aim(world, t);
                    world.give(i as u8, Kind::Skiff, x, y);
                    *skiff = Some(t);
                }
            }
        }
        let m = &mut members[i];
        match m.leg {
            Leg::In if goals.contains(&here) => {
                m.leg = Leg::Vault;
                m.route.clear();
            }
            Leg::Vault => {
                if world.vault.opened_at.is_none() {
                    if !m.cracking {
                        world.give(i as u8, Kind::Crack, 0, 0);
                        m.cracking = true;
                        cracked_at.get_or_insert(now);
                    }
                } else if !m.loading {
                    world.give(i as u8, Kind::Load, BREAKEVEN_FILL as i16, 0);
                    m.loading = true;
                }
                continue;
            }
            _ => {}
        }
        let goal = match m.leg {
            Leg::In => goals.iter().copied()
                .min_by_key(|&g| crate::path::find(&world.grid, here, g).map_or(usize::MAX, |r| r.len())),
            Leg::Out => *skiff,
            Leg::Vault => None,
        };
        let Some(goal) = goal else { continue };
        if here == goal {
            continue;
        }
        let still = world.raiders[i].still();
        let threatened = m.route.get(m.next).is_some_and(|&t| {
            (0..world.guards.len()).any(|gi| !world.guards[gi].knocked_out && world.seen_tiles(gi).contains(&t))
        });
        if m.route.is_empty() || (still && threatened) {
            m.route = plan(world, here, goal);
            m.next = 0;
            if m.route.is_empty() {
                continue;
            }
        } else if !still {
            continue;
        }
        // The next checkpoint along the route.
        let reach = (m.next + CHECKPOINT_EVERY).min(m.route.len()) - 1;
        let to = m.route[reach];
        m.next = reach + 1;
        let (x, y) = aim(world, to);
        world.give(i as u8, Kind::MoveTo, x, y);
    }
}

/// §13.3's hold of `island`: of `raids` heists of the competent crew of
/// `crew` on its clock of `ticks`, the seeds `seed` and those after it, how
/// many it held (Foiled), and their outcomes.
pub fn hold(island: &Island, seed: u64, raids: u32, ticks: u32, crew: u8) -> (u32, Vec<Outcome>) {
    let outcomes: Vec<Outcome> = (0..raids as u64)
        .map(|k| play(island, seed.wrapping_add(k), ticks, crew, None).outcome())
        .collect();
    (outcomes.iter().filter(|o| o.grade == Grade::Foiled).count() as u32, outcomes)
}
