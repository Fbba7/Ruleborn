//! The ext's own checks, on plain Rust types: Godot's types need the engine
//! at run time, so these drive `RulebornReplay` through its fields and the
//! methods that take and return integers.

use super::RulebornReplay;
use ruleborn_sim as sim;
use sim::island::Island;
use sim::replay::{Heist, Kind, MAX_HEIST_BYTES};
use sim::universe::{LinkKind, Universe};
use sim::World;

/// A heist to be played on `island`, as `start` makes one.
fn played(island: Island, seed: u64, ticks: u32, crew: u8) -> RulebornReplay {
    let heist = Heist { seed, island: island.digest(), rules: sim::rules_version(), ticks, crew, era: None,
                        manifest: None, commands: Vec::new(), checksums: Vec::new() };
    RulebornReplay { world: Some(World::from_island(&island, &heist)), heist: Some(heist), island: Some(island),
                     mismatch: 0, agreed: 0, era: None, universe: None, entry: (0, false), crossing: None }
}

/// A heist across two realms, the Heart and one outer realm a stone link
/// away, as `start_universe` makes one: nothing landed yet.
fn across(seed: u64, crew: u8) -> (RulebornReplay, Universe, Vec<Island>) {
    let (heart, outer) = (Island::example(), Island::generated(2, 1));
    let u = Universe { realms: vec![(0, heart.digest()), (1, outer.digest())], links: vec![(LinkKind::Stone, 1, 0)],
                       flicker: 0, faults: Vec::new() };
    let islands = vec![heart, outer];
    let mut r = played(islands[0].clone(), seed, sim::universe::clock_ticks(0), crew);
    r.heist.as_mut().unwrap().island = u.digest();
    r.universe = Some((u.clone(), islands.clone()));
    (r, u, islands)
}

/// A tile's centre, at 1/256 of a tile, as a command aims at it.
fn aim(x: u8, y: u8) -> (i64, i64) {
    (x as i64 * 256 + 128, y as i64 * 256 + 128)
}

/// Steps `r` to `tick`.
fn step_to(r: &mut RulebornReplay, tick: u32) {
    while r.w().unwrap().tick < tick && r.step() {}
}

#[test]
fn sim_2_the_single_island_recorder_never_returns_a_replay_over_2_kb() {
    // Audit finding SIM-2 (docs/security/audit-2026-11/sim.md), on the
    // device: sim.md's honest long heist, given as a player's taps.
    let island = Island::example_open();
    let side = island.side() as u32;
    let (lx, ly) = island.landings()[0];
    let mut r = played(island.clone(), 7, sim::MAX_TICKS, 3);
    let (x, y) = aim(lx, ly);
    assert!(r.give(0, Kind::Land as i64, x, y), "the landing");
    let mut refused = 0;
    for i in 0..180u32 {
        step_to(&mut r, 30 + i * 37);
        let (x, y) = aim(((i * 3) % side) as u8, ((i * 7) % side) as u8);
        if !r.give((i % 3) as i64, Kind::MoveTo as i64, x, y) {
            refused += 1;
        }
    }
    let bytes = r.recorded();
    assert!(!bytes.is_empty() && bytes.len() <= MAX_HEIST_BYTES,
            "the device recorded a {}-byte replay (limit {MAX_HEIST_BYTES})", bytes.len());
    assert!(refused > 0, "the device took every command, past the replay's limit");
    let heist = Heist::decode(&bytes).expect("the replay reads");
    assert!(sim::verify_on(&island, &heist).is_ok(), "the server accepts it: {:?}",
            sim::verify_on(&island, &heist).err());
}

#[test]
fn sim_2_the_single_island_recorder_refuses_a_log_over_2_kb() {
    // A log past the limit however it got there (here straight into the
    // world, as no tap can): no replay rather than one the server refuses.
    let island = Island::example_open();
    let side = island.side() as i16;
    let (lx, ly) = island.landings()[0];
    let mut r = played(island, 7, sim::MAX_TICKS, 3);
    let world = r.world.as_mut().unwrap();
    assert!(world.give(0, Kind::Land, lx as i16 * 256 + 128, ly as i16 * 256 + 128));
    for i in 0..400i16 {
        assert!(world.give((i % 3) as u8, Kind::MoveTo, (i * 3) % side * 256 + 128, (i * 7) % side * 256 + 128));
    }
    let bytes = r.recorded();
    assert!(bytes.is_empty(), "the device recorded a {}-byte replay (limit {MAX_HEIST_BYTES})", bytes.len());
}

#[test]
fn sim_2_the_universe_recorder_never_returns_a_replay_over_2_kb() {
    // SIM-2 across a universe: a long heist through the outer realm on the
    // lease's clock for one link, a walk every 20 ticks.
    let (mut r, u, islands) = across(7, 3);
    let ticks = sim::universe::clock_ticks(1);
    assert!(r.preview(1, false, ticks as i64), "the outer realm on show");
    let outer = &islands[1];
    let side = outer.side() as u32;
    let (lx, ly) = outer.landings()[0];
    let (x, y) = aim(lx, ly);
    assert!(r.give(0, Kind::Land as i64, x, y), "the landing");
    assert!(r.crossing.is_some());
    let mut refused = 0;
    for i in 0..230u32 {
        step_to(&mut r, 10 + i * 20);
        let (x, y) = aim(((i * 3) % side) as u8, ((i * 7) % side) as u8);
        if !r.give((i % 3) as i64, Kind::MoveTo as i64, x, y) {
            refused += 1;
        }
    }
    let bytes = r.recorded();
    assert!(!bytes.is_empty() && bytes.len() <= MAX_HEIST_BYTES,
            "the device recorded a {}-byte replay (limit {MAX_HEIST_BYTES})", bytes.len());
    assert!(refused > 0, "the device took every command, past the replay's limit");
    let heist = Heist::decode(&bytes).expect("the replay reads");
    assert!(sim::universe::verify_universe(&u, &islands, &heist).is_ok(), "the server accepts it: {:?}",
            sim::universe::verify_universe(&u, &islands, &heist).err());
}

#[test]
fn cli_23_give_refuses_what_its_casts_would_wrap() {
    // Audit finding CLI-23 (docs/security/audit-2026-11/client.md): `give`
    // narrowed its integers with `as`, so an actor of 256 was actor 0, a
    // kind of 256 a walk, and a position past i16 a different tile.
    let island = Island::example_open();
    let (lx, ly) = island.landings()[0];
    let mut r = played(island, 7, sim::MAX_TICKS, 3);
    let (x, y) = aim(lx, ly);
    assert!(r.give(0, Kind::Land as i64, x, y), "the landing");
    let at = r.w().unwrap().commands().len();
    let wrapped = [
        ("actor 256", 256, Kind::MoveTo as i64, x, y),
        ("actor -1", -1, Kind::MoveTo as i64, x, y),
        ("actor 16, which the replay cannot carry", 16, Kind::MoveTo as i64, x, y),
        ("kind 256", 0, 256, x, y),
        ("kind -256", 0, -256, x, y),
        ("x past i16", 0, Kind::MoveTo as i64, 65_536 + x, y),
        ("y past i16", 0, Kind::MoveTo as i64, x, -65_536 + y),
    ];
    let taken: Vec<&str> = wrapped.iter().filter(|w| r.give(w.1, w.2, w.3, w.4)).map(|w| w.0).collect();
    assert!(taken.is_empty(), "give took {taken:?}");
    assert_eq!(r.w().unwrap().commands().len(), at, "and logged nothing");
    assert!(r.give(2, Kind::MoveTo as i64, x, y), "an honest walk is still taken");
}

#[test]
fn cli_23_the_landing_refuses_what_its_casts_would_wrap() {
    let (mut r, _, islands) = across(7, 3);
    assert!(r.preview(1, false, sim::universe::clock_ticks(1) as i64));
    let (x, y) = aim(islands[1].landings()[0].0, islands[1].landings()[0].1);
    assert!(!r.give(0, Kind::Land as i64 + 256, x, y), "kind 267 is no landing");
    assert!(!r.give(0, Kind::Land as i64, 65_536 + x, y), "x past i16 is no tile");
    assert!(r.crossing.is_none(), "nothing landed");
    assert!(r.give(0, Kind::Land as i64, x, y), "the honest landing");
}

#[test]
fn cli_23_preview_refuses_a_clock_past_u32() {
    // `preview` narrowed the lease's clock with `as u32`: 2^32 + 4950 ticks
    // was a clock of 4950.
    let (mut r, _, _) = across(7, 3);
    let ticks = sim::universe::clock_ticks(1) as i64;
    assert!(!r.preview(1, false, (1i64 << 32) + ticks), "a clock past u32");
    assert_eq!(r.heist.as_ref().unwrap().ticks, sim::universe::clock_ticks(0), "the clock is unchanged");
    assert!(r.preview(1, false, ticks), "the lease's clock");
}
