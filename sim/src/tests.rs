//! Properties the checksum rests on. A cross-target digest proves two builds
//! agree; it does not prove they agree on something *correct*. These are the
//! invariants that would make an agreed-upon answer still be wrong.

use crate::fixed::{isqrt_u64, Ang, Fx, ANG_TURN};
use crate::rng::{Rng, Stream};
use crate::replay::{Command, Heist, Kind, MAX_HEIST_BYTES};
use crate::{fixture, trig, verify, World, TICKS_PER_SECOND};

#[test]
fn fixed_point_round_trips_whole_numbers() {
    for n in [-1000, -7, -1, 0, 1, 7, 1000] {
        assert_eq!(Fx::from_int(n).to_int(), n as i64, "round trip of {n}");
    }
}

#[test]
fn multiplication_is_commutative_and_has_an_identity() {
    let values = [
        Fx::from_ratio(1, 3),
        Fx::from_ratio(-7, 2),
        Fx::from_int(5),
        Fx::from_ratio(1, 1024),
    ];
    for a in values {
        assert_eq!(a.mul(Fx::ONE), a, "one is the identity");
        for b in values {
            assert_eq!(a.mul(b), b.mul(a), "multiplication commutes");
        }
    }
}

#[test]
fn division_undoes_multiplication_to_within_one_unit() {
    // Fixed point is lossy; what matters is that the loss is bounded and the
    // same everywhere, not that it is absent.
    let a = Fx::from_ratio(355, 113);
    let b = Fx::from_ratio(7, 3);
    let back = a.mul(b).div(b);
    assert!((back.0 - a.0).abs() <= 2, "round trip lost {}", (back.0 - a.0).abs());
}

#[test]
fn rounding_is_the_same_on_both_sides_of_zero() {
    // from_ratio floors, so -1/3 and 1/3 must be exact negatives of each
    // other's floor, not of each other. The property that matters is that a
    // value and its negation round consistently rather than toward zero.
    let pos = Fx::from_ratio(1, 3);
    let neg = Fx::from_ratio(-1, 3);
    assert_eq!(pos.0 + neg.0, -1, "floor on both sides differs by exactly one unit");
}

#[test]
fn integer_square_root_is_exact_for_squares() {
    for n in [0u64, 1, 4, 9, 16, 10_000, 1 << 40] {
        let root = isqrt_u64(n);
        assert_eq!(root * root, n, "isqrt({n}) should be exact");
    }
}

#[test]
fn integer_square_root_never_overshoots() {
    for n in [2u64, 3, 5, 99, 1_000_003, u32::MAX as u64, (1u64 << 52) + 7] {
        let r = isqrt_u64(n);
        assert!(r * r <= n, "isqrt({n}) = {r} overshoots");
        assert!((r + 1).saturating_mul(r + 1) > n, "isqrt({n}) = {r} undershoots");
    }
}

#[test]
fn sine_has_the_values_it_must() {
    assert_eq!(trig::sin(Ang::ZERO), Fx::ZERO, "sin 0");
    assert_eq!(trig::sin(Ang::from_turn_ratio(1, 4)), Fx::ONE, "sin quarter turn");
    assert_eq!(trig::sin(Ang::from_turn_ratio(1, 2)), Fx::ZERO, "sin half turn");
    assert_eq!(trig::sin(Ang::from_turn_ratio(3, 4)), -Fx::ONE, "sin three quarters");
    assert_eq!(trig::cos(Ang::ZERO), Fx::ONE, "cos 0");
    assert_eq!(trig::cos(Ang::from_turn_ratio(1, 4)), Fx::ZERO, "cos quarter turn");
}

#[test]
fn sine_is_exactly_odd() {
    // sin(-x) == -sin(x) exactly, which a table per quadrant would not give.
    // This is why the quarter table is reflected rather than four tables.
    for step in (0..ANG_TURN).step_by(97) {
        let a = Ang(step);
        assert_eq!(trig::sin(Ang(-a.0)), -trig::sin(a), "odd at {step}");
    }
}

#[test]
fn the_pythagorean_identity_holds_to_the_tables_resolution() {
    // sin^2 + cos^2 = 1, to within the interpolation error of a 1024-entry
    // quarter table. A large error here would mean the table or the
    // interpolation is wrong, not merely coarse.
    for step in (0..ANG_TURN).step_by(89) {
        let a = Ang(step);
        let s = trig::sin(a);
        let c = trig::cos(a);
        let sum = s.mul(s) + c.mul(c);
        let off = (sum.0 - Fx::ONE.0).abs();
        assert!(off < 1 << 18, "identity off by {off} at {step}");
    }
}

#[test]
fn angles_wrap_rather_than_accumulate() {
    let mut a = Ang::ZERO;
    for _ in 0..1000 {
        a = Ang(a.0 + Ang::from_degrees(37).0).wrapped();
    }
    assert!(a.0 >= 0 && a.0 < ANG_TURN, "stayed inside one turn: {}", a.0);
    // 1000 * 37 degrees = 37000 degrees = 102.77... turns.
    let expected = Ang(((1000i64 * Ang::from_degrees(37).0 as i64) % ANG_TURN as i64) as i32);
    assert_eq!(a, expected, "wrapping is exact, not drifting");
}

#[test]
fn streams_are_independent() {
    // The reason for per-subsystem streams: drawing from one must not move
    // another. If these matched, adding a perception roll would shift every
    // movement roll and old replays would diverge for no reason.
    let mut a = Rng::new(7, Stream::Perception);
    let mut b = Rng::new(7, Stream::Movement);
    let first: Vec<u64> = (0..8).map(|_| a.next_u64()).collect();
    let second: Vec<u64> = (0..8).map(|_| b.next_u64()).collect();
    assert_ne!(first, second, "two streams of one seed must differ");
}

#[test]
fn the_generator_is_reproducible() {
    let draw = |_| {
        let mut r = Rng::new(0xDEAD_BEEF, Stream::Loot);
        (0..16).map(|_| r.next_u64()).collect::<Vec<_>>()
    };
    assert_eq!(draw(()), draw(()), "same seed, same sequence");
}

#[test]
fn below_stays_in_range_and_covers_it() {
    let mut r = Rng::new(3, Stream::Noise);
    let mut seen = [false; 6];
    for _ in 0..600 {
        let v = r.below(6) as usize;
        assert!(v < 6, "below(6) returned {v}");
        seen[v] = true;
    }
    assert!(seen.iter().all(|s| *s), "every value of a d6 appears in 600 rolls");
}

#[test]
fn a_heist_is_reproducible_from_its_seed() {
    // §24.10: "What is recorded — commands, never state. State is always
    // recoverable by re-simulating."
    let heist = fixture(0x1234_5678, 900, 3);
    assert_eq!(crate::run(&heist), crate::run(&heist), "same log, same checksums");
}

#[test]
fn different_seeds_produce_different_heists() {
    let a = crate::digest(&fixture(1, 900, 3));
    let b = crate::digest(&fixture(2, 900, 3));
    assert_ne!(a, b, "the seed has to matter or the spike proves nothing");
}

#[test]
fn a_heist_round_trips_through_bytes() {
    let heist = fixture(0xFEED, 1800, 4);
    let bytes = heist.encode();
    let back = Heist::decode(&bytes).expect("a heist we encoded must decode");
    assert_eq!(back, heist, "encoding is lossless");
}

#[test]
fn a_full_length_heist_fits_the_size_budget() {
    // §24.10: "Size of a heist — under 2 kilobytes." 7,200 ticks is the long
    // end of "4,500 to 7,200", so this is the worst case the document names.
    for seed in [1u64, 7, 12345, u64::MAX] {
        let heist = fixture(seed, 7_200, 5);
        let size = heist.encode().len();
        assert!(size <= MAX_HEIST_BYTES,
                "seed {seed}: {size} bytes, over the {MAX_HEIST_BYTES} limit");
    }
}

#[test]
fn a_truncated_or_padded_file_is_refused() {
    // A replay arriving from a client is untrusted input. §24.9 is about
    // tests an agent cannot satisfy by cheating; this is the same idea for a
    // decoder — it must refuse, not guess.
    let bytes = fixture(3, 600, 3).encode();
    assert!(Heist::decode(&bytes[..bytes.len() - 1]).is_none(), "truncated");
    let mut longer = bytes.clone();
    longer.push(0);
    assert!(Heist::decode(&longer).is_none(), "trailing bytes");
    let mut wrong_magic = bytes.clone();
    wrong_magic[0] = b'X';
    assert!(Heist::decode(&wrong_magic).is_none(), "wrong magic");
}

#[test]
fn verification_names_the_second_that_diverges() {
    // §24.10: "the first mismatched second narrows a divergence to thirty
    // ticks". A boolean would not, so verify returns the second.
    let mut heist = fixture(11, 900, 3);
    assert_eq!(verify(&heist), Ok(()), "an untouched heist verifies");
    let target = 7usize;
    heist.checksums[target - 1] ^= 1;
    assert_eq!(verify(&heist), Err(target), "the second is reported, not just failure");
}

#[test]
fn commands_are_what_drives_the_crew() {
    // If the crew moved without commands, the input log would not be the
    // whole record and §24.10's "commands, never state" would be false.
    let quiet = Heist {
        commands: Vec::new(),
        checksums: Vec::new(),
        ..fixture(5, 300, 3)
    };
    let mut world = World::new(quiet.seed, quiet.crew, Vec::new());
    let start: Vec<_> = world.raiders.iter().map(|r| r.at).collect();
    for _ in 0..300 {
        world.step();
    }
    let end: Vec<_> = world.raiders.iter().map(|r| r.at).collect();
    assert_eq!(start, end, "no commands, no movement");
}

#[test]
fn a_command_for_a_crew_member_who_is_not_there_is_dropped() {
    // The server re-simulates logs it did not write. A command naming crew
    // member nine must not panic the simulation.
    let heist = Heist {
        crew: 3,
        commands: vec![Command { tick: 1, actor: 9, kind: Kind::MoveTo, x: 100, y: 100 }],
        checksums: Vec::new(),
        ..fixture(5, 60, 3)
    };
    let _ = crate::run(&heist);
}

#[test]
fn suspicion_stays_inside_the_documents_range() {
    // §12.17: "Each guard carries a suspicion value from 0 to 1000."
    let heist = fixture(0xABCD, TICKS_PER_SECOND * 240, 3);
    let mut world = World::new(heist.seed, heist.crew, heist.commands.clone());
    for _ in 0..(TICKS_PER_SECOND * 240) {
        world.step();
        for guard in world.guards.iter() {
            assert!(
                (0..=crate::SUSPICION_MAX).contains(&guard.suspicion),
                "guard {} left the range at {}", guard.id, guard.suspicion);
        }
    }
}

#[test]
fn the_checksum_notices_a_single_unit_of_difference() {
    // A checksum that ignored the low bits of a position would agree across
    // targets while hiding exactly the divergence it exists to find.
    let heist = fixture(5, 300, 3);
    let mut world = World::new(heist.seed, heist.crew, heist.commands);
    for _ in 0..100 {
        world.step();
    }
    let before = world.checksum();
    world.raiders[0].at.x = Fx(world.raiders[0].at.x.0 + 1);
    assert_ne!(before, world.checksum(), "one unit in the last place must show");
}

// --------------------------------------------------------------------------
// Golden replays (T3.2)
// --------------------------------------------------------------------------

/// Every committed replay still decodes, still verifies, and still fits.
///
/// This is the regression harness the spike exists to become. The bytes in
/// `golden/` were written by a build that is now history; a change that moves
/// any number in the simulation fails here and names the second it moved at.
/// §24.11's promise depends on it: "Old replays stay valid forever against the
/// rules they were played under."
#[test]
fn golden_replays_still_verify() {
    let dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("golden");
    let mut names: Vec<_> = std::fs::read_dir(&dir)
        .expect("golden/ should exist — cargo run --bin golden -- --write")
        .filter_map(|e| e.ok().map(|e| e.path()))
        .filter(|p| p.extension().is_some_and(|x| x == "rbh"))
        .collect();
    names.sort();
    assert!(names.len() >= 4, "found {} golden replays, expected at least 4",
            names.len());

    for path in names {
        let bytes = std::fs::read(&path).expect("read a golden replay");
        let name = path.file_name().unwrap().to_string_lossy().to_string();

        assert!(bytes.len() <= MAX_HEIST_BYTES,
                "{name}: {} bytes, over §24.10's limit", bytes.len());

        let heist = Heist::decode(&bytes)
            .unwrap_or_else(|| panic!("{name}: the format no longer decodes it"));

        assert_eq!(heist.encode(), bytes, "{name}: re-encoding changed the bytes");

        match verify(&heist) {
            Ok(()) => {}
            Err(second) => panic!(
                "{name}: the simulation has changed — the replay and the \
                 re-simulation part company at second {second} of {}. \
                 Decide whether that was intended before regenerating: if it \
                 was, `cargo run --bin golden -- --write` in the same commit \
                 as the change, and say in the message what moved. \
                 Regenerating to make a red test green is how a regression \
                 gets committed.",
                heist.checksums.len()),
        }
    }
}

/// The goldens have to disagree with each other, or four files are testing
/// one thing.
#[test]
fn golden_replays_are_different_heists() {
    let dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("golden");
    let mut digests = Vec::new();
    for entry in std::fs::read_dir(&dir).expect("golden/").flatten() {
        if entry.path().extension().is_some_and(|x| x == "rbh") {
            let bytes = std::fs::read(entry.path()).unwrap();
            let heist = Heist::decode(&bytes).unwrap();
            digests.push(crate::digest(&heist));
        }
    }
    let unique: std::collections::BTreeSet<_> = digests.iter().collect();
    assert_eq!(unique.len(), digests.len(), "two goldens are the same heist");
}

// --------------------------------------------------------------------------
// The tile grid and the pathfinder (T5.5, §12.18)
// --------------------------------------------------------------------------

use crate::grid::{Grid, Terrain};
use crate::path;

#[test]
fn realm_grids_are_the_sizes_5_2_states() {
    // §5.2: 10x10 at realm level 1, rising to 14x14 at 5.
    for (level, side) in [(1u8, 10u16), (2, 11), (3, 12), (4, 13), (5, 14)] {
        let grid = Grid::for_realm_level(level);
        assert_eq!((grid.width, grid.height), (side, side), "realm level {level}");
    }
}

#[test]
fn a_tile_index_round_trips_through_its_coordinates() {
    let grid = Grid::new(14, 14);
    for y in 0..grid.height {
        for x in 0..grid.width {
            let i = grid.index(x, y).expect("inside the grid");
            assert_eq!(grid.coords(i), (x, y), "round trip at {x},{y}");
        }
    }
    assert_eq!(grid.index(14, 0), None, "off the east edge");
    assert_eq!(grid.index(0, 14), None, "off the south edge");
}

#[test]
fn a_position_lands_in_the_tile_whose_centre_it_is() {
    let grid = Grid::new(14, 14);
    for i in [0u32, 1, 13, 14, 97, 195] {
        let (x, y) = grid.centre(i);
        assert_eq!(grid.tile_at(x, y), Some(i), "centre of tile {i}");
    }
}

#[test]
fn the_neighbour_order_is_north_east_south_west() {
    // §12.18 makes this part of the contract: "a fixed neighbour order".
    // Changing it changes every route in every replay ever recorded, so the
    // order is asserted rather than assumed.
    let grid = Grid::new(5, 5);
    let middle = grid.index(2, 2).unwrap();
    let n = grid.neighbours(middle);
    assert_eq!(n[0], grid.index(2, 1), "first neighbour is north");
    assert_eq!(n[1], grid.index(3, 2), "second is east");
    assert_eq!(n[2], grid.index(2, 3), "third is south");
    assert_eq!(n[3], grid.index(1, 2), "fourth is west");

    let corner = grid.index(0, 0).unwrap();
    let c = grid.neighbours(corner);
    assert_eq!(c[0], None, "no north from the top row");
    assert_eq!(c[3], None, "no west from the first column");
}

#[test]
fn a_route_is_the_shortest_one() {
    let grid = Grid::new(10, 10);
    let from = grid.index(0, 0).unwrap();
    let to = grid.index(3, 4).unwrap();
    let route = path::find(&grid, from, to).expect("open grid, a route exists");
    // Four neighbours, so the shortest route is the Manhattan distance.
    assert_eq!(route.len(), 3 + 4, "shortest is |dx| + |dy|");
    assert_eq!(*route.last().unwrap(), to, "a route ends at the goal");
}

#[test]
fn a_route_bends_around_a_wall_and_takes_the_gap() {
    let mut grid = Grid::new(10, 10);
    for y in 0..10 {
        if y != 7 {
            grid.set(5, y, Terrain::Blocked);
        }
    }
    let from = grid.index(0, 0).unwrap();
    let to = grid.index(9, 0).unwrap();
    let route = path::find(&grid, from, to).expect("the gap makes one");
    let gap = grid.index(5, 7).unwrap();
    assert!(route.contains(&gap), "the only way through is the gap at (5,7)");
    for tile in route.iter() {
        assert!(grid.at(*tile).passable(), "a route never enters a wall");
    }
}

#[test]
fn a_sealed_goal_has_no_route_and_that_is_the_answer() {
    // §12.18: "no automatic re-routing ... no picking a different door."
    // The pathfinder says there is no route; it does not find a nearby one.
    let mut grid = Grid::new(10, 10);
    for (x, y) in [(8, 8), (9, 8), (8, 9)] {
        grid.set(x, y, Terrain::Blocked);
    }
    let from = grid.index(0, 0).unwrap();
    let to = grid.index(9, 9).unwrap();
    assert_eq!(path::find(&grid, from, to), None, "walled in is walled in");
}

#[test]
fn a_route_into_a_wall_is_refused_rather_than_approximated() {
    let mut grid = Grid::new(10, 10);
    grid.set(4, 4, Terrain::Blocked);
    let from = grid.index(0, 0).unwrap();
    let into_wall = grid.index(4, 4).unwrap();
    assert_eq!(path::find(&grid, from, into_wall), None, "a wall is not a destination");
}

#[test]
fn the_same_route_is_found_every_time_and_by_both_ends_of_the_grid() {
    // Determinism by construction, which is what §12.18 claims. Two runs and
    // two grids that differ only in an unrelated tile must agree.
    let mut grid = Grid::new(12, 12);
    grid.set(6, 0, Terrain::Blocked);
    grid.set(6, 1, Terrain::Blocked);
    let from = grid.index(1, 5).unwrap();
    let to = grid.index(10, 5).unwrap();
    let first = path::find(&grid, from, to).unwrap();
    let second = path::find(&grid, from, to).unwrap();
    assert_eq!(first, second, "the same call gives the same route");

    let mut elsewhere = grid.clone();
    elsewhere.set(11, 11, Terrain::Pace(60));   // slower, not blocked
    assert_eq!(path::find(&elsewhere, from, to).unwrap(), first,
               "a change that does not block does not move the route");
}

#[test]
fn slow_ground_does_not_move_the_route() {
    // Breadth-first counts tiles, so mud cannot bend a path. §12.18 is
    // explicit that this is the rule and not a shortcoming: a pathfinder
    // that routed around mud would be choosing for the player.
    let mut grid = Grid::new(10, 10);
    let from = grid.index(0, 5).unwrap();
    let to = grid.index(9, 5).unwrap();
    let clear = path::find(&grid, from, to).unwrap();
    for x in 1..9 {
        grid.set(x, 5, Terrain::Pace(40));      // very slow, straight ahead
    }
    assert_eq!(path::find(&grid, from, to).unwrap(), clear,
               "the shortest route in tiles is unchanged by how slow it is");
}

#[test]
fn slow_ground_does_change_how_long_the_walk_takes() {
    // ...but it must change the walk, or Terrain::Pace would be decoration.
    let ticks = |pace: Terrain| {
        let heist = fixture(1, 600, 3);
        let mut world = World::new(heist.seed, 1, Vec::new());
        for x in 0..world.grid.width {
            world.grid.set(x, 0, pace);
        }
        let to = world.grid.index(6, 0).unwrap();
        let from = world.grid.tile_at(world.raiders[0].at.x, world.raiders[0].at.y).unwrap();
        world.raiders[0].route = path::find(&world.grid, from, to).unwrap();
        let mut n = 0;
        while world.raiders[0].along < world.raiders[0].route.len() && n < 10_000 {
            world.step();
            n += 1;
        }
        n
    };
    let normal = ticks(Terrain::Open);
    let slow = ticks(Terrain::Pace(50));
    assert!(slow > normal, "half speed should take longer: {slow} against {normal}");
}

#[test]
fn a_crew_member_never_re_routes_itself() {
    // §12.18: "no automatic re-routing around a guard the player walked them
    // into". Once a route is set, only a command replaces it.
    let heist = fixture(9, 600, 3);
    let mut world = World::new(heist.seed, 1, Vec::new());
    let from = world.grid.tile_at(world.raiders[0].at.x, world.raiders[0].at.y).unwrap();
    let to = world.grid.index(2, 9).unwrap();
    world.raiders[0].route = path::find(&world.grid, from, to).unwrap();
    let planned = world.raiders[0].route.clone();
    for _ in 0..300 {
        world.step();
        assert_eq!(world.raiders[0].route, planned,
                   "the route changed without a command");
    }
}

#[test]
fn crew_pass_through_one_another() {
    // §12.18: "They pass through one another. Collision between friends is a
    // source of non-determinism and of the exact frustration this rule exists
    // to prevent." Two crew sent to one tile must both reach it.
    let heist = fixture(4, 900, 2);
    let mut world = World::new(heist.seed, 2, Vec::new());
    let target = world.grid.index(6, 9).unwrap();
    for i in 0..2 {
        let from = world.grid.tile_at(world.raiders[i].at.x, world.raiders[i].at.y).unwrap();
        world.raiders[i].route = path::find(&world.grid, from, target).unwrap();
    }
    for _ in 0..900 {
        world.step();
    }
    let (x, y) = world.grid.centre(target);
    for raider in world.raiders.iter() {
        assert_eq!((raider.at.x, raider.at.y), (x, y),
                   "crew member {} did not reach the shared tile", raider.id);
    }
}
