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

        // §24.11's four things: the header names the island by its hash and
        // the rules by the version this build is. A behaviour change moves the
        // version, so a golden recorded before it no longer claims to be
        // playable here — which is the pin §24.11 asks for.
        assert_eq!(heist.island, crate::island::Island::fixture().digest(),
                   "{name}: the header does not name the fixture realm");
        assert_eq!(heist.rules, crate::rules_version(),
                   "{name}: recorded under another rules version — the \
                    simulation's behaviour has moved; see `rules_version`");

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

// --------------------------------------------------------------------------
// Line of sight (§12.17, §21.12, §6.2)
// --------------------------------------------------------------------------

use crate::grid::Feature;
use crate::sight;

#[test]
fn a_straight_line_crosses_only_its_own_row() {
    let grid = Grid::new(10, 10);
    let from = grid.index(1, 4).unwrap();
    let to = grid.index(8, 4).unwrap();
    let tiles = sight::line(&grid, from, to);
    assert_eq!(tiles.len(), 8, "eight tiles from column 1 to column 8");
    for t in tiles {
        assert_eq!(grid.coords(t).1, 4, "a horizontal line stays in its row");
    }
}

#[test]
fn a_line_is_the_same_from_either_end() {
    // The reason for the supercover rule: a guard must not see a raider whose
    // line back to the guard says it is hidden. Checked over every pair of
    // tiles in a small grid rather than a handful of chosen ones.
    let grid = Grid::new(7, 7);
    for a in 0..grid.len() as u32 {
        for b in 0..grid.len() as u32 {
            let mut there = sight::line(&grid, a, b);
            let mut back = sight::line(&grid, b, a);
            there.sort();
            back.sort();
            assert_eq!(there, back, "the line {a}->{b} is not the line {b}->{a}");
        }
    }
}

#[test]
fn a_diagonal_through_a_corner_crosses_both_side_tiles() {
    // Two pillars meeting at a corner leave no window. A line that stepped in
    // one axis on a tie would see through the gap from one side only.
    let grid = Grid::new(5, 5);
    let tiles = sight::line(&grid, grid.index(0, 0).unwrap(), grid.index(2, 2).unwrap());
    for (x, y) in [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)] {
        assert!(tiles.contains(&grid.index(x, y).unwrap()),
                "the corner crossing should include ({x},{y})");
    }
}

#[test]
fn a_rock_pillar_hides_what_is_behind_it() {
    let mut grid = Grid::new(10, 10);
    grid.place(5, 5, Feature::RockPillar);
    let guard = grid.index(2, 5).unwrap();
    let behind = grid.index(8, 5).unwrap();
    let beside = grid.index(8, 8).unwrap();
    assert!(!sight::visible(&grid, guard, behind), "the pillar is in the way");
    assert!(sight::visible(&grid, guard, beside), "the pillar is not in this line");
}

#[test]
fn a_fence_stops_feet_and_not_eyes() {
    // §6.2: a fence "blocks walking" and "doesn't block sight". The two
    // properties are separate on the tile, and this is the feature that
    // proves they have to be.
    let mut grid = Grid::new(10, 10);
    for y in 0..10 {
        grid.place(5, y, Feature::Fence);
    }
    let guard = grid.index(2, 4).unwrap();
    let across = grid.index(8, 4).unwrap();
    assert!(sight::visible(&grid, guard, across), "a guard sees over a fence");
    assert_eq!(path::find(&grid, guard, across), None, "and nobody walks through it");
}

#[test]
fn a_fog_bank_stops_eyes_and_not_feet() {
    // §6.2: fog "hides anyone inside and blocks sight through it", and it
    // is ground, not a wall.
    let mut grid = Grid::new(10, 10);
    grid.place(5, 4, Feature::FogBank);
    let guard = grid.index(2, 4).unwrap();
    let inside = grid.index(5, 4).unwrap();
    let beyond = grid.index(8, 4).unwrap();
    assert!(!sight::visible(&grid, guard, inside), "hides anyone inside");
    assert!(!sight::visible(&grid, guard, beyond), "and blocks sight through it");
    assert!(path::find(&grid, guard, beyond).is_some(), "but it can be walked through");
}

#[test]
fn a_guard_can_always_see_out_of_its_own_tile() {
    // The observer's tile never blocks: a guard standing in fog is looking
    // out of it, not at it.
    let mut grid = Grid::new(10, 10);
    grid.place(2, 4, Feature::FogBank);
    let guard = grid.index(2, 4).unwrap();
    let target = grid.index(5, 4).unwrap();
    assert!(sight::visible(&grid, guard, target), "fog under the guard does not blind it");
}

#[test]
fn a_ruin_wall_hides_the_far_side_except_through_its_gap() {
    // The fixture's own wall, as §6.2 describes it: "Blocks, with gaps".
    let heist = fixture(1, 60, 3);
    let world = World::new(heist.seed, 3, Vec::new());
    let west = world.grid.index(3, 6).unwrap();
    let through_gap = world.grid.index(11, 6).unwrap();
    let past_wall = world.grid.index(11, 2).unwrap();
    assert!(sight::visible(&world.grid, west, through_gap), "straight through the gap");
    assert!(!sight::visible(&world.grid, west, past_wall), "the wall hides the rest");
}

#[test]
fn every_fixture_guard_stands_inside_the_realm() {
    // A guard off the grid sees nothing, which would leave its row of §12.17's
    // table untested while every other check still passed.
    let heist = fixture(1, 60, 3);
    let world = World::new(heist.seed, 3, Vec::new());
    for guard in world.guards.iter() {
        assert!(world.grid.tile_at(guard.at.x, guard.at.y).is_some(),
                "guard {} is off the grid", guard.id);
    }
}

#[test]
fn walls_change_what_the_guards_notice() {
    // If line of sight never changed an outcome it would be decoration. Run
    // the same heist with sight blocked everywhere it is blocked and with the
    // blocking removed, and the guards' suspicion must differ.
    let heist = fixture(0x5EED_0000_0000_0001, 2400, 5);
    let total = |clear: bool| {
        let mut world = World::new(heist.seed, heist.crew, heist.commands.clone());
        if clear {
            for y in 0..world.grid.height {
                for x in 0..world.grid.width {
                    if world.grid.blocks_sight(world.grid.index(x, y).unwrap()) {
                        world.grid.place(x, y, Feature::Fence);   // feet blocked, eyes clear
                    }
                }
            }
        }
        let mut sum = 0i64;
        for _ in 0..heist.ticks {
            world.step();
            sum += world.guards.iter().map(|g| g.suspicion as i64).sum::<i64>();
        }
        sum
    };
    assert_ne!(total(false), total(true), "line of sight changed nothing");
}

// --------------------------------------------------------------------------
// Noise (§12.17: "Noise travels the way a crew walks")
// --------------------------------------------------------------------------

use crate::guard::{self, State};
use crate::Point;
use crate::noise::{self, Sound};

#[test]
fn sounds_carry_the_documents_distances() {
    // §12.17's table, in whole steps of one metre (§21.1). Walking is 2.5 m,
    // which reaches two steps and not three.
    assert_eq!(Sound::Crawling.steps(), 0, "crawling is silent");
    assert_eq!(Sound::CrouchedWalk.steps(), 1, "crouched walk, 1 m");
    assert_eq!(Sound::Walking.steps(), 2, "walking, 2.5 m");
    assert_eq!(Sound::Running.steps(), 4, "running, 4.5 m");
    assert_eq!(Sound::Breaking.steps(), 5, "breaking something, 5 m");
}

#[test]
fn a_sound_goes_round_a_wall_not_through_it() {
    // Two tiles apart in a straight line with a wall between: a walking sound
    // would reach through, and must not, because the walk round is longer.
    let mut grid = Grid::new(10, 10);
    for y in 0..9 {
        grid.place(4, y, Feature::RockPillar);
    }
    let source = grid.index(3, 2).unwrap();
    let listener = grid.index(5, 2).unwrap();
    let field = noise::field(&grid, source, Sound::Walking.steps());
    assert_eq!(field[listener as usize], noise::UNHEARD, "no hearing through a wall");

    let open = Grid::new(10, 10);
    let field = noise::field(&open, source, Sound::Walking.steps());
    assert_eq!(field[listener as usize], 2, "and heard at two steps without it");
}

#[test]
fn a_guard_turns_toward_the_way_around_not_toward_the_raider() {
    // §12.17: "a guard turns toward the way around, not toward you". The
    // raider is west of the guard behind a wall; the gap is to the south; the
    // first step of the walk back is south, not west into the wall.
    let mut grid = Grid::new(10, 10);
    for y in 0..9 {
        grid.place(4, y, Feature::RockPillar);          // gap at (4, 9)
    }
    let source = grid.index(3, 6).unwrap();
    let listener = grid.index(5, 6).unwrap();
    let field = noise::field(&grid, source, 20);
    let step = noise::way_around(&grid, &field, listener).expect("a way round exists");
    assert_eq!(step, grid.index(5, 7).unwrap(), "south, toward the gap");
    assert_ne!(step, grid.index(4, 6).unwrap(), "not west, into the wall");
}

/// A world with no crew and every guard parked well apart, for state tests.
fn quiet_world() -> World {
    let heist = fixture(3, 60, 1);
    World::new(heist.seed, 0, Vec::new())
}

#[test]
fn a_walking_raider_is_heard_and_a_standing_one_is_not() {
    // Standing still is silent; walking carries 2.5 m. The raider is behind
    // the guard — due south while it faces north — so sight cannot be what
    // wakes it.
    let run = |walking: bool| {
        let heist = fixture(3, 60, 1);
        let mut world = World::new(heist.seed, 1, Vec::new());
        let post = world.grid.index(2, 3).unwrap();
        let (gx, gy) = world.grid.centre(post);
        world.guards[0].at = Point { x: gx, y: gy };
        world.guards[0].home = post;
        world.guards[0].facing = Ang::from_degrees(270);
        let start = world.grid.index(2, 5).unwrap();
        let (rx, ry) = world.grid.centre(start);
        world.raiders[0].at = Point { x: rx, y: ry };
        if walking {
            let to = world.grid.index(2, 6).unwrap();
            world.raiders[0].route = path::find(&world.grid, start, to).unwrap();
        }
        world.step();
        world.guards[0].state
    };
    assert_eq!(run(false), State::Unaware, "a standing raider makes no sound");
    assert_eq!(run(true), State::Investigating,
               "\u{a7}12.17: Investigating at \"600, or on hearing something\"");
}

// --------------------------------------------------------------------------
// Guard states (§12.17's table)
// --------------------------------------------------------------------------

#[test]
fn a_state_does_not_fall_back_within_half_a_second() {
    // "A state cannot fall back for half a second once reached, so nothing
    // flickers at the edge of a zone."
    let mut world = quiet_world();
    world.guards[0].suspicion = 250;
    world.step();
    assert_eq!(world.guards[0].state, State::Suspicious, "rising is immediate");
    let entered = world.guards[0].state_since;
    // Suspicion drains 20 a tick with nothing in sight, so it is below 200
    // within three ticks. The state must still hold for the full half second.
    while world.tick < entered + guard::HOLD_TICKS {
        world.step();
        if world.tick < entered + guard::HOLD_TICKS {
            assert_eq!(world.guards[0].state, State::Suspicious,
                       "fell back {} ticks in", world.tick - entered);
        }
    }
    for _ in 0..3 {
        world.step();
    }
    assert_eq!(world.guards[0].state, State::Unaware, "and then it does fall back");
}

#[test]
fn investigating_walks_to_the_spot_searches_ten_seconds_then_walks_home() {
    let mut world = quiet_world();
    let home = world.guards[0].home;
    let spot = world.grid.index(2, 6).unwrap();
    world.guards[0].interest = Some(spot);
    world.enter(0, State::Investigating);

    let mut arrived = None;
    for _ in 0..600 {
        world.step();
        if world.guards[0].arrived_at.is_some() {
            arrived = world.guards[0].arrived_at;
            break;
        }
    }
    let arrived = arrived.expect("reaches the spot");
    let (sx, sy) = world.grid.centre(spot);
    assert_eq!((world.guards[0].at.x, world.guards[0].at.y), (sx, sy), "at the spot");

    // "Searches nearby for ten seconds."
    while world.tick < arrived + guard::SEARCH_SPOT_TICKS {
        assert_eq!(world.guards[0].state, State::Investigating, "still searching");
        world.step();
    }
    world.step();
    assert_eq!(world.guards[0].state, State::Returning, "gives up after ten seconds");

    for _ in 0..600 {
        world.step();
        if world.guards[0].state == State::Unaware {
            break;
        }
    }
    let (hx, hy) = world.grid.centre(home);
    assert_eq!(world.guards[0].state, State::Unaware, "home and settled");
    assert_eq!((world.guards[0].at.x, world.guards[0].at.y), (hx, hy), "back at its post");
}

#[test]
fn alerted_searches_twenty_seconds_after_losing_sight_then_returns() {
    // Entered directly: with nobody in view, perception drains suspicion
    // before the states phase reads it, so setting 1000 and stepping would
    // test the drain rather than the state.
    let mut world = quiet_world();
    world.enter(0, State::Alerted);
    // Nobody is there, so it has lost sight; after the hold it searches.
    for _ in 0..guard::HOLD_TICKS + 1 {
        world.step();
    }
    assert_eq!(world.guards[0].state, State::Searching, "\"after losing sight\"");
    let since = world.guards[0].state_since;
    while world.tick <= since + guard::SEARCHING_TICKS {
        world.step();
    }
    assert_eq!(world.guards[0].state, State::Returning, "\"after giving up\"");
}

#[test]
fn an_alert_reaches_guards_within_four_metres_half_a_second_later() {
    // "Alarm spreads by distance, not everywhere at once: guards within four
    // metres start investigating half a second later."
    let mut world = quiet_world();
    let place = |world: &mut World, g: usize, x: u16, y: u16| {
        let t = world.grid.index(x, y).unwrap();
        let (cx, cy) = world.grid.centre(t);
        world.guards[g].at = Point { x: cx, y: cy };
        world.guards[g].home = t;
    };
    place(&mut world, 0, 2, 2);
    place(&mut world, 1, 2, 5);     // three metres away
    place(&mut world, 2, 2, 11);    // nine metres away
    world.enter(0, State::Alerted);
    let raised = world.tick;
    while world.tick < raised + guard::SPREAD_DELAY_TICKS {
        assert_eq!(world.guards[1].state, State::Unaware, "not before half a second");
        world.step();
    }
    world.step();
    assert_eq!(world.guards[1].state, State::Investigating, "then investigating");
    assert_ne!(world.guards[2].state, State::Investigating, "not nine metres away");
}

#[test]
fn under_delay_the_alarms_spread_lands_three_seconds_after_it_arrives() {
    // G23: a guard the alarm reaches is triggered, so under Delay it changes
    // state 3 seconds later, like a rise on its own suspicion.
    let mut world = quiet_world();
    world.weave(&[("delay", (0, 13))]);
    let place = |world: &mut World, g: usize, x: u16, y: u16| {
        let t = world.grid.index(x, y).unwrap();
        let (cx, cy) = world.grid.centre(t);
        world.guards[g].at = Point { x: cx, y: cy };
        world.guards[g].home = t;
    };
    place(&mut world, 0, 2, 2);
    place(&mut world, 1, 2, 5);
    world.enter(0, State::Alerted);
    let reached = world.tick + guard::SPREAD_DELAY_TICKS;
    let mut risen = None;
    for _ in 0..5 * TICKS_PER_SECOND {
        world.step();
        if risen.is_none() && world.guards[1].state == State::Investigating {
            risen = Some(world.tick);
        }
    }
    assert_eq!(risen, Some(reached + 1 + 3 * TICKS_PER_SECOND), "the tick after it lands");
}

// --------------------------------------------------------------------------
// The realm alarm (§12.17, §12.6)
// --------------------------------------------------------------------------

#[test]
fn the_realm_alarm_climbs_once_every_thirty_seconds_to_six() {
    let mut world = quiet_world();
    for level in 0..=6 {
        while world.tick < level as u32 * guard::ALARM_STEP_TICKS {
            world.step();
        }
        world.step();
        assert_eq!(world.alarm, level, "{} seconds in", world.tick / TICKS_PER_SECOND);
    }
    for _ in 0..guard::ALARM_STEP_TICKS * 2 {
        world.step();
    }
    assert_eq!(world.alarm, guard::ALARM_MAX, "and never above six");
}

#[test]
fn at_alarm_five_one_more_warden_arrives_at_the_entrance() {
    // "At 5 another Warden arrives at an entrance." Once, not once a tick.
    let mut world = quiet_world();
    let before = world.guards.len();
    while world.alarm < guard::REINFORCE_AT {
        world.step();
        if world.alarm < guard::REINFORCE_AT {
            assert_eq!(world.guards.len(), before, "nobody arrives early");
        }
    }
    assert_eq!(world.guards.len(), before + 1, "one Warden");
    let warden = world.guards.last().unwrap();
    let (ex, ey) = world.grid.centre(world.entrance);
    assert_eq!((warden.at.x, warden.at.y), (ex, ey), "at the entrance");
    assert_eq!(warden.cone, Ang::from_degrees(40), "with the Warden's cone");
    for _ in 0..guard::ALARM_STEP_TICKS * 2 {
        world.step();
    }
    assert_eq!(world.guards.len(), before + 1, "and only one, through alarm 6");
}

#[test]
fn a_raider_held_in_the_near_zone_raises_a_guard_to_alerted() {
    // The real route to Alerted: §12.17's near zone fills in about half a
    // second, so a raider standing a metre in front of a guard takes it from
    // Unaware through every state to Alerted in about fifteen ticks.
    let heist = fixture(3, 60, 1);
    let mut world = World::new(heist.seed, 1, Vec::new());
    let post = world.grid.index(2, 4).unwrap();
    let (gx, gy) = world.grid.centre(post);
    world.guards[0].at = Point { x: gx, y: gy };
    world.guards[0].home = post;
    world.guards[0].turn_per_tick = Ang::ZERO;           // hold the gaze still
    let spot = world.grid.index(2, 3).unwrap();          // one tile north
    let (rx, ry) = world.grid.centre(spot);
    world.raiders[0].at = Point { x: rx, y: ry };
    world.guards[0].facing = world.guards[0].at.bearing_to(world.raiders[0].at);
    let mut seen = Vec::new();
    for _ in 0..40 {
        world.step();
        if seen.last() != Some(&world.guards[0].state) {
            seen.push(world.guards[0].state);
        }
    }
    assert_eq!(world.guards[0].state, State::Alerted, "seen up close for long enough");
    // The first tick is spent noticing: the guard is still Unaware after it.
    seen.retain(|s| *s != State::Unaware);
    assert_eq!(&seen[..3], &[State::Suspicious, State::Investigating, State::Alerted],
               "through the table in order");
}

// --------------------------------------------------------------------------
// Roles and gaits (§11.1's speeds; §12.17 prices crouching and running)
// --------------------------------------------------------------------------

use crate::{Gait, Role};
use crate::grid::Surface;
use crate::noise::Sound as S;

/// Walk crew member 0, a Warden, east along an open row for two seconds and
/// return where it ends up, in tiles.
fn two_seconds_east(gait: Gait) -> Fx {
    let heist = fixture(3, 60, 1);
    let mut world = World::new(heist.seed, 1, Vec::new());
    world.grid = Grid::new(14, 14);
    world.guards.clear();
    world.raiders[0].role = Role::Warden;
    world.raiders[0].speed = Role::Warden.speed();
    world.raiders[0].gait = gait;
    let start = world.grid.index(0, 0).unwrap();
    let end = world.grid.index(13, 0).unwrap();
    world.raiders[0].route = path::find(&world.grid, start, end).unwrap();
    for _ in 0..60 {
        world.step();
    }
    world.raiders[0].at.x
}

#[test]
fn a_crew_member_covers_its_roles_distance_whatever_the_tile_edges() {
    // §11.1: a Warden walks 2.6 tiles a second, so two seconds from the centre
    // of tile 0 end at 0.5 + 5.2 = 5.7. Reaching a tile centre part-way
    // through a tick must not throw the rest of that tick's step away — the
    // first version did, and every role walked up to a tick a tile slower
    // than §11.1 says.
    let near = |at: Fx, want_tenths: i64| (at - Fx::from_ratio(want_tenths, 10)).0.abs()
        < Fx::from_ratio(1, 100).0;
    let walk = two_seconds_east(Gait::Walk);
    assert!(near(walk, 57), "walking: 5.7, got {} in 2^-32 tiles", walk.0);
    let crouch = two_seconds_east(Gait::Crouch);
    assert!(near(crouch, 31), "crouched, at half: 3.1");
    let run = two_seconds_east(Gait::Run);
    assert!(near(run, 109), "running, at double: 10.9");
}

/// An open 14x14 realm with one Scout at the centre of (6, 6) facing east and
/// one raider `metres_tenths` away at `degrees` off its facing, standing still.
fn scout_and_raider(metres_tenths: i64, degrees: i32) -> World {
    let heist = fixture(3, 60, 1);
    let mut world = World::new(heist.seed, 1, Vec::new());
    world.grid = Grid::new(14, 14);
    world.guards.truncate(1);                     // row 0 is the Scout
    let post = world.grid.index(6, 6).unwrap();
    let (gx, gy) = world.grid.centre(post);
    world.guards[0].at = Point { x: gx, y: gy };
    world.guards[0].facing = Ang::from_degrees(0);
    let r = Fx::from_ratio(metres_tenths, 10);
    let a = Ang::from_degrees(degrees);
    world.raiders[0].at = Point { x: gx + trig::cos(a).mul(r), y: gy + trig::sin(a).mul(r) };
    world.raiders[0].route.clear();
    world
}

fn rate(world: &World) -> Option<i32> {
    world.noticed(0, 0).map(|(per_tick, _)| per_tick)
}

/// A world at realm alarm `level`, reached as the alarm climbs: thirty
/// seconds a level, so the states phase keeps it there.
fn at_alarm(mut world: World, level: i32) -> World {
    world.tick = level as u32 * crate::guard::ALARM_STEP_TICKS;
    world.alarm = level;
    world
}

#[test]
fn from_alarm_level_1_suspicion_empties_at_half_its_rate() {
    // §12.17: "Suspicion empties at half its rate, about 3.4 seconds instead
    // of 1.7". The raider stands behind the Scout, unseen.
    let drained = |level: i32| {
        let mut world = at_alarm(scout_and_raider(15, 180), level);
        world.guards[0].suspicion = 400;
        world.step();
        400 - world.guards[0].suspicion
    };
    assert_eq!(drained(0), crate::DECAY_PER_TICK, "at level 0, the full rate");
    assert_eq!(drained(1), crate::DECAY_PER_TICK / 2, "from level 1, half");
    assert_eq!(drained(6), crate::DECAY_PER_TICK / 2, "and it keeps at higher levels");
}

#[test]
fn from_alarm_level_2_every_noise_carries_a_metre_further_except_crouching_on_moss() {
    use crate::grid::Surface;
    use crate::noise::Sound;
    let extra = |level, sound, surface| crate::alarm_noise_extra(level, sound, surface);
    assert_eq!(extra(1, Sound::Walking, Surface::Plain), 0, "not before level 2");
    assert_eq!(extra(2, Sound::Walking, Surface::Plain), 2, "a metre, in half metres");
    assert_eq!(extra(2, Sound::CrouchedWalk, Surface::Moss), 0, "a crouched step on moss");
    assert_eq!(extra(2, Sound::CrouchedWalk, Surface::Plain), 2, "a crouched step elsewhere");
    assert_eq!(extra(2, Sound::Walking, Surface::Moss), 2, "walking on moss");
    // Walking's 2.5 m reaches two steps, and 3.5 m three; crawling stays silent.
    let law = (1, 1);
    assert_eq!(Sound::Walking.steps_further(Surface::Plain, law, 0), 2);
    assert_eq!(Sound::Walking.steps_further(Surface::Plain, law, 2), 3);
    assert_eq!(Sound::Crawling.steps_further(Surface::Plain, law, 2), 0);
}

#[test]
fn from_alarm_level_3_an_investigating_guard_searches_for_20_seconds() {
    use crate::guard::{SEARCH_SPOT_LONG_TICKS, SEARCH_SPOT_TICKS};
    let world = |level| at_alarm(scout_and_raider(15, 180), level);
    assert_eq!(world(2).search_spot_ticks(), SEARCH_SPOT_TICKS);
    assert_eq!(SEARCH_SPOT_TICKS, TICKS_PER_SECOND * 10);
    assert_eq!(world(3).search_spot_ticks(), SEARCH_SPOT_LONG_TICKS);
    assert_eq!(SEARCH_SPOT_LONG_TICKS, TICKS_PER_SECOND * 20);
}

#[test]
fn from_alarm_level_4_the_alarm_and_a_glare_reach_8_m() {
    // §12.17: "The alarm spreads twice as far: guards within 8 m, not 4";
    // §10.3: a Glare's 4 m is "8 m from alarm level 4".
    let world = |level| at_alarm(scout_and_raider(15, 180), level);
    assert_eq!(world(3).spread_reach(), Fx::from_int(4));
    assert_eq!(world(4).spread_reach(), Fx::from_int(8));
    assert_eq!(world(3).glare_reach(), Fx::from_int(4));
    assert_eq!(world(4).glare_reach(), Fx::from_int(8));
}

#[test]
fn at_alarm_level_6_every_guard_in_the_realm_enters_searching() {
    use crate::guard::State;
    // One step before level 6 is reached: every guard is still at its post.
    let heist = fixture(3, 60, 1);
    let mut world = World::new(heist.seed, 1, Vec::new());
    world.tick = 6 * crate::guard::ALARM_STEP_TICKS - 1;
    world.alarm = 5;
    world.reinforced = true;
    world.step();
    assert!(world.guards.iter().all(|g| g.state != State::Searching), "not yet");
    world.step();
    assert_eq!(world.alarm, 6);
    for (gi, g) in world.guards.iter().enumerate() {
        assert!(matches!(g.state, State::Searching | State::Alerted) || !g.awake(world.tick),
                "guard {gi} is {:?}", g.state);
    }
}

#[test]
fn a_realms_watch_tunes_its_guards_by_realm_level() {
    // §12.17 (v3.7): "at realm level 1 suspicion fills at 0.6 of the rates
    // above; at level 2 every zone reaches 0.75 as far, and at level 3 0.7 as
    // far; from level 4 guards see and notice at full strength." The fixture is
    // realm level 5, at full strength. The Scout's zones reach 2, 4 and 6 m.
    use crate::REALM_WATCH;
    let watched = |level: usize, metres_tenths: i64| {
        let mut world = scout_and_raider(metres_tenths, 0);
        world.watch = REALM_WATCH[level - 1];
        rate(&world)
    };
    let full = rate(&scout_and_raider(15, 0)).expect("1.5 m ahead is seen");
    assert_eq!(watched(5, 15), Some(full), "realm level 5 is full strength");
    assert_eq!(watched(4, 15), Some(full), "and so is realm level 4");
    let slow = watched(1, 15).expect("realm level 1 still sees 1.5 m ahead");
    assert!((slow - full * 3 / 5).abs() <= 1, "realm level 1 fills at 0.6: {slow} of {full}");
    // 5.5 m is inside the Scout's 6 m far zone, and outside 0.75 of it (4.5 m)
    // and 0.7 of it (4.2 m).
    assert!(watched(5, 55).is_some(), "seen at 5.5 m at full strength");
    assert!(watched(1, 55).is_some(), "realm level 1 sees as far");
    assert_eq!(watched(2, 55), None, "realm level 2 reaches 0.75 as far");
    assert_eq!(watched(3, 55), None, "realm level 3 reaches 0.7 as far");
    // 4.4 m: inside 0.75 of 6 m, outside 0.7 of it.
    assert!(watched(2, 44).is_some(), "4.4 m is inside realm level 2's reach");
    assert_eq!(watched(3, 44), None, "and outside realm level 3's");
}

#[test]
fn the_corner_of_the_eye_notices_at_half_the_rate() {
    // The Scout's cone is 45 degrees, so 22.5 either side; its corner of the
    // eye is 110, so 55 either side. 1.5 m is inside its near zone.
    assert_eq!(rate(&scout_and_raider(15, 0)), Some(67), "in the cone, near: 67");
    assert_eq!(rate(&scout_and_raider(15, 40)), Some(33), "corner of the eye: half");
    assert_eq!(rate(&scout_and_raider(15, 320)), Some(33), "on either side");
    assert_eq!(rate(&scout_and_raider(15, 70)), None, "outside both arcs: nothing");
    // The same zones reach the same distances: 5 m is the far zone either way.
    assert_eq!(rate(&scout_and_raider(50, 0)), Some(12));
    assert_eq!(rate(&scout_and_raider(50, 40)), Some(6));
    assert_eq!(rate(&scout_and_raider(65, 40)), None, "past the far zone");
    // And a guard standing on the raider sees it, whichever way it faces.
    let mut world = scout_and_raider(0, 0);
    world.guards[0].facing = Ang::from_degrees(90);
    assert_eq!(rate(&world), Some(67), "on the same spot: near, and in view");
}

#[test]
fn gait_and_light_multiply_the_rate_once() {
    // §12.17: crouched halves, running adds three quarters, unlit halves
    // again. The factors multiply and one division comes last.
    let with = |gait: Gait, dark: bool, degrees: i32| {
        let mut world = scout_and_raider(15, degrees);
        world.raiders[0].gait = gait;
        if dark {
            let (x, y) = world.grid.coords(
                world.grid.tile_at(world.raiders[0].at.x, world.raiders[0].at.y).unwrap());
            world.grid.darken(x, y);
        }
        rate(&world)
    };
    assert_eq!(with(Gait::Walk, false, 0), Some(67));
    assert_eq!(with(Gait::Crouch, false, 0), Some(33));
    assert_eq!(with(Gait::Run, false, 0), Some(117), "67 x 7/4 = 117.25");
    assert_eq!(with(Gait::Walk, true, 0), Some(33), "unlit");
    assert_eq!(with(Gait::Crouch, true, 0), Some(16), "a quarter: 67/4");
    assert_eq!(with(Gait::Run, true, 0), Some(58), "67 x 7/8 = 58.6");
    // All three halvings at once: an eighth of 67, from one division.
    assert_eq!(with(Gait::Crouch, true, 40), Some(8));
}

#[test]
fn standing_still_in_tall_grass_hides_until_a_guard_walks_in() {
    // 2 m puts the raider on the centre of (8, 6), so a guard a quarter-tile
    // short of it is inside the tile and still facing it.
    let hidden = |moving: bool, guard_inside: bool| {
        let mut world = scout_and_raider(20, 0);
        let tile = world.grid.tile_at(world.raiders[0].at.x, world.raiders[0].at.y).unwrap();
        let (x, y) = world.grid.coords(tile);
        world.grid.place(x, y, Feature::TallGrass);
        if moving {
            let next = world.grid.index(x, y + 1).unwrap();
            world.raiders[0].route = vec![next];
        }
        if guard_inside {
            let (cx, cy) = world.grid.centre(tile);
            world.guards[0].at = Point { x: cx - Fx::from_ratio(1, 4), y: cy };
        }
        rate(&world).is_none()
    };
    assert!(hidden(false, false), "still in grass: invisible");
    assert!(!hidden(true, false), "moving through it: seen");
    assert!(!hidden(false, true), "\"until a guard walks into the tile\"");
    // And grass does not block sight past it, as a fog bank does.
    let mut grid = Grid::new(10, 10);
    grid.place(3, 2, Feature::TallGrass);
    assert!(sight::visible(&grid, grid.index(1, 2).unwrap(), grid.index(5, 2).unwrap()));
}

#[test]
fn gravel_and_water_carry_further_and_moss_less() {
    // Spec: louder x1.25, quieter x0.75, applied to the radius before it is
    // cut to whole steps.
    assert_eq!(S::Walking.steps_on(Surface::Plain), 2, "2.5 m");
    assert_eq!(S::Walking.steps_on(Surface::Gravel), 3, "3.1 m");
    assert_eq!(S::Walking.steps_on(Surface::Moss), 1, "1.9 m");
    assert_eq!(S::Running.steps_on(Surface::Water), 5, "5.6 m");
    assert_eq!(S::CrouchedWalk.steps_on(Surface::Moss), 0, "0.75 m: under a step");
    assert_eq!(S::CrouchedWalk.steps_on(Surface::Plain), 1);
}

#[test]
fn a_walk_on_gravel_is_heard_where_the_same_walk_on_grass_is_not() {
    // A guard three steps from a walking raider, facing away: plain ground
    // carries two steps and gravel three.
    let wakes = |surface: Surface| {
        let heist = fixture(3, 60, 1);
        let mut world = World::new(heist.seed, 1, Vec::new());
        world.grid = Grid::new(14, 14);
        world.guards.truncate(1);
        let post = world.grid.index(2, 2).unwrap();
        let (gx, gy) = world.grid.centre(post);
        world.guards[0].at = Point { x: gx, y: gy };
        world.guards[0].facing = Ang::from_degrees(270);
        world.grid.set_surface(2, 5, surface);
        let start = world.grid.index(2, 5).unwrap();
        let (rx, ry) = world.grid.centre(start);
        world.raiders[0].at = Point { x: rx, y: ry };
        world.raiders[0].route = vec![world.grid.index(2, 6).unwrap()];
        world.step();
        world.guards[0].state
    };
    assert_eq!(wakes(Surface::Plain), State::Unaware);
    assert_eq!(wakes(Surface::Gravel), State::Investigating);
}

#[test]
fn running_is_heard_further_than_walking() {
    let wakes = |gait: Gait| {
        let heist = fixture(3, 60, 1);
        let mut world = World::new(heist.seed, 1, Vec::new());
        world.grid = Grid::new(14, 14);
        world.guards.truncate(1);
        let post = world.grid.index(2, 2).unwrap();
        let (gx, gy) = world.grid.centre(post);
        world.guards[0].at = Point { x: gx, y: gy };
        world.guards[0].facing = Ang::from_degrees(270);
        let start = world.grid.index(2, 6).unwrap();
        let (rx, ry) = world.grid.centre(start);
        world.raiders[0].at = Point { x: rx, y: ry };
        world.raiders[0].gait = gait;
        world.raiders[0].route = vec![world.grid.index(2, 7).unwrap()];
        world.step();
        world.guards[0].state
    };
    assert_eq!(wakes(Gait::Walk), State::Unaware, "four steps: walking carries two");
    assert_eq!(wakes(Gait::Run), State::Investigating, "running carries four");
}

#[test]
fn a_gait_command_changes_the_gait_and_a_bad_one_is_dropped() {
    let heist = fixture(3, 60, 1);
    let commands = vec![
        Command { tick: 0, actor: 0, kind: Kind::Gait, x: 2, y: 0 },
        Command { tick: 1, actor: 0, kind: Kind::Gait, x: 7, y: 0 },
    ];
    let mut world = World::new(heist.seed, 1, commands);
    world.step();
    assert_eq!(world.raiders[0].gait, Gait::Run);
    world.step();
    assert_eq!(world.raiders[0].gait, Gait::Run, "no gait 7: dropped, not guessed");
}

#[test]
fn the_crew_and_the_guards_move_at_their_roles_speeds() {
    // §11.1's column, per tick at 30 ticks a second.
    let heist = fixture(3, 60, 1);
    let world = World::new(heist.seed, 5, Vec::new());
    let roles: Vec<Role> = world.raiders.iter().map(|r| r.role).collect();
    assert_eq!(roles, [Role::Scout, Role::Breaker, Role::Carrier, Role::Warden, Role::Mender],
               "a fixture crew in \u{a7}11.1's order");
    for raider in &world.raiders {
        assert_eq!(raider.speed, Fx::from_ratio(raider.role.speed_tenths(), 300));
    }
    assert_eq!(Role::Scout.speed_tenths(), 45);
    assert_eq!(Role::Warden.speed_tenths(), 26);
    // Guard rows are §12.17's order: Scout, Warden, Breaker, Carrier, Mender.
    assert_eq!(world.guards[1].speed, Role::Warden.speed());
    assert_eq!(world.guards[3].speed, Role::Carrier.speed());
}

#[test]
fn the_seed_cannot_change_what_a_guard_does() {
    // §12.17: "nothing here is random: a player who scouts an island can
    // predict exactly what will happen." The same commands on two seeds must
    // produce the same heist, tick for tick.
    let commands = fixture(11, 3000, 3).commands;
    let mut a = World::new(1, 3, commands.clone());
    let mut b = World::new(u64::MAX, 3, commands);
    for _ in 0..3000 {
        assert_eq!(a.step(), b.step(), "a guard's behaviour depended on the seed");
    }
}

// --------------------------------------------------------------------------
// The Vault, loading and the skiff (§12.6, §12.19, §5.4)
// --------------------------------------------------------------------------

use crate::heist::{self as h, Grade, Standing, Task};
use crate::{make_guard, planned, SUSPICION_MAX};

/// An open 14x14 realm with the Vault at (6, 6), no guards, and `crew` crew
/// members in §11.1's order.
fn vault_world(crew: u8) -> World {
    let mut world = World::new(1, crew, Vec::new());
    world.grid = Grid::new(14, 14);
    world.grid.place(6, 6, Feature::Vault);
    world.vault.tile = world.grid.index(6, 6).unwrap();
    world.guards.clear();
    world
}

fn put(world: &mut World, ri: usize, x: u16, y: u16) {
    let (px, py) = world.grid.centre(world.grid.index(x, y).unwrap());
    world.raiders[ri].at = Point { x: px, y: py };
    world.raiders[ri].route.clear();
}

/// The four tiles beside (6, 6), and one more on the first so a fifth crew
/// member has somewhere to stand.
const BESIDE: [(u16, u16); 5] = [(6, 5), (7, 6), (6, 7), (5, 6), (6, 5)];

fn ticks_to_open(roles: &[usize]) -> u32 {
    let mut world = vault_world(5);
    for (slot, &ri) in roles.iter().enumerate() {
        let (x, y) = BESIDE[slot];
        put(&mut world, ri, x, y);
        world.raiders[ri].task = Task::Crack;
    }
    for ri in 0..5 {
        if !roles.contains(&ri) {
            put(&mut world, ri, 0, 13);
        }
    }
    while world.vault.opened_at.is_none() && world.tick < 10_000 {
        world.step();
    }
    world.tick
}

#[test]
fn a_breaker_cracks_at_double_damage_and_a_helper_adds_a_quarter() {
    let mut world = vault_world(2);
    put(&mut world, 0, 6, 5);                     // the Scout
    put(&mut world, 1, 7, 6);                     // the Breaker
    world.raiders[0].task = Task::Crack;
    world.raiders[1].task = Task::Crack;
    for _ in 0..h::HIT_TICKS - 1 {
        world.step();
    }
    assert_eq!(world.vault.health, 1500, "nothing lands before the 0.8 s wind-up ends");
    world.step();
    // §11.1 (v3.3): two working one object, every hit a quarter more.
    assert_eq!(world.vault.health, 1500 - 15 - 100, "Scout 12 and Breaker 80, each x1.25");
}

#[test]
fn cracking_takes_what_12_19_says_with_and_without_a_breaker() {
    // §12.19 (v3.3): "at Vault level 1, 15 seconds for a Breaker alone and 8
    // for a full crew with the assist bonus ... about 26 seconds for four at
    // Vault level 1 without the assist bonus, and about 22 with it."
    // Alone: 80 a hit, nineteen hits: 15.2 s.
    assert_eq!(ticks_to_open(&[1]), 19 * h::HIT_TICKS);
    // All five: 15 + 100 + 10 + 25 + 7 = 157 a hit, ten hits: 8 s.
    assert_eq!(ticks_to_open(&[0, 1, 2, 3, 4]), 10 * h::HIT_TICKS);
    // Four with no Breaker: 15 + 10 + 25 + 7 = 57 a hit, 27 hits: 21.6 s.
    assert_eq!(ticks_to_open(&[0, 2, 3, 4]), 27 * h::HIT_TICKS);
}

#[test]
fn no_guard_hears_the_vault_but_one_beside_it_still_sees() {
    // F35, decided: "A hit on the Vault is heard by no guard. A guard beside
    // it still sees the crew." v3.4 had every hit heard within 5 m and every
    // five seconds of cracking call the guards within 5 m of the walk.
    //
    // A guard on the Vault's far side, beside it and facing away, through
    // twenty seconds of cracking: it hears nothing and stays Unaware.
    let mut world = vault_world(2);
    put(&mut world, 1, 5, 6);                     // the Breaker, west of the Vault
    world.raiders[1].task = Task::Crack;
    put(&mut world, 0, 13, 13);
    let mut g = make_guard(0, 0, world.grid.index(7, 6).unwrap(), &world.grid);
    g.facing = Ang::from_degrees(0);              // east, away from the Vault
    world.guards.push(g);
    let health = world.vault.health;
    run_for(&mut world, 20 * TICKS_PER_SECOND);
    assert!(world.vault.health < health, "the Vault was hit");
    assert_eq!(world.guards[0].state, State::Unaware, "and nobody heard it");
    assert_eq!(world.guards[0].suspicion, 0);
    // A guard with a clear line to the Breaker, two tiles north of it, sees
    // it. (Beside the Vault on another side, the Vault's corner is in the
    // way of the diagonal.)
    let mut world = vault_world(2);
    put(&mut world, 1, 5, 6);
    world.raiders[1].task = Task::Crack;
    put(&mut world, 0, 13, 13);
    let mut g = make_guard(0, 0, world.grid.index(5, 4).unwrap(), &world.grid);
    g.facing = g.at.bearing_to(world.raiders[1].at);   // toward the Breaker
    world.guards.push(g);
    run_for(&mut world, 2 * TICKS_PER_SECOND);
    assert!(world.guards[0].suspicion > 0, "a guard that can see the crew still sees it");
}

#[test]
fn loading_is_thirty_a_second_to_the_target() {
    let mut world = vault_world(3);
    world.vault.health = 0;
    world.vault.opened_at = Some(0);
    put(&mut world, 2, 6, 5);                     // the Carrier
    world.raiders[2].task = Task::Load;
    world.raiders[2].target_fill = 50;
    put(&mut world, 0, 13, 13);
    put(&mut world, 1, 13, 13);
    for _ in 0..TICKS_PER_SECOND {
        world.step();
    }
    assert_eq!(world.raiders[2].carried, 30, "30 in a second");
    for _ in 0..(10 * TICKS_PER_SECOND) {
        world.step();
    }
    assert_eq!(world.raiders[2].carried, 150, "and stops at half of 300");
}

#[test]
fn a_full_five_crew_load_takes_ten_seconds() {
    // §12.6: "A full five-crew load therefore takes about ten seconds."
    let mut world = vault_world(5);
    world.vault.health = 0;
    world.vault.opened_at = Some(0);
    for ri in 0..5 {
        let (x, y) = BESIDE[ri];
        put(&mut world, ri, x, y);
        world.raiders[ri].task = Task::Load;
    }
    let full = |w: &World| w.raiders.iter().all(|r| r.carried == r.role.carry());
    for _ in 0..(10 * TICKS_PER_SECOND - 1) {
        world.step();
    }
    assert!(!full(&world), "not before ten seconds");
    world.step();
    assert!(full(&world), "every bag full at ten: the Carrier's 300 at 30 a second");
    assert_eq!(world.vault.exposed, 0, "750 exposed, 750 carried");
}

#[test]
fn loading_stops_when_the_exposed_share_is_gone() {
    let mut world = vault_world(2);
    world.vault.health = 0;
    world.vault.opened_at = Some(0);
    world.vault.exposed = 45;
    for ri in 0..2 {
        let (x, y) = BESIDE[ri];
        put(&mut world, ri, x, y);
        world.raiders[ri].task = Task::Load;
    }
    for _ in 0..(5 * TICKS_PER_SECOND) {
        world.step();
    }
    let carried: i32 = world.raiders.iter().map(|r| r.carried).sum();
    assert_eq!(carried, 45);
    assert_eq!(world.raiders[0].carried, 23, "in id order: the Scout takes the odd unit");
}

#[test]
fn the_carrier_walks_fifteen_percent_slower_loaded() {
    let walk = |carried: i32| {
        let mut world = vault_world(3);
        put(&mut world, 2, 0, 0);
        world.raiders[2].carried = carried;
        let end = world.grid.index(13, 0).unwrap();
        let start = world.grid.index(0, 0).unwrap();
        world.raiders[2].route = path::find(&world.grid, start, end).unwrap();
        put(&mut world, 0, 0, 13);
        put(&mut world, 1, 1, 13);
        world.raiders[2].route = path::find(&world.grid, start, end).unwrap();
        for _ in 0..TICKS_PER_SECOND {
            world.step();
        }
        world.raiders[2].at.x - Fx::from_ratio(1, 2)
    };
    let empty = walk(0);
    let loaded = walk(1);
    // 3.6 tiles a second, and 85% of that: 3.06.
    assert!((empty - Fx::from_ratio(36, 10)).0.abs() < Fx::from_ratio(1, 100).0);
    assert!((loaded - Fx::from_ratio(306, 100)).0.abs() < Fx::from_ratio(1, 100).0);
}

#[test]
fn the_skiff_comes_to_an_edge_after_twenty_seconds_and_nowhere_else() {
    // §5.4: "20 seconds to fight the winds around the Heart", "to any edge
    // tile", and "the crew must hold the spot until it arrives".
    let inland = vec![Command { tick: 0, actor: 0, kind: Kind::Skiff,
                                x: 5 * 256 + 128, y: 5 * 256 + 128 }];
    let mut world = World::new(1, 1, inland);
    world.step();
    assert!(world.skiff.is_none(), "an inland tile is not a place a skiff comes");

    let mut world = vault_world(1);
    world.commands_for_test(vec![Command { tick: 0, actor: 0, kind: Kind::Skiff,
                                           x: 13 * 256 + 128, y: 5 * 256 + 128 }]);
    world.raiders[0].carried = 40;
    put(&mut world, 0, 13, 5);
    for _ in 0..(20 * TICKS_PER_SECOND) {
        world.step();
        assert_eq!(world.raiders[0].standing, Standing::Active, "held, not yet aboard");
    }
    world.step();                                 // tick 600: it arrives
    assert_eq!(world.raiders[0].standing, Standing::Out);
    assert_eq!(world.outcome().banked, 40);
    assert_eq!(world.outcome().left, 0, "banked is not left");
}

#[test]
fn anyone_inside_when_the_clock_ends_is_caught() {
    let mut world = vault_world(2);
    world.clock = 90;
    world.raiders[1].carried = 25;
    for _ in 0..90 {
        world.step();
    }
    assert!(world.raiders.iter().all(|r| r.standing == Standing::Caught));
    assert_eq!(world.raiders[1].carried, 0, "and drops what it carries");
    assert_eq!(world.dropped.len(), 1);
    assert_eq!(world.outcome().grade, Grade::Foiled);
    assert_eq!(world.outcome().left, 25, "what the crew was carrying, left behind (9.4)");
}

#[test]
fn the_four_grades_follow_12_9() {
    let grade = |standings: [Standing; 2], carried: [i32; 2], alarm: bool| {
        let mut world = vault_world(2);
        for ri in 0..2 {
            world.raiders[ri].standing = standings[ri];
            world.raiders[ri].carried = carried[ri];
        }
        world.alarm_raised = alarm;
        world.outcome().grade
    };
    use Standing::*;
    assert_eq!(grade([Out, Out], [10, 0], false), Grade::Clean, "no alarm; everyone out");
    assert_eq!(grade([Out, Out], [10, 0], true), Grade::Loud, "alarm raised; everyone out");
    assert_eq!(grade([Out, Caught], [10, 0], false), Grade::Partial, "some caught; some out");
    assert_eq!(grade([Out, Out], [0, 0], false), Grade::Foiled, "no loot out");
    assert_eq!(grade([Caught, Caught], [0, 0], true), Grade::Foiled);
}

// --------------------------------------------------------------------------
// Fights, knockouts and capture (§12.20, §12.8)
// --------------------------------------------------------------------------

/// A guard of §12.17 row `row` at (x, y), facing north, in `world`.
fn post(world: &mut World, row: usize, x: u16, y: u16) -> usize {
    let id = world.guards.len() as u32;
    let g = make_guard(id, row, world.grid.index(x, y).unwrap(), &world.grid);
    world.guards.push(g);
    id as usize
}

#[test]
fn an_alerted_guard_hits_once_every_eight_tenths_for_its_power() {
    // The Breaker guard, Power 40, beside the crew's Scout, Health 120:
    // three hits, the third at 2.4 s, and the Scout's loot on the tile.
    let mut world = vault_world(1);
    put(&mut world, 0, 3, 4);
    world.raiders[0].carried = 30;
    let gi = post(&mut world, 2, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(90);  // south, at the Scout
    world.enter(gi, State::Alerted);
    world.guards[gi].route.clear();
    world.guards[gi].interest = world.grid.index(3, 4);
    for _ in 0..(2 * h::HIT_TICKS) {
        world.step();
    }
    assert_eq!(world.raiders[0].health, 120 - 80, "two hits in 1.6 s");
    for _ in 0..h::HIT_TICKS {
        world.step();
    }
    assert_eq!(world.raiders[0].standing, Standing::Down);
    assert_eq!(world.dropped, vec![(world.grid.index(3, 4).unwrap(), 30)]);
}

#[test]
fn a_downed_crew_member_is_caught_after_ten_seconds_unless_revived() {
    let down = |helper: Option<usize>| {
        let mut world = vault_world(5);
        for ri in 0..5 {
            put(&mut world, ri, 13, ri as u16 * 2);
        }
        put(&mut world, 0, 3, 3);
        world.raiders[0].health = 0;
        if let Some(ri) = helper {
            put(&mut world, ri, 3, 4);            // adjacent
        }
        let mut revived_at = None;
        for _ in 0..(11 * TICKS_PER_SECOND) {
            world.step();
            if revived_at.is_none() && world.raiders[0].standing == Standing::Active
                && world.tick > 1
            {
                revived_at = Some(world.tick);
            }
        }
        (world.raiders[0].standing, revived_at, world.raiders[0].health)
    };
    let (alone, _, _) = down(None);
    assert_eq!(alone, Standing::Caught, "ten seconds and nobody came");
    let (_, by_breaker, health) = down(Some(1));
    // Down on tick 0; the revive runs from tick 0 and completes after 90.
    assert_eq!(by_breaker, Some(h::REVIVE_TICKS), "an ally: three seconds");
    assert_eq!(health, 120 * 30 / 100, "back at 30% of full health (§12.20)");
    let (_, by_mender, _) = down(Some(4));
    assert_eq!(by_mender, Some(h::MENDER_REVIVE_TICKS), "a Mender: one and a half");
}

#[test]
fn an_ambush_knocks_out_every_role_of_guard_after_a_two_second_takedown() {
    // §12.8 (v3.3): the first hit on an Unaware guard "knocks it out,
    // whatever its role or level ... a build test asserts it for all
    // twenty-five pairings of attacker and guard role". §29.1: "a knockout
    // ... after a 2 s takedown". This is that build test.
    let roles = [Role::Scout, Role::Warden, Role::Breaker, Role::Carrier, Role::Mender];
    for (row, guard_role) in roles.iter().enumerate() {
        for attacker in roles {
            let mut world = vault_world(1);
            let gi = post(&mut world, row, 3, 3);
            world.guards[gi].facing = Ang::from_degrees(270);   // north, away
            world.raiders[0].role = attacker;
            put(&mut world, 0, 3, 4);                          // behind it
            world.raiders[0].task = Task::Attack;
            world.raiders[0].target = gi as u32;
            for _ in 0..(h::TAKEDOWN_TICKS - 1) {
                world.step();
            }
            assert!(!world.guards[gi].knocked_out, "{attacker:?} on {guard_role:?}: not before 2 s");
            world.step();
            assert!(world.guards[gi].knocked_out, "{attacker:?} on {guard_role:?}: down at 2 s");
            assert_eq!(world.guards[gi].health, 0, "exactly what it had left");
            assert!(!world.alarm_raised, "an ambush raises nothing");
        }
    }
}

#[test]
fn a_guard_that_notices_mid_takedown_takes_an_ordinary_hit() {
    // "The guard must still be Unaware when the hit lands." Past the 0.8 s
    // an ordinary swing needs, the swing lands at once, for Power.
    let mut world = vault_world(1);
    let gi = post(&mut world, 1, 3, 3);           // the Warden, 420
    put(&mut world, 0, 3, 4);
    world.raiders[0].task = Task::Attack;
    world.raiders[0].target = gi as u32;
    for _ in 0..TICKS_PER_SECOND {
        world.step();
    }
    world.guards[gi].state = State::Suspicious;   // it turns, a second in
    world.guards[gi].suspicion = 400;
    world.guards[gi].state_since = world.tick;
    world.step();
    assert!(!world.guards[gi].knocked_out);
    assert_eq!(world.guards[gi].health, 420 - 12, "the Scout's Power, not a knockout");
}

#[test]
fn an_open_hit_sends_suspicion_straight_to_1000() {
    let mut world = vault_world(1);
    let gi = post(&mut world, 1, 3, 3);
    // Searching, facing away: it has noticed the crew, so this is no ambush,
    // and its suspicion has drained to nothing by the time the hit lands.
    world.guards[gi].state = State::Searching;
    world.guards[gi].suspicion = 300;
    put(&mut world, 0, 3, 4);
    world.raiders[0].task = Task::Attack;
    world.raiders[0].target = gi as u32;
    for _ in 0..h::HIT_TICKS {
        world.step();
    }
    assert_eq!(world.guards[gi].health, 420 - 12, "Power, not an ambush");
    assert_eq!(world.guards[gi].suspicion, SUSPICION_MAX);
}

#[test]
fn a_knocked_out_guard_found_by_another_raises_the_realm_alarm() {
    // §12.17: "once per knocked-out guard discovered".
    let mut world = vault_world(0);
    let seer = post(&mut world, 0, 3, 6);         // a Scout, facing north
    let down = post(&mut world, 1, 3, 3);         // three tiles in front of it
    world.guards[down].knocked_out = true;
    world.step();
    assert!(world.guards[down].found);
    assert_eq!(world.knockouts_discovered, 1);
    assert_eq!(world.alarm, 1, "the alarm climbs with it");
    world.step();
    assert_eq!(world.knockouts_discovered, 1, "found once, counted once");
    let _ = seer;
}

#[test]
fn a_body_in_tall_grass_is_not_found() {
    // §12.8 (v3.3): "a body is seen exactly as a still crew member lying on
    // its tile would be, so tall grass ... hides it".
    let mut world = vault_world(0);
    post(&mut world, 0, 3, 6);                    // a Scout, facing north
    let down = post(&mut world, 1, 3, 3);         // three tiles in front of it
    world.grid.place(3, 3, Feature::TallGrass);
    world.guards[down].knocked_out = true;
    for _ in 0..TICKS_PER_SECOND {
        world.step();
    }
    assert!(!world.guards[down].found);
    assert_eq!(world.knockouts_discovered, 0);
}

#[test]
fn a_dragged_body_goes_with_its_dragger_at_crouching_speed() {
    // "A crew member can drag a body at crouching speed and hide it."
    let mut world = vault_world(1);
    let down = post(&mut world, 1, 3, 3);
    world.guards[down].knocked_out = true;
    put(&mut world, 0, 3, 4);
    world.raiders[0].gait = Gait::Run;            // whatever the gait
    world.raiders[0].task = Task::Drag;
    world.raiders[0].target = down as u32;
    let from = world.grid.index(3, 4).unwrap();
    let to = world.grid.index(3, 10).unwrap();
    world.raiders[0].route = path::find(&world.grid, from, to).unwrap();
    world.step();
    let r = &world.raiders[0];
    let crouched = crate::step_for(&world.grid, &world.sheet, r, Gait::Crouch, Some(from), false);
    let (_, y0) = world.grid.centre(from);
    // Within a millionth of a tile: the step is walked along a bearing, and
    // the cosine carries its own last-bit rounding.
    let moved = world.raiders[0].at.y - y0;
    assert!((moved - crouched).0.abs() < 1 << 12, "one tick at crouching speed, not running: \
            {moved:?} against {crouched:?}");
    assert_eq!(world.guards[down].at, world.raiders[0].at, "and the body with it");
    for _ in 0..(10 * TICKS_PER_SECOND) {
        world.step();
    }
    assert_eq!(world.grid.tile_at(world.guards[down].at.x, world.guards[down].at.y), Some(to),
               "left where the dragger stopped");
}

#[test]
fn a_posted_guard_holds_its_facing() {
    let mut world = vault_world(0);
    let gi = post(&mut world, 0, 3, 3);
    let facing = world.guards[gi].facing;
    for _ in 0..90 {
        world.step();
    }
    assert_eq!(world.guards[gi].facing, facing, "holds its post, facing where posted");
}

#[test]
fn a_crouched_step_up_behind_a_guard_is_heard_unless_it_is_on_moss() {
    // A crouched walk carries 1 m (§12.17), and the tile behind a guard is 1 m
    // from it — so on plain ground the last step of an approach is heard,
    // the guard has noticed, and §12.8's ambush ("a guard that has not
    // noticed the crew") cannot be reached. Moss, x0.75, carries it nowhere.
    let approach = |surface: Surface| {
        let mut world = vault_world(1);
        let gi = post(&mut world, 1, 3, 3);       // facing north
        world.grid.set_surface(3, 4, surface);
        put(&mut world, 0, 3, 6);
        world.raiders[0].gait = Gait::Crouch;
        let from = world.grid.index(3, 6).unwrap();
        let to = world.grid.index(3, 4).unwrap();
        world.raiders[0].route = path::find(&world.grid, from, to).unwrap();
        for _ in 0..(3 * TICKS_PER_SECOND) {
            world.step();
        }
        world.guards[gi].state
    };
    assert_ne!(approach(Surface::Plain), State::Unaware, "heard on the last step");
    assert_eq!(approach(Surface::Moss), State::Unaware, "silent on moss");
}

#[test]
fn the_planned_heist_ends_clean_with_every_bag_full() {
    let heist = planned();
    let mut world = World::from_heist(&heist);
    for _ in 0..heist.ticks {
        world.step();
    }
    let o = world.outcome();
    assert_eq!(o.grade, Grade::Clean, "{o:?}");
    assert_eq!(o.banked, o.capacity, "every bag full");
    assert_eq!(world.guards.iter().filter(|g| g.knocked_out).count(), 4,
               "four guards taken down; the Warden on its rise is out of reach");
    assert_eq!(world.knockouts_discovered, 0, "and nobody found them");
    assert_eq!(world.guards[1].state, State::Unaware,
               "the Vault opened before five seconds of cracking, so the Warden never heard it");
    assert_eq!(o.pages, 1, "Haste's pylon broken on the way in: a page of it");
    assert!(heist.size_fits());
}

// --------------------------------------------------------------------------
// Laws and pylons (§7.3, §12.6, §12.21)
// --------------------------------------------------------------------------

use crate::laws_table::{Param, LAWS};
use crate::Sheet;

#[test]
fn every_law_is_in_the_table_and_the_sheet_multiplies_the_ones_that_stand() {
    assert_eq!(LAWS.len(), 48, "\u{a7}7's 48 laws");
    let mut world = vault_world(0);
    world.weave(&[("tilt", (0, 13)), ("current", (1, 13))]);
    // Both carry Flow, so they harmonise (§8.2): each 1.3 is a quarter
    // stronger, 1.375, and the sheet multiplies them exactly.
    assert_eq!(world.sheet.factor(Param::CrewSpeed), (121, 64), "1.375 x 1.375, exactly");
    world.laws[0].broken_at = Some(0);
    world.step();
    assert_eq!(world.sheet.factor(Param::CrewSpeed), (13, 10), "one pylon down");
    assert_eq!(Sheet::plain().factor(Param::CrewSpeed), (1, 1));
}

#[test]
fn haste_runs_everyone_and_the_clock_a_quarter_fast() {
    // "Everyone moves 25% faster, and the heist clock runs 25% faster."
    let mut world = vault_world(1);
    world.weave(&[("haste", (0, 13))]);
    world.clock = 100;
    let mut ticks = 0;
    while world.raiders[0].standing == Standing::Active {
        world.step();
        ticks += 1;
    }
    assert_eq!(ticks, 80, "a 100-tick clock ends at tick 80");
    assert_eq!(world.sheet.factor(Param::GuardSpeed), (5, 4));
}

#[test]
fn glowing_dark_halves_sight_and_sleepwalk_closes_the_guards_eyes() {
    let with = |law: &str, tenths: i64| {
        let mut world = scout_and_raider(tenths, 0);
        world.weave(&[(law, (0, 13))]);
        rate(&world)
    };
    // The Scout's zones are 2, 4 and 6 m; halved, 1, 2 and 3.
    assert_eq!(with("glowing_dark", 15), Some(33), "1.5 m: mid, not near");
    assert_eq!(with("glowing_dark", 50), None, "5 m: out of sight");
    assert_eq!(with("sleepwalk", 15), None, "eyes closed");
}

#[test]
fn glass_lets_a_guard_see_through_a_wall() {
    let behind = |law: Option<&str>| {
        let mut world = scout_and_raider(30, 0);
        world.grid.place(7, 6, Feature::RockPillar);  // between them
        if let Some(l) = law {
            world.weave(&[(l, (0, 13))]);
        }
        rate(&world)
    };
    assert_eq!(behind(None), None, "the pillar hides the raider");
    assert_eq!(behind(Some("glass")), Some(33), "\"nobody can hide behind them\"");
}

#[test]
fn stillness_hides_whoever_stands_still_for_a_second_and_a_half() {
    let mut world = scout_and_raider(15, 0);
    world.weave(&[("stillness", (0, 13))]);
    world.guards[0].facing = Ang::from_degrees(180);  // away, so it stays calm
    for _ in 0..(h::STILL_TICKS - 1) {
        world.step();
    }
    world.guards[0].facing = Ang::from_degrees(0);
    assert_eq!(rate(&world), Some(67), "still for less than 1.5 s: seen");
    world.step();
    world.guards[0].facing = Ang::from_degrees(0);
    assert_eq!(rate(&world), None, "still for 1.5 s: invisible");
}

#[test]
fn brittle_stone_doubles_every_hit_on_a_structure() {
    let hit = |law: Option<&str>| {
        let mut world = vault_world(2);
        if let Some(l) = law {
            world.weave(&[(l, (0, 13))]);
        }
        put(&mut world, 1, 7, 6);
        world.raiders[1].task = Task::Crack;
        for _ in 0..h::HIT_TICKS {
            world.step();
        }
        1500 - world.vault.health
    };
    assert_eq!(hit(None), 80, "a Breaker: twice its 40");
    assert_eq!(hit(Some("brittle_stone")), 160, "and twice again");
}

#[test]
fn whispers_carries_an_alert_to_every_guard() {
    // "When one guard raises the alarm, every guard in the universe hears it."
    let spread = |law: Option<&str>| {
        let mut world = vault_world(0);
        if let Some(l) = law {
            world.weave(&[(l, (0, 13))]);
        }
        let a = post(&mut world, 0, 1, 1);
        post(&mut world, 1, 12, 12);              // far beyond 4 m
        world.enter(a, State::Alerted);
        for _ in 0..(guard::SPREAD_DELAY_TICKS + 1) {
            world.step();
        }
        world.guards[1].state
    };
    assert_eq!(spread(None), State::Unaware, "4 m, and it is further");
    assert_eq!(spread(Some("whispers")), State::Investigating);
}

#[test]
fn breaking_a_pylon_switches_its_law_off_and_earns_its_page() {
    // §10.2: a level-1 pylon has 600 health. A Breaker deals twice its 40.
    let mut world = vault_world(2);
    world.weave(&[("haste", (3, 3))]);
    put(&mut world, 1, 3, 4);
    let tile = world.grid.index(3, 3).unwrap();
    world.raiders[1].task = Task::Break;
    world.raiders[1].target = tile;
    let mut broke = None;
    for _ in 0..(10 * h::HIT_TICKS) {
        world.step();
        if broke.is_none() && world.laws[0].broken_at.is_some() {
            broke = Some(world.tick);
            assert_eq!(world.sheet.factor(Param::CrewSpeed), (5, 4),
                       "still in force on the tick it breaks");
        }
    }
    assert_eq!(broke, Some(8 * h::HIT_TICKS), "600 / 80: eight hits");
    assert_eq!(world.sheet.factor(Param::CrewSpeed), (1, 1), "off from the next tick");
    assert_eq!(world.outcome().pages, 1);
}

#[test]
fn a_replay_carries_the_laws_it_was_made_under() {
    // §24.11: "Every island and every replay records the exact set of laws it
    // was made under." Which laws a realm runs, and where their pylons stand,
    // are the island's, so they are in the island's hash; what each law does
    // is the rules version's. Both are in the header.
    use crate::island::Island;
    let heist = planned();
    assert_eq!(heist.island, Island::fixture().digest());
    assert_eq!(heist.rules, crate::rules_version());
    let mut fewer = Island::fixture();
    fewer.laws.pop();
    assert_ne!(fewer.digest(), Island::fixture().digest(), "a law fewer");
    let mut moved = Island::fixture();
    moved.laws[0].2 += 1;
    assert_ne!(moved.digest(), Island::fixture().digest(), "and where its pylon stands");
}

// --------------------------------------------------------------------------
// The escape (§12.6): loading to what the clock affords, and dropping loot
// --------------------------------------------------------------------------

#[test]
fn loading_stops_when_the_clock_left_only_covers_getting_out() {
    // §12.6: "the crew loads to whatever that target and the remaining clock
    // afford". With no skiff called, getting out is the nearest edge and the
    // Heart's 20-second skiff: 600 ticks. A 700-tick clock affords loading
    // while more than 600 remain — the first 99 ticks, 99 units.
    let load = |clock: u32| {
        let mut world = vault_world(3);
        world.vault.health = 0;
        world.vault.opened_at = Some(0);
        put(&mut world, 2, 6, 5);                 // the Carrier, beside it
        put(&mut world, 0, 13, 13);
        put(&mut world, 1, 12, 13);
        world.raiders[2].task = Task::Load;
        world.clock = clock;
        for _ in 0..200 {
            world.step();
        }
        world.raiders[2].carried
    };
    assert_eq!(load(700), 99, "stops when the clock no longer covers the skiff");
    assert_eq!(load(u32::MAX), 200, "with no clock, 30 a second throughout");
}

#[test]
fn dropping_loot_costs_exactly_the_fraction_dropped() {
    // §12.19: "Dropping loot to run faster costs exactly the fraction
    // dropped." A Carrier with 300 drops half: 150 stays on the tile, and it
    // is still loaded, so still 15% slower. Dropping all of it frees its pace.
    let mut world = vault_world(3);
    put(&mut world, 2, 3, 3);
    world.raiders[2].carried = 300;
    world.commands_for_test(vec![
        Command { tick: 0, actor: 2, kind: Kind::Drop, x: 50, y: 0 },
        Command { tick: 1, actor: 2, kind: Kind::Drop, x: 100, y: 0 },
    ]);
    world.step();
    assert_eq!(world.raiders[2].carried, 150);
    assert_eq!(world.dropped, vec![(world.grid.index(3, 3).unwrap(), 150)]);
    world.step();
    assert_eq!(world.raiders[2].carried, 0);
    let sheet = world.sheet;
    let r = &world.raiders[2];
    assert_eq!(crate::step_for(&world.grid, &sheet, r, r.gait, None, false), Role::Carrier.speed(),
               "empty-handed: \u{a7}11.1's full 3.6 tiles a second");
}

#[test]
fn kinship_heals_whoever_stands_beside_an_ally() {
    // "Characters standing next to an ally heal each other 1.5% a second."
    let mut world = vault_world(4);
    world.weave(&[("kinship", (0, 13))]);
    put(&mut world, 3, 3, 3);                     // the Warden, 420
    put(&mut world, 1, 3, 4);                     // the Breaker, 180, beside it
    put(&mut world, 0, 10, 10);                   // the Scout, alone
    put(&mut world, 2, 10, 12);
    for ri in 0..4 {
        world.raiders[ri].health = 50;
    }
    world.step();                                 // tick 0: once a second
    assert_eq!(world.raiders[3].health, 50 + 6, "1.5% of 420, rounded down");
    assert_eq!(world.raiders[1].health, 50 + 2, "1.5% of 180");
    assert_eq!(world.raiders[0].health, 50, "nobody beside the Scout");
}

#[test]
fn regrowth_heals_guards_pylons_and_the_vault_and_revives_nothing() {
    // "Buildings, wards and guards heal 2% of their health each second."
    let mut world = vault_world(0);
    world.weave(&[("regrowth", (0, 13)), ("haste", (1, 13))]);
    let g = post(&mut world, 2, 3, 3);            // the Breaker guard, 180
    let down = post(&mut world, 1, 9, 9);
    world.guards[g].health = 100;
    world.guards[down].knocked_out = true;
    world.guards[down].health = 0;
    world.vault.health = 1000;
    world.laws[0].health = 300;
    world.laws[1].health = 0;
    world.laws[1].broken_at = Some(0);
    world.step();
    assert_eq!(world.guards[g].health, 100 + 3, "2% of 180");
    assert_eq!(world.guards[down].health, 0, "knocked out stays down");
    assert_eq!(world.vault.health, 1000 + 30, "2% of 1,500");
    assert_eq!(world.laws[0].health, 300 + 12, "2% of a pylon's 600");
    assert_eq!(world.laws[1].health, 0, "a broken pylon is not rebuilt");
}

#[test]
fn rb28_regrowth_heals_a_vault_up_to_its_own_levels_health() {
    // RB-28: §12.6 gives a Vault 1,500 health a level, and Regrowth heals
    // "2% of their health each second": a level-10 Vault's 15,000, not a
    // level-1 Vault's 1,500.
    use crate::island::Island;
    let mut island = Island::example();
    island.vault_level = 10;
    let mut world = World::on_ground(&island, 3, vec![]);
    world.weave(&[("regrowth", (0, 0))]);
    assert_eq!(world.vault.health, 15_000);
    world.step();
    assert_eq!(world.vault.health, 15_000, "an untouched Vault stays at full health");
    world.vault.health = 10_000;
    for _ in 0..crate::TICKS_PER_SECOND {
        world.step();
    }
    assert_eq!(world.vault.health, 10_000 + 300, "2% of 15,000");
}

// --------------------------------------------------------------------------
// Wards (§10.3, as spec/wards.md reads them at level 1)
// --------------------------------------------------------------------------

use crate::heist::WardKind;

fn ward_world(crew: u8, kind: WardKind, at: (u16, u16)) -> World {
    let mut world = vault_world(crew);
    world.place_wards(&[(kind, at)]);
    world
}

#[test]
fn a_time_snare_freezes_the_first_to_step_on_it_then_waits_twelve_seconds() {
    let mut world = ward_world(2, WardKind::TimeSnare, (3, 3));
    put(&mut world, 0, 3, 3);                     // on it
    put(&mut world, 1, 3, 4);                     // beside it, not on it
    world.step();
    assert_eq!(world.raiders[0].frozen_until, h::SNARE_FREEZE_TICKS, "2.5 s from tick 0");
    assert_eq!(world.raiders[1].frozen_until, 0, "only the first to step on it");
    assert_eq!(world.wards[0].armed_at, 12 * TICKS_PER_SECOND, "\u{a7}10.3's 12 s (C32)");
    // Frozen means it does not walk its route.
    let before = world.raiders[0].at;
    world.raiders[0].route = vec![world.grid.index(4, 3).unwrap()];
    for _ in 0..30 {
        world.step();
    }
    assert_eq!(world.raiders[0].at, before, "frozen: no step");
}

#[test]
fn a_gravity_well_pulls_everyone_within_three_tiles_and_holds_them_two_seconds() {
    let mut world = ward_world(3, WardKind::GravityWell, (6, 3));
    put(&mut world, 0, 8, 3);                     // 2 tiles away
    put(&mut world, 1, 6, 0);                     // 3 tiles away
    put(&mut world, 2, 11, 3);                    // 5 away: out of reach
    let goal = world.grid.index(13, 3).unwrap();
    let from = world.grid.index(8, 3).unwrap();
    world.raiders[0].route = path::find(&world.grid, from, goal).unwrap();
    world.step();
    let (cx, cy) = world.grid.centre(world.grid.index(6, 3).unwrap());
    assert_eq!(world.raiders[0].at, Point { x: cx, y: cy }, "pulled to its centre");
    assert_eq!(world.raiders[1].at, Point { x: cx, y: cy });
    assert_ne!(world.raiders[2].at, Point { x: cx, y: cy }, "five tiles off: untouched");
    assert_eq!(world.raiders[0].frozen_until, h::WELL_HOLD_TICKS);
    assert_eq!(world.raiders[0].route.last(), Some(&goal),
               "still going where it was told, from where it now is");
}

#[test]
fn a_static_coil_shocks_everyone_within_two_tiles_every_three_seconds() {
    let mut world = ward_world(2, WardKind::StaticCoil, (6, 6));
    put(&mut world, 0, 6, 8);                     // 2 tiles
    put(&mut world, 1, 6, 9);                     // 3 tiles
    for _ in 0..=h::COIL_PERIOD_TICKS {
        world.step();
    }
    assert_eq!(world.raiders[0].health, 120 - 120 * 8 / 100, "8% of the Scout's 120");
    assert_eq!(world.raiders[1].health, 180, "out of reach");
}

#[test]
fn a_thorn_hedge_hurts_whoever_pushes_through_five_percent_a_second() {
    let mut world = ward_world(2, WardKind::ThornHedge, (3, 3));
    put(&mut world, 1, 3, 3);                     // the Breaker, 180, in it
    for _ in 0..=TICKS_PER_SECOND {
        world.step();
    }
    assert_eq!(world.raiders[1].health, 180 - 2 * 9, "two ticks on a second boundary: 9 each");
}

#[test]
fn a_lantern_glare_shows_the_crew_to_the_guards_within_4_m_and_blinds_it() {
    // F33, decided: a Glare shows the crew "to every guard within 4 m of it",
    // where §10.3 still reads "every guard in the realm". Both guards face
    // away; only the near one is shown the crew.
    let mut world = ward_world(1, WardKind::LanternGlare, (3, 3));
    let near = post(&mut world, 1, 3, 7);         // four tiles south
    let far = post(&mut world, 1, 12, 12);        // across the realm
    for gi in [near, far] {
        world.guards[gi].facing = Ang::from_degrees(90);   // south, away
    }
    put(&mut world, 0, 3, 3);
    world.step();
    assert_eq!(world.revealed_until(), h::GLARE_REVEAL_TICKS);
    assert_eq!(world.raiders[0].frozen_until, h::GLARE_BLIND_TICKS, "blinded for 2 s");
    for _ in 0..20 {
        world.step();
    }
    assert!(world.guards[near].state.rank() >= State::Investigating.rank(),
            "within 4 m, shown the crew");
    assert_eq!(world.guards[far].state, State::Unaware, "across the realm, not");
    assert_eq!(world.guards[far].suspicion, 0);
}

#[test]
fn a_lantern_glares_reach_is_4_m_whatever_the_alarms_reach() {
    // F52, decided: a fixed 4 m, which Whispers — the whole universe for the
    // alarm — does not stretch. In the first ticks after the Glare fires, the
    // guard across the realm is shown nothing while the near one is.
    let mut world = ward_world(1, WardKind::LanternGlare, (3, 3));
    world.weave(&[("whispers", (0, 13))]);
    let near = post(&mut world, 1, 3, 7);
    let far = post(&mut world, 1, 12, 12);
    for gi in [near, far] {
        world.guards[gi].facing = Ang::from_degrees(90);
    }
    put(&mut world, 0, 3, 3);
    for _ in 0..3 {
        world.step();
    }
    assert!(world.revealed_until() > 0, "the Glare fired");
    assert!(world.guards[near].suspicion > 0, "within 4 m, shown the crew");
    assert_eq!(world.guards[far].suspicion, 0, "Whispers does not carry the Glare across the realm");
}

#[test]
fn a_crystal_wall_blocks_until_it_is_broken() {
    let mut world = ward_world(2, WardKind::CrystalWall, (3, 3));
    let wall = world.grid.index(3, 3).unwrap();
    assert!(!world.grid.at(wall).passable(), "a wall");
    put(&mut world, 1, 3, 4);                     // the Breaker, beside it
    world.raiders[1].task = Task::Break;
    world.raiders[1].target = wall;
    let mut hits = 0;
    while world.grid.at(wall) != crate::grid::Terrain::Open && hits < 50 {
        for _ in 0..h::HIT_TICKS {
            world.step();
        }
        hits += 1;
    }
    assert_eq!(hits, 10, "800 health, 80 a hit");
    assert!(world.wards[0].broken);
    assert!(!world.grid.blocks_sight(wall), "and open to the eye");
}

#[test]
fn disarming_takes_fifteen_seconds_on_the_tile_is_silent_and_stepping_off_restarts_it() {
    // §10.3 (v3.3): "stands on the ward's tile for 15 seconds at every ward
    // level ... stepping off starts it again. Disarming makes no noise." A
    // Static Coil, whose shock does not stop the disarmer: 5 of them, 40%.
    let mut world = ward_world(1, WardKind::StaticCoil, (3, 3));
    let coil = world.grid.index(3, 3).unwrap();
    let g = post(&mut world, 1, 3, 6);
    world.guards[g].facing = Ang::from_degrees(90);
    put(&mut world, 0, 3, 3);
    world.raiders[0].task = Task::Disarm;
    world.raiders[0].target = coil;
    for _ in 0..(10 * TICKS_PER_SECOND) {
        world.step();
    }
    put(&mut world, 0, 3, 4);                     // steps off
    world.step();
    assert_eq!(world.wards[0].disarm, 0, "stepping off starts it again");
    put(&mut world, 0, 3, 3);
    for _ in 0..(h::DISARM_TICKS - 1) {
        world.step();
    }
    assert!(!world.wards[0].disarmed, "not before fifteen seconds");
    world.step();
    assert!(world.wards[0].disarmed, "fifteen seconds on the tile");
    assert_eq!(world.guards[g].state, State::Unaware, "silent");
}

#[test]
fn a_ward_ignores_the_crew_member_disarming_it_and_fires_on_anyone_else() {
    // §10.3 (v3.4, G16): "While it disarms, the ward's sensor ignores that
    // crew member, so every known ward can be disarmed; it still fires on
    // anyone else in reach." v3.3 said nothing, and a Time Snare froze its
    // own disarmer twice in a fifteen-second job.
    let mut world = ward_world(2, WardKind::TimeSnare, (3, 3));
    let snare = world.grid.index(3, 3).unwrap();
    put(&mut world, 0, 3, 3);
    world.raiders[0].task = Task::Disarm;
    world.raiders[0].target = snare;
    put(&mut world, 1, 3, 3);                     // a second member, not disarming
    world.step();
    assert!(world.raiders[1].frozen_until > world.tick, "it fires on anyone else");
    assert!(world.raiders[0].frozen_until <= world.tick, "and not on its disarmer");
    put(&mut world, 1, 6, 6);
    for _ in 0..h::DISARM_TICKS {
        world.step();
    }
    assert!(world.wards[0].disarmed, "fifteen seconds of work, never frozen");
}

#[test]
fn a_glare_still_fires_on_a_disarmer_walking_to_it() {
    // G18: the sensor ignores a crew member "while it disarms", and a
    // disarmer stands on the tile. A Lantern Glare's reach is two tiles, so
    // the walk there crosses it, and nothing in §10.3 covers the walk.
    let mut world = ward_world(1, WardKind::LanternGlare, (3, 3));
    let glare = world.grid.index(3, 3).unwrap();
    put(&mut world, 0, 3, 5);                     // two tiles off, on its way
    world.raiders[0].task = Task::Disarm;
    world.raiders[0].target = glare;
    world.step();
    assert!(world.wards[0].armed_at > world.tick, "the Glare fired on the way in");
}

#[test]
fn two_lantern_glares_each_show_the_crew_around_their_own_tile() {
    // The second Glare to fire does not take the first's reveal away: a
    // guard beside the first is still shown the crew after the second fires.
    let mut world = vault_world(1);
    world.place_wards(&[(WardKind::LanternGlare, (3, 3)), (WardKind::LanternGlare, (12, 12))]);
    let first = post(&mut world, 1, 3, 7);        // four tiles from the first
    let far = post(&mut world, 1, 7, 12);         // five from the second
    for gi in [first, far] {
        world.guards[gi].facing = Ang::from_degrees(180);  // west, away from (12, 12)
    }
    put(&mut world, 0, 3, 3);
    world.step();
    assert_eq!(world.glares.len(), 1);
    put(&mut world, 0, 12, 12);
    world.raiders[0].frozen_until = 0;
    world.step();
    assert_eq!(world.glares.len(), 2, "both reveals held");
    world.guards[first].suspicion = 0;
    world.guards[first].state = State::Unaware;
    for _ in 0..20 {
        world.step();
    }
    assert!(world.guards[first].suspicion > 0, "the first Glare's guard is still shown the crew");
    assert_eq!(world.guards[far].suspicion, 0, "beyond both reaches, not");
}

#[test]
fn a_lantern_glare_fires_when_a_crew_member_comes_within_two_tiles() {
    // §10.3 (v3.3): "Triggered: a crew member comes within 2 tiles".
    let at = |x: u16, y: u16| {
        let mut world = ward_world(1, WardKind::LanternGlare, (3, 3));
        put(&mut world, 0, x, y);
        world.step();
        world.revealed_until()
    };
    assert_eq!(at(3, 5), h::GLARE_REVEAL_TICKS, "two tiles away: it fires");
    assert_eq!(at(3, 6), 0, "three tiles away: it does not");
}

#[test]
fn smashing_a_ward_is_loud_and_a_breaker_does_it_in_seven_hits() {
    // §10.3: 550 health at level 1, smashed "in about 6 seconds"; §11.1:
    // Breakers double, 80 a hit, so seven hits — 5.6 seconds.
    let mut world = ward_world(2, WardKind::StaticCoil, (3, 3));
    let coil = world.grid.index(3, 3).unwrap();
    put(&mut world, 1, 2, 3);
    world.raiders[1].task = Task::Break;
    world.raiders[1].target = coil;
    for _ in 0..(7 * h::HIT_TICKS) {
        world.step();
    }
    assert!(world.wards[0].broken, "560 >= 550");
}

// --------------------------------------------------------------------------
// Height (§6.2's raised ground, §12.17's higher and lower ground)
// --------------------------------------------------------------------------

#[test]
fn climbing_a_level_needs_a_ramp_and_dropping_is_free_and_one_way() {
    let mut grid = Grid::new(6, 3);
    for y in 0..3 {
        grid.set_height(3, y, 1);
        grid.set_height(4, y, 1);
        grid.set_height(5, y, 1);
    }
    let low = grid.index(1, 1).unwrap();
    let high = grid.index(4, 1).unwrap();
    assert!(path::find(&grid, low, high).is_none(), "a cliff: no way up");
    assert!(path::find(&grid, high, low).is_some(), "and a free way down");
    grid.make_climbable(3, 0);
    let up = path::find(&grid, low, high).expect("a ramp makes it climbable");
    assert!(up.contains(&grid.index(3, 0).unwrap()), "by way of the ramp");
    // Two levels at once is a cliff even with a ramp.
    grid.set_height(4, 1, 3);
    let (a, b) = (grid.index(3, 1).unwrap(), grid.index(4, 1).unwrap());
    assert!(!grid.can_step(a, b), "1 to 3 is not a climb");
    assert!(grid.can_step(b, a), "3 to 1 is a drop");
}

#[test]
fn honeycomb_lets_anyone_climb_one_level() {
    // "everyone moves 20% slower but can climb walls and cliffs one level."
    let mut world = vault_world(1);
    world.weave(&[("honeycomb", (0, 13))]);
    for y in 0..14 {
        world.grid.set_height(9, y, 1);
    }
    world.step();
    let (a, b) = (world.grid.index(8, 4).unwrap(), world.grid.index(9, 4).unwrap());
    assert!(world.grid.can_step(a, b), "up a level with no ramp");
}

#[test]
fn a_guard_a_level_up_sees_a_metre_further_and_one_below_loses_its_far_zone() {
    // The Scout's far zone ends at 6 m. At 6.5 m, level ground: nothing.
    let at = |guard_h: u8, raider_h: u8, tenths: i64| {
        let mut world = scout_and_raider(tenths, 0);
        let g = world.grid.tile_at(world.guards[0].at.x, world.guards[0].at.y).unwrap();
        let r = world.grid.tile_at(world.raiders[0].at.x, world.raiders[0].at.y).unwrap();
        let (gx, gy) = world.grid.coords(g);
        let (rx, ry) = world.grid.coords(r);
        world.grid.set_height(gx, gy, guard_h);
        world.grid.set_height(rx, ry, raider_h);
        rate(&world)
    };
    assert_eq!(at(0, 0, 65), None, "6.5 m on level ground: beyond the far zone");
    assert_eq!(at(1, 0, 65), Some(12), "a level up: a metre further, still the far rate");
    assert_eq!(at(0, 0, 50), Some(12), "5 m on level ground: far zone");
    assert_eq!(at(0, 1, 50), None, "looking up: no far zone at all");
    assert_eq!(at(0, 1, 35), Some(33), "but the mid zone still sees");
}

#[test]
fn a_drop_is_heard_two_metres_off_for_one_level_and_four_for_three() {
    use crate::noise::Sound as S2;
    assert_eq!(S2::LandingOne.steps(), 2, "\u{a7}12.17: landing from one level, 2 m");
    assert_eq!(S2::LandingThree.steps(), 4, "from three, 4 m");
    // In the world: a Scout drops a level beside a guard facing away three
    // steps off. A walk there carries two steps; the landing carries two too,
    // so put the guard two steps away and walk crouched — only the landing
    // can reach it.
    let wakes = |drop: bool| {
        let mut world = vault_world(1);
        if drop {
            world.grid.set_height(3, 3, 1);
        }
        let g = post(&mut world, 1, 3, 6);
        world.guards[g].facing = Ang::from_degrees(90);  // away
        put(&mut world, 0, 3, 3);
        world.raiders[0].gait = Gait::Crouch;              // carries 1 step
        world.raiders[0].route = vec![world.grid.index(3, 4).unwrap()];
        for _ in 0..40 {
            world.step();
        }
        world.guards[g].state
    };
    assert_eq!(wakes(false), State::Unaware, "a crouched step carries one tile");
    assert_eq!(wakes(true), State::Investigating, "the landing carries two");
}



// --------------------------------------------------------------------------
// The server's half: SHA-256, the island bundle, the rules version and the
// validator (§24.8, §24.11, §24.12)
// --------------------------------------------------------------------------

fn hex(d: &[u8; 32]) -> String {
    crate::sha256::hex(d)
}

#[test]
fn sha256_gives_the_standards_answers() {
    use crate::sha256::sha256;
    // FIPS 180-4's examples, and the empty message: one block, two blocks, and
    // the padding edge where the length no longer fits the first block.
    assert_eq!(hex(&sha256(b"")),
               "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    assert_eq!(hex(&sha256(b"abc")),
               "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    assert_eq!(hex(&sha256(b"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")),
               "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
    assert_eq!(hex(&sha256(&vec![b'a'; 1_000_000])),
               "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0");
    assert_eq!(hex(&sha256(&[0u8; 55])).len(), 64);
    assert_ne!(sha256(&[0u8; 55]), sha256(&[0u8; 56]));
}

#[test]
fn an_island_is_one_encoding_and_one_hash() {
    use crate::island::Island;
    for island in [Island::fixture(), Island::example()] {
        let bytes = island.encode();
        let back = Island::decode(&bytes).expect("an island decodes what it encodes");
        assert_eq!(back, island);
        assert_eq!(back.encode(), bytes);
        assert_eq!(back.digest(), crate::sha256::sha256(&bytes));
    }
    assert_ne!(Island::fixture().digest(), Island::example().digest());
}

#[test]
fn an_exposure_above_i32_max_is_refused() {
    use crate::island::{Island, Malformed};
    let mut b = Island::example().encode();
    b[6..10].copy_from_slice(&0x8000_0000u32.to_le_bytes());
    assert_eq!(Island::decode(&b), Err(Malformed::Exposed));
    b[6..10].copy_from_slice(&(i32::MAX as u32).to_le_bytes());
    assert!(Island::decode(&b).is_ok());
}

#[test]
fn a_second_encoding_of_an_island_is_refused() {
    use crate::island::{Island, Malformed};
    let good = Island::example().encode();
    let tile0 = 4 + 10;                  // the first tile's three bytes
    // Past the laws comes only a list of buildings (§10.1), then one of
    // tunnels (TD.38), and past that nothing.
    let mut trailing = good.clone();
    trailing.extend_from_slice(&[1, 2, 0, 0, 1, 0, 0, 2, 0, 0]);
    assert_eq!(Island::decode(&trailing), Err(Malformed::TrailingBytes));
    trailing.truncate(good.len() + 1);
    trailing[good.len()] = 0;
    assert_eq!(Island::decode(&trailing), Err(Malformed::NoBuildings));
    trailing.extend_from_slice(&[0]);
    assert_eq!(Island::decode(&trailing), Err(Malformed::Tunnel), "a tunnels list of none");
    let mut hundred = good.clone();
    hundred[tile0 + 1] = 100;            // a pace of 100 is written as 0
    assert_eq!(Island::decode(&hundred), Err(Malformed::NonCanonicalPace));
    // Flag bits 2 and 3 are a feature code's high bits (TD.15); bit 4 and
    // above mean nothing.
    let mut flags = good.clone();
    flags[tile0 + 2] = 64;
    assert_eq!(Island::decode(&flags), Err(Malformed::FlagBits));
    // Bits 4 and 5 are a facing, which only a directional feature has.
    flags[tile0 + 2] = 16;
    assert_eq!(Island::decode(&flags), Err(Malformed::FlagBits));
    let mut feature = good.clone();
    feature[tile0] = 15;
    feature[tile0 + 2] = 12;             // code 63, which is no feature
    assert_eq!(Island::decode(&feature), Err(Malformed::UnknownFeature));
    let mut magic = good.clone();
    magic[3] = b'2';
    assert_eq!(Island::decode(&magic), Err(Malformed::Magic));
    let mut off = good.clone();
    off[10] = 12;                        // the Vault's x, on a 12-wide realm
    assert_eq!(Island::decode(&off), Err(Malformed::OffGrid));
    assert_eq!(Island::decode(&good[..good.len() - 1]), Err(Malformed::Truncated));
}

/// SEC-22: a bare tile carries only a pace the rules define, normal (0), mud
/// (60) or a fast path (115). Any other byte made a hand-edited island whose
/// every tile was 1% of normal speed, slower than any honest editor can make.
#[test]
fn a_pace_the_rules_do_not_define_is_refused() {
    use crate::island::{Island, Malformed};
    let good = Island::example().encode();
    let pace = 4 + 10 + 1;               // the first tile's pace byte
    assert!(Island::example().tiles[0].feature.is_none(), "the first tile is open ground");
    for p in [60u8, 115] {
        let mut b = good.clone();
        b[pace] = p;
        assert_eq!(Island::decode(&b).map(|i| i.tiles[0].pace), Ok(p), "pace {p} is defined");
    }
    for p in [1u8, 40, 50, 59, 61, 99, 101, 114, 116, 255] {
        let mut b = good.clone();
        b[pace] = p;
        assert_eq!(Island::decode(&b), Err(Malformed::Pace), "pace {p}");
    }
    // 100 is still the second encoding of normal, refused as before.
    let mut b = good.clone();
    b[pace] = 100;
    assert_eq!(Island::decode(&b), Err(Malformed::NonCanonicalPace));
}

#[test]
fn an_island_keeps_to_5_2_and_6_1_or_is_not_published() {
    use crate::heist::WardKind;
    use crate::island::{Island, Problem};
    assert_eq!(Island::example().check(), vec![]);
    // The fixture is a test realm: every row of §12.17's guards, five posts
    // where §5.2 gives realm level 5 one (v3.7), and its wards where it gives
    // none.
    assert_eq!(Island::fixture().check(), vec![Problem::TooManyWards, Problem::TooManyGuards]);

    let mut crowded = Island::example();
    crowded.wards.push((WardKind::TimeSnare, 6, 9));      // on the Vault
    assert!(crowded.check().contains(&Problem::Crowded));

    // A Crystal Wall in the ruin wall's gap cuts the north edge off from the
    // Vault, but the crew lands on any edge tile (§5.4), and the south edge
    // still walks in: not sealed.
    let mut halved = Island::example();
    halved.wards.push((WardKind::CrystalWall, 9, 5));     // in the wall's gap
    assert_eq!(halved.check(), vec![]);
    // The north edge is still a landing, but not one the Vault can be
    // walked to from, so a default landing never picks it.
    assert!(halved.landings().contains(&(0, 0)));
    assert!(!halved.reaching().contains(&(0, 0)));
    assert!(halved.reaching().contains(&(0, 11)));
    assert!(halved.reaching().iter().all(|t| halved.landings().contains(t)));
    // Walled in on every side, the Vault is sealed from every edge.
    let mut sealed = Island::example();
    let side = sealed.side() as usize;
    for (x, y) in [(6, 8), (5, 9), (6, 10)] {
        sealed.tiles[y * side + x].feature = Some(crate::grid::Feature::RockPillar);
    }
    sealed.wards.push((WardKind::CrystalWall, 7, 9));
    assert_eq!(sealed.check(), vec![Problem::Sealed]);
    assert!(sealed.reaching().is_empty() && !sealed.landings().is_empty());

    let mut many = Island::example();
    many.laws.push(("glass".to_string(), 11, 4));
    assert_eq!(many.check(), vec![Problem::TooManyLaws]);

    let mut unknown = Island::example();
    unknown.laws[0].0 = "no_such_law".to_string();
    assert_eq!(unknown.check(), vec![Problem::UnknownLaw]);

    // One edge tile closed leaves the rest to land on; every one closed
    // leaves nowhere.
    let mut landing = Island::example();
    landing.tiles[2].feature = Some(crate::grid::Feature::RockPillar);   // (2, 0)
    assert_eq!(landing.check(), vec![]);
    assert!(!landing.landings().contains(&(2, 0)));
    let side = landing.side() as usize;
    for i in 0..side * side {
        let (x, y) = (i % side, i / side);
        let edge = x == 0 || y == 0 || x == side - 1 || y == side - 1;
        // A pylon already closes its tile (the one at (11, 2)).
        if edge && landing.occupant(x as u8, y as u8) == crate::island::Occupant::None {
            landing.tiles[i].feature = Some(crate::grid::Feature::RockPillar);
        }
    }
    assert!(landing.landings().is_empty());
    // The entrance, (11, 11), is an edge tile too, now under a pillar (RB-40).
    assert_eq!(landing.check(), vec![Problem::LandingBlocked, Problem::EdgeClosed, Problem::EntranceBlocked]);

    // F51: each side keeps half its tiles open. The north side is twelve
    // tiles; six closed is still half open, seven is not.
    for (closed, problems) in [(6, vec![]), (7, vec![Problem::EdgeClosed])] {
        let mut edge = Island::example();
        for x in 0..closed {
            edge.tiles[x].feature = Some(crate::grid::Feature::RockPillar);
        }
        assert_eq!(edge.check(), problems, "{closed} of the north side closed");
    }
}

#[test]
fn a_verified_heist_reports_where_the_crew_landed_and_was_seen_what_fired_and_who_caught_them() {
    // TD.39: the defender's report and Profile's records read the event log
    // at settlement (§13.2, §23.2), outside the checksum.
    use crate::island::Island;
    use crate::{draw, record, verify_on, verify_report};
    let island = Island::example();
    let mut caught = 0;
    let mut seen = 0;
    for seed in 0..12u64 {
        let heist = record(&island, seed, 4_500, 4, draw(&island, seed, 4_500, 4));
        let (outcome, report) = verify_report(&island, &heist).expect("verified");
        assert_eq!(outcome, verify_on(&island, &heist).expect("verified"), "the same verdict");
        let (lx, ly) = report.landing.expect("a crew always lands");
        let side = island.side() as u8;
        assert!(lx == 0 || ly == 0 || lx == side - 1 || ly == side - 1, "on an edge (5.4)");
        assert!(report.slept as usize <= island.guards.len());
        assert!(report.alerted as usize <= island.guards.len() + 1);
        for &(row, x, y) in &report.caught_by {
            assert!(row == 255 || island.guards.iter().any(|p| (p.row, p.x, p.y) == (row, x, y)), "a post's guard");
        }
        for &(kind, x, y, n) in &report.fired {
            assert!(n > 0 && island.wards.iter().any(|w| *w == (kind, x, y)), "a ward of the island's");
        }
        assert!(report.seen.iter().all(|&(c, x, y)| c < 4 && x < side && y < side));
        caught += report.caught_by.len();
        seen += report.seen.len();
        let wire = report.encode();
        assert!(report.held as u32 <= 4_500 / crate::TICKS_PER_SECOND);
        assert_eq!(wire.len(), 11 + 3 * report.seen.len() + 4 * report.fired.len() + 3 * report.caught_by.len());
    }
    assert!(caught > 0 && seen > 0, "the drawn crews are seen and caught on the example island");
}

#[test]
fn a_replay_verifies_on_its_island_and_nowhere_else() {
    use crate::island::Island;
    use crate::{draw, record, verify_on, Refusal};
    let island = Island::example();
    let heist = record(&island, 42, 4_500, 4, draw(&island, 42, 4_500, 4));
    let outcome = verify_on(&island, &heist).expect("a replay verifies on its own island");
    assert_eq!(outcome.capacity, 104 + 104 + 300 + 138, "a crew of four's Carry");

    // Named for another island, or played on one it does not name.
    assert_eq!(verify_on(&Island::fixture(), &heist), Err(Refusal::Island));
    let mut other_rules = heist.clone();
    other_rules.rules[0] ^= 1;
    assert_eq!(verify_on(&island, &other_rules), Err(Refusal::Rules));

    // A tampered second is found, and named.
    let mut tampered = heist.clone();
    tampered.checksums[60] ^= 1;
    assert_eq!(verify_on(&island, &tampered), Err(Refusal::Diverged(61)));

    // A replay that carries no checksums would verify against anything.
    let mut bare = heist.clone();
    bare.checksums.clear();
    assert_eq!(verify_on(&island, &bare), Err(Refusal::Checksums));

    // The shape §24.10 and §12.5 give a heist.
    let short = record(&island, 42, 900, 3, draw(&island, 42, 900, 3));
    assert_eq!(verify_on(&island, &short), Err(Refusal::Length));
    let two = record(&island, 42, 4_500, 2, draw(&island, 42, 4_500, 2));
    assert_eq!(verify_on(&island, &two), Err(Refusal::Crew));
    let mut late = heist.clone();
    late.commands.push(Command { tick: 4_500, actor: 0, kind: Kind::Halt, x: 0, y: 0 });
    assert_eq!(verify_on(&island, &late), Err(Refusal::Log));
}

#[test]
fn the_rules_version_is_the_same_every_time_it_is_asked() {
    assert_eq!(crate::rules_version(), crate::rules_version());
    assert_ne!(crate::rules_version(), [0u8; 32]);
}

#[test]
fn a_vault_a_level_up_holds_more() {
    use crate::island::Island;
    let mut island = Island::example();
    island.vault_level = 1;
    let one = World::on_ground(&island, 3, vec![]).vault.health;
    island.vault_level = 4;
    let four = World::on_ground(&island, 3, vec![]).vault.health;
    assert_eq!(four, one * 4, "§12.6: health a Vault level");
}

#[test]
fn every_tile_a_guards_drawn_cone_covers_is_one_where_a_walker_is_noticed() {
    // §21.12: the selected guard's vision is drawn, "a tile is inside or
    // outside". The client draws `seen_tiles`, so each tile in it must be one
    // where a crew member walking there is noticed in the cone proper — the
    // drawing and the rule are one rule.
    let mut world = World::new(0, 1, Vec::new());
    let seen = world.seen_tiles(0);
    assert!(seen.len() > 3, "a guard on its post sees some of the realm");
    for &tile in &seen {
        // Tall grass hides a crew member standing still in it (§12.17), and
        // one placed by hand is standing still; the tile is still drawn as
        // seen, because the guard sees the grass.
        if world.grid.feature(tile) == Some(Feature::TallGrass) {
            continue;
        }
        let (x, y) = world.grid.centre(tile);
        world.raiders[0].at = Point { x, y };
        world.raiders[0].route.clear();
        world.raiders[0].still_for = 0;
        assert!(world.noticed(0, 0).is_some(), "tile {tile} is drawn and not seen");
    }
}

#[test]
fn a_rock_pillar_takes_the_tiles_behind_it_out_of_the_drawn_cone() {
    // §6.2: a rock pillar "blocks sight". Put one on the nearest tile the
    // guard sees and at least one tile beyond it along the same line drops out.
    let world = World::new(0, 1, Vec::new());
    let before = world.seen_tiles(0);
    let from = world.grid.tile_at(world.guards[0].at.x, world.guards[0].at.y).unwrap();
    let near = *before.iter().filter(|&&t| t != from)
        .min_by_key(|&&t| {
            let (x, y) = world.grid.centre(t);
            (world.guards[0].at.distance(Point { x, y }).0, t)
        })
        .unwrap();
    let mut walled = world.clone();
    let (nx, ny) = (near % walled.grid.width as u32, near / walled.grid.width as u32);
    walled.grid.place(nx as u16, ny as u16, Feature::RockPillar);
    let after = walled.seen_tiles(0);
    assert!(after.len() < before.len(), "{} tiles before, {} after", before.len(), after.len());
    assert!(!after.contains(&near), "the pillar's own tile is not seen through");
}

#[test]
fn commands_given_live_record_the_same_heist_as_the_log_they_make() {
    // A device plays a heist by giving commands as the player taps, then
    // records the log it made (§24.12's Play and Queue). The world it showed
    // must be the one the recording reproduces: the planned heist's commands,
    // given one at a time at their ticks, end in the same checksum and make
    // the same replay.
    let planned = planned();
    let mut live = World::from_heist(&Heist { commands: Vec::new(), ..planned.clone() });
    let mut pending = planned.commands.iter().peekable();
    let mut last = 0;
    while live.tick < planned.ticks {
        while let Some(c) = pending.next_if(|c| c.tick == live.tick) {
            assert!(live.give(c.actor, c.kind, c.x, c.y));
        }
        last = live.step();
    }
    assert!(!live.give(0, Kind::Halt, 0, 0), "no command after the clock");
    let recorded = crate::record(&crate::island::Island::fixture(), planned.seed, planned.ticks, planned.crew,
                          live.commands().to_vec());
    assert_eq!(recorded, planned);
    assert_eq!(crate::truncate(last), *planned.checksums.last().unwrap());
}

// --------------------------------------------------------------------------
// The launch laws that are rows, not multipliers (§7.3, v3.4; §7.10)
// --------------------------------------------------------------------------

use crate::laws_table::{Param as P, Res};

/// A move order for crew member `actor` to tile (x, y), given this tick.
fn order(world: &mut World, actor: u8, x: i16, y: i16) {
    let tick = world.tick;
    world.commands_for_test(vec![Command {
        tick, actor, kind: Kind::MoveTo, x: x * 256 + 128, y: y * 256 + 128,
    }]);
}

fn tile_of(world: &World, ri: usize) -> (u16, u16) {
    let r = &world.raiders[ri];
    world.grid.coords(world.grid.tile_at(r.at.x, r.at.y).unwrap())
}

fn run_for(world: &mut World, ticks: u32) {
    for _ in 0..ticks {
        world.step();
    }
}

#[test]
fn every_one_of_the_48_laws_weaves_and_runs() {
    // The sheet once held twenty parameters and the table named twenty-two,
    // so weaving Thorns ran off the end of it.
    for law in crate::laws_table::LAWS.iter() {
        let mut world = World::new(1, 5, Vec::new());
        world.weave(&[(law.id, (0, 13))]);
        run_for(&mut world, 2 * TICKS_PER_SECOND);
    }
}

#[test]
fn frictionless_slides_on_past_the_end_of_a_route_until_something_stops_it() {
    let slide = |law: bool, body: bool| {
        let mut world = vault_world(1);
        if law {
            world.weave(&[("frictionless", (0, 13))]);
        }
        world.grid.place(10, 3, Feature::RockPillar);
        if body {
            let g = post(&mut world, 0, 8, 3);
            world.guards[g].knocked_out = true;   // a body lying there
        }
        put(&mut world, 0, 2, 3);
        order(&mut world, 0, 4, 3);
        run_for(&mut world, 6 * TICKS_PER_SECOND);
        tile_of(&world, 0)
    };
    assert_eq!(slide(false, false), (4, 3), "friction on: it stops where it was sent");
    assert_eq!(slide(true, false), (9, 3), "friction off: on to the pillar");
    assert_eq!(slide(true, true), (7, 3), "or to whoever stands in the way");
}

#[test]
fn frictionless_and_bounce_are_pinball_and_a_warden_absorbs_the_ricochet() {
    // A slide is the only way into a wall, and Frictionless with Bounce is
    // Pinball: "sliding characters ricochet off walls" — every wall.
    let slide = |ri: usize, secs: u32| {
        let mut world = vault_world(4);
        world.weave(&[("frictionless", (0, 13)), ("bounce", (1, 13))]);
        assert!(world.combos.resonance(Res::Pinball));
        world.grid.place(10, 3, Feature::RockPillar);
        world.grid.place(0, 3, Feature::RockPillar);
        put(&mut world, ri, 2, 3);
        order(&mut world, ri as u8, 4, 3);
        let mut seen = Vec::new();
        for _ in 0..secs * TICKS_PER_SECOND {
            world.step();
            let t = tile_of(&world, ri);
            if seen.last() != Some(&t) {
                seen.push(t);
            }
        }
        (seen, world.raiders[ri].still())
    };
    let (path, still) = slide(0, 12);
    let turns = path.windows(3).filter(|w| w[0] == w[2]).count();
    assert!(path.contains(&(9, 3)) && path.contains(&(1, 3)), "wall to wall: {path:?}");
    assert!(turns >= 2 && !still, "and back again, still going");
    let (path, still) = slide(3, 12);
    assert_eq!((path.last(), still), (Some(&(9, 3)), true), "the Warden stops at the first wall");
}

#[test]
fn bounce_returns_half_of_a_blow_on_a_ward_to_whoever_struck_it() {
    let struck = |ri: usize, law: bool| {
        let mut world = ward_world(4, WardKind::CrystalWall, (3, 3));
        if law {
            world.weave(&[("bounce", (0, 13))]);
        }
        put(&mut world, ri, 3, 4);
        world.raiders[ri].task = Task::Break;
        world.raiders[ri].target = world.grid.index(3, 3).unwrap();
        let before = world.raiders[ri].health;
        run_for(&mut world, h::HIT_TICKS);
        before - world.raiders[ri].health
    };
    let scout = Role::Scout.power();
    assert_eq!(struck(0, false), 0);
    assert_eq!(struck(0, true), scout / 2, "\"bounce back 50% of what hits them\"");
    assert_eq!(struck(3, true), 0, "a Warden absorbs it");
}

#[test]
fn density_makes_the_large_tougher_and_slower_until_its_pylon_falls() {
    let mut world = vault_world(4);
    world.weave(&[("density", (0, 13))]);
    assert_eq!(Role::Warden.size(), crate::Size::Large);
    assert_eq!(world.raiders[3].health, 420 * 13 / 10, "large: +30% health");
    assert_eq!(world.raiders[0].health, 120, "a Scout reads as standard");
    let plain = crate::Sheet::plain();
    let w = &world.raiders[3];
    assert_eq!(crate::step_for(&world.grid, &world.sheet, w, w.gait, None, false),
               crate::step_for(&world.grid, &plain, w, w.gait, None, false)
                   .mul(Fx::from_ratio(4, 5)),
               "large: -20% speed");
    world.laws[0].health = 0;
    world.laws[0].broken_at = Some(0);
    world.step();
    assert_eq!(world.raiders[3].health, 420, "its law off, the extra health goes with it");
}

#[test]
fn delay_lands_a_triggered_ward_three_seconds_after_it_fires() {
    let mut world = ward_world(1, WardKind::TimeSnare, (3, 3));
    world.weave(&[("delay", (0, 13))]);
    put(&mut world, 0, 3, 3);
    world.step();
    assert_eq!(world.raiders[0].frozen_until, 0, "nothing yet");
    assert_eq!(world.wards[0].armed_at, 12 * TICKS_PER_SECOND, "but it has fired");
    run_for(&mut world, 3 * TICKS_PER_SECOND);
    assert_eq!(world.raiders[0].frozen_until, 3 * TICKS_PER_SECOND + h::SNARE_FREEZE_TICKS,
               "the snare lands at 3 s");
}

#[test]
fn a_regrow_time_takes_the_shortest_applied_not_the_product() {
    // G24, decided: "When several laws set a regrow time, the shortest one
    // applies". Bloom's 10 s and Crystal growth's 8 s, each a fifth shorter
    // for the Bloom harmony both carry: 8 s and 6.4 s, so 6.4 s — where the
    // product was 51.2 s.
    let mut world = vault_world(1);
    world.weave(&[("bloom", (0, 13)), ("crystal_growth", (1, 13))]);
    assert_eq!(world.sheet.ticks(crate::laws_table::Param::RegrowSeconds),
               Some(32 * TICKS_PER_SECOND / 5));
    let mut alone = vault_world(1);
    alone.weave(&[("bloom", (0, 13))]);
    assert_eq!(alone.sheet.ticks(crate::laws_table::Param::RegrowSeconds), Some(10 * TICKS_PER_SECOND));
}

#[test]
fn under_delay_a_guard_rises_three_seconds_after_it_is_triggered() {
    // G23, decided: under Delay "guards change state 3 seconds after they
    // are triggered", as wards take effect. Falling is not delayed.
    let rise = |delay: bool| {
        let mut world = vault_world(1);
        if delay {
            world.weave(&[("delay", (0, 13))]);
        }
        put(&mut world, 0, 13, 13);
        let gi = post(&mut world, 1, 2, 2);
        world.guards[gi].suspicion = crate::INVESTIGATING_AT + 200;
        let mut risen = None;
        for _ in 0..5 * TICKS_PER_SECOND {
            world.step();
            if risen.is_none() && world.guards[gi].state.rank() >= State::Investigating.rank() {
                risen = Some(world.tick);
            }
        }
        risen
    };
    assert_eq!(rise(false), Some(1), "at once without Delay");
    assert_eq!(rise(true), Some(1 + 3 * TICKS_PER_SECOND), "three seconds later with it");
}

#[test]
fn a_rise_queued_under_delay_still_lands_after_its_pylon_breaks() {
    // G23: the rise was triggered while Delay stood, so it lands at its tick
    // even though the pylon is broken before then — it is not lost.
    let mut world = vault_world(1);
    world.weave(&[("delay", (0, 13))]);
    put(&mut world, 0, 13, 13);
    let gi = post(&mut world, 1, 2, 2);
    world.guards[gi].suspicion = crate::INVESTIGATING_AT + 200;
    world.step();
    assert_eq!(world.guards[gi].rising.len(), 1, "queued");
    world.guards[gi].suspicion = 0;
    world.laws[0].broken_at = Some(world.tick);
    let mut risen = None;
    for _ in 0..5 * TICKS_PER_SECOND {
        world.step();
        if risen.is_none() && world.guards[gi].state.rank() >= State::Investigating.rank() {
            risen = Some(world.tick);
        }
    }
    assert_eq!(risen, Some(1 + 3 * TICKS_PER_SECOND));
    assert!(world.guards[gi].rising.is_empty());
}

#[test]
fn aurora_doubles_sight_inside_its_band_and_halves_it_between() {
    // 5 m east of the Scout, on row 6: its far zone, 12 a tick, with no law.
    assert_eq!(rate(&scout_and_raider(50, 0)), Some(12));
    let mut world = scout_and_raider(50, 0);
    world.weave(&[("aurora", (0, 13))]);
    assert_eq!(rate(&world), None, "between bands: 6 m halves to 3 and 5 m is out");
    // The band is two rows, crossing sixteen rows (fourteen and its own
    // depth) in ten seconds: row 6 is lit from tick 132 to 168.
    world.tick = 150;
    assert_eq!(rate(&world), Some(33), "in the band: the 4 m mid zone doubles to 8");
    world.tick = 170;
    assert_eq!(rate(&world), None, "and the band moves on");
}

/// An Alerted guard of `row` at (3, 3) facing south at crew member 0 on
/// (3, 4).
fn swinging_guard(world: &mut World, row: usize) -> usize {
    put(world, 0, 3, 4);
    let gi = post(world, row, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(90);
    world.enter(gi, State::Alerted);
    world.guards[gi].route.clear();
    world.guards[gi].interest = world.grid.index(3, 4);
    gi
}

#[test]
fn chain_lightning_jumps_a_hit_to_the_nearest_ally_within_three_tiles_at_half() {
    let mut world = vault_world(3);
    world.weave(&[("chain_lightning", (0, 13))]);
    swinging_guard(&mut world, 2);                // the Breaker guard, Power 40
    put(&mut world, 1, 3, 6);                     // two tiles on: in reach
    put(&mut world, 2, 3, 8);                     // four: out of it
    run_for(&mut world, h::HIT_TICKS);
    assert_eq!(world.raiders[0].health, 120 - 40, "the hit, whole: no longer halved");
    assert_eq!(world.raiders[1].health, 180 - 20, "the jump, at 50%");
    assert_eq!(world.raiders[2].health, Role::Carrier.health(), "too far for it");
}

#[test]
fn chain_lightning_jumps_from_a_guard_to_the_nearest_guard_as_a_hit() {
    let mut world = vault_world(1);
    world.weave(&[("chain_lightning", (0, 13))]);
    let a = post(&mut world, 2, 3, 3);            // unaware, back to the crew
    let b = post(&mut world, 0, 5, 3);
    world.guards[a].facing = Ang::from_degrees(270);
    world.guards[b].facing = Ang::from_degrees(270);
    put(&mut world, 0, 3, 4);
    world.raiders[0].task = Task::Attack;
    world.raiders[0].target = a as u32;
    let (full_a, full_b) = (world.guards[a].health, world.guards[b].health);
    run_for(&mut world, h::TAKEDOWN_TICKS);
    assert!(world.guards[a].knocked_out, "the takedown");
    assert_eq!(world.guards[b].health, full_b - full_a / 2, "half of what the takedown dealt");
    assert!(world.guards[b].suspicion >= crate::SUSPICIOUS_AT, "a hit: straight to 1000");
}

#[test]
fn static_charges_over_five_tiles_and_stuns_the_next_one_it_touches() {
    let stunned = |law: bool| {
        let mut world = vault_world(2);
        if law {
            world.weave(&[("static", (0, 13))]);
        }
        put(&mut world, 0, 1, 3);
        put(&mut world, 1, 7, 3);
        order(&mut world, 0, 6, 3);
        let mut first = None;
        for _ in 0..(4 * TICKS_PER_SECOND) {
            world.step();
            if first.is_none() && world.raiders[1].frozen_until > 0 {
                first = Some((world.tick - 1, world.raiders[1].frozen_until, world.raiders[0].charge));
            }
        }
        first
    };
    assert_eq!(stunned(false), None);
    let (at, until, charge) = stunned(true).expect("five tiles walked, then a touch");
    assert_eq!(until, at + TICKS_PER_SECOND / 2, "half a second");
    assert_eq!(charge, 0, "the charge is spent");
}

#[test]
fn echoes_returns_the_knocked_out_once_at_sixty_per_cent() {
    let mut world = vault_world(1);
    world.weave(&[("echoes", (0, 13))]);
    swinging_guard(&mut world, 2);
    world.raiders[0].health = 30;
    world.raiders[0].carried = 20;
    run_for(&mut world, h::HIT_TICKS);
    let r = &world.raiders[0];
    assert!(r.active() && r.revived, "back on its feet");
    assert_eq!(r.health, 120 * 6 / 10, "at 60% of full health");
    assert_eq!((r.carried, world.dropped.len()), (0, 1), "its loot left where it fell");
    world.raiders[0].health = 30;
    run_for(&mut world, h::HIT_TICKS);
    assert_eq!(world.raiders[0].standing, Standing::Down, "only once");
}

#[test]
fn soul_swap_trades_places_with_the_nearest_ally_who_takes_half_the_blow() {
    let mut world = vault_world(3);
    world.weave(&[("soul_swap", (0, 13))]);
    swinging_guard(&mut world, 2);                // Power 40
    put(&mut world, 1, 8, 8);                     // the nearest ally
    put(&mut world, 2, 12, 12);
    world.raiders[0].health = 30;
    let (was_0, was_1) = (world.raiders[0].at, world.raiders[1].at);
    run_for(&mut world, h::HIT_TICKS);
    assert_eq!((world.raiders[0].at, world.raiders[1].at), (was_1, was_0), "traded places");
    assert_eq!(world.raiders[0].health, 30, "the one about to fall takes nothing");
    assert_eq!(world.raiders[1].health, 180 - 20, "the ally takes half the blow");
    assert!(world.raiders[0].active() && world.raiders[0].revived);
}

#[test]
fn the_higher_revival_applies_when_two_laws_cover_a_knockout() {
    let mut world = vault_world(1);
    world.weave(&[("echoes", (0, 13)), ("soul_swap", (1, 13))]);
    assert_eq!(world.revival(), Some(crate::Revival::Return(3, 5)), "60% over 50%");
    assert!(world.sheet.is_set(P::RevivalSwap));
}

#[test]
fn thorns_cost_whoever_touches_a_wall_or_a_hedge_five_per_cent_a_second() {
    let mut world = ward_world(3, WardKind::ThornHedge, (10, 10));
    world.weave(&[("thorns", (0, 13))]);
    world.grid.place(2, 2, Feature::RockPillar);
    put(&mut world, 0, 2, 3);                     // beside the pillar
    put(&mut world, 1, 5, 6);                     // beside the Vault: a structure
    put(&mut world, 2, 10, 11);                   // beside the hedge
    let g = post(&mut world, 2, 3, 2);            // a guard hugging the pillar
    let full = world.guards[g].health;
    world.step();
    assert_eq!(world.raiders[0].health, 120 - 6, "5% of 120");
    assert_eq!(world.raiders[1].health, 180, "the Vault is not a wall");
    let carrier = Role::Carrier.health();
    assert_eq!(world.raiders[2].health, carrier - carrier / 20, "a hedge is");
    assert_eq!(world.guards[g].health, full - full / 20, "guards cannot hug the walls either");
}

#[test]
fn bloom_regrows_a_cut_hedge_after_ten_seconds() {
    let cut = |law: bool| {
        let mut world = ward_world(1, WardKind::ThornHedge, (3, 3));
        if law {
            world.weave(&[("bloom", (0, 13))]);
        }
        put(&mut world, 0, 12, 12);
        world.wards[0].health = 0;
        world.wards[0].broken = true;
        world.wards[0].broken_at = Some(0);
        run_for(&mut world, 10 * TICKS_PER_SECOND);
        let before = world.wards[0].live();
        world.step();
        (before, world.wards[0].live(), world.wards[0].health)
    };
    assert_eq!(cut(false), (false, false, 0));
    assert_eq!(cut(true), (false, true, h::WARD_HEALTH_PER_LEVEL), "whole again at 10 s");
}

#[test]
fn regrowth_heals_wards_too() {
    // "Buildings, wards and guards heal 2% of their health each second."
    let mut world = ward_world(1, WardKind::ThornHedge, (3, 3));
    world.weave(&[("regrowth", (0, 13))]);
    put(&mut world, 0, 12, 12);
    world.wards[0].health = 100;
    world.step();
    assert_eq!(world.wards[0].health, 100 + h::WARD_HEALTH_PER_LEVEL / 50);
}


// --------------------------------------------------------------------------
// §8: harmonies, dissonances, signature resonances and chords
// --------------------------------------------------------------------------

use crate::combos::Combos;
use crate::laws_table::{note, Chord};

/// Weave `laws`, each with a pylon on row 13.
fn weave(world: &mut World, laws: &[&str]) {
    let at: Vec<(&str, (u16, u16))> = laws.iter().enumerate()
        .map(|(i, id)| (*id, (i as u16, 13))).collect();
    world.weave(&at);
}

fn rows(ids: &[&str]) -> Vec<usize> {
    ids.iter().map(|id| LAWS.iter().position(|l| l.id == *id).unwrap()).collect()
}

/// A guard facing north at (2, 2), and crew member 0 at (2, `y`) walking a
/// tile south with `gait`: whether the guard hears it, after one tick. Sight
/// cannot reach it, so what wakes the guard is sound.
fn heard(laws: &[&str], y: u16, gait: Gait) -> bool {
    let mut world = vault_world(1);
    weave(&mut world, laws);
    let g = post(&mut world, 0, 2, 2);
    world.guards[g].facing = Ang::from_degrees(270);
    put(&mut world, 0, 2, y);
    world.raiders[0].gait = gait;
    world.raiders[0].route = vec![world.grid.index(2, y + 1).unwrap()];
    world.step();
    world.guards[g].heard.is_some()
}

#[test]
fn which_combinations_sound_is_read_off_the_standing_laws() {
    let c = Combos::of(&rows(&["haste", "brittle_stone", "glowing_dark"]));
    assert!(c.harmony(note::SPARK) && !c.harmony(note::FLOW), "Spark is shared, Flow is not");
    assert!(c.resonance(Res::NightRunners));
    assert!(c.chord(Chord::WildHunt), "Flow, Spark and Hush from three laws");
    // §8.8: two laws carrying three notes are not a chord.
    let two = Combos::of(&rows(&["haste", "glass"]));
    assert!(!two.chord(Chord::Tempest), "Flow and Spark from one law, Glow from another");
    assert!(Combos::of(&rows(&["haste", "brittle_stone", "glass"])).chord(Chord::Tempest));
    // Opposites clash only across two laws.
    assert!(Combos::of(&rows(&["haste", "slow_rivers"])).dissonance(note::WEIGHT));
    assert_eq!(Combos::of(&rows(&["haste"])).dissonances, 0);
}

#[test]
fn a_broken_pylon_silences_everything_its_law_was_part_of() {
    let mut world = vault_world(1);
    weave(&mut world, &["haste", "brittle_stone", "glowing_dark"]);
    assert!(world.combos.chord(Chord::WildHunt) && world.combos.resonance(Res::NightRunners));
    world.laws[0].broken_at = Some(0);
    world.step();
    assert_eq!(world.combos, Combos::default().tap(|c| c.harmonies = 0), "haste gone: nothing left");
}

trait Tap: Sized {
    fn tap(mut self, f: impl FnOnce(&mut Self)) -> Self {
        f(&mut self);
        self
    }
}
impl Tap for Combos {}

// Harmonies (§8.2) --------------------------------------------------------

#[test]
fn a_flow_harmony_makes_movement_a_quarter_stronger() {
    let mut world = vault_world(1);
    weave(&mut world, &["haste", "half_gravity"]);
    assert!(world.combos.harmony(note::FLOW));
    assert_eq!(world.sheet.factor(P::CrewSpeed), (21, 16), "Haste's +25% becomes +31.25%");
    assert_eq!(world.sheet.factor(P::GuardSpeed), (21, 16));
}

#[test]
fn a_weight_harmony_makes_slowing_a_quarter_stronger() {
    let mut world = vault_world(1);
    weave(&mut world, &["slow_rivers", "density"]);
    assert_eq!(world.sheet.factor(P::CrewSpeed), (3, 8), "half speed becomes 37.5%");
    assert_eq!(world.sheet.factor(P::LargeSpeed), (3, 4), "-20% becomes -25%");
}

#[test]
fn a_glow_harmony_makes_auroras_band_two_rows_deeper() {
    let lit = |laws: &[&str]| {
        let mut world = vault_world(0);
        weave(&mut world, laws);
        world.tick = 150;
        (0..14u16).filter(|&y| world.in_band(world.grid.index(0, y).unwrap()) == Some(true)).count()
    };
    assert_eq!(lit(&["aurora"]), 2);
    assert_eq!(lit(&["aurora", "glass"]), 4, "\"light and reveal ranges 2 tiles longer\"");
}

#[test]
fn a_hush_harmony_lets_the_crew_hide_a_tile_closer() {
    // Glowing dark halves the Scout's zones to 1, 2 and 3 m.
    let at = |laws: &[&str]| {
        let mut world = scout_and_raider(15, 0);
        let pylons: Vec<(&str, (u16, u16))> =
            laws.iter().enumerate().map(|(i, l)| (*l, (i as u16, 13))).collect();
        world.weave(&pylons);
        rate(&world)
    };
    assert_eq!(at(&["glowing_dark"]), Some(33), "1.5 m: the mid zone");
    assert_eq!(at(&["glowing_dark", "stillness"]), Some(12), "seen as 2.5 m: the far zone");
}

#[test]
fn a_bloom_harmony_makes_healing_and_regrowth_a_quarter_stronger() {
    let mut world = vault_world(1);
    weave(&mut world, &["kinship", "regrowth"]);
    assert_eq!(world.sheet.factor(P::AllyHealing), (3, 160), "1.5% becomes 1.875%");
    assert_eq!(world.sheet.factor(P::StructureHealing), (1, 40), "2% becomes 2.5%");
    let mut world = vault_world(1);
    weave(&mut world, &["bloom", "kinship"]);
    assert_eq!(world.sheet.ticks(P::RegrowSeconds), Some(8 * TICKS_PER_SECOND),
               "ten seconds, a quarter sooner");
}

#[test]
fn a_spark_harmony_makes_damage_and_stuns_a_quarter_stronger() {
    let mut world = vault_world(1);
    weave(&mut world, &["brittle_stone", "chain_lightning"]);
    assert_eq!(world.sheet.factor(P::StructureDamage), (9, 4), "double becomes 2.25");
    assert_eq!(world.sheet.factor(P::ChainShare), (5, 8));
    let mut world = vault_world(1);
    weave(&mut world, &["static", "haste"]);
    assert_eq!(world.sheet.factor(P::TouchStunSeconds), (5, 8), "half a second becomes 0.625");
}

#[test]
fn an_echo_harmony_makes_returns_a_quarter_stronger() {
    let mut world = vault_world(1);
    weave(&mut world, &["echoes", "whispers"]);
    assert_eq!(world.revival(), Some(crate::Revival::Return(3, 4)), "60% becomes 75%");
}

#[test]
fn a_veil_harmony_sounds_and_has_no_launch_illusion_to_lengthen() {
    let mut world = vault_world(1);
    weave(&mut world, &["delay", "soul_swap"]);
    assert!(world.combos.harmony(note::VEIL));
    assert_eq!(world.sheet.ticks(P::EffectDelaySeconds), Some(3 * TICKS_PER_SECOND));
    assert_eq!(world.sheet.factor(P::RevivalSwap), (1, 2));
}

// Dissonances (§8.3) ------------------------------------------------------

#[test]
fn gusts_and_lulls_move_everyones_speed_twenty_per_cent_every_ten_seconds() {
    let mut seen = Vec::new();
    for seed in 0..16 {
        let mut world = vault_world(1);
        world.rng = Rng::new(seed, Stream::Laws);
        weave(&mut world, &["haste", "slow_rivers"]);
        assert_eq!(world.gust, (1, 1));
        run_for(&mut world, h::GUST_TICKS + 1);
        let (gn, gd) = world.gust;
        assert!(matches!(world.gust, (6, 5) | (4, 5)));
        assert_eq!(world.sheet.factor(P::CrewSpeed), crate::Sheet::plain()
            .tap(|s| { s.apply(P::CrewSpeed, 5, 8); s.apply(P::CrewSpeed, gn, gd); })
            .factor(P::CrewSpeed), "Haste x Slow rivers x the gust");
        seen.push(world.gust);
    }
    assert!(seen.contains(&(6, 5)) && seen.contains(&(4, 5)), "at random, both ways");
}
impl Tap for crate::Sheet {}

#[test]
fn flicker_makes_the_whole_realm_bright_or_dark_for_three_seconds_every_fifteen() {
    let mut world = vault_world(1);
    weave(&mut world, &["glass", "stillness"]);
    run_for(&mut world, h::FLICKER_TICKS + 1);
    let (bright, until) = world.light.expect("a flicker at 15 s");
    assert_eq!(until, h::FLICKER_TICKS + h::FLICKER_HOLD_TICKS);
    let t = world.grid.index(9, 9).unwrap();
    assert_eq!(world.unlit(t), !bright, "every tile alike");
    run_for(&mut world, h::FLICKER_HOLD_TICKS);
    assert_eq!(world.light, None, "for three seconds");
}

#[test]
fn wildfire_burns_the_grass_a_spark_lands_on_and_hurts_whoever_stands_in_it() {
    let mut world = vault_world(3);
    weave(&mut world, &["kinship", "chain_lightning"]);
    assert!(world.combos.dissonance(note::BLOOM));
    swinging_guard(&mut world, 2);
    world.grid.place(3, 6, Feature::TallGrass);
    put(&mut world, 1, 3, 6);                     // the jump lands here, in grass
    put(&mut world, 2, 12, 12);
    run_for(&mut world, h::HIT_TICKS);
    assert_eq!(world.raiders[1].health, 180 - 20, "the jump");
    assert!(world.burning.iter().any(|&(t, _)| t == world.grid.index(3, 6).unwrap()), "alight");
    world.guards[0].knocked_out = true;           // no second blow
    run_for(&mut world, TICKS_PER_SECOND);
    assert_eq!(world.raiders[1].health, 180 - 20 - 9, "5% of full health, a second in the fire");
}

#[test]
fn deja_vu_once_a_heist_draws_the_guards_to_an_illusion() {
    let mut world = vault_world(1);
    weave(&mut world, &["echoes", "soul_swap"]);
    let g = post(&mut world, 0, 12, 2);
    put(&mut world, 0, 0, 12);
    let mut drawn = 0;
    for _ in 0..(62 * TICKS_PER_SECOND) {
        let before = world.guards[g].state;
        world.step();
        if before == State::Unaware && world.guards[g].state == State::Investigating {
            drawn += 1;
        }
    }
    assert!(world.deja_vu_spent);
    assert_eq!(drawn, 1, "once, inside the minute");
}

// Signature resonances (§8.4) ---------------------------------------------

#[test]
fn drifting_echoes_lets_a_returned_echo_float_over_one_wall() {
    let crossed = |laws: &[&str]| {
        let mut world = vault_world(1);
        weave(&mut world, laws);
        for x in 0..14 {
            world.grid.place(x, 5, Feature::RockPillar);   // no way round
        }
        put(&mut world, 0, 3, 4);
        world.raiders[0].health = 0;
        world.step();                                     // knocked out, and back
        assert!(world.raiders[0].active());
        order(&mut world, 0, 3, 6);
        run_for(&mut world, 3 * TICKS_PER_SECOND);
        (tile_of(&world, 0), world.raiders[0].wall_pass)
    };
    assert_eq!(crossed(&["echoes"]), ((3, 4), false), "no route: it stays");
    assert_eq!(crossed(&["half_gravity", "echoes"]), ((3, 6), false), "over the wall, once");
}

#[test]
fn mangrove_banks_slow_crews_on_a_bank_by_a_further_fifth() {
    let mut world = vault_world(1);
    weave(&mut world, &["slow_rivers", "bloom"]);
    world.grid.set_surface(5, 3, crate::grid::Surface::Water);
    let bank = world.grid.index(4, 3);
    let inland = world.grid.index(4, 9);
    assert_eq!(world.pace_here(bank, true, 0), (4, 5));
    assert_eq!(world.pace_here(bank, false, 0), (1, 1), "crews, not guards");
    assert_eq!(world.pace_here(inland, true, 0), (1, 1));
}

#[test]
fn night_runners_speeds_anyone_in_the_dark_by_thirty_per_cent() {
    let mut world = vault_world(1);
    weave(&mut world, &["haste", "glowing_dark"]);
    let t = world.grid.index(4, 4);
    assert_eq!(world.pace_here(t, true, 0), (13, 10), "Glowing dark: the realm is dark");
    assert_eq!(world.pace_here(t, false, 0), (13, 10), "anyone");
    world.light = Some((true, 1_000));
    assert_eq!(world.pace_here(t, true, 0), (1, 1), "not while a light is over it");
}

#[test]
fn cracked_gardens_counts_every_structure_broken_for_the_owner() {
    let mut world = ward_world(1, WardKind::ThornHedge, (3, 3));
    weave(&mut world, &["brittle_stone", "bloom"]);
    put(&mut world, 0, 3, 4);
    world.wards[0].health = 1;
    world.raiders[0].task = Task::Break;
    world.raiders[0].target = world.grid.index(3, 3).unwrap();
    run_for(&mut world, h::HIT_TICKS);
    assert!(world.wards[0].broken);
    assert_eq!(world.outcome().cracked, 1);
}

#[test]
fn storm_grid_chains_on_to_three_targets() {
    let mut world = vault_world(4);
    weave(&mut world, &["chain_lightning", "static"]);
    swinging_guard(&mut world, 2);                // Power 40, on crew member 0
    put(&mut world, 1, 3, 6);
    put(&mut world, 2, 3, 8);
    put(&mut world, 3, 3, 10);
    run_for(&mut world, h::HIT_TICKS);
    // A Spark harmony too: the jump's 50% is 62.5%, 25 of the 40.
    assert_eq!(world.raiders[1].health, 180 - 25);
    assert_eq!(world.raiders[2].health, Role::Carrier.health() - 25);
    assert_eq!(world.raiders[3].health, 420 - 25, "the third, each from the last");
}

#[test]
fn briar_maze_regrows_a_cut_hedge_a_tile_wider() {
    let mut world = ward_world(1, WardKind::ThornHedge, (3, 3));
    weave(&mut world, &["thorns", "bloom"]);
    put(&mut world, 0, 12, 12);
    world.wards[0].health = 0;
    world.wards[0].broken = true;
    world.wards[0].broken_at = Some(0);
    // Both carry Bloom: regrowth comes a quarter sooner, at eight seconds.
    run_for(&mut world, 8 * TICKS_PER_SECOND + 1);
    assert!(world.wards[0].live() && world.wards[0].regrown);
    assert_eq!(world.wards.len(), 2);
    assert_eq!(world.grid.coords(world.wards[1].tile), (3, 2), "the first bare side, north");
}

#[test]
fn twin_souls_heal_the_two_who_swapped_by_a_fifth() {
    let mut world = vault_world(3);
    weave(&mut world, &["soul_swap", "kinship"]);
    swinging_guard(&mut world, 2);
    put(&mut world, 1, 8, 8);
    put(&mut world, 2, 12, 12);
    world.raiders[0].health = 30;
    world.raiders[1].health = 100;
    run_for(&mut world, h::HIT_TICKS);
    assert_eq!(world.raiders[0].health, 30 + 24, "20% of 120");
    assert_eq!(world.raiders[1].health, 100 - 20 + 36, "half the blow, then 20% of 180");
}

#[test]
fn soul_tether_lets_a_returned_echo_swap_once() {
    let mut world = vault_world(2);
    weave(&mut world, &["soul_swap", "echoes"]);
    swinging_guard(&mut world, 2);
    put(&mut world, 1, 8, 8);
    world.raiders[0].health = 30;
    run_for(&mut world, h::HIT_TICKS);
    assert!(world.raiders[0].revived && !world.raiders[0].tethered, "Echoes' 60% outranks the swap");
    let ally = world.raiders[1].at;
    let back = world.raiders[0].at;
    world.raiders[0].health = 30;
    world.guards[0].swing = 0;
    run_for(&mut world, h::HIT_TICKS);
    assert!(world.raiders[0].tethered && world.raiders[0].active());
    assert_eq!((world.raiders[0].at, world.raiders[1].at), (ally, back), "then the swap");
    assert_eq!(world.raiders[1].health, 180 - 20);
}

#[test]
fn shattered_glass_breaks_a_crystal_wall_in_one_hit_and_its_shards_slow() {
    let mut world = ward_world(1, WardKind::CrystalWall, (3, 3));
    weave(&mut world, &["glass", "brittle_stone"]);
    put(&mut world, 0, 3, 4);
    world.raiders[0].task = Task::Break;
    world.raiders[0].target = world.grid.index(3, 3).unwrap();
    run_for(&mut world, h::HIT_TICKS);
    assert!(world.wards[0].broken, "800 health, one hit");
    assert_eq!(world.shards, vec![world.grid.index(3, 3).unwrap()]);
    world.raiders[0].task = Task::None;
    order(&mut world, 0, 3, 2);
    run_for(&mut world, TICKS_PER_SECOND);
    let r = &world.raiders[0];
    assert!(r.slowed_until > world.tick, "crossing the shards");
    assert_eq!(world.pace_here(world.grid.tile_at(r.at.x, r.at.y), true, r.slowed_until),
               (7, 10), "30% slower");
}

#[test]
fn honey_trap_sticks_whoever_comes_to_touch_a_regrown_hedge() {
    let mut world = ward_world(1, WardKind::ThornHedge, (5, 3));
    weave(&mut world, &["honeycomb", "bloom"]);
    world.wards[0].regrown = true;
    put(&mut world, 0, 2, 3);
    order(&mut world, 0, 4, 3);
    let mut stuck = None;
    for _ in 0..(3 * TICKS_PER_SECOND) {
        world.step();
        if stuck.is_none() && world.raiders[0].frozen_until > 0 {
            stuck = Some((world.tick - 1, world.raiders[0].frozen_until, tile_of(&world, 0)));
        }
    }
    let (at, until, tile) = stuck.expect("it touches the hedge");
    assert_eq!((until - at, tile), (h::HONEY_TICKS, (4, 3)), "a second, beside it");
}

#[test]
fn northern_lights_makes_the_bands_the_only_light() {
    let mut world = vault_world(0);
    weave(&mut world, &["aurora", "glowing_dark"]);
    world.tick = 150;                               // the band is on rows 6 and 7
    assert!(!world.unlit(world.grid.index(3, 6).unwrap()), "inside the band: lit");
    assert!(world.unlit(world.grid.index(3, 1).unwrap()), "outside it: dark");
}

// Chords (§8.5) -----------------------------------------------------------

#[test]
fn tempest_speeds_everyone_and_lights_the_realm_every_twenty_seconds() {
    let mut world = vault_world(1);
    weave(&mut world, &["half_gravity", "brittle_stone", "glass"]);
    assert!(world.combos.chord(Chord::Tempest));
    assert_eq!(world.sheet.factor(P::CrewSpeed), (6, 5));
    assert_eq!(world.sheet.factor(P::GuardSpeed), (6, 5));
    run_for(&mut world, h::TEMPEST_TICKS + 1);
    assert_eq!(world.light, Some((true, h::TEMPEST_TICKS + h::TEMPEST_FLASH_TICKS)));
}

#[test]
fn deep_sleep_dozes_every_guard_and_muffles_footsteps() {
    let sleep = ["slow_rivers", "stillness", "kinship"];
    assert!(heard(&[], 4, Gait::Walk), "walking carries two steps");
    assert!(!heard(&sleep, 4, Gait::Walk), "muffled to one");
    let mut world = vault_world(1);
    weave(&mut world, &sleep);
    let g = post(&mut world, 0, 12, 2);
    run_for(&mut world, h::DEEP_SLEEP_TICKS + 1);
    assert_eq!(world.guards[g].stunned_until, h::DEEP_SLEEP_TICKS + h::DOZE_TICKS);
}

#[test]
fn ghost_tide_sends_the_knocked_out_back_to_where_they_landed() {
    let mut world = vault_world(2);
    weave(&mut world, &["half_gravity", "echoes", "stillness"]);
    world.landing = world.grid.index(13, 5);        // landed on the east edge
    put(&mut world, 1, 9, 9);
    world.raiders[1].revived = true;                // Echoes already spent
    world.raiders[1].health = 0;
    run_for(&mut world, h::DOWN_TICKS + 2);
    let r = &world.raiders[1];
    assert!(r.active(), "not caught");
    assert_eq!(tile_of(&world, 1), (13, 5), "the landing spot (5.4)");
    assert_eq!(r.health, 180 * 30 / 100, "at the revive health");
}

#[test]
fn fair_lights_draws_the_nearest_guard_to_an_illusion() {
    let mut world = vault_world(1);
    weave(&mut world, &["glass", "kinship", "soul_swap"]);
    let near = post(&mut world, 0, 12, 2);
    put(&mut world, 0, 0, 12);
    run_for(&mut world, h::FAIR_LIGHTS_TICKS + 1);
    let g = &world.guards[near];
    assert_eq!(g.state, State::Investigating);
    assert!(g.interest.is_some_and(|t| world.bare(t)), "drawn to open ground");
}

#[test]
fn iron_bell_carries_sound_two_further_and_sight_two_shorter() {
    let bell = ["slow_rivers", "echoes", "glass"];
    assert!(!heard(&[], 6, Gait::Walk), "four steps: walking carries two");
    assert!(heard(&bell, 6, Gait::Walk), "two more");
    let mut world = scout_and_raider(15, 0);
    world.weave(&[("slow_rivers", (0, 13)), ("echoes", (1, 13)), ("glass", (2, 13))]);
    assert_eq!(rate(&world), Some(33), "1.5 m is seen as 3.5: the mid zone, not near");
}

#[test]
fn mirage_shows_a_moving_crew_member_on_the_tile_it_just_left() {
    let mut world = scout_and_raider(20, 0);          // (8, 6), east of the Scout
    world.weave(&[("half_gravity", (0, 13)), ("soul_swap", (1, 13)), ("glass", (2, 13))]);
    assert!(world.combos.chord(Chord::Mirage));
    let from = world.grid.tile_at(world.raiders[0].at.x, world.raiders[0].at.y).unwrap();
    world.raiders[0].route = vec![world.grid.index(9, 6).unwrap(), world.grid.index(10, 6).unwrap()];
    while tile_of(&world, 0) != (9, 6) {
        world.step();
    }
    assert!(!world.raiders[0].still());
    assert_eq!(world.noticed(0, 0).map(|(_, t)| t), Some(from), "seen where it was");
}

#[test]
fn clockwork_triggers_every_ward_together_every_fifteen_seconds() {
    let mut world = ward_world(1, WardKind::LanternGlare, (12, 12));
    weave(&mut world, &["slow_rivers", "brittle_stone", "echoes"]);
    assert!(world.combos.chord(Chord::Clockwork));
    put(&mut world, 0, 1, 1);                       // nowhere near it
    run_for(&mut world, h::CLOCKWORK_TICKS + 1);
    assert_eq!(world.revealed_until(), h::CLOCKWORK_TICKS + h::GLARE_REVEAL_TICKS, "it fired");
}

#[test]
fn wild_hunt_silences_running() {
    let hunt = ["half_gravity", "brittle_stone", "stillness"];
    assert!(heard(&[], 5, Gait::Run));
    assert!(!heard(&hunt, 5, Gait::Run), "running makes no noise at all");
    assert!(heard(&hunt, 4, Gait::Walk), "walking still does");
}

#[test]
fn hidden_garden_spreads_tall_grass_a_tile_a_minute() {
    let mut world = vault_world(1);
    weave(&mut world, &["kinship", "stillness", "soul_swap"]);
    world.grid.place(9, 9, Feature::TallGrass);
    put(&mut world, 0, 0, 1);
    run_for(&mut world, h::HIDDEN_GARDEN_TICKS);
    assert_eq!(world.grid.feature(world.grid.index(9, 8).unwrap()), None, "not yet");
    world.step();
    for (x, y) in [(9, 8), (10, 9), (9, 10), (8, 9)] {
        assert_eq!(world.grid.feature(world.grid.index(x, y).unwrap()), Some(Feature::TallGrass));
    }
}

#[test]
fn lantern_festival_returns_each_character_once_at_the_revive_health() {
    let mut world = vault_world(1);
    weave(&mut world, &["glass", "kinship", "regrowth"]);
    assert_eq!(world.revival(), Some(crate::Revival::Return(3, 10)));
    put(&mut world, 0, 3, 3);
    world.raiders[0].health = 0;
    world.step();
    assert!(world.raiders[0].active());
    assert_eq!(world.raiders[0].health, 120 * 3 / 10);
}

#[test]
fn quicksand_opens_hidden_pits_that_drop_whoever_steps_in() {
    let mut world = vault_world(1);
    weave(&mut world, &["slow_rivers", "soul_swap", "stillness"]);
    world.step();
    assert_eq!(world.pits.len(), h::QUICKSAND_PITS);
    let pit = world.pits[0];
    let (px, py) = world.grid.coords(pit);
    let beside = world.grid.neighbours(pit).into_iter().flatten()
        .find(|&t| world.grid.at(t).passable() && !world.pits.contains(&t)).unwrap();
    let (bx, by) = world.grid.coords(beside);
    put(&mut world, 0, bx, by);
    order(&mut world, 0, px as i16, py as i16);
    let mut fell = None;
    for _ in 0..(4 * TICKS_PER_SECOND) {
        world.step();
        if fell.is_none() && world.raiders[0].frozen_until > 0 {
            fell = Some((world.tick - 1, world.raiders[0].frozen_until));
        }
    }
    let (at, until) = fell.expect("it steps in");
    assert_eq!(until - at, h::PIT_HOLD_TICKS, "a second to climb out");
}

#[test]
fn rebound_bounces_every_stun_on_to_the_nearest_enemy() {
    let mut world = vault_world(2);
    weave(&mut world, &["half_gravity", "echoes", "static"]);
    assert!(world.combos.chord(Chord::Rebound));
    put(&mut world, 0, 1, 3);
    put(&mut world, 1, 7, 3);
    let g = post(&mut world, 0, 9, 3);
    world.guards[g].knocked_out = false;
    world.guards[g].facing = Ang::from_degrees(0);  // east: its back to the crew
    order(&mut world, 0, 6, 3);
    let mut both = None;
    for _ in 0..(4 * TICKS_PER_SECOND) {
        world.step();
        if both.is_none() && world.raiders[1].frozen_until > 0 {
            both = Some((world.raiders[1].frozen_until, world.guards[g].stunned_until));
        }
    }
    let (ally, guard) = both.expect("a touch");
    assert_eq!(ally, guard, "the same stun, bounced on");
}

// --------------------------------------------------------------------------
// Editing an island, as the builder does
// --------------------------------------------------------------------------

use crate::island::{Island, Occupant, Problem};

#[test]
fn a_blank_island_is_publishable_and_round_trips() {
    for level in 1..=5 {
        let island = Island::blank(level);
        assert_eq!(island.check(), vec![], "realm level {level}");
        assert_eq!(Island::decode(&island.encode()).unwrap(), island);
    }
}

#[test]
fn an_edited_island_is_one_the_format_can_write_and_check_can_judge() {
    let mut island = Island::blank(3);
    assert!(island.set_feature(2, 4, Some(Feature::RockPillar)));
    assert!(!island.set_feature(2, 4, Some(Feature::Vault)), "the Vault comes from its own list");
    assert!(island.weave("haste", 1, 10));
    assert!(island.weave("haste", 2, 10), "a law is woven once: its pylon moves");
    assert_eq!(island.laws, vec![("haste".to_string(), 2, 10)]);
    assert!(!island.weave("no_such_law", 3, 3));
    assert!(island.place_ward(WardKind::TimeSnare, 5, 5));
    assert!(island.post_guard(1, 7, 7));
    assert!(island.post_guard(2, 7, 7), "a post replaces what stood there");
    assert_eq!(island.guards.len(), 1);
    assert_eq!(island.occupant(5, 5), Occupant::Ward(0));
    let (vx, vy) = island.vault;
    assert!(!island.place_ward(WardKind::TimeSnare, vx, vy), "the Vault cannot be covered");
    assert!(!island.clear(vx, vy), "or removed, only moved");
    assert_eq!(Island::decode(&island.encode()).unwrap(), island);
    assert_eq!(island.check(), vec![]);
    // Walls round the Vault seal it (§6.1), and check says so.
    for (x, y) in [(vx - 1, vy), (vx + 1, vy), (vx, vy - 1), (vx, vy + 1)] {
        island.set_feature(x, y, Some(Feature::RockPillar));
    }
    assert_eq!(island.check(), vec![Problem::Sealed]);
    assert!(island.clear(vx - 1, vy));
    assert_eq!(island.check(), vec![]);
}

// --------------------------------------------------------------------------
// §10.1: buildings on the grid
// --------------------------------------------------------------------------

use crate::island::{building_code, Malformed};

fn spire() -> u8 {
    building_code("keeper_s_spire").unwrap()
}

fn well() -> u8 {
    building_code("star_well").unwrap()
}

#[test]
fn a_building_blocks_feet_and_eyes_on_every_tile_of_its_footprint() {
    // "Buildings sit on the realm grid and block movement and sight. Most
    // are 2 by 2 tiles; the Spire and Vault are 3 by 3."
    let mut island = Island::blank(3);
    assert!(island.place_building(spire(), 2, 2));
    assert!(island.place_building(well(), 7, 2));
    let grid = island.ground();
    let square = |x0: u16, y0: u16, side: u16| {
        (x0..x0 + side).flat_map(move |x| (y0..y0 + side).map(move |y| (x, y)))
    };
    for (x, y) in square(2, 2, 3).chain(square(7, 2, 2)) {
        let t = grid.index(x, y).unwrap();
        assert_eq!(grid.feature(t), Some(Feature::Building), "({x}, {y}) is under a building");
        assert!(!grid.at(t).passable() && grid.blocks_sight(t));
    }
    for (x, y) in [(5, 2), (2, 5), (9, 2), (7, 4), (6, 3)] {
        assert!(grid.at(grid.index(x, y).unwrap()).passable(), "({x}, {y}) is beside one");
    }
    let at = |x, y| grid.index(x, y).unwrap();
    assert!(!sight::visible(&grid, at(1, 3), at(8, 3)), "the Spire stands between");
    assert!(sight::visible(&grid, at(1, 6), at(8, 6)), "south of it the line is open");
    assert!(walled_by(Feature::Building) && !seen_past(Feature::Building));
}

#[test]
fn no_crew_walks_through_a_building_on_its_way_across_the_realm() {
    // The Spire's 3 by 3 squarely between the landing and the tile the crew
    // is sent to: every member goes round it, and gets there.
    let mut island = Island::blank(3);
    assert!(island.place_building(spire(), 4, 3));
    assert_eq!(island.check(), vec![]);
    let to = (5, 8);
    let go: Vec<Command> = (0..3).map(|actor| Command {
        tick: 0, actor, kind: Kind::MoveTo, x: to.0 * 256 + 128, y: to.1 * 256 + 128,
    }).collect();
    let mut world = landed(&island, (5, 0), go);
    let footprint: Vec<_> = island.footprint_tiles(0).iter()
        .map(|&(x, y)| world.grid.index(x as u16, y as u16).unwrap()).collect();
    for _ in 0..30 * TICKS_PER_SECOND {
        world.step();
        for r in &world.raiders {
            let t = world.grid.tile_at(r.at.x, r.at.y).unwrap();
            assert!(!footprint.contains(&t), "crew member {} stood in the Spire", r.id);
        }
    }
    let there = world.grid.index(to.0 as u16, to.1 as u16).unwrap();
    assert!(world.raiders.iter().any(|r| world.grid.tile_at(r.at.x, r.at.y) == Some(there)),
            "the crew went round and arrived");
}

#[test]
fn an_island_keeps_its_buildings_and_one_without_keeps_its_bytes() {
    let mut island = Island::blank(3);
    let before = island.encode();
    assert!(island.place_building(spire(), 2, 2));
    let bytes = island.encode();
    assert_eq!(&bytes[..before.len()], &before[..], "an island with no building ends at its laws");
    assert_eq!(bytes.len(), before.len() + 4);
    assert_eq!(Island::decode(&bytes), Ok(island.clone()));
    let with = |tail: &[u8]| {
        let mut b = before.clone();
        b.extend_from_slice(tail);
        Island::decode(&b)
    };
    assert_eq!(with(&[0]), Err(Malformed::NoBuildings), "a list of none is written by leaving it out");
    assert_eq!(with(&[1, 99, 0, 0]), Err(Malformed::UnknownBuilding));
    assert_eq!(with(&[1, spire(), 10, 0]), Err(Malformed::OffGrid), "the 3 by 3 overhangs a 12-tile side");
    assert_eq!(with(&[1, well(), 10, 10]).map(|i| i.buildings), Ok(vec![(well(), 10, 10)]));
    assert_eq!(with(&[2, spire(), 0, 0]), Err(Malformed::Truncated));
}

#[test]
fn a_building_is_crowded_by_what_stands_under_it_and_can_seal_the_vault() {
    let (vx, vy) = Island::blank(3).vault;
    // Written straight into the lists, as a bundle could: check judges it.
    let mut island = Island::blank(3);
    island.wards.push((WardKind::ThornHedge, 3, 3));
    island.buildings.push((spire(), 2, 2));
    assert_eq!(island.check(), vec![Problem::Crowded]);
    let mut island = Island::blank(3);
    island.buildings = vec![(well(), 2, 2), (well(), 3, 3)];
    assert_eq!(island.check(), vec![Problem::Crowded], "two footprints share (3, 3)");
    // The builder clears what a footprint covers, refuses the Vault and the
    // grid's edge, and a tap anywhere in a footprint takes the building.
    let mut island = Island::blank(3);
    assert!(island.place_ward(WardKind::ThornHedge, 3, 3));
    assert!(island.place_building(spire(), 2, 2));
    assert!(island.wards.is_empty());
    assert_eq!(island.occupant(4, 4), Occupant::Building(0));
    assert!(!island.place_building(spire(), vx - 1, vy - 1), "over the Vault");
    assert!(!island.place_building(spire(), 10, 0), "off the grid");
    assert!(island.clear(4, 4));
    assert!(island.buildings.is_empty());
    // A building closes the last side of the Vault (§6.1), and check says so.
    let mut island = Island::blank(3);
    for (x, y) in [(vx - 1, vy), (vx + 1, vy), (vx, vy + 1)] {
        island.set_feature(x, y, Some(Feature::RockPillar));
    }
    assert_eq!(island.check(), vec![]);
    assert!(island.place_building(spire(), vx - 1, vy - 3));
    assert_eq!(island.check(), vec![Problem::Sealed]);
}

// --------------------------------------------------------------------------
// §18.3: eras
// --------------------------------------------------------------------------

use crate::era::Era;
use crate::{record_in, verify_on, Revival};

/// The vault world in an era, with `laws` woven.
fn in_era(era: Option<Era>, laws: &[&str]) -> World {
    let mut world = vault_world(3);
    world.era = era;
    weave(&mut world, laws);
    world
}

#[test]
fn a_heist_with_no_era_is_written_as_before_and_one_with_an_era_names_it() {
    let plain = fixture(3, 4_500, 3);
    let bytes = plain.encode();
    assert_eq!(&bytes[..4], b"RBH1", "no era: the format every replay so far is in");
    let mut era = plain.clone();
    era.era = Some(Era::GlassMoon);
    let with = era.encode();
    assert_eq!(&with[..4], b"RBH2");
    assert_eq!(with.len(), bytes.len() + 1, "one byte, the era");
    assert_eq!(Heist::decode(&with), Some(era));
    assert_eq!(Heist::decode(&bytes), Some(plain));
    let mut bad = with.clone();
    bad[81] = 0;
    assert_eq!(Heist::decode(&bad), None, "an RBH2 always names an era");
    bad[81] = 9;
    assert_eq!(Heist::decode(&bad), None, "and only one of the eight");
}

#[test]
fn the_eras_are_the_contents_eight_with_the_figures_their_rules_state() {
    let ids: Vec<&str> = crate::laws_table::ERAS.iter().map(|(id, _)| *id).collect();
    assert_eq!(ids.len(), 8);
    for (i, id) in ids.iter().enumerate() {
        let era = Era::from_id(id).unwrap();
        assert_eq!((era as usize, era.id()), (i + 1, *id));
    }
    assert_eq!(Era::TheLongNight.figure(), 30);
    assert_eq!(Era::QuietWeek.figure(), 30);
}

#[test]
fn the_long_night_is_first_on_the_sheet_and_every_law_follows_it() {
    // "Vision is 30% shorter everywhere"; Glowing dark then halves it again.
    assert_eq!(in_era(Some(Era::TheLongNight), &[]).sheet.factor(P::SightRange), (7, 10));
    assert_eq!(in_era(Some(Era::TheLongNight), &["glowing_dark"]).sheet.factor(P::SightRange),
               (7, 20));
    assert_eq!(in_era(None, &[]).sheet.factor(P::SightRange), (1, 1));
}

#[test]
fn glass_moon_makes_every_wall_see_through() {
    assert_eq!(in_era(Some(Era::GlassMoon), &[]).sheet.flag(P::HideBehindWalls), Some(0));
    assert_eq!(in_era(None, &[]).sheet.flag(P::HideBehindWalls), None);
}

#[test]
fn heavy_stars_will_not_let_half_gravity_lower_gravity() {
    assert!(in_era(None, &["half_gravity"]).sheet.is_set(P::LeapObstacles));
    let heavy = in_era(Some(Era::HeavyStars), &["half_gravity"]);
    assert!(!heavy.sheet.is_set(P::LeapObstacles), "no gravity to lower");
    assert_eq!(heavy.laws.len(), 1, "still woven");
}

#[test]
fn wildgrowth_makes_each_life_law_a_quarter_stronger_by_what_its_line_is() {
    // Each woven alone: two Life laws together share a note, and their
    // harmony (§8.3) would strengthen them on top of the era.
    let wild = |law: &str, p| in_era(Some(Era::Wildgrowth), &[law]).sheet.factor(p);
    assert_eq!(wild("bloom", P::RegrowSeconds), (8, 1), "Bloom's 10 s comes a quarter sooner");
    assert_eq!(wild("kinship", P::AllyHealing), (3, 160), "Kinship's 1.5% a second, 1.875%");
    assert_eq!(wild("thorns", P::TouchDamage), (1, 16), "Thorns' 5%, 6.25%");
    assert_eq!(wild("regrowth", P::StructureHealing), (1, 40), "Regrowth's 2%, 2.5%");
    assert_eq!(in_era(Some(Era::Wildgrowth), &["wild_paths"]).sheet.factor(P::CrewSpeed), (5, 4),
               "a multiplier moves a quarter further from 1: +20% is +25%");
    assert_eq!(in_era(Some(Era::Wildgrowth), &["spores"]).sheet.factor(P::CrewSpeed), (3, 8),
               "and a slowing one slows more: half is three eighths");
    assert_eq!(in_era(Some(Era::Wildgrowth), &["haste"]).sheet, in_era(None, &["haste"]).sheet,
               "a law of another school is as it was");
}

#[test]
fn echoing_skies_returns_everyone_once_at_forty_and_the_highest_revival_wins() {
    assert!(matches!(in_era(Some(Era::EchoingSkies), &[]).revival(), Some(Revival::Return(40, 100))));
    assert!(in_era(None, &[]).revival().is_none());
    // Echoes' 60% covers the same knockout: the highest N applies (§7.3).
    assert!(matches!(in_era(Some(Era::EchoingSkies), &["echoes"]).revival(), Some(Revival::Return(3, 5))));
}

#[test]
fn static_storm_makes_the_static_coils_shock_half_again() {
    let shock = |era: Option<Era>| {
        let mut world = ward_world(1, WardKind::StaticCoil, (3, 3));
        world.era = era;
        put(&mut world, 0, 3, 4);
        let full = world.raiders[0].health;
        for _ in 0..=h::COIL_PERIOD_TICKS {
            world.step();
        }
        (full, full - world.raiders[0].health)
    };
    let (full, plain) = shock(None);
    assert_eq!(plain, full * 8 / 100);
    assert_eq!(shock(Some(Era::StaticStorm)).1, full * 12 / 100, "8% of health becomes 12%");
}

#[test]
fn quiet_week_heists_may_run_thirty_seconds_past_the_longest() {
    let island = crate::island::Island::fixture();
    let ticks = crate::MAX_TICKS + 30 * TICKS_PER_SECOND;
    let long = |era| record_in(&island, 5, ticks, 3, era, crate::draw(&island, 5, ticks, 3));
    assert!(verify_on(&island, &long(Some(Era::QuietWeek))).is_ok());
    assert!(verify_on(&island, &long(None)).is_err(), "240 seconds is the longest otherwise");
}

#[test]
fn a_heist_re_simulates_in_the_era_it_names_and_no_other() {
    let island = crate::island::Island::fixture();
    let played = record_in(&island, 11, 4_500, 3, Some(Era::TheLongNight), crate::draw(&island, 11, 4_500, 3));
    assert!(verify_on(&island, &played).is_ok());
    let plain = crate::record(&island, 11, 4_500, 3, crate::draw(&island, 11, 4_500, 3));
    assert_ne!(played.checksums, plain.checksums, "the era changed what happened");
    let mut claimed = played.clone();
    claimed.era = None;
    assert!(verify_on(&island, &claimed).is_err(), "a device cannot say it played in a kinder week");
}

// -- §5.4's landing ---------------------------------------------------------

/// A world on `island` whose log lands the crew on (x, y) at tick 0, after
/// `rest` in the log's order, with the landing applied and nothing else run.
fn landed(island: &crate::island::Island, (x, y): (i16, i16), rest: Vec<Command>) -> World {
    let mut commands = rest;
    commands.push(Command { tick: 0, actor: 2, kind: Kind::Land, x: x * 256 + 128, y: y * 256 + 128 });
    commands.sort_by_key(|c| c.tick);
    let heist = Heist {
        seed: 1, island: island.digest(), rules: crate::rules_version(), ticks: 4_500, crew: 3,
        era: None, manifest: None, commands, checksums: Vec::new(),
    };
    let mut world = World::from_island(island, &heist);
    world.phase_inputs();
    world
}

#[test]
fn the_whole_crew_lands_on_the_spot_the_log_names() {
    let island = crate::island::Island::fixture();
    let world = landed(&island, (13, 2), Vec::new());
    let spot = world.grid.index(13, 2).unwrap();
    assert_eq!(world.landing, Some(spot));
    let (x, y) = world.grid.centre(spot);
    for r in &world.raiders {
        assert_eq!((r.at.x, r.at.y), (x, y), "crew member {} is on the spot", r.id);
        assert_eq!(r.last_tile, Some(spot));
    }
    // A move given at tick 0 is a move from the landing, wherever the log
    // puts it among tick 0's commands: here, before the landing.
    let first = Command { tick: 0, actor: 0, kind: Kind::MoveTo, x: 13 * 256 + 128, y: 6 * 256 + 128 };
    let world = landed(&island, (13, 2), vec![first]);
    let route = &world.raiders[0].route;
    assert_eq!(route.first().map(|t| world.grid.coords(*t)), Some((13, 3)), "the route starts beside the spot");
}

#[test]
fn a_landing_is_heard_within_six_tiles_unless_the_spot_is_hidden() {
    use crate::grid::Feature;
    use crate::heist::{LANDING_HEARD_TILES, LANDING_SUSPICION};
    let island = crate::island::Island::fixture();
    let world = landed(&island, (13, 2), Vec::new());
    let spot = world.grid.index(13, 2).unwrap();
    assert!(!world.grid.is_unlit(spot) && world.grid.feature(spot).is_none(), "an open, lit spot");
    // Six steps walked, as every sound travels (§12.17): the Mender at
    // (12, 2) and the Breaker at (9, 4) are, the others are not.
    let walked = crate::noise::field(&world.grid, spot, LANDING_HEARD_TILES as u16);
    let (mut heard, mut unheard) = (0, 0);
    for g in &world.guards {
        let at = world.grid.tile_at(g.at.x, g.at.y).unwrap();
        if walked[at as usize] != crate::noise::UNHEARD {
            assert_eq!(g.suspicion, LANDING_SUSPICION, "guard {} is within six steps", g.id);
            heard += 1;
        } else {
            assert_eq!(g.suspicion, 0, "guard {} is beyond six steps", g.id);
            unheard += 1;
        }
    }
    assert_eq!((heard, unheard), (2, 3), "the spot has guards on both sides of the line");

    // A wall between: the Breaker, 4.5 tiles away in a straight line, is
    // more than six steps round the pillars, and does not hear it.
    let mut walled = crate::island::Island::fixture();
    let side = walled.side() as usize;
    for y in 0..8 {
        walled.tiles[y * side + 11].feature = Some(Feature::RockPillar);
    }
    let world = landed(&walled, (13, 2), Vec::new());
    let breaker = world.guards.iter().find(|g| g.id == 2).unwrap();
    assert_eq!(breaker.suspicion, 0, "not heard through the wall");
    let mender = world.guards.iter().find(|g| g.id == 4).unwrap();
    assert_eq!(mender.suspicion, LANDING_SUSPICION, "heard on its own side");

    // Tall grass, fog or darkness on the spot: nobody hears it.
    for hide in 0..3 {
        let mut hidden = crate::island::Island::fixture();
        let side = hidden.side() as usize;
        let tile = &mut hidden.tiles[2 * side + 13];
        match hide {
            0 => tile.feature = Some(Feature::TallGrass),
            1 => tile.feature = Some(Feature::FogBank),
            _ => tile.unlit = true,
        }
        let world = landed(&hidden, (13, 2), Vec::new());
        assert!(world.landing.is_some());
        assert!(world.guards.iter().all(|g| g.suspicion == 0), "hidden landing {hide} is unheard");
    }
}

#[test]
fn a_landing_spot_is_marked_covered_from_the_terrain_alone_as_the_simulation_hears_it() {
    use crate::grid::Feature;
    // §5.4 and §12.4: the picker marks each edge spot covered or open from
    // the terrain alone, so the marks are the same whatever guards and wards
    // the island places, and a covered spot is one no guard hears.
    let mut island = crate::island::Island::fixture();
    let side = island.side() as usize;
    island.tiles[2 * side + 13].feature = Some(Feature::FogBank);
    island.tiles[side - 1].unlit = true;
    let marks = |i: &crate::island::Island| -> Vec<bool> {
        i.landings().iter().map(|&(x, y)| i.landing_covered(x, y)).collect()
    };
    let with = marks(&island);
    assert!(island.landing_covered(13, 2) && island.landing_covered(side as u8 - 1, 0));
    assert!(with.iter().any(|&c| !c), "most of the edge is open");
    let mut bare = island.clone();
    bare.guards.clear();
    bare.wards.clear();
    assert_eq!(marks(&bare), with, "guards and wards change no mark");
    for (k, &(x, y)) in island.landings().iter().enumerate().step_by(5) {
        let world = landed(&island, (x as i16, y as i16), Vec::new());
        assert_eq!(world.landing_reach(), crate::heist::LANDING_HEARD_TILES as u16, "no law stretches it here");
        if with[k] {
            assert!(world.guards.iter().all(|g| g.suspicion == 0), "covered ({x}, {y}) is unheard");
        }
    }
}

#[test]
fn a_landing_off_the_edge_late_or_twice_is_dropped() {
    let island = crate::island::Island::fixture();
    // Inland, off the grid, and on a closed edge tile.
    assert_eq!(landed(&island, (6, 6), Vec::new()).landing, None);
    assert_eq!(landed(&island, (40, 0), Vec::new()).landing, None);
    let mut closed = crate::island::Island::fixture();
    let side = closed.side() as usize;
    closed.tiles[13 * side + 13].feature = Some(crate::grid::Feature::RockPillar);
    assert_eq!(landed(&closed, (13, 13), Vec::new()).landing, None);
    // A second landing at tick 0 is not a second skiff: the first stands.
    let second = Command { tick: 0, actor: 1, kind: Kind::Land, x: 13 * 256 + 128, y: 2 * 256 + 128 };
    let world = landed(&island, (0, 5), vec![second]);
    assert_eq!(world.landing, world.grid.index(13, 2), "the first in the log's order lands");
    // A landing after tick 0, in a world that has not landed, moves nobody.
    let late = Command { tick: 1, actor: 0, kind: Kind::Land, x: 13 * 256 + 128, y: 2 * 256 + 128 };
    let heist = Heist {
        seed: 1, island: island.digest(), rules: crate::rules_version(), ticks: 4_500, crew: 3,
        era: None, manifest: None, commands: vec![late], checksums: Vec::new(),
    };
    let mut world = World::from_island(&island, &heist);
    let before: Vec<_> = world.raiders.iter().map(|r| (r.at.x, r.at.y)).collect();
    world.step();
    world.step();
    assert_eq!(world.landing, None, "a late landing is no landing");
    let after: Vec<_> = world.raiders.iter().map(|r| (r.at.x, r.at.y)).collect();
    assert_eq!(before, after, "nobody moved");
}

#[test]
fn the_server_refuses_a_heist_that_never_lands() {
    use crate::island::Island;
    use crate::{draw, record, verify_on, Refusal};
    let island = Island::example();
    let drawn = draw(&island, 42, 4_500, 3);
    assert_eq!(drawn.iter().filter(|c| c.kind == Kind::Land).count(), 1, "the seeded player lands");
    assert!(verify_on(&island, &record(&island, 42, 4_500, 3, drawn.clone())).is_ok());
    let unlanded: Vec<Command> = drawn.iter().copied().filter(|c| c.kind != Kind::Land).collect();
    let heist = record(&island, 42, 4_500, 3, unlanded);
    assert_eq!(verify_on(&island, &heist), Err(Refusal::Landing));
    let mut inland = drawn.clone();
    for c in inland.iter_mut().filter(|c| c.kind == Kind::Land) {
        (c.x, c.y) = (6 * 256 + 128, 7 * 256 + 128);
    }
    assert_eq!(verify_on(&island, &record(&island, 42, 4_500, 3, inland)), Err(Refusal::Landing));
}

#[test]
fn every_open_edge_tile_is_a_landing_and_nothing_else_is() {
    use crate::island::Island;
    let island = Island::example();
    let landings = island.landings();
    let world = World::on_ground(&island, 3, Vec::new());
    let side = island.side() as u8;
    for y in 0..side {
        for x in 0..side {
            let t = world.grid.index(x as u16, y as u16).unwrap();
            let open = world.grid.is_edge(t) && world.grid.at(t).passable()
                && !island.laws.iter().any(|(_, lx, ly)| (*lx, *ly) == (x, y));
            assert_eq!(landings.contains(&(x, y)), open, "({x}, {y})");
        }
    }
    // Every one lands a world.
    for &(x, y) in &landings {
        assert!(landed(&island, (x as i16, y as i16), Vec::new()).landing.is_some(), "({x}, {y})");
    }
}

// -- §12.5's crew manifest and §12.6's abilities (TD.12) -----------------------

use crate::replay::{Manifest, Member, MAGIC_CREW};
use crate::ruleborn::{self, RULEBORN};

fn manifest(kinds: &[&str]) -> Manifest {
    Manifest {
        members: kinds.iter().map(|id| Member {
            kind: ruleborn::by_id(id).unwrap_or_else(|| panic!("no kind {id}")),
            form: 0,
            level: 1,
            traits: Vec::new(),
        }).collect(),
        sage: 0,
        casts: Vec::new(),
    }
}

/// `vault_world`'s open 14x14 realm with a crew of these kinds, in portrait
/// order, standing in a row along y = 10.
fn kinds_world(kinds: &[&str]) -> World {
    let mut world = vault_world(kinds.len() as u8);
    world.crew_from(&manifest(kinds));
    for i in 0..kinds.len() {
        put(&mut world, i, 2 + 2 * i as u16, 10);
    }
    world
}

/// Crew member `ri`'s ability, aimed at tile (x, y), now.
fn fire_at(world: &mut World, ri: u8, x: u16, y: u16) {
    world.give(ri, Kind::Ability, x as i16 * 256 + 128, y as i16 * 256 + 128);
}

#[test]
fn a_crew_manifest_travels_in_the_replay_and_reads_back() {
    let mut heist = fixture(9, 60, 3);
    let plain = heist.encode();
    assert_eq!(&plain[..4], b"RBH1", "no manifest: the bytes every replay so far is in");
    let mut crew = manifest(&["stormhound", "quarryback", "skyskipper"]);
    crew.members[1].form = 2;
    crew.members[1].level = 7;
    crew.members[1].traits = vec![0, 6];
    crew.sage = 1;
    crew.casts = vec![3];
    heist.manifest = Some(crew);
    for era in [None, Some(Era::QuietWeek)] {
        heist.era = era;
        let bytes = heist.encode();
        assert_eq!(&bytes[..4], &MAGIC_CREW);
        assert_eq!(Heist::decode(&bytes).as_ref(), Some(&heist), "round trip, era {era:?}");
        assert!(heist.size_fits(), "\u{a7}24.10's 2 KB holds a manifest");
    }
}

#[test]
fn a_manifest_naming_a_kind_past_the_eighteen_is_malformed() {
    let mut heist = fixture(9, 60, 1);
    heist.manifest = Some(manifest(&["mossbear"]));
    let mut bytes = heist.encode();
    let kind_at = 4 + 8 + 32 + 32 + 4 + 1 + 1;          // after the era byte
    assert_eq!(bytes[kind_at], ruleborn::by_id("mossbear").unwrap());
    bytes[kind_at] = RULEBORN.len() as u8;
    assert_eq!(Heist::decode(&bytes), None, "no nineteenth kind");
}

#[test]
fn each_member_plays_its_kinds_role_size_and_two_uses() {
    let world = kinds_world(&["emberling", "glass_golem", "lantern_wisp"]);
    let (r0, r1, r2) = (&world.raiders[0], &world.raiders[1], &world.raiders[2]);
    assert_eq!((r0.role, r0.size), (Role::Breaker, crate::Size::Small));
    assert_eq!((r1.role, r1.size), (Role::Warden, crate::Size::Large));
    assert_eq!((r2.role, r2.size), (Role::Scout, crate::Size::Small));
    assert_eq!(r0.uses, ruleborn::USES, "\u{a7}12.6: \"two uses a heist\"");
    assert_eq!(r0.health, Role::Breaker.health(), "\u{a7}11.1's numbers, by role");
    let by_role = World::new(1, 3, Vec::new());
    assert!(by_role.raiders.iter().all(|r| r.kind.is_none() && r.uses == 0),
            "a crew with no manifest plays by role, with no abilities");
}

#[test]
fn a_heist_with_a_manifest_records_and_verifies() {
    let island = Island::fixture();
    let mut commands = crate::draw(&island, 4, 600, 3);
    let at = commands.iter().position(|c| c.tick > 30).unwrap();
    commands.insert(at, Command { tick: commands[at].tick, actor: 0, kind: Kind::Ability,
                                   x: 0, y: 0 });
    let mut heist = crate::record(&island, 4, 600, 3, Vec::new());
    heist.manifest = Some(manifest(&["stormhound", "rambler", "skyskipper"]));
    heist.commands = commands;
    heist.checksums = crate::run_on(&island, &heist).iter().map(|s| crate::truncate(*s)).collect();
    let back = Heist::decode(&heist.encode()).unwrap();
    assert_eq!(crate::run_on(&island, &back).len(), heist.checksums.len());
    assert_eq!(crate::run_on(&island, &back).iter().map(|s| crate::truncate(*s)).collect::<Vec<_>>(),
               heist.checksums, "the same manifest plays the same heist");
    let mut by_role = heist.clone();
    by_role.manifest = None;
    assert_ne!(crate::run_on(&island, &by_role).iter().map(|s| crate::truncate(*s)).collect::<Vec<_>>(),
               heist.checksums, "and without it the crew is another crew");
}

#[test]
fn density_reads_a_small_kind_by_its_size_whatever_its_role() {
    // G23: sizing by role made the Warden the only large character and
    // nobody small, so Density's small band never played. The Emberling is
    // a small Breaker.
    let mut world = kinds_world(&["emberling", "quarryback"]);
    world.weave(&[("density", (0, 13))]);
    assert_eq!(world.raiders[0].health, Role::Breaker.health() * 4 / 5,
               "small: -20% health, a Breaker all the same");
    assert_eq!(world.raiders[1].health, Role::Breaker.health(), "a standard Breaker");
    let plain = crate::Sheet::plain();
    let e = &world.raiders[0];
    assert_eq!(crate::step_for(&world.grid, &world.sheet, e, e.gait, None, false),
               crate::step_for(&world.grid, &plain, e, e.gait, None, false)
                   .mul(Fx::from_ratio(5, 4)),
               "small: +25% speed");
}

#[test]
fn an_ability_has_two_uses_ten_seconds_apart() {
    let mut world = kinds_world(&["stormhound"]);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert_eq!(world.raiders[0].uses, 1);
    run_for(&mut world, 5 * TICKS_PER_SECOND);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert_eq!(world.raiders[0].uses, 1, "inside the lockout: refused, nothing spent");
    run_for(&mut world, ruleborn::LOCKOUT_TICKS);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert_eq!(world.raiders[0].uses, 0, "ten seconds on: the second use");
    run_for(&mut world, ruleborn::LOCKOUT_TICKS);
    assert!(!world.raiders[0].ready, "no uses left: never ready again");
}

#[test]
fn at_most_four_abilities_are_ready_and_the_fifth_waits_its_turn() {
    let mut world = kinds_world(&["stormhound", "quarryback", "skyskipper", "mossbear",
                                  "bloomling"]);
    world.step();
    let ready = |w: &World| w.raiders.iter().map(|r| r.ready).collect::<Vec<_>>();
    assert_eq!(ready(&world), [true, true, true, true, false],
               "\u{a7}12.6: \"the rightmost portrait's ability waits\"");
    fire_at(&mut world, 1, 0, 0);                    // the Quarryback's pound
    world.step();
    world.step();
    assert_eq!(ready(&world), [true, false, true, true, true],
               "\"becomes ready the moment any other ability's use is taken\"");
    run_for(&mut world, ruleborn::LOCKOUT_TICKS);
    assert!(!world.raiders[1].ready,
            "\"an ability whose lockout ends while four are ready waits its turn\"");
    fire_at(&mut world, 0, 0, 0);
    world.step();
    world.step();
    assert_eq!(ready(&world), [false, true, true, true, true], "and takes the next turn");
}

#[test]
fn an_ability_with_nothing_to_act_on_spends_no_use() {
    let mut world = kinds_world(&["hourkeeper", "glass_golem", "featherkin"]);
    fire_at(&mut world, 0, 12, 12);                   // nobody there
    world.step();
    assert_eq!(world.raiders[0].uses, 2, "a rewind aimed at an empty tile is dropped");
    fire_at(&mut world, 1, 4, 10);                    // where the golem stands
    world.step();
    assert_eq!(world.raiders[1].uses, 2, "a wall aimed at the golem's own tile is dropped");
    fire_at(&mut world, 2, 5, 9);                     // it stands on (6, 10)
    world.step();
    assert_eq!(world.raiders[2].uses, 2, "a glide aimed off its row and column is dropped");
}

#[test]
fn the_stormhounds_sprint_runs_sixty_percent_faster_for_four_seconds() {
    let walk = |sprint: bool| {
        let mut world = kinds_world(&["stormhound"]);
        put(&mut world, 0, 1, 1);
        if sprint {
            fire_at(&mut world, 0, 0, 0);
            world.step();
        }
        let from = world.raiders[0].at;
        let a = world.grid.index(1, 1).unwrap();
        let b = world.grid.index(12, 1).unwrap();
        world.raiders[0].route = path::find(&world.grid, a, b).unwrap();
        world.raiders[0].along = 0;
        run_for(&mut world, TICKS_PER_SECOND);
        from.distance(world.raiders[0].at)
    };
    let (plain, fast) = (walk(false), walk(true));
    // Thirty steps each rounded to the fixed-point unit: equal to well under
    // a ten-thousandth of a tile.
    let off = (fast.0 - plain.mul(Fx::from_ratio(8, 5)).0).abs();
    assert!(off < Fx::from_ratio(1, 10_000).0, "\"Sprints 60% faster\", off by {off}");
    let mut world = kinds_world(&["stormhound"]);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert!(world.raiders[0].running(ruleborn::Ability::Sprint, 4 * TICKS_PER_SECOND - 1));
    assert!(!world.raiders[0].running(ruleborn::Ability::Sprint, 4 * TICKS_PER_SECOND),
            "\"for 4 s\"");
}

/// A crew of these kinds beside an open Vault holding plenty, each told to
/// load to full; how much each has after `ticks`.
fn loaded_after(kinds: &[&str], fire: Option<u8>, ticks: u32) -> Vec<i32> {
    let mut world = kinds_world(kinds);
    world.vault.opened_at = Some(0);
    world.vault.exposed = 10_000;
    for i in 0..kinds.len() {
        let (x, y) = BESIDE[i];
        put(&mut world, i, x, y);
        world.raiders[i].task = Task::Load;
        world.raiders[i].target_fill = 100;
    }
    if let Some(ri) = fire {
        fire_at(&mut world, ri, 0, 0);
    }
    run_for(&mut world, ticks);
    world.raiders.iter().map(|r| r.carried).collect()
}

#[test]
fn the_skyskippers_satchel_loads_sixty_a_second_for_five_seconds() {
    assert_eq!(loaded_after(&["skyskipper"], None, TICKS_PER_SECOND), [h::LOAD_PER_SECOND]);
    assert_eq!(loaded_after(&["skyskipper"], Some(0), TICKS_PER_SECOND),
               [2 * h::LOAD_PER_SECOND], "\"loads at 60 a second instead of 30\"");
    // A Carrier's bag holds 300, which the satchel fills in exactly its five
    // seconds; a Breaker's holds 104, so a slower load shows the rate.
    assert_eq!(loaded_after(&["skyskipper"], Some(0), 5 * TICKS_PER_SECOND), [300]);
    let mut world = kinds_world(&["skyskipper"]);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert_eq!(world.raiders[0].effect_until, ruleborn::SATCHEL_TICKS, "\"for 5 s\"");
}

#[test]
fn nothing_slows_the_tidewalker_for_six_seconds() {
    let step = |unhindered: bool, carrying: i32| {
        let mut world = kinds_world(&["tidewalker"]);
        world.weave(&[("heavy_ground", (0, 13))]);
        world.raiders[0].carried = carrying;
        if unhindered {
            fire_at(&mut world, 0, 0, 0);
            world.step();
        }
        let r = &world.raiders[0];
        crate::step_with(&world.grid, &world.sheet, r, r.gait, None, carrying > 0, (1, 1),
                         r.running(ruleborn::Ability::Unhindered, world.tick))
    };
    let base = Role::Carrier.speed();
    assert!(step(false, 100) < base, "loaded, under a law that slows the crew");
    assert_eq!(step(true, 100), base,
               "\"terrain, laws and its own load leave it at full speed\"");
}

#[test]
fn the_quarrybacks_pound_hits_the_vault_half_again_as_hard() {
    let hit = |pound: bool| {
        let mut world = kinds_world(&["quarryback"]);
        put(&mut world, 0, 6, 5);
        world.raiders[0].task = Task::Crack;
        if pound {
            fire_at(&mut world, 0, 0, 0);
        }
        let before = world.vault.health;
        run_for(&mut world, h::HIT_TICKS);
        before - world.vault.health
    };
    let plain = Role::Breaker.power() * 2;           // a Breaker hits it for double
    assert_eq!(hit(false), plain);
    assert_eq!(hit(true), plain * 3 / 2, "\"deal 50% more\"");
}

#[test]
fn the_emberling_bursts_triple_its_power_on_every_ward_and_pylon_within_a_tile() {
    let mut world = kinds_world(&["emberling"]);
    world.weave(&[("density", (3, 4))]);
    world.place_wards(&[(WardKind::TimeSnare, (4, 3)), (WardKind::TimeSnare, (6, 3))]);
    put(&mut world, 0, 4, 4);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    let burst = Role::Breaker.power() * 3;
    assert_eq!(world.wards[0].health, h::WARD_HEALTH_PER_LEVEL - burst, "the ward a tile away");
    assert_eq!(world.laws[0].health, h::PYLON_HEALTH - burst, "the pylon a tile away");
    assert_eq!(world.wards[1].health, h::WARD_HEALTH_PER_LEVEL, "two tiles off: untouched");
}

/// A Thorn Hedge on (x, y), and crew member `ri` standing in it.
fn in_a_hedge(world: &mut World, ri: usize, x: u16, y: u16) {
    world.place_wards(&[(WardKind::ThornHedge, (x, y))]);
    put(world, ri, x, y);
}

#[test]
fn the_hourkeeper_gives_an_ally_back_what_it_lost_in_the_last_five_seconds() {
    let mut world = kinds_world(&["hourkeeper", "stormhound"]);
    in_a_hedge(&mut world, 1, 8, 8);
    let each = Role::Scout.health() * 5 / 100;
    run_for(&mut world, 7 * TICKS_PER_SECOND);        // seven thorns: ticks 0, 30 ... 180
    assert_eq!(world.raiders[1].health, Role::Scout.health() - 7 * each);
    put(&mut world, 1, 9, 9);
    fire_at(&mut world, 0, 9, 9);
    world.step();
    assert_eq!(world.raiders[1].health, Role::Scout.health() - 2 * each,
               "the five thorns of the last 5 s back, not the two before");
    fire_at(&mut world, 0, 9, 9);
    run_for(&mut world, ruleborn::LOCKOUT_TICKS + 1);
    fire_at(&mut world, 0, 9, 9);
    world.step();
    assert_eq!(world.raiders[1].health, Role::Scout.health() - 2 * each,
               "what was given back is not given twice");
}

#[test]
fn the_stillwatch_freezes_a_guard_or_a_ward_for_two_and_a_half_seconds() {
    let mut world = kinds_world(&["stillwatch", "stormhound"]);
    let post = world.grid.index(3, 3).unwrap();
    world.guards.push(make_guard(0, 0, post, &world.grid));
    fire_at(&mut world, 0, 3, 3);
    world.step();
    assert_eq!(world.guards[0].stunned_until, ruleborn::FREEZE_TICKS,
               "\"it cannot move, act, see or grow suspicious\"");
    assert!(!world.guards[0].awake(1));

    let mut world = kinds_world(&["stillwatch", "stormhound"]);
    world.place_wards(&[(WardKind::TimeSnare, (8, 8))]);
    fire_at(&mut world, 0, 8, 8);
    world.step();
    put(&mut world, 1, 8, 8);
    world.step();
    assert_eq!(world.raiders[1].frozen_until, 0, "a frozen snare catches nobody");
    run_for(&mut world, ruleborn::FREEZE_TICKS);
    assert!(world.raiders[1].frozen_until > 0, "thawed, it does");
}

#[test]
fn the_mossbear_rooted_takes_half_damage_and_does_not_move() {
    let hurt = |root: bool| {
        let mut world = kinds_world(&["mossbear"]);
        in_a_hedge(&mut world, 0, 5, 5);
        if root {
            fire_at(&mut world, 0, 0, 0);
        }
        world.step();
        Role::Warden.health() - world.raiders[0].health
    };
    let thorn = Role::Warden.health() * 5 / 100;
    assert_eq!(hurt(false), thorn);
    assert_eq!(hurt(true), thorn / 2, "\"taking half damage\"");

    let mut world = kinds_world(&["mossbear"]);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    world.give(0, Kind::MoveTo, 12 * 256 + 128, 10 * 256 + 128);
    let at = world.raiders[0].at;
    run_for(&mut world, ruleborn::ROOT_TICKS - 2);
    assert_eq!(world.raiders[0].at, at, "\"it cannot move while rooted\"");
    run_for(&mut world, TICKS_PER_SECOND);
    assert_ne!(world.raiders[0].at, at, "then it goes where it was told");
}

#[test]
fn the_bloomling_heals_every_ally_within_three_tiles_by_fifteen_percent() {
    let mut world = kinds_world(&["bloomling", "stormhound", "quarryback"]);
    put(&mut world, 0, 5, 5);
    put(&mut world, 1, 7, 7);                         // 2.8 tiles
    put(&mut world, 2, 9, 5);                         // 4 tiles
    for r in world.raiders.iter_mut() {
        r.health = 50;
    }
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert_eq!(world.raiders[1].health, 50 + Role::Scout.health() * 15 / 100);
    assert_eq!(world.raiders[2].health, 50, "four tiles off");
    assert_eq!(world.raiders[0].health, 50, "an ally, not itself");
}

#[test]
fn the_echoplate_returns_a_crew_member_knocked_out_within_three_tiles() {
    let mut world = kinds_world(&["echoplate", "stormhound", "quarryback"]);
    put(&mut world, 0, 5, 5);
    in_a_hedge(&mut world, 1, 7, 5);
    in_a_hedge(&mut world, 2, 10, 5);
    world.raiders[1].health = 1;
    world.raiders[2].health = 1;
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert_eq!(world.raiders[1].standing, Standing::Active);
    assert_eq!(world.raiders[1].health, Role::Scout.health() * 40 / 100,
               "\"returns at once at 40% of its full health\"");
    assert_eq!(world.raiders[2].standing, Standing::Down, "five tiles off");

    let mut world = kinds_world(&["echoplate"]);
    in_a_hedge(&mut world, 0, 5, 5);
    world.raiders[0].health = 1;
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert_eq!(world.raiders[0].standing, Standing::Active, "\"itself included\"");
}

#[test]
fn the_soulmenders_link_shares_every_hit_evenly_across_the_crew() {
    let mut world = kinds_world(&["soulmender", "stormhound", "quarryback"]);
    in_a_hedge(&mut world, 1, 8, 8);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    let thorn = Role::Scout.health() * 5 / 100;      // 6
    let lost: Vec<i32> = world.raiders.iter().map(|r| r.full(&world.sheet) - r.health).collect();
    assert_eq!(lost.iter().sum::<i32>(), thorn, "nothing more is lost, nothing less");
    assert_eq!(lost, [thorn / 3; 3], "\"shared evenly across all\"");
    run_for(&mut world, ruleborn::LINK_TICKS);
    let before = world.raiders[1].health;
    run_for(&mut world, TICKS_PER_SECOND);
    assert_eq!(before - world.raiders[1].health, thorn, "after 6 s, its own again");
}

// -- §11.7's Sage on a heist (TD.12) --------------------------------------------

/// `kinds_world` with a Sage: 1 the Archivist, 2 the Tinkerer, 3 the
/// Gardener, 4 the Wanderer.
fn sage_world(kinds: &[&str], sage: u8) -> World {
    let mut world = kinds_world(kinds);
    let mut crew = manifest(kinds);
    crew.sage = sage;
    world.crew_from(&crew);
    world
}

/// The Sage's power `i` (0 to 2), aimed at tile (x, y), now.
fn call_at(world: &mut World, i: u8, x: u16, y: u16) {
    world.give(i, Kind::Sage, x as i16 * 256 + 128, y as i16 * 256 + 128);
}

#[test]
fn a_sage_comes_with_the_manifest_and_its_powers_uses() {
    let world = sage_world(&["stormhound"], 1);
    let s = world.sage.unwrap();
    assert_eq!(ruleborn::SAGES[s.sage as usize].id, "the_archivist");
    assert_eq!(s.uses, [1, 2, 1], "Suspend 1, Reveal 2, Recall 1 (\u{a7}11.7)");
    assert_eq!(kinds_world(&["stormhound"]).sage, None, "\"a heist can go without a Sage\"");
}

#[test]
fn the_sage_cools_down_twenty_seconds_after_any_power() {
    let mut world = sage_world(&["stormhound"], 1);
    call_at(&mut world, 1, 0, 0);                     // Reveal
    world.step();
    assert_eq!(world.sage.unwrap().uses[1], 1);
    run_for(&mut world, 10 * TICKS_PER_SECOND);
    call_at(&mut world, 1, 0, 0);
    world.step();
    assert_eq!(world.sage.unwrap().uses[1], 1, "cooling down: refused, nothing spent");
    run_for(&mut world, ruleborn::SAGE_COOLDOWN_TICKS);
    call_at(&mut world, 1, 0, 0);
    world.step();
    assert_eq!(world.sage.unwrap().uses[1], 0, "twenty seconds on");
    run_for(&mut world, ruleborn::SAGE_COOLDOWN_TICKS);
    call_at(&mut world, 1, 0, 0);
    world.step();
    assert_eq!(world.sage.unwrap().uses[1], 0, "and no use left");
}

#[test]
fn suspend_switches_off_one_law_for_ten_seconds() {
    let mut world = sage_world(&["glass_golem"], 1);
    world.weave(&[("density", (3, 4))]);
    assert!(world.sheet.is_set(Param::LargeHealth));
    call_at(&mut world, 0, 3, 4);                     // its pylon
    world.step();
    assert!(!world.sheet.is_set(Param::LargeHealth), "\"switch off one law ... for 10 s\"");
    assert_eq!(world.raiders[0].health, Role::Warden.health(), "its extra health goes with it");
    run_for(&mut world, ruleborn::SUSPEND_TICKS);
    assert!(world.sheet.is_set(Param::LargeHealth), "and it comes back");
    assert!(world.laws[0].broken_at.is_none(), "suspended, not broken: no page");
}

#[test]
fn reveal_shows_every_ward_in_the_realm() {
    let mut world = sage_world(&["stormhound"], 1);
    assert_eq!(world.wards_shown_at, None);
    run_for(&mut world, 3);
    call_at(&mut world, 1, 0, 0);
    world.step();
    assert_eq!(world.wards_shown_at, Some(3));
}

#[test]
fn recall_brings_a_knocked_out_crew_member_back_at_forty_percent() {
    let mut world = sage_world(&["stormhound", "quarryback"], 1);
    in_a_hedge(&mut world, 1, 6, 9);
    world.raiders[1].health = 1;
    world.step();
    assert_eq!(world.raiders[1].standing, Standing::Down);
    put(&mut world, 1, 7, 9);                         // off the hedge, still down
    call_at(&mut world, 2, 7, 9);
    world.step();
    assert_eq!(world.raiders[1].standing, Standing::Active);
    assert_eq!(world.raiders[1].health, Role::Breaker.health() * 40 / 100);
    assert_eq!(world.sage.unwrap().uses[2], 0);
}

#[test]
fn jam_disables_a_ward_for_twelve_seconds() {
    let mut world = sage_world(&["stormhound", "quarryback"], 2);
    world.place_wards(&[(WardKind::TimeSnare, (8, 8))]);
    call_at(&mut world, 1, 8, 8);
    world.step();
    put(&mut world, 1, 8, 8);
    run_for(&mut world, ruleborn::JAM_TICKS - 2);
    assert_eq!(world.raiders[1].frozen_until, 0, "\"disable a ward for 12 s\"");
    run_for(&mut world, 2);
    assert!(world.raiders[1].frozen_until > 0, "then it works again");
}

#[test]
fn renew_heals_the_crew_thirty_percent_over_five_seconds() {
    let mut world = sage_world(&["stormhound", "quarryback"], 3);
    for r in world.raiders.iter_mut() {
        r.health = 10;
    }
    call_at(&mut world, 1, 0, 0);
    run_for(&mut world, 6 * TICKS_PER_SECOND);
    assert_eq!(world.raiders[0].health, 10 + 5 * (Role::Scout.health() * 30 / 500));
    assert_eq!(world.raiders[1].health, 10 + 5 * (Role::Breaker.health() * 30 / 500),
               "30% of each one's full health, a fifth each second");
}

#[test]
fn a_decoy_sapling_draws_the_guards_for_eight_seconds() {
    let mut world = sage_world(&["stormhound"], 3);
    let post = world.grid.index(3, 3).unwrap();
    world.guards.push(make_guard(0, 0, post, &world.grid));
    call_at(&mut world, 2, 9, 3);
    world.step();
    assert_eq!(world.guards[0].state, State::Investigating);
    assert_eq!(world.guards[0].interest, world.grid.index(9, 3), "it chases the sapling");
    run_for(&mut world, ruleborn::DECOY_TICKS);
    assert_eq!(world.decoy, None, "\"for 8 s\"");
}

#[test]
fn tailwind_moves_the_crew_forty_percent_faster_for_six_seconds() {
    let walk = |tailwind: bool| {
        let mut world = sage_world(&["quarryback"], 4);
        put(&mut world, 0, 1, 1);
        if tailwind {
            call_at(&mut world, 2, 0, 0);
            world.step();
        }
        let from = world.raiders[0].at;
        let a = world.grid.index(1, 1).unwrap();
        let b = world.grid.index(12, 1).unwrap();
        world.raiders[0].route = path::find(&world.grid, a, b).unwrap();
        world.raiders[0].along = 0;
        run_for(&mut world, TICKS_PER_SECOND);
        from.distance(world.raiders[0].at)
    };
    let off = (walk(true).0 - walk(false).mul(Fx::from_ratio(7, 5)).0).abs();
    assert!(off < Fx::from_ratio(1, 10_000).0, "\"crew moves 40% faster\", off by {off}");
}

#[test]
fn the_sparkwright_cuts_the_sages_cooldown_by_ten_seconds() {
    let mut world = sage_world(&["sparkwright"], 1);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert_eq!(world.raiders[0].uses, 2, "nothing cooling: nothing to cut, no use spent");
    call_at(&mut world, 1, 0, 0);
    world.step();
    let cooling = world.sage.unwrap().cooling_until;
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert_eq!(world.sage.unwrap().cooling_until, cooling - ruleborn::QUICKEN_TICKS,
               "\"Cuts the Sage's cooldown by 10 s\"");
    assert_eq!(world.raiders[0].uses, 1);
}

#[test]
fn a_power_not_built_yet_spends_no_use() {
    let mut world = sage_world(&["stormhound"], 2);
    call_at(&mut world, 2, 5, 5);                     // Plank, which waits for gaps
    world.step();
    assert_eq!(world.sage.unwrap().uses[2], 2);
    assert_eq!(world.sage.unwrap().cooling_until, 0, "and starts no cooldown");
}

// -- §24.10's event log (TD.13) -------------------------------------------------

use crate::events::{Back, Cause, Event as E, Hurt, Log, MomentKind};

/// Guard `gi`'s logged state changes: (to, cause), in order.
fn changes(world: &World, gi: usize) -> Vec<(State, Cause)> {
    world.log.events.iter().filter_map(|(_, e)| match *e {
        E::Guard { guard, to, cause, .. } if guard as usize == gi => Some((to, cause)),
        _ => None,
    }).collect()
}

fn logged(world: &World, want: E) -> bool {
    world.log.events.iter().any(|(_, e)| *e == want)
}

#[test]
fn a_guard_that_sees_the_crew_is_logged_rising_with_who_it_saw() {
    let mut world = vault_world(2);
    put(&mut world, 0, 13, 13);
    put(&mut world, 1, 3, 5);
    let gi = post(&mut world, 2, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(90);  // south, at crew member 1
    run_for(&mut world, 2 * TICKS_PER_SECOND);
    let seen = changes(&world, gi);
    assert_eq!(seen.first(), Some(&(State::Suspicious, Cause::Saw(1))));
    assert!(seen.contains(&(State::Alerted, Cause::Saw(1))), "{seen:?}");
}

#[test]
fn a_guard_that_hears_the_crew_is_logged_as_hearing() {
    let mut world = World::new(3, 1, Vec::new());
    let post_tile = world.grid.index(2, 3).unwrap();
    let (gx, gy) = world.grid.centre(post_tile);
    world.guards[0].at = Point { x: gx, y: gy };
    world.guards[0].home = post_tile;
    world.guards[0].facing = Ang::from_degrees(270);
    let start = world.grid.index(2, 5).unwrap();
    let (rx, ry) = world.grid.centre(start);
    world.raiders[0].at = Point { x: rx, y: ry };
    world.raiders[0].route = path::find(&world.grid, start, world.grid.index(2, 6).unwrap()).unwrap();
    world.step();
    assert_eq!(changes(&world, 0), [(State::Investigating, Cause::Heard)]);
}

#[test]
fn an_alert_that_spreads_is_logged_as_spreading() {
    let mut world = vault_world(1);
    put(&mut world, 0, 13, 13);
    let a = post(&mut world, 2, 3, 3);
    let b = post(&mut world, 0, 5, 3);
    world.enter(a, State::Alerted);
    run_for(&mut world, TICKS_PER_SECOND);
    assert_eq!(changes(&world, b).first(), Some(&(State::Investigating, Cause::Spread)));
}

#[test]
fn a_guard_drawn_by_a_decoy_is_logged_as_lured() {
    let mut world = sage_world(&["stormhound"], 3);
    let gi = post(&mut world, 0, 3, 3);
    call_at(&mut world, 2, 9, 3);
    world.step();
    assert_eq!(changes(&world, gi), [(State::Investigating, Cause::Lured)]);
}

#[test]
fn alarm_level_six_sending_guards_searching_is_logged_as_the_alarms() {
    let mut world = vault_world(1);
    put(&mut world, 0, 13, 13);
    let gi = post(&mut world, 0, 3, 3);
    let mut world = at_alarm(world, 6);
    world.step();
    assert_eq!(changes(&world, gi), [(State::Searching, Cause::Alarm)]);
}

#[test]
fn a_change_the_state_table_makes_is_logged_as_the_tables() {
    // Suspicion left over, nothing seen or heard: the rise and the fall are
    // the table's own.
    let mut world = vault_world(1);
    put(&mut world, 0, 13, 13);
    let gi = post(&mut world, 0, 3, 3);
    world.guards[gi].suspicion = 250;
    run_for(&mut world, 2 * TICKS_PER_SECOND);
    assert_eq!(changes(&world, gi), [(State::Suspicious, Cause::Table), (State::Unaware, Cause::Table)]);
}

#[test]
fn a_knockout_on_either_side_is_logged_with_what_did_it() {
    let mut world = vault_world(1);
    put(&mut world, 0, 3, 4);
    let gi = post(&mut world, 2, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(90);
    world.enter(gi, State::Alerted);
    world.guards[gi].route.clear();
    world.guards[gi].interest = world.grid.index(3, 4);
    run_for(&mut world, 3 * h::HIT_TICKS);
    assert!(logged(&world, E::Down { crew: 0, by: Hurt::Guard(gi as u16) }));

    let mut world = vault_world(1);
    let gi = post(&mut world, 0, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(270);
    put(&mut world, 0, 3, 4);
    world.raiders[0].task = Task::Attack;
    world.raiders[0].target = gi as u32;
    run_for(&mut world, h::TAKEDOWN_TICKS);
    assert!(logged(&world, E::GuardDown { guard: gi as u16 }));

    let mut world = ward_world(1, WardKind::ThornHedge, (5, 5));
    put(&mut world, 0, 5, 5);
    world.raiders[0].health = 1;
    world.step();
    assert!(logged(&world, E::Down { crew: 0, by: Hurt::Ward(0) }), "a ward's thorns");
}

#[test]
fn a_crew_member_back_on_its_feet_is_logged_with_how() {
    let mut world = vault_world(2);
    put(&mut world, 0, 3, 3);
    put(&mut world, 1, 3, 4);
    world.raiders[0].health = 0;
    run_for(&mut world, 4 * TICKS_PER_SECOND);
    assert!(logged(&world, E::Back { crew: 0, how: Back::Ally }));

    let mut world = kinds_world(&["echoplate", "stormhound"]);
    put(&mut world, 0, 5, 5);
    in_a_hedge(&mut world, 1, 6, 5);
    world.raiders[1].health = 1;
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert!(logged(&world, E::Back { crew: 1, how: Back::Echoplate }));
}

#[test]
fn captures_and_escapes_are_logged() {
    let mut world = vault_world(1);
    put(&mut world, 0, 3, 3);
    world.raiders[0].health = 0;
    run_for(&mut world, 11 * TICKS_PER_SECOND);
    assert!(logged(&world, E::Caught { crew: 0, clock: false }), "down ten seconds");

    let mut world = vault_world(1);
    world.clock = 5;
    run_for(&mut world, 10);
    assert!(logged(&world, E::Caught { crew: 0, clock: true }), "inside at the clock");

    let mut world = vault_world(1);
    let edge = world.grid.index(0, 3).unwrap();
    world.skiff = Some(h::Skiff { tile: edge, arrives: 0 });
    put(&mut world, 0, 0, 3);
    world.raiders[0].carried = 50;
    world.step();
    assert!(logged(&world, E::Out { crew: 0, carried: 50 }), "aboard, with its loot");
}

#[test]
fn the_realm_alarm_is_logged_level_by_level_with_its_cause() {
    let mut world = vault_world(1);
    put(&mut world, 0, 13, 13);
    run_for(&mut world, crate::guard::ALARM_STEP_TICKS + 1);
    assert!(logged(&world, E::Alarm { level: 1, found: false }), "thirty seconds");
    world.knockouts_discovered += 1;
    world.step();
    assert!(logged(&world, E::Alarm { level: 2, found: true }), "a knocked-out guard found");
    let mut world = at_alarm(vault_world(1), 5);
    world.step();
    assert!(world.log.events.iter().any(|(_, e)| matches!(e, E::Reinforced { .. })),
            "level 5's Warden");
}

#[test]
fn wards_pylons_and_the_vault_are_logged() {
    let mut world = ward_world(1, WardKind::TimeSnare, (3, 3));
    put(&mut world, 0, 3, 3);
    world.step();
    assert!(logged(&world, E::Ward { ward: 0, crew: 0 }));

    let mut world = kinds_world(&["emberling"]);
    world.weave(&[("density", (3, 4))]);
    world.laws[0].health = 10;
    put(&mut world, 0, 4, 4);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert!(logged(&world, E::Pylon { law: 0 }));

    let mut world = vault_world(1);
    put(&mut world, 0, 6, 5);
    world.raiders[0].task = Task::Crack;
    world.vault.health = 1;
    run_for(&mut world, h::HIT_TICKS);
    assert!(logged(&world, E::Vault));
}

#[test]
fn a_law_suspended_an_ability_and_a_power_are_logged() {
    let mut world = sage_world(&["stormhound"], 1);
    world.weave(&[("density", (3, 4))]);
    call_at(&mut world, 0, 3, 4);
    fire_at(&mut world, 0, 0, 0);
    world.step();
    assert!(logged(&world, E::LawOff { law: 0, until: ruleborn::SUSPEND_TICKS }));
    assert!(logged(&world, E::Power { power: 0 }));
    assert!(logged(&world, E::Ability { crew: 0 }));
}

#[test]
fn every_crew_member_on_the_island_is_logged_once_a_second() {
    let mut world = vault_world(3);
    world.raiders[2].standing = Standing::Out;
    run_for(&mut world, 3 * TICKS_PER_SECOND);
    let ticks: Vec<(u32, u8)> = world.log.positions.iter().map(|&(t, c, _, _)| (t, c)).collect();
    assert_eq!(ticks, [(0, 0), (0, 1), (30, 0), (30, 1), (60, 0), (60, 1)],
               "the two on the island, each second; the one out is not");
    let (_, _, x, y) = world.log.positions[0];
    let (cx, cy) = world.grid.centre(world.grid.index(0, 0).unwrap());
    assert_eq!((x, y), ((cx.mul(Fx::from_int(256))).to_int() as i16,
                        (cy.mul(Fx::from_int(256))).to_int() as i16), "at 1/256 of a tile");
}

#[test]
fn the_log_is_outside_the_checksum() {
    let heist = fixture(42, 900, 4);
    let mut kept = World::from_heist(&heist);
    let mut emptied = World::from_heist(&heist);
    for _ in 0..900 {
        let a = kept.step();
        let b = emptied.step();
        emptied.log = Log::default();
        assert_eq!(a, b, "the log changes no checksum");
    }
    assert!(!kept.log.events.is_empty() && !kept.log.positions.is_empty());
}

#[test]
fn the_decisive_moment_is_chosen_by_twelve_thirteens_rule() {
    let mut log = Log::default();
    log.push(50, E::LawOff { law: 3, until: 350 });
    log.push(100, E::Guard { guard: 2, from: State::Suspicious, to: State::Alerted,
                             cause: Cause::Saw(1) });
    log.push(120, E::Guard { guard: 4, from: State::Searching, to: State::Alerted,
                             cause: Cause::Saw(0) });
    log.push(150, E::Down { crew: 1, by: Hurt::Guard(2) });
    log.push(450, E::Caught { crew: 1, clock: false });
    log.closest = Some((80, 2, 640));
    let foiled = log.moment(Grade::Foiled).unwrap();
    assert_eq!((foiled.kind, foiled.tick, foiled.guard, foiled.crew),
               (MomentKind::Capture, 100, Some(2), Some(1)),
               "the first capture, back to the tick its captor became Alerted to it");
    assert_eq!(foiled.blink, Some(3), "a law's blink at that tick is named");
    let loud = log.moment(Grade::Loud).unwrap();
    assert_eq!((loud.kind, loud.tick, loud.cause), (MomentKind::Alert, 100, Some(Cause::Saw(1))),
               "the first guard Alerted, and why");
    let clean = log.moment(Grade::Clean).unwrap();
    assert_eq!((clean.kind, clean.tick, clean.guard), (MomentKind::CloseCall, 80, Some(2)),
               "the closest call");
    // A capture with no guard behind it is its own moment.
    let mut clock = Log::default();
    clock.push(4500, E::Caught { crew: 0, clock: true });
    assert_eq!(clock.moment(Grade::Partial).map(|m| m.tick), Some(4500));
}

#[test]
fn every_golden_heist_has_a_decisive_moment() {
    for (name, seed, ticks, crew) in crate::GOLDEN {
        let heist = fixture(*seed, *ticks, *crew);
        let mut world = World::from_heist(&heist);
        for _ in 0..heist.ticks {
            world.step();
        }
        let grade = world.outcome().grade;
        assert!(world.log.moment(grade).is_some(), "{name}: {grade:?} has one");
    }
}

// -- §6.2's features (TD.15) ----------------------------------------------------

use crate::grid;

/// A Scout guard at (3, 3) facing south, and crew member 0 at (3, y),
/// on `vault_world`'s open ground with `f` placed under the crew member:
/// whether the guard notices it this tick, standing still.
fn noticed_on(f: Option<Feature>, y: u16) -> bool {
    let mut world = vault_world(1);
    let gi = post(&mut world, 0, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(90);
    if let Some(f) = f {
        world.grid.place(3, y, f);
    }
    put(&mut world, 0, 3, y);
    world.noticed(gi, 0).is_some()
}

/// Whether a route can be found from (1, 5) to (5, 5) with `f` on (3, 4..6).
fn walled_by(f: Feature) -> bool {
    let mut world = vault_world(1);
    for y in 0..14 {
        world.grid.place(3, y, f);
    }
    let a = world.grid.index(1, 5).unwrap();
    let b = world.grid.index(5, 5).unwrap();
    path::find(&world.grid, a, b).is_none()
}

/// Whether a guard at (1, 5) facing east sees a crew member at (5, 5) over a
/// line of `f` on x = 3.
fn seen_past(f: Feature) -> bool {
    let mut world = vault_world(1);
    for y in 0..14 {
        world.grid.place(3, y, f);
    }
    let gi = post(&mut world, 0, 1, 5);
    world.guards[gi].facing = Ang::from_degrees(0);
    put(&mut world, 0, 5, 5);
    world.noticed(gi, 0).is_some()
}

#[test]
fn a_hedge_blocks_feet_and_eyes_and_is_cut_through_in_three_seconds() {
    assert!(walled_by(Feature::Hedge) && !seen_past(Feature::Hedge));
    let mut world = vault_world(1);
    world.grid.place(4, 4, Feature::Hedge);
    put(&mut world, 0, 4, 5);
    world.raiders[0].task = Task::Break;
    world.raiders[0].target = world.grid.index(4, 4).unwrap();
    run_for(&mut world, grid::HEDGE_CUT_SECONDS * TICKS_PER_SECOND - 1);
    assert_eq!(world.grid.feature(world.grid.index(4, 4).unwrap()), Some(Feature::Hedge));
    world.step();
    assert_eq!(world.grid.feature(world.grid.index(4, 4).unwrap()), None, "cut through at 3 s");
}

#[test]
fn a_tree_is_walked_round_and_blocks_sight() {
    assert!(walled_by(Feature::Tree) && !seen_past(Feature::Tree));
}

#[test]
fn a_boulder_blocks_until_a_breaker_smashes_it_in_six_seconds() {
    assert!(walled_by(Feature::Boulder) && !seen_past(Feature::Boulder));
    let smashed = |role: Role| {
        let mut world = vault_world(1);
        world.grid.place(4, 4, Feature::Boulder);
        world.raiders[0].role = role;
        put(&mut world, 0, 4, 5);
        world.raiders[0].task = Task::Break;
        world.raiders[0].target = world.grid.index(4, 4).unwrap();
        run_for(&mut world, grid::BOULDER_SMASH_SECONDS * TICKS_PER_SECOND);
        world.grid.feature(world.grid.index(4, 4).unwrap()).is_none()
    };
    assert!(smashed(Role::Breaker), "\"a Breaker smashes it in about 6 seconds\"");
    assert!(!smashed(Role::Scout), "nobody else can");
}

#[test]
fn a_statue_blocks_one_tile_and_gives_cover() {
    assert!(walled_by(Feature::Statue) && !seen_past(Feature::Statue));
}

#[test]
fn a_crystal_outcrop_blocks_feet_not_eyes_and_carries_a_lantern_further() {
    assert!(walled_by(Feature::CrystalOutcrop) && seen_past(Feature::CrystalOutcrop));
    let lit = |outcrop: bool| {
        let mut world = vault_world(1);
        world.grid.place(2, 2, Feature::LanternPost);
        if outcrop {
            world.grid.place(2, 3, Feature::CrystalOutcrop);
        }
        world.step();
        world.lantern_lit(world.grid.index(2, 7).unwrap())
    };
    assert!(!lit(false), "five tiles off: past a lantern's 3");
    assert!(lit(true), "\"lanterns reach 2 tiles further past it\"");
}

#[test]
fn a_lava_crack_is_impassable_and_seen_over() {
    assert!(walled_by(Feature::LavaCrack) && seen_past(Feature::LavaCrack));
}

#[test]
fn a_stream_is_waded_twenty_percent_slower_and_is_water() {
    let mut world = vault_world(1);
    world.grid.place(4, 4, Feature::Stream);
    let t = world.grid.index(4, 4).unwrap();
    assert_eq!(world.grid.at(t).pace(), Fx::from_ratio(80, 100));
    assert_eq!(world.grid.surface(t), grid::Surface::Water, "louder underfoot (12.17)");
}

#[test]
fn a_gravel_path_is_fifteen_percent_faster_and_crunchy() {
    let mut world = vault_world(1);
    world.grid.place(4, 4, Feature::GravelPath);
    let t = world.grid.index(4, 4).unwrap();
    assert_eq!(world.grid.at(t).pace(), Fx::from_ratio(115, 100));
    assert_eq!(world.grid.surface(t), grid::Surface::Gravel);
}

#[test]
fn a_thicket_is_slower_and_hides_anyone_beyond_a_tile() {
    let mut world = vault_world(1);
    world.grid.place(4, 4, Feature::Thicket);
    assert_eq!(world.grid.at(world.grid.index(4, 4).unwrap()).pace(), Fx::from_ratio(70, 100));
    assert!(noticed_on(Some(Feature::Thicket), 4), "a tile off: seen");
    assert!(!noticed_on(Some(Feature::Thicket), 6), "three tiles off: hidden");
    assert!(noticed_on(None, 6), "and seen there on open ground");
}

#[test]
fn a_shade_canopy_hides_anyone_beyond_three_tiles() {
    assert!(noticed_on(Some(Feature::ShadeCanopy), 6));
    assert!(!noticed_on(Some(Feature::ShadeCanopy), 7));
    assert!(noticed_on(None, 7));
}

#[test]
fn a_bush_hides_one_still_character_completely() {
    assert!(!noticed_on(Some(Feature::Bush), 4), "still, alone, a tile off: hidden");
    let mut world = vault_world(2);
    let gi = post(&mut world, 0, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(90);
    world.grid.place(3, 4, Feature::Bush);
    put(&mut world, 0, 3, 4);
    put(&mut world, 1, 3, 4);
    assert!(world.noticed(gi, 0).is_some(), "two in one bush: \"one\" character");
}

#[test]
fn a_hot_spring_heals_both_sides_and_its_steam_hides_beyond_two_tiles() {
    let mut world = vault_world(1);
    world.grid.place(5, 5, Feature::HotSpring);
    put(&mut world, 0, 5, 5);
    world.raiders[0].health = 50;
    let gi = post(&mut world, 0, 9, 9);
    world.grid.place(9, 9, Feature::HotSpring);
    world.guards[gi].health = 50;
    run_for(&mut world, TICKS_PER_SECOND);
    assert_eq!(world.raiders[0].health, 50 + Role::Scout.health() * 2 / 100);
    assert_eq!(world.guards[gi].health, 50 + Role::Scout.health() * 2 / 100, "for both sides");
    assert!(noticed_on(Some(Feature::HotSpring), 5));
    assert!(!noticed_on(Some(Feature::HotSpring), 6), "steam, beyond 2 tiles");
}

#[test]
fn a_lantern_post_lights_three_tiles_and_nothing_hides_inside_the_light() {
    let seen = |lantern: bool| {
        let mut world = vault_world(1);
        let gi = post(&mut world, 0, 3, 3);
        world.guards[gi].facing = Ang::from_degrees(90);
        world.grid.place(3, 4, Feature::Bush);
        if lantern {
            world.grid.place(5, 4, Feature::LanternPost);
        }
        put(&mut world, 0, 3, 4);
        world.step();
        world.guards[gi].suspicion > 0
    };
    assert!(!seen(false), "in a bush, hidden");
    assert!(seen(true), "in a bush two tiles from a lantern, seen");
}

#[test]
fn scree_makes_guards_within_four_tiles_notice_a_quarter_faster() {
    let fill = |scree: bool, y: u16| {
        let mut world = vault_world(1);
        let gi = post(&mut world, 0, 3, 3);
        world.guards[gi].facing = Ang::from_degrees(90);
        if scree {
            world.grid.place(3, y, Feature::Scree);
        }
        put(&mut world, 0, 3, y);
        world.noticed(gi, 0).map(|(n, _)| n)
    };
    assert_eq!(fill(true, 5).unwrap(), fill(false, 5).unwrap() * 5 / 4, "two tiles off");
    assert_eq!(fill(true, 8), fill(false, 8), "five tiles off: as on open ground");
}

#[test]
fn an_ember_vent_bursts_every_eight_seconds_and_hurts_whoever_is_on_it() {
    let mut world = vault_world(1);
    world.grid.place(5, 5, Feature::EmberVent);
    put(&mut world, 0, 5, 5);
    run_for(&mut world, grid::EMBER_SECONDS * TICKS_PER_SECOND);
    assert_eq!(world.raiders[0].health, Role::Scout.health(), "nothing before the burst");
    world.step();
    assert_eq!(world.raiders[0].health,
               Role::Scout.health() - Role::Scout.health() * h::BURN_DAMAGE.0 / h::BURN_DAMAGE.1);
    assert!(world.lantern_lit(world.grid.index(5, 7).unwrap()), "\"Lights 2 tiles when it bursts\"");
}

#[test]
fn a_static_stone_zaps_anyone_within_a_tile_every_four_seconds() {
    let mut world = vault_world(2);
    world.grid.place(5, 5, Feature::StaticStone);
    put(&mut world, 0, 5, 6);
    put(&mut world, 1, 5, 8);
    run_for(&mut world, grid::STONE_SECONDS * TICKS_PER_SECOND + 1);
    let zap = Role::Scout.health() * h::COIL_DAMAGE.0 / h::COIL_DAMAGE.1;
    assert_eq!(world.raiders[0].health, Role::Scout.health() - zap);
    assert_eq!(world.raiders[1].health, Role::Breaker.health(), "three tiles off");
}

#[test]
fn every_feature_built_travels_in_the_island_and_reads_back() {
    let mut island = Island::example_open();
    for (i, &(f, _, _)) in crate::island::FEATURE_CODES.iter().enumerate() {
        assert!(island.set_feature((i % 10) as u8, 9 + (i / 10) as u8 % 2, Some(f)), "{f:?}");
    }
    let back = Island::decode(&island.encode()).unwrap();
    assert_eq!(back.encode(), island.encode());
    assert_eq!(Island::decode(&Island::example().encode()).unwrap().digest(),
               Island::example().digest(), "an island of the old five keeps its bytes");
}

/// Whether a guard on (3, 3), raised one level and facing south, sees a crew
/// member on (3, y) at ground level, with `f` under it and (3, 4) raised to
/// `edge` (and a ramp there if `ramp`).
fn seen_from_above(f: Option<Feature>, y: u16, edge: u8, ramp: bool) -> bool {
    let mut world = vault_world(1);
    world.grid.set_height(3, 3, 1);
    world.grid.set_height(3, 4, edge);
    if ramp {
        world.grid.make_climbable(3, 4);
    }
    let gi = post(&mut world, 0, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(90);
    if let Some(f) = f {
        world.grid.place(3, y, f);
    }
    put(&mut world, 0, 3, y);
    world.noticed(gi, 0).is_some()
}

#[test]
fn an_arch_is_walked_under_and_hides_whoever_is_under_it_from_above() {
    assert!(!walled_by(Feature::Arch) && seen_past(Feature::Arch), "level with it: seen");
    assert!(seen_from_above(None, 5, 0, false), "from above, on open ground: seen");
    assert!(!seen_from_above(Some(Feature::Arch), 5, 0, false), "\"blocks sight from above\"");
}

#[test]
fn a_guard_cannot_see_the_foot_of_its_own_cliff() {
    assert!(!seen_from_above(None, 5, 1, false), "right under the edge: hidden");
    assert!(seen_from_above(None, 5, 1, true), "a ramp is not a cliff");
    assert!(seen_from_above(None, 7, 1, false), "two tiles out from the foot: seen");
}

/// Whether a crew member walking from (1, 2) to (6, 2) over `f` on (3, 2)
/// left a footprint there.
fn printed(f: Feature) -> bool {
    let mut world = vault_world(1);
    world.grid.place(3, 2, f);
    put(&mut world, 0, 1, 2);
    order(&mut world, 0, 6, 2);
    run_for(&mut world, 3 * TICKS_PER_SECOND);
    let tile = world.grid.index(3, 2).unwrap() as u16;
    world.log.events.iter().any(|&(_, e)| e == crate::events::Event::Print { crew: 0, tile })
}

#[test]
fn a_marsh_is_forty_percent_slower_wet_and_keeps_footprints() {
    let mut world = vault_world(1);
    world.grid.place(4, 4, Feature::Marsh);
    let t = world.grid.index(4, 4).unwrap();
    assert_eq!(world.grid.at(t).pace(), Fx::from_ratio(grid::MARSH_PACE as i64, 100));
    assert_eq!(world.grid.surface(t), grid::Surface::Water);
    assert!(printed(Feature::Marsh));
    assert!(!printed(Feature::GravelPath), "only where §6.2 says");
}

#[test]
fn a_flower_meadow_shows_footprints_and_slows_nobody() {
    let mut world = vault_world(1);
    world.grid.place(4, 4, Feature::FlowerMeadow);
    assert_eq!(world.grid.at(world.grid.index(4, 4).unwrap()).pace(), Fx::ONE);
    assert!(printed(Feature::FlowerMeadow));
}

#[test]
fn an_ice_sheet_takes_a_tile_to_stop() {
    let stop = |ice: bool, halt: bool| {
        let mut world = vault_world(1);
        if ice {
            for x in 1..10 {
                world.grid.place(x, 2, Feature::IceSheet);
            }
        }
        put(&mut world, 0, 1, 2);
        order(&mut world, 0, if halt { 8 } else { 4 }, 2);
        if halt {
            run_for(&mut world, TICKS_PER_SECOND / 2);
            let tick = world.tick;
            world.commands_for_test(vec![Command { tick, actor: 0, kind: Kind::Halt, x: 0, y: 0 }]);
        }
        run_for(&mut world, 4 * TICKS_PER_SECOND);
        tile_of(&world, 0)
    };
    assert_eq!(stop(false, false), (4, 2));
    assert_eq!(stop(true, false), (5, 2), "\"stopping takes 1 tile\"");
    let (on_ground, on_ice) = (stop(false, true), stop(true, true));
    assert!(on_ice.0 >= on_ground.0 && on_ice.0 <= on_ground.0 + 1,
            "a halt on ice still reaches the tile ahead: {on_ground:?} {on_ice:?}");
}

#[test]
fn a_pond_is_gone_round_seen_across_and_water() {
    assert!(walled_by(Feature::Pond) && seen_past(Feature::Pond));
    let mut world = vault_world(1);
    world.grid.place(4, 4, Feature::Pond);
    assert_eq!(world.grid.surface(world.grid.index(4, 4).unwrap()), grid::Surface::Water);
}

#[test]
fn a_bell_post_bumped_raises_the_realm_alarm_a_level_late_under_delay() {
    let rung = |laws: &[&str]| {
        let mut world = vault_world(1);
        weave(&mut world, laws);
        world.grid.place(3, 2, Feature::BellPost);
        put(&mut world, 0, 1, 2);
        order(&mut world, 0, 5, 2);
        let mut first = None;
        for _ in 0..8 * TICKS_PER_SECOND {
            world.step();
            if world.alarm > 0 && first.is_none() {
                first = Some(world.tick);
            }
        }
        let bell = world.log.events.iter().find_map(|&(t, e)| match e {
            crate::events::Event::Bell { crew: 0, .. } => Some(t),
            _ => None,
        });
        (bell, first, world.alarm)
    };
    let (bell, raised, level) = rung(&[]);
    assert!(bell.is_some() && raised.is_some() && level == grid::BELL_LEVELS);
    assert!(raised.unwrap() - bell.unwrap() <= 1, "at once");
    let (bell, raised, _) = rung(&["delay"]);
    assert!(raised.unwrap() - bell.unwrap() >= 3 * TICKS_PER_SECOND, "\"Delay makes the ring come late\"");
}

#[test]
fn stepping_stones_are_a_road_only_under_a_law_that_leaps() {
    assert!(walled_by(Feature::SteppingStones));
    let crossed = |laws: &[&str]| {
        let mut world = vault_world(1);
        weave(&mut world, laws);
        for y in 0..14 {
            world.grid.place(3, y, Feature::SteppingStones);
        }
        world.step();
        let (a, b) = (world.grid.index(1, 5).unwrap(), world.grid.index(5, 5).unwrap());
        path::find(&world.grid, a, b).is_some()
    };
    assert!(!crossed(&[]));
    assert!(crossed(&["half_gravity"]), "\"Half gravity … makes them a road\"");
}

#[test]
fn a_bounce_mushroom_launches_three_tiles_and_the_landing_is_heard_four_away() {
    let launch = |laws: &[&str]| {
        let mut world = vault_world(1);
        weave(&mut world, laws);
        world.grid.place(3, 2, Feature::BounceMushroom);
        let near = post(&mut world, 0, 10, 4);
        let far = post(&mut world, 0, 11, 4);
        put(&mut world, 0, 1, 2);
        order(&mut world, 0, 12, 2);
        for _ in 0..3 * TICKS_PER_SECOND {
            world.step();
            if world.raiders[0].bounced {
                return (tile_of(&world, 0), world.guards[near].heard.is_some(),
                        world.guards[far].heard.is_some(), world.raiders[0].route.last().copied());
            }
        }
        panic!("never launched");
    };
    let (landed, near, far, goal) = launch(&[]);
    assert_eq!(landed, (6, 2), "3 tiles forward of the mushroom");
    let mut world = vault_world(1);
    world.grid.place(3, 2, Feature::BounceMushroom);
    assert_eq!(goal, world.grid.index(12, 2), "and on to where it was going");
    // (6, 2) to (10, 4) is 6 steps by the walk; the landing reaches 4.
    assert!(!near && !far);
    let (landed, _, _, _) = launch(&["half_gravity"]);
    assert_eq!(landed, (8, 2), "\"Half gravity makes it 5 tiles\"");
    let heard = |gx: u16| {
        let mut world = vault_world(1);
        world.grid.place(3, 2, Feature::BounceMushroom);
        let gi = post(&mut world, 0, gx, 2);
        world.guards[gi].facing = Ang::from_degrees(0);
        put(&mut world, 0, 1, 2);
        order(&mut world, 0, 6, 2);
        loop {
            world.step();
            if world.raiders[0].bounced {
                return world.guards[gi].heard.is_some();
            }
        }
    };
    assert!(heard(10), "4 tiles from the landing");
    assert!(!heard(11), "5 tiles from it");
}

#[test]
fn an_updraft_vent_lifts_one_level_and_two_under_a_law_that_leaps() {
    let mut grid = Grid::new(10, 10);
    let (vent, up) = (grid.index(3, 5).unwrap(), grid.index(4, 5).unwrap());
    grid.set_height(4, 5, 1);
    assert!(!grid.can_step(vent, up), "a level up needs a climb");
    grid.place(3, 5, Feature::UpdraftVent);
    assert!(grid.can_step(vent, up), "\"lifts anyone one level\"");
    grid.set_height(4, 5, 2);
    assert!(!grid.can_step(vent, up));
    grid.leap = true;
    assert!(grid.can_step(vent, up), "\"Half gravity sends people two levels\"");
}

#[test]
fn a_pit_drops_anyone_a_level_and_needs_a_climb_out() {
    let mut grid = Grid::new(10, 10);
    let (edge, pit) = (grid.index(3, 5).unwrap(), grid.index(4, 5).unwrap());
    grid.place(4, 5, Feature::Pit);
    assert_eq!(grid.level(pit), -1);
    assert!(grid.can_step(edge, pit) && !grid.can_step(pit, edge), "in free, out by a climb");
    grid.make_climbable(4, 5);
    assert!(grid.can_step(pit, edge), "a ramp out");
    let mut world = vault_world(1);
    world.grid.place(4, 2, Feature::Pit);
    put(&mut world, 0, 2, 2);
    order(&mut world, 0, 4, 2);
    let mut dropped = 0;
    for _ in 0..2 * TICKS_PER_SECOND {
        world.step();
        dropped = dropped.max(world.raiders[0].landed);
    }
    assert_eq!(dropped, 1, "a landing from one level, heard as one (12.17)");
    assert_eq!(tile_of(&world, 0), (4, 2));
}

/// A pond `wide` tiles across, from x = 3, over every row.
fn moat(world: &mut World, wide: u16) {
    for x in 3..3 + wide {
        for y in 0..14 {
            if world.grid.feature(world.grid.index(x, y).unwrap()).is_none() {
                world.grid.place(x, y, Feature::Pond);
            }
        }
    }
}

#[test]
fn the_featherkins_glide_crosses_a_gap_three_tiles_in_one_move() {
    let glide = |to: (u16, u16), setup: &dyn Fn(&mut World)| {
        let mut world = kinds_world(&["featherkin"]);
        moat(&mut world, 2);
        setup(&mut world);
        put(&mut world, 0, 2, 2);
        fire_at(&mut world, 0, to.0, to.1);
        run_for(&mut world, 3 * TICKS_PER_SECOND);
        (tile_of(&world, 0), world.raiders[0].uses)
    };
    assert_eq!(glide((5, 2), &|_| {}), ((5, 2), 1), "over a two-tile pond, three tiles");
    assert_eq!(glide((6, 2), &|_| {}).1, 2, "four tiles is too far, and costs nothing");
    assert_eq!(glide((5, 2), &|w| w.grid.place(5, 2, Feature::RockPillar)).1, 2,
               "it lands on ground it can stand on");
    assert_eq!(glide((5, 2), &|w| w.grid.set_height(5, 2, 1)), ((5, 2), 1), "rising a level");
    assert_eq!(glide((5, 2), &|w| w.grid.set_height(5, 2, 2)).1, 2, "not two");
    let mut world = kinds_world(&["featherkin"]);
    world.grid.place(3, 2, Feature::RockPillar);
    put(&mut world, 0, 2, 2);
    fire_at(&mut world, 0, 4, 2);
    world.step();
    assert_eq!(world.raiders[0].uses, 2, "a gap, not a wall");
}

#[test]
fn the_ramblers_charge_runs_four_tiles_twice_as_fast_and_breaks_the_first_hedge() {
    let charge = |setup: &dyn Fn(&mut World)| {
        let mut world = kinds_world(&["rambler"]);
        setup(&mut world);
        put(&mut world, 0, 1, 2);
        fire_at(&mut world, 0, 8, 2);
        let mut ticks = 0;
        world.step();
        while world.raiders[0].charging && ticks < 10 * TICKS_PER_SECOND {
            world.step();
            ticks += 1;
        }
        (world, ticks)
    };
    let (world, ticks) = charge(&|w| w.grid.place(3, 2, Feature::Hedge));
    assert_eq!(world.grid.feature(world.grid.index(3, 2).unwrap()), None, "the hedge is broken");
    assert_eq!(tile_of(&world, 0), (5, 2), "and the charge runs its 4 tiles");
    let mut walk = kinds_world(&["rambler"]);
    put(&mut walk, 0, 1, 2);
    order(&mut walk, 0, 5, 2);
    let mut walked = 0;
    while tile_of(&walk, 0) != (5, 2) || !walk.raiders[0].still() {
        walk.step();
        walked += 1;
    }
    assert!(ticks * 2 <= walked + 2 && ticks * 2 + 2 >= walked, "\"Speed ×2\": {ticks} against {walked}");
    let (world, _) = charge(&|w| w.grid.place(3, 2, Feature::RockPillar));
    assert_eq!(tile_of(&world, 0), (2, 2), "a pillar cannot be broken: the charge stops before it");
    let (world, _) = charge(&|w| {
        w.grid.place(3, 2, Feature::Boulder);
        w.grid.place(4, 2, Feature::Hedge);
    });
    assert_eq!(world.grid.feature(world.grid.index(4, 2).unwrap()), Some(Feature::Hedge),
               "only the first in its way");
    assert_eq!(tile_of(&world, 0), (3, 2));
}

#[test]
fn the_rootrunners_bridge_spans_a_gap_of_up_to_three_tiles_for_eight_seconds() {
    let bridged = |wide: u16| {
        let mut world = kinds_world(&["rootrunner"]);
        moat(&mut world, wide);
        put(&mut world, 0, 2, 2);
        fire_at(&mut world, 0, 3, 2);
        world.step();
        world
    };
    let across = |w: &World| {
        let (a, b) = (w.grid.index(2, 2).unwrap(), w.grid.index(9, 2).unwrap());
        path::find(&w.grid, a, b).is_some()
    };
    let mut world = bridged(3);
    assert!(across(&world) && world.raiders[0].uses == 1, "a three-tile gap, bridged");
    assert!(!across(&bridged(4)) && bridged(4).raiders[0].uses == 2, "four is too wide");
    put(&mut world, 0, 4, 2);                     // standing on the roots
    run_for(&mut world, ruleborn::ROOT_BRIDGE_TICKS);
    assert!(!across(&world), "gone after 8 s");
    assert_eq!(tile_of(&world, 0), (2, 2), "and whoever was on it is back where it was laid from");
}

#[test]
fn the_tinkerers_plank_lays_a_four_tile_shortcut_over_a_gap_for_fifteen_seconds() {
    let planked = |wide: u16| {
        let mut world = sage_world(&["stormhound"], 2);
        moat(&mut world, wide);
        call_at(&mut world, 2, 4, 5);                 // Plank, the Tinkerer's third
        world.step();
        world
    };
    let across = |w: &World| {
        let (a, b) = (w.grid.index(2, 5).unwrap(), w.grid.index(9, 5).unwrap());
        path::find(&w.grid, a, b).is_some()
    };
    let mut world = planked(4);
    assert!(across(&world), "four tiles across, along the row");
    assert!(!across(&planked(5)), "five is too wide");
    run_for(&mut world, ruleborn::PLANK_TICKS);
    assert!(!across(&world), "gone after 15 s");
}

// -- The six with a direction, a tunnel, and a post's facing (TD.38, G56) ----

use crate::grid::{EAST, NORTH, SOUTH, WEST};

#[test]
fn a_ramp_climbs_one_level_up_the_side_it_faces() {
    let mut grid = Grid::new(10, 10);
    let (low, high) = (grid.index(3, 5).unwrap(), grid.index(4, 5).unwrap());
    grid.set_height(4, 5, 1);
    assert!(!grid.can_step(low, high), "a level up needs a climb");
    grid.place(3, 5, Feature::Ramp);
    for (facing, climbs) in [(EAST, true), (WEST, false), (NORTH, false), (SOUTH, false)] {
        grid.set_facing(3, 5, facing);
        assert_eq!(grid.can_step(low, high), climbs, "a ramp facing {facing}");
    }
    assert!(grid.can_step(high, low), "down is free, whichever way it faces");
    // On the high tile it is the same ramp, climbed onto the way it faces.
    let mut grid = Grid::new(10, 10);
    grid.set_height(4, 5, 1);
    grid.place(4, 5, Feature::Ramp);
    grid.set_facing(4, 5, EAST);
    assert!(grid.can_step(low, high));
    grid.set_height(4, 5, 2);
    assert!(!grid.can_step(low, high), "two levels at once is a cliff, ramp or not");
    // A guard looks down a ramp: the foot of a slope is not a cliff's foot.
    let mut world = vault_world(1);
    world.grid.set_height(3, 3, 1);
    world.grid.set_height(3, 4, 1);
    world.grid.place(3, 4, Feature::Ramp);
    world.grid.set_facing(3, 4, NORTH);
    let gi = post(&mut world, 0, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(90);
    put(&mut world, 0, 3, 5);
    assert!(world.noticed(gi, 0).is_some());
}

#[test]
fn stairs_climb_a_level_a_fifth_faster_than_a_ramp() {
    assert_eq!(Feature::Ramp.terrain(), Terrain::Open, "a ramp is walked at the ground's pace");
    assert_eq!(Feature::Stairs.terrain(), Terrain::Pace(crate::grid::STAIRS_PACE));
    assert_eq!(crate::grid::STAIRS_PACE, 120, "\"20% faster than a ramp\"");
    let mut grid = Grid::new(10, 10);
    let (low, high) = (grid.index(3, 5).unwrap(), grid.index(3, 4).unwrap());
    grid.set_height(3, 4, 1);
    grid.place(3, 5, Feature::Stairs);
    grid.set_facing(3, 5, NORTH);
    assert!(grid.can_step(low, high));
    grid.set_facing(3, 5, SOUTH);
    assert!(!grid.can_step(low, high), "up the side it faces, and no other");
    // The walk up: a crew member crosses stairs sooner than a ramp.
    let climb = |f: Feature| {
        let mut world = vault_world(1);
        world.grid.set_height(2, 1, 1);
        world.grid.set_height(2, 0, 1);
        world.grid.place(2, 2, f);
        world.grid.set_facing(2, 2, NORTH);
        put(&mut world, 0, 2, 4);
        order(&mut world, 0, 2, 0);
        for t in 0..10 * TICKS_PER_SECOND {
            world.step();
            if tile_of(&world, 0) == (2, 0) {
                return t;
            }
        }
        panic!("never climbed");
    };
    assert!(climb(Feature::Stairs) < climb(Feature::Ramp));
}

#[test]
fn climbing_vines_climb_a_level_where_there_is_no_ramp() {
    let mut grid = Grid::new(10, 10);
    let (foot, top) = (grid.index(5, 6).unwrap(), grid.index(5, 5).unwrap());
    grid.set_height(5, 5, 1);
    grid.place(5, 6, Feature::ClimbingVines);
    grid.set_facing(5, 6, NORTH);
    assert!(grid.can_step(foot, top), "\"climb one level without a ramp\"");
    grid.set_facing(5, 6, EAST);
    assert!(!grid.can_step(foot, top));
    // Vines hang on a cliff: its foot is still hidden from a guard above.
    let mut world = vault_world(1);
    world.grid.set_height(3, 3, 1);
    world.grid.set_height(3, 4, 1);
    world.grid.place(3, 4, Feature::ClimbingVines);
    let gi = post(&mut world, 0, 3, 3);
    world.guards[gi].facing = Ang::from_degrees(90);
    put(&mut world, 0, 3, 5);
    assert!(world.noticed(gi, 0).is_none());
}

#[test]
fn a_waterfall_is_walked_behind_along_its_ledge_and_blocks_sight() {
    let mut grid = Grid::new(10, 10);
    grid.place(4, 5, Feature::Waterfall);
    grid.set_facing(4, 5, SOUTH);                  // the water falls south
    let at = |x, y| grid.index(x, y).unwrap();
    assert!(grid.can_step(at(3, 5), at(4, 5)) && grid.can_step(at(4, 5), at(5, 5)),
            "along the ledge, across the fall");
    assert!(!grid.can_step(at(4, 6), at(4, 5)) && !grid.can_step(at(4, 4), at(4, 5)),
            "never through the water");
    assert!(grid.blocks_sight(at(4, 5)));
    // A guard south of it sees neither whoever is behind it nor beyond.
    let seen = |crew_y: u16, fall: bool| {
        let mut world = vault_world(1);
        if fall {
            world.grid.place(4, 5, Feature::Waterfall);
            world.grid.set_facing(4, 5, SOUTH);
        }
        let gi = post(&mut world, 0, 4, 8);
        world.guards[gi].facing = Ang::from_degrees(270);
        put(&mut world, 0, 4, crew_y);
        world.noticed(gi, 0).is_some()
    };
    assert!(seen(5, false) && seen(4, false));
    assert!(!seen(5, true), "on the hidden ledge");
    assert!(!seen(4, true), "beyond it");
}

#[test]
fn rapids_push_anyone_a_tile_a_second_downstream() {
    let mut world = vault_world(1);
    for x in 2..=5 {
        world.grid.place(x, 2, Feature::Rapids);
        world.grid.set_facing(x, 2, EAST);
    }
    world.grid.place(5, 3, Feature::Rapids);
    world.grid.set_facing(5, 3, SOUTH);
    world.grid.place(6, 2, Feature::RockPillar);
    put(&mut world, 0, 2, 2);
    let gi = post(&mut world, 0, 5, 3);
    assert_eq!(world.grid.surface(world.grid.index(3, 2).unwrap()), crate::grid::Surface::Water);
    world.step();                                    // the first whole second
    assert_eq!(tile_of(&world, 0), (3, 2), "a tile downstream on the second");
    let g = world.guards[gi].at;
    assert_eq!(world.grid.coords(world.grid.tile_at(g.x, g.y).unwrap()), (5, 4), "guards too");
    run_for(&mut world, TICKS_PER_SECOND - 1);
    assert_eq!(tile_of(&world, 0), (3, 2), "and only on the second");
    run_for(&mut world, 1);
    assert_eq!(tile_of(&world, 0), (4, 2));
    run_for(&mut world, 2 * TICKS_PER_SECOND);
    assert_eq!(tile_of(&world, 0), (5, 2), "a rock stops the push");
}

#[test]
fn a_tunnel_is_a_hidden_path_up_to_six_tiles_and_nobody_sees_into_it() {
    let mut world = vault_world(1);
    for y in 0..14 {
        world.grid.place(4, y, Feature::RockPillar);
    }
    let at = |w: &World, x, y| w.grid.index(x, y).unwrap();
    let (from, to) = (at(&world, 2, 2), at(&world, 8, 2));
    assert!(path::find_through(&world.grid, from, to).is_none(), "the wall is whole");
    world.grid.dig_tunnel(at(&world, 3, 2), at(&world, 6, 2));
    let route = path::find_through(&world.grid, from, to).expect("through the tunnel");
    assert_eq!(route, vec![at(&world, 3, 2), at(&world, 6, 2), at(&world, 7, 2), at(&world, 8, 2)]);
    assert!(path::find(&world.grid, from, to).is_none(), "guards keep to the surface");
    // A guard looking at the tunnel's middle sees nobody in it.
    let gi = post(&mut world, 0, 5, 6);
    world.guards[gi].facing = Ang::from_degrees(270);
    put(&mut world, 0, 2, 2);
    order(&mut world, 0, 8, 2);
    let mut inside = 0;
    for _ in 0..10 * TICKS_PER_SECOND {
        world.step();
        if tile_of(&world, 0) == (5, 2) {
            inside += 1;
            assert!(world.noticed(gi, 0).is_none(), "\"nobody can see into it\"");
        }
    }
    assert!(inside > 0, "it walked under (5, 2)");
    assert_eq!(tile_of(&world, 0), (8, 2), "and came out the far side");
    // Its walk is as long as it is: the six tiles take what six tiles in the
    // open take.
    let arrive = |tunnel: bool| {
        let mut w = vault_world(1);
        if tunnel {
            for y in 0..14 {
                w.grid.place(4, y, Feature::RockPillar);
            }
            let (a, b) = (w.grid.index(3, 2).unwrap(), w.grid.index(6, 2).unwrap());
            w.grid.dig_tunnel(a, b);
        }
        put(&mut w, 0, 2, 2);
        order(&mut w, 0, 8, 2);
        (0..10 * TICKS_PER_SECOND).find(|_| {
            w.step();
            tile_of(&w, 0) == (8, 2)
        })
    };
    assert_eq!(arrive(true), arrive(false));
    // Standing on (5, 2) in the open, it is seen.
    let mut seen = vault_world(1);
    let gi = post(&mut seen, 0, 5, 6);
    seen.guards[gi].facing = Ang::from_degrees(270);
    put(&mut seen, 0, 5, 2);
    assert!(seen.noticed(gi, 0).is_some());
}

#[test]
fn a_held_post_faces_the_way_its_owner_sets() {
    let mut island = Island::example();
    let post = island.guards[0];
    assert!(island.face(post.x, post.y, EAST));
    assert_eq!(island.facing(post.x, post.y), Some(EAST));
    let back = Island::decode(&island.encode()).unwrap();
    assert_eq!(back.guards[0].facing, EAST);
    let world = World::on_ground(&back, 1, Vec::new());
    assert_eq!(world.guards[0].facing, Ang::from_degrees(0), "east is 0°");
    // North is how every post faced before, so it costs an island no bytes.
    assert!(island.face(post.x, post.y, NORTH));
    assert_eq!(island.encode(), Island::example().encode());
    assert_eq!(World::on_ground(&island, 1, Vec::new()).guards[0].facing, Ang::from_degrees(270));
    assert!(!island.face(0, 0, EAST), "bare ground has no facing");
}

#[test]
fn the_generator_faces_a_post_toward_the_nearest_shortest_route() {
    // A blank realm 1: 10 by 10, the Vault at (5, 7). The shortest way in
    // is from (5, 9) to (5, 8), beside it.
    let mut island = Island::blank(1);
    assert!(island.post_guard(0, 2, 2));
    assert_eq!(island.guards[0].facing, SOUTH, "north-west of the route: it looks south");
    assert!(island.post_guard(0, 8, 8));
    assert_eq!(island.guards[1].facing, WEST, "east of it: it looks west");
    assert_eq!(island.default_facing(1), WEST);
    assert!(island.post_guard(0, 0, 4));
    assert_eq!(island.guards[2].facing, EAST, "toward (5, 8), five across and four down");
    // A wall across the south moves the route to the sides, and the post
    // turns with it: (0, 7) to (4, 7) is now a shortest way in.
    let mut walled = Island::blank(1);
    for x in 1..10 {
        walled.set_feature(x, 8, Some(Feature::RockPillar));
    }
    walled.set_feature(9, 7, Some(Feature::RockPillar));
    assert!(walled.post_guard(0, 0, 4));
    assert_eq!(walled.guards[0].facing, SOUTH, "toward (0, 7), three down");
}

#[test]
fn the_six_and_a_tunnel_travel_in_the_island_and_a_second_encoding_is_refused() {
    use crate::island::Malformed;
    let mut island = Island::example_open();
    for (i, f) in [Feature::Ramp, Feature::Stairs, Feature::ClimbingVines, Feature::Waterfall,
                   Feature::Rapids].into_iter().enumerate() {
        assert!(island.set_feature(i as u8, 0, Some(f)));
        assert!(island.face(i as u8, 0, i as u8 % 4));
    }
    assert!(island.dig_tunnel((9, 4), (5, 2)));
    assert!(island.dig_tunnel((0, 3), (0, 5)));
    assert_eq!(island.tunnels, vec![((5, 2), (9, 4)), ((0, 3), (0, 5))],
               "each first by its lower mouth, in order of tile index");
    assert!(!island.dig_tunnel((0, 0), (7, 0)), "7 tiles is further than a tunnel goes");
    assert!(!island.dig_tunnel((1, 1), (2, 1)), "a mouth beside a mouth is no path");
    let bytes = island.encode();
    let back = Island::decode(&bytes).unwrap();
    assert_eq!(back, island);
    assert_eq!(back.encode(), bytes);
    let grid = back.ground();
    assert_eq!(grid.tunnel_exit(grid.index(5, 2).unwrap()), grid.index(9, 4));
    assert_eq!(grid.facing(grid.index(3, 0).unwrap()), 3);
    // Taking a mouth away takes the tunnel.
    let mut gone = island.clone();
    assert!(gone.clear(9, 4));
    assert_eq!(gone.tunnels.len(), 1);
    // The tunnels come last, after a buildings count of 0.
    let n = bytes.len();
    assert_eq!(&bytes[n - 10..], &[0, 2, 5, 2, 9, 4, 0, 3, 0, 5]);
    let refused = |edit: &dyn Fn(&mut Vec<u8>)| {
        let mut b = bytes.clone();
        edit(&mut b);
        Island::decode(&b)
    };
    assert_eq!(refused(&|b| { b.swap(n - 8, n - 6); b.swap(n - 7, n - 5); }),
               Err(Malformed::Tunnel), "mouths out of order");
    assert_eq!(refused(&|b| { b[n - 3] = 1; b[n - 1] = 3; }), Err(Malformed::Tunnel),
               "tunnels out of order");
    assert_eq!(refused(&|b| b[n - 4..].copy_from_slice(&[8, 3, 9, 4])), Err(Malformed::Tunnel),
               "a mouth shared");
    assert_eq!(refused(&|b| { b[n - 2] = 6; b[n - 1] = 9; }), Err(Malformed::Tunnel),
               "12 tiles apart");
    assert!(refused(&|_| {}).is_ok());
    // A tunnel's mouth is dug in bare ground.
    let mut crowded = island.clone();
    let side = crowded.side() as usize;
    crowded.tiles[3 * side].feature = Some(Feature::Bush);
    assert!(crowded.check().contains(&crate::island::Problem::Crowded));
}

// -- The Glass golem's wall, the Lantern wisp's reveal, Invert and the vine
// bridge (TD.12) ---------------------------------------------------------------

#[test]
fn the_glass_golems_wall_stands_three_tiles_across_the_way_for_six_seconds_and_is_seen_through() {
    let mut world = kinds_world(&["glass_golem", "stormhound"]);
    put(&mut world, 0, 2, 3);
    put(&mut world, 1, 2, 5);
    order(&mut world, 1, 8, 5);
    run_for(&mut world, 15);                          // under way, toward (5, 5)
    fire_at(&mut world, 0, 5, 5);
    world.step();
    let raised = |w: &World| -> Vec<(u16, u16)> {
        (0..w.grid.len() as u32).filter(|&t| w.grid.is_raised(t)).map(|t| w.grid.coords(t)).collect()
    };
    // The golem at (2, 3) aims east of south-east: the wall runs north to south.
    assert_eq!(raised(&world), vec![(5, 4), (5, 5), (5, 6)], "\"a crystal wall 3 tiles long\"");
    assert_eq!(world.raiders[0].uses, 1);
    run_for(&mut world, 3 * TICKS_PER_SECOND);
    assert_eq!(tile_of(&world, 1), (4, 5), "\"nothing passes it\": the walk waits at the wall");
    // A guard beyond it sees the Stormhound through it.
    let gi = post(&mut world, 0, 7, 5);
    world.guards[gi].facing = Ang::from_degrees(180);
    assert!(world.noticed(gi, 1).is_some(), "\"it does not block sight\"");
    world.guards.clear();
    run_for(&mut world, ruleborn::WALL_TICKS);
    assert!(raised(&world).is_empty(), "gone after 6 s");
    run_for(&mut world, 3 * TICKS_PER_SECOND);
    assert_eq!(tile_of(&world, 1), (8, 5), "and the walk goes on");
    // Not on a tile someone stands on: dropped, nothing spent.
    let mut world = kinds_world(&["glass_golem", "stormhound"]);
    fire_at(&mut world, 0, 4, 10);
    world.step();
    assert!(raised(&world).is_empty() && world.raiders[0].uses == 2);
}

#[test]
fn the_lantern_wisps_reveal_shows_what_is_hidden_within_six_tiles_for_six_seconds() {
    let mut world = kinds_world(&["lantern_wisp"]);
    let at = |w: &World, x, y| w.grid.index(x, y).unwrap();
    assert!(!world.revealed(at(&world, 2, 10)), "nothing shown before it is used");
    fire_at(&mut world, 0, 2, 10);
    world.step();
    assert_eq!(world.raiders[0].uses, 1);
    assert!(world.revealed(at(&world, 8, 10)), "6 tiles away");
    assert!(!world.revealed(at(&world, 9, 10)), "7 is beyond it");
    // It goes with the wisp.
    put(&mut world, 0, 9, 10);
    assert!(world.revealed(at(&world, 13, 10)) && !world.revealed(at(&world, 2, 10)));
    run_for(&mut world, ruleborn::REVEAL_TICKS);
    assert!(!world.revealed(at(&world, 9, 10)), "for 6 s");
    // Shown, not simulated: a heist with a reveal plays as one without.
    let plain = |reveal: bool| {
        let mut w = kinds_world(&["lantern_wisp"]);
        w.place_wards(&[(WardKind::TimeSnare, (6, 10))]);
        if reveal {
            fire_at(&mut w, 0, 2, 10);
            w.step();
            w.reveals.clear();
        } else {
            w.step();
        }
        order(&mut w, 0, 10, 10);
        run_for(&mut w, 5 * TICKS_PER_SECOND);
        (w.raiders[0].at, w.raiders[0].frozen_until)
    };
    assert_eq!(plain(true), plain(false));
}

#[test]
fn invert_turns_a_law_into_its_opposite_for_ten_seconds() {
    let mut world = sage_world(&["stormhound"], 2);   // the Tinkerer: Invert first
    world.weave(&[("haste", (3, 4))]);
    world.step();
    assert_eq!(world.sheet.factor(Param::CrewSpeed), (5, 4));
    call_at(&mut world, 0, 3, 4);
    world.step();
    assert_eq!(world.sheet.factor(Param::CrewSpeed), (4, 5), "25% faster turned: 20% slower");
    assert_eq!(world.sheet.factor(Param::ClockRate), (4, 5), "and the clock with it");
    assert!(logged(&world, crate::events::Event::LawTurned { law: 0, until: 1 + ruleborn::INVERT_TICKS }));
    assert_eq!(world.sage.unwrap().uses[0], 0);
    run_for(&mut world, ruleborn::INVERT_TICKS);
    assert_eq!(world.sheet.factor(Param::CrewSpeed), (5, 4), "back after 10 s");
    // Half gravity's one line is the leap, which has no opposite: turned, the
    // realm has no leap.
    let mut world = sage_world(&["stormhound"], 2);
    world.weave(&[("half_gravity", (8, 4))]);
    call_at(&mut world, 0, 8, 4);
    world.step();
    assert!(!world.sheet.is_set(Param::LeapObstacles) && !world.grid.leap);
    // Aimed at bare ground: nothing to turn, nothing spent.
    let mut world = sage_world(&["stormhound"], 2);
    call_at(&mut world, 0, 1, 1);
    world.step();
    assert_eq!(world.sage.unwrap().uses[0], 1);
}

#[test]
fn the_gardeners_vine_bridge_joins_two_banks_up_to_six_tiles_apart_for_twenty_seconds() {
    let vined = |wide: u16| {
        let mut world = sage_world(&["stormhound"], 3); // the Gardener: Vine bridge first
        moat(&mut world, wide);
        call_at(&mut world, 0, 4, 5);
        world.step();
        world
    };
    let across = |w: &World| {
        let (a, b) = (w.grid.index(2, 5).unwrap(), w.grid.index(10, 5).unwrap());
        path::find(&w.grid, a, b).is_some()
    };
    let mut world = vined(5);
    assert!(across(&world), "(2, 5) to (8, 5): six apart");
    assert!(!across(&vined(6)) && vined(6).sage.unwrap().uses[0] == 1, "seven is too far");
    run_for(&mut world, ruleborn::VINE_BRIDGE_TICKS);
    assert!(!across(&world), "gone after 20 s");
}

// -- The Prism mite's split (TD.12) ---------------------------------------------

/// A Prism mite at (2, 10) carrying 51, split at tick 0.
fn split_mite() -> World {
    let mut world = kinds_world(&["prism_mite"]);
    world.raiders[0].carried = 51;
    fire_at(&mut world, 0, 2, 10);
    world.step();
    world
}

fn walk_to(world: &mut World, actor: u8, x: i16, y: i16) {
    world.give(actor, Kind::MoveTo, x * 256 + 128, y * 256 + 128);
}

#[test]
fn the_prism_mite_splits_into_two_halves_that_go_different_ways_and_rejoin_after_eight_seconds() {
    let full = kinds_world(&["prism_mite"]).raiders[0].health;
    let mut world = split_mite();
    assert_eq!(world.raiders.len(), 2, "\"splits into two mites\"");
    let (mite, half) = (&world.raiders[0], &world.raiders[1]);
    assert_eq!((mite.carried, half.carried), (26, 25), "\"each with half its load\"");
    assert_eq!(mite.health + half.health, full);
    assert_eq!(half.health, full / 2, "and half its health");
    assert_eq!(half.size, mite.size, "a mite still");
    assert_eq!((half.kind, half.uses), (None, 0), "the half has no ability of its own");
    assert_eq!(world.raiders[0].uses, 1);
    // "They can go different ways": the half answers to its own index.
    walk_to(&mut world, 0, 8, 10);
    walk_to(&mut world, 1, 2, 4);
    run_for(&mut world, 5 * TICKS_PER_SECOND);
    assert_eq!((tile_of(&world, 0), tile_of(&world, 1)), ((8, 10), (2, 4)));
    // §12.6's lockout outlasts the split: the second use is a new half, with
    // a new index, and the first's is never reused.
    run_for(&mut world, ruleborn::LOCKOUT_TICKS);
    assert_eq!(world.raiders[1].standing, Standing::Gone);
    fire_at(&mut world, 0, 8, 10);
    world.step();
    assert_eq!((world.raiders.len(), world.raiders[2].half_of, world.raiders[0].uses), (3, Some(0), 0));
    // "They rejoin when it ends", where the mite stands.
    let mut world = split_mite();
    walk_to(&mut world, 1, 2, 4);
    run_for(&mut world, ruleborn::SPLIT_TICKS);
    assert_eq!(world.raiders[1].standing, Standing::Gone);
    assert_eq!((world.raiders[0].carried, world.raiders[0].health), (51, full));
    assert_eq!(tile_of(&world, 0), (2, 10));
}

#[test]
fn a_caught_half_loses_only_its_half_whichever_half_it_is() {
    // The half caught: the mite rejoins alone, with its own half.
    let mut world = split_mite();
    world.raiders[1].standing = Standing::Caught;
    run_for(&mut world, ruleborn::SPLIT_TICKS);
    assert_eq!(world.raiders[0].carried, 26, "\"a caught mite loses only its half\"");
    assert_eq!(world.raiders[1].standing, Standing::Gone);
    assert_eq!(world.outcome().caught, 0, "the half is never one of the crew caught");
    // The mite caught: the half carries on as the mite, where it is.
    let mut world = split_mite();
    walk_to(&mut world, 1, 2, 6);
    run_for(&mut world, 3 * TICKS_PER_SECOND);
    world.raiders[0].standing = Standing::Caught;
    run_for(&mut world, ruleborn::SPLIT_TICKS);
    let mite = &world.raiders[0];
    assert_eq!((mite.standing, mite.carried, mite.kind.is_some(), mite.half_of), (Standing::Active, 25, true, None));
    assert_eq!(tile_of(&world, 0), (2, 6));
    assert!(logged(&world, crate::events::Event::Back { crew: 0, how: crate::events::Back::Split }));
}

#[test]
fn what_a_half_brings_out_is_banked_and_the_half_is_never_counted_as_crew() {
    let mut world = split_mite();
    world.raiders[0].standing = Standing::Out;
    world.raiders[1].standing = Standing::Out;
    let o = world.outcome();
    assert_eq!((o.banked, o.out, o.out_mask, o.capacity), (51, 1, 0b1, Role::Carrier.carry()));
    assert_ne!(o.grade, Grade::Partial, "one crew member, out: the half is not a second");
    // The mite out and the half still inside: the half goes on alone, and its
    // load is left if the clock catches it.
    let mut world = split_mite();
    world.raiders[0].standing = Standing::Out;
    run_for(&mut world, ruleborn::SPLIT_TICKS);
    assert_eq!(world.raiders[1].standing, Standing::Active, "the half goes on");
    world.raiders[1].standing = Standing::Caught;
    let o = world.outcome();
    assert_eq!((o.banked, o.caught, o.left), (26, 0, 25));
}

// -- Casts and the Wanderer's Copy: laws that hold inside a circle (TD.12) ------

use crate::zoned;

/// A crew of these kinds carrying casts of these laws, standing as
/// `kinds_world` puts them.
fn casting_world(kinds: &[&str], casts: &[&str]) -> World {
    let mut world = kinds_world(kinds);
    let mut crew = manifest(kinds);
    crew.casts = rows(casts).into_iter().map(|r| r as u8).collect();
    world.crew_from(&crew);
    world
}

fn cast_at(world: &mut World, i: u8, x: u16, y: u16) {
    world.give(i, Kind::Cast, x as i16 * 256 + 128, y as i16 * 256 + 128);
}

#[test]
fn a_cast_lays_its_law_on_a_circle_of_four_tiles_for_ten_seconds() {
    let mut world = casting_world(&["stormhound", "quarryback"], &["haste"]);
    assert_eq!(world.outcome().casts_used, 0, "carried and never placed: never billed");
    cast_at(&mut world, 0, 2, 10);
    world.step();
    let at = |x: u16, y: u16| {
        let (px, py) = world.grid.centre(world.grid.index(x, y).unwrap());
        zoned(&world.sheet, &world.circles, Point { x: px, y: py }).factor(Param::CrewSpeed)
    };
    assert_eq!((at(2, 10), at(6, 10), at(7, 10)), ((5, 4), (5, 4), (1, 1)),
               "\"a circle of 4 tiles\": Haste's 25% inside it, nothing beyond");
    assert_eq!(world.sheet.factor(Param::ClockRate), (1, 1), "the clock is the realm's, not the circle's");
    assert_eq!(world.outcome().casts_used, 0b1, "used: billed (§12.5)");
    assert!(logged(&world, crate::events::Event::Cast { cast: 0, law: rows(&["haste"])[0] as u16 }));
    // Walking inside it is faster.
    let walked = |cast: bool| {
        let mut w = casting_world(&["stormhound"], &["haste"]);
        if cast {
            cast_at(&mut w, 0, 2, 10);
        }
        w.step();
        walk_to(&mut w, 0, 2, 7);
        run_for(&mut w, 10);
        w.raiders[0].at.y
    };
    assert!(walked(true) < walked(false), "further north in a third of a second inside the circle");
    // Once a heist, and gone after 10 s.
    cast_at(&mut world, 0, 12, 10);
    world.step();
    assert_eq!(world.zones.len(), 1, "a cast is used once");
    run_for(&mut world, ruleborn::CAST_TICKS);
    assert!(world.zones.is_empty());
    // No cast in that slot: nothing.
    let mut bare = kinds_world(&["stormhound"]);
    cast_at(&mut bare, 0, 2, 10);
    bare.step();
    assert!(bare.zones.is_empty() && bare.outcome().casts_used == 0);
}

#[test]
fn a_guard_looking_into_a_cast_of_glowing_dark_sees_half_as_far() {
    let seen = |cast: bool| {
        let mut world = casting_world(&["stormhound"], &["glowing_dark"]);
        put(&mut world, 0, 2, 9);
        let gi = post(&mut world, 0, 2, 5);
        world.guards[gi].facing = Ang::from_degrees(90);
        if cast {
            cast_at(&mut world, 0, 2, 9);
        }
        world.step();
        world.noticed(gi, 0).is_some()
    };
    assert!(seen(false), "four tiles off, in a Scout's far zone");
    assert!(!seen(true), "inside the dark, half as far: out of reach");
}

#[test]
fn copy_carries_an_enemy_law_around_the_crew_for_the_rest_of_the_heist() {
    let mut world = sage_world(&["stormhound", "quarryback"], 4); // the Wanderer: Copy first
    world.weave(&[("haste", (3, 4))]);
    call_at(&mut world, 0, 3, 4);
    world.step();
    assert_eq!(world.sage.unwrap().uses[0], 0);
    let at = |w: &World, p: Point| zoned(&w.sheet, &w.circles, p).factor(Param::CrewSpeed);
    let far = {
        let (x, y) = world.grid.centre(world.grid.index(13, 0).unwrap());
        Point { x, y }
    };
    // Two crew members two tiles apart: the copy holds once where both
    // circles meet, not twice.
    assert_eq!(at(&world, world.raiders[0].at), (25, 16), "the realm's Haste and the copy");
    assert_eq!(at(&world, world.raiders[1].at), (25, 16));
    assert_eq!(at(&world, far), (5, 4), "away from the crew, the realm's alone");
    // The pylon broken, the realm's law is off and the crew still carries it.
    world.laws[0].broken_at = Some(world.tick);
    run_for(&mut world, 60 * TICKS_PER_SECOND);
    assert_eq!(at(&world, world.raiders[0].at), (5, 4), "for the rest of the heist");
    assert_eq!(at(&world, far), (1, 1));
}

#[test]
fn a_manifest_casting_no_law_is_refused() {
    let mut heist = fixture(9, 60, 3);
    let mut crew = manifest(&["stormhound", "quarryback", "skyskipper"]);
    crew.casts = vec![LAWS.len() as u8];
    heist.manifest = Some(crew);
    assert!(Heist::decode(&heist.encode()).is_none());
}

// -- §12.22's generated targets (TD.16) ------------------------------------------

#[test]
fn a_generated_island_is_made_from_its_seed_to_5_2s_budget_and_passes_every_check() {
    use crate::island::{GUARD_POSTS, LAW_SLOTS, WARD_LIMITS};
    for level in 1..=5u8 {
        let li = (level - 1) as usize;
        for seed in 0..40u64 {
            let island = Island::generated(seed, level);
            assert_eq!(island.check(), vec![], "level {level} seed {seed}");
            assert_eq!(island.realm_level, level);
            assert_eq!(island.guards.len(), GUARD_POSTS[li] as usize, "§5.2's posts, all of them");
            assert_eq!(island.laws.len(), LAW_SLOTS[li] as usize, "§5.2's law slots, filled");
            assert_eq!(island.wards.len(), WARD_LIMITS[li] as usize, "§5.2's wards, all of them");
            assert!(!island.wards.iter().any(|w| w.0 == WardKind::CrystalWall));
            // §7.6: chapter 1's laws only, which every Keeper may meet, so
            // matchmaking can offer the game's own islands to any raider.
            assert!(island.laws.iter().all(|(id, _, _)| crate::laws_table::LAWS.iter()
                .any(|l| l.id == id && l.launch && l.chapter == 1)), "level {level} seed {seed}: {:?}", island.laws);
            for (i, g) in island.guards.iter().enumerate() {
                assert_eq!(g.facing, island.default_facing(i), "faced as the generator faces a post");
            }
            let back = Island::decode(&island.encode()).expect("a generated island is a bundle");
            assert_eq!(back, island);
        }
    }
    assert_eq!(Island::generated(7, 3).digest(), Island::generated(7, 3).digest(), "one seed, one island");
    assert_ne!(Island::generated(7, 3).digest(), Island::generated(8, 3).digest());
    // Wards keep their distance from every edge: a crew lands where it likes.
    for seed in 0..40 {
        let island = Island::generated(seed, 3);
        let side = island.side() as u8;
        let e = crate::island::WARD_EDGE;
        assert!(island.wards.iter().all(|&(_, x, y)| x >= e && y >= e && x + e < side && y + e < side));
    }
}
#[test]
fn a_curated_layout_keeps_its_owners_buildings_vault_and_woven_laws_and_its_terrain_survives_curation() {
    // §13.3's curation: "pick a different generated layout" for a player's
    // own realm. The generator lays out what the player has: their placed
    // buildings, their Vault's level and the laws they have woven (G54).
    use crate::island::building_code;
    let garden = building_code("garden").expect("a garden is a building");
    let store = building_code("storehouse").expect("a storehouse is a building");
    let buildings = [(garden, 0u8, 0u8), (store, 10, 0)];
    let laws = ["bounce", "glass"];
    for seed in 0..30u64 {
        let island = Island::curated(seed, 3, 2, &buildings, &laws);
        assert_eq!(island.check(), vec![], "seed {seed}");
        assert_eq!((island.realm_level, island.vault_level), (3, 2));
        assert_eq!(island.buildings, buildings.to_vec(), "where its owner placed them (10.1)");
        let woven: Vec<&str> = island.laws.iter().map(|(id, _, _)| id.as_str()).collect();
        assert_eq!(woven, laws.to_vec(), "the realm's own laws, and no other");
        assert_eq!(island.guards.len(), crate::island::GUARD_POSTS[2] as usize);
        assert_eq!(Island::decode(&island.encode()).expect("a bundle"), island);
    }
    let a = Island::curated(4, 3, 1, &[], &[]);
    assert_eq!(a, Island::curated(4, 3, 1, &[], &[]), "one seed, one layout");
    assert_ne!(a.terrain_digest(), Island::curated(5, 3, 1, &[], &[]).terrain_digest());
    // Curation's verbs leave the terrain as it was: a post moved and
    // turned, a law swapped, a ward taken up.
    let mut curated = a.clone();
    let (x, y) = (curated.guards[0].x, curated.guards[0].y);
    let row = curated.guards[0].row;
    let free = (1..curated.side() as u8 - 1).flat_map(|y| (1..curated.side() as u8 - 1).map(move |x| (x, y)))
        .find(|&(x, y)| curated.tile(x, y).is_some_and(|t| t.feature.is_none())
            && curated.occupant(x, y) == crate::island::Occupant::None && curated.vault != (x, y))
        .expect("open ground");
    assert!(curated.clear(x, y) && curated.post_guard(row, free.0, free.1) && curated.face(free.0, free.1, 2));
    if let Some((_, lx, ly)) = curated.laws.first().cloned() {
        assert!(curated.clear(lx, ly) && curated.weave("stillness", lx, ly));
    }
    assert_ne!(curated.digest(), a.digest());
    assert_eq!(curated.terrain_digest(), a.terrain_digest(), "curation's verbs keep the generated origin");
    // An edit to the ground makes it authored.
    let mut edited = curated.clone();
    assert!(edited.set_feature(0, 0, Some(crate::grid::Feature::RockPillar)));
    assert_ne!(edited.terrain_digest(), a.terrain_digest(), "the terrain edited, authored (13.3)");
}

#[test]
fn every_first_draw_of_the_generator_passes_its_checks() {
    // The retry in `generated` is a backstop, not the method: a seed's own
    // draw is legal, so neighbouring seeds make different islands.
    for level in 1..=5u8 {
        for seed in 0..50u64 {
            assert_eq!(Island::draw_for_test(seed, level).check(), vec![], "level {level} seed {seed}");
        }
    }
    let distinct: std::collections::BTreeSet<[u8; 32]> = (0..20).map(|s| Island::generated(s, 2).digest()).collect();
    assert_eq!(distinct.len(), 20, "twenty seeds, twenty islands");
}

#[test]
fn the_competent_reference_crew_lands_routes_round_what_it_sees_cracks_loads_to_break_even_and_leaves() {
    // §13.3's reference crew inside the simulation (D66, TD.16): on an island
    // with nothing defending it, every raid it plays gets everyone out with
    // the bag at §12.19's break-even.
    use crate::island::Island;
    use crate::reference::{competent, hold, play, BREAKEVEN_FILL};
    let open = Island::example_open();
    let (held, outcomes) = hold(&open, 0, 12, 4_500, 3);
    assert_eq!(held, 0);
    assert!(outcomes.iter().all(|o| o.grade == crate::heist::Grade::Clean && o.out == 3), "{outcomes:?}");
    let w = play(&open, 3, 4_500, 3, None);
    assert!(w.raiders.iter().all(|r| r.carried == 0 || r.carried >= r.role.carry() * BREAKEVEN_FILL / 100));
    assert!(w.commands().iter().any(|c| c.kind == crate::replay::Kind::Crack));
    assert!(w.commands().iter().all(|c| c.kind != crate::replay::Kind::MoveTo || c.tick > 0));
    // Its heist is a replay like any other: it verifies, to the outcome it
    // played, and fits §24.10's size.
    let heist = competent(&open, 3, 4_500, 3, None);
    assert_eq!(crate::verify_on(&open, &heist), Ok(w.outcome()));
    assert!(heist.encode().len() <= crate::replay::MAX_HEIST_BYTES);
}

#[test]
fn a_hold_is_counted_over_the_reference_crews_raids_their_landings_drawn_from_the_seed() {
    // §13.3: "800 raids of the competent reference crew". Each raid's seed
    // draws its landing among the spots a competent crew weighs, so raids
    // differ; one seed is one raid everywhere.
    use crate::island::Island;
    use crate::reference::{hold, play};
    let island = Island::example();
    let (held, outcomes) = hold(&island, 0, 24, 4_500, 3);
    assert_eq!(outcomes.len(), 24);
    assert!(held > 0 && held < 24, "the example island holds some raids and not others: {held}");
    assert_eq!(hold(&island, 0, 24, 4_500, 3).0, held, "one seed, one count");
    let landings: std::collections::BTreeSet<_> = (0..24u64).map(|s| play(&island, s, 4_500, 3, None).landing).collect();
    assert!(landings.len() > 1, "raids come in at more than one spot");
    for s in 0..4u64 {
        let heist = crate::reference::competent(&island, s, 4_500, 3, None);
        assert_eq!(crate::verify_on(&island, &heist).map(|o| o.grade), Ok(outcomes[s as usize].grade));
    }
}

#[test]
fn a_rehearsal_crew_plays_its_style_on_the_same_simulation() {
    // §13: "Cautious waits whenever a guard could see its next tile and
    // never runs; greedy loads until the bag is full, whatever the clock;
    // fast takes the shortest route and runs. Each is a policy in the
    // simulation, run on the same code as real heists."
    use crate::island::Island;
    use crate::reference::{rehearse, Style};
    use crate::replay::Kind;
    let island = Island::example();
    assert_eq!(Style::from_u8(3), Some(Style::Fast));
    assert_eq!(Style::from_u8(4), None);
    let gaits = |h: &crate::replay::Heist| -> Vec<i16> {
        h.commands.iter().filter(|c| c.kind == Kind::Gait).map(|c| c.x).collect()
    };
    let loads = |h: &crate::replay::Heist| -> Vec<i16> {
        h.commands.iter().filter(|c| c.kind == Kind::Load).map(|c| c.x).collect()
    };
    let mut grades = std::collections::BTreeSet::new();
    for (style, gait) in [(Style::Cautious, 1), (Style::Greedy, 1), (Style::Fast, 2)] {
        let heist = rehearse(&island, 1, 4_500, 3, style);
        assert!(gaits(&heist).iter().all(|&g| g == gait), "{style:?} keeps its gait");
        if style == Style::Greedy {
            assert!(loads(&heist).iter().all(|&l| l == 100), "the greedy crew fills the bag");
        }
        let outcome = crate::verify_on(&island, &heist).expect("a rehearsal is a replay like any other");
        assert_eq!(rehearse(&island, 1, 4_500, 3, style).commands, heist.commands, "one seed, one rehearsal");
        grades.insert(format!("{:?} {}", outcome.grade, outcome.banked));
    }
    assert_eq!(grades.len(), 3, "three styles, three heists: {grades:?}");
}

#[test]
fn a_universe_bundle_is_its_realms_in_order_and_its_links_and_decodes_only_what_it_encodes() {
    // §5.3, D71: a universe travels as RBU1, addressed by its SHA-256.
    use crate::universe::{LinkKind, Universe, MAGIC};
    let u = Universe {
        realms: vec![(0, [1; 32]), (1, [2; 32]), (3, [3; 32])],
        links: vec![(LinkKind::Stone, 1, 0), (LinkKind::Chute, 2, 1), (LinkKind::Rift, 2, 0)],
        flicker: 1,
        faults: vec![2],
    };
    let bytes = u.encode();
    assert_eq!(&bytes[..4], &MAGIC);
    assert_eq!(bytes.len(), 4 + 1 + 3 * 33 + 1 + 3 * 3 + 1 + 1 + 1);
    assert_eq!(Universe::decode(&bytes), Some(u.clone()));
    assert_eq!(u.digest(), crate::sha256::sha256(&bytes));
    let refused = |f: &dyn Fn(&mut Universe)| {
        let mut v = u.clone();
        f(&mut v);
        Universe::decode(&v.encode())
    };
    assert_eq!(refused(&|v| v.realms.truncate(1)), None, "a Heart alone is an island, not a universe");
    assert_eq!(refused(&|v| v.realms.swap(0, 1)), None, "the Heart first, codes rising");
    assert_eq!(refused(&|v| v.realms[2].0 = 1), None, "no code twice");
    assert_eq!(refused(&|v| v.realms[2].0 = 7), None, "six outer realms at most");
    assert_eq!(refused(&|v| v.links.push((LinkKind::Rope, 1, 1))), None, "a link joins two realms");
    assert_eq!(refused(&|v| v.links.push((LinkKind::Rope, 3, 0))), None, "that exist");
    assert_eq!(refused(&|v| v.links.push((LinkKind::Rope, 0, 1))), None, "each pair once, either way");
    let mut long = bytes.clone();
    long.push(0);
    assert_eq!(Universe::decode(&long), None, "nothing after");
    let mut kind = bytes.clone();
    let at = bytes.len() - 6;
    kind[at] = 4;
    assert_eq!(Universe::decode(&kind), None, "four kinds of link");
    assert_eq!(refused(&|v| v.flicker = 3), None, "Cracking's flicker or Breaking's");
    assert_eq!(refused(&|v| v.faults = vec![0]), None, "a fault opens from an outer realm");
    assert_eq!(refused(&|v| v.faults = vec![3]), None, "that exists");
    assert_eq!(refused(&|v| v.faults = vec![2, 1]), None, "in rising order");
    assert_eq!(refused(&|v| v.faults = vec![1, 1]), None, "once");
    let mut magic = bytes;
    magic[3] = b'2';
    assert_eq!(Universe::decode(&magic), None);
}

#[test]
fn the_route_to_the_heart_is_the_fewest_links_a_chute_crossed_only_its_own_way_ties_to_the_earlier_realm() {
    // §5.4's clock counts "each link on the shortest route from the landing
    // realm to the Heart"; §5.3: a Chute is "one-way".
    use crate::universe::{LinkKind::*, Universe};
    let realms = |n: u8| (0..n).map(|c| (c, [c; 32])).collect::<Vec<_>>();
    let u = Universe { realms: realms(4), links: vec![(Stone, 1, 0), (Stone, 2, 0), (Rope, 3, 1), (Rope, 3, 2)],
                      flicker: 0, faults: Vec::new() };
    assert_eq!(u.route(3), Some(vec![3, 1, 0]), "two ways of two links: the earlier realm's");
    assert_eq!(u.route(2), Some(vec![2, 0]));
    assert_eq!(u.route(0), Some(vec![0]));
    let down = Universe { realms: realms(3), links: vec![(Chute, 1, 0), (Chute, 0, 2)], flicker: 0,
                         faults: Vec::new() };
    assert_eq!(down.route(1), Some(vec![1, 0]), "down a Chute");
    assert_eq!(down.route(2), None, "never up one");
    assert_eq!(down.link(0, 1), Some(Chute));
    assert_eq!(down.link(1, 2), None);
    assert_eq!(crate::universe::clock_ticks(1), 165 * TICKS_PER_SECOND);
    assert_eq!(crate::universe::clock_ticks(9), 240 * TICKS_PER_SECOND, "up to 240 seconds");
}

/// The Heart's example island and an outer realm's generated one, joined by
/// a Stone bridge.
#[cfg(test)]
fn two_realms(kind: crate::universe::LinkKind) -> (crate::universe::Universe, Vec<crate::island::Island>) {
    use crate::island::Island;
    let (heart, outer) = (Island::example(), Island::generated(2, 1));
    let u = crate::universe::Universe { realms: vec![(0, heart.digest()), (1, outer.digest())],
                                        links: vec![(kind, 1, 0)], flicker: 0, faults: Vec::new() };
    (u, vec![heart, outer])
}

#[test]
fn a_crew_lands_on_an_outer_realm_crosses_at_its_way_on_and_takes_the_hearts_vault_on_one_clock() {
    // §5.4: "The crew lands on any edge tile of any outer realm"; §13.3: an
    // outer realm's Vault is the way on toward the Heart; §12.6: one clock.
    use crate::heist::{Grade, SKIFF_HEART_TICKS, SKIFF_OUTER_TICKS};
    use crate::reference::{competent_universe, hold_universe, play_universe};
    use crate::universe::{verify_universe, LinkKind};
    use crate::Refusal;
    let (u, islands) = two_realms(LinkKind::Stone);
    let mut banked = 0;
    let mut outcomes = Vec::new();
    for seed in 0..6u64 {
        let c = play_universe(&u, &islands, seed, 3).unwrap();
        assert_eq!((c.route.clone(), c.leg, c.crossed.len()), (vec![1, 0], 1, 1), "crossed to the Heart");
        let (outer, heart) = (&c.crossed[0], &c.world);
        assert!(outer.landing.is_some() && outer.vault.opened_at.is_none(), "the way on is not cracked");
        assert_eq!(outer.vault.exposed, 0, "and holds nothing");
        assert_eq!((outer.skiff_ticks, heart.skiff_ticks), (SKIFF_OUTER_TICKS, SKIFF_HEART_TICKS));
        assert_eq!(heart.clock, 165 * TICKS_PER_SECOND, "150 seconds and 15 for the one link");
        assert_eq!(heart.tick, heart.clock, "one clock, run to its end");
        assert!(outer.tick > 0 && outer.tick < heart.tick);
        assert_eq!(heart.landing, Some(heart.entrance), "where it entered the realm, as Ghost tide reads it");
        let reports = c.reports();
        assert_eq!(reports.iter().map(|r| r.0).collect::<Vec<_>>(), vec![1, 0]);
        // "held" is the heist's, counting whoever went out or was caught in
        // either realm.
        let o = c.outcome();
        assert!(reports.iter().all(|r| r.1.held == reports[0].1.held));
        if o.out + o.caught == 3 {
            assert!((reports[0].1.held as u32) * TICKS_PER_SECOND < heart.clock, "ended before the clock");
        }
        // Loot dropped in a realm the crew has left is still what it left.
        let mut dropped = play_universe(&u, &islands, seed, 3).unwrap();
        dropped.crossed[0].dropped.push((0, 7));
        assert_eq!(dropped.outcome().left, o.left + 7);
        banked += c.outcome().banked;
        outcomes.push(c.outcome());
    }
    assert!(banked > 0, "the crew takes the Heart's Vault");
    let (held, counted) = hold_universe(&u, &islands, 0, 6, 3);
    assert_eq!(counted, outcomes);
    assert_eq!(held as usize, outcomes.iter().filter(|o| o.grade == Grade::Foiled).count());
    // A replay like any other: verified on the universe and its islands, and
    // refused where a one-island replay is.
    let heist = competent_universe(&u, &islands, 1, 3, None, None, None).unwrap();
    assert_eq!(heist.island, u.digest());
    assert_eq!(verify_universe(&u, &islands, &heist), Ok(outcomes[1]));
    let mut heart_landing = heist.clone();
    heart_landing.commands[0].actor = 0;
    assert_eq!(verify_universe(&u, &islands, &heart_landing), Err(Refusal::Landing), "§5.4's winds");
    let mut swapped = islands.clone();
    swapped.swap(0, 1);
    assert_eq!(verify_universe(&u, &swapped, &heist), Err(Refusal::Island));
    assert_eq!(crate::verify_on(&islands[0], &heist), Err(Refusal::Island), "not a one-island replay");
    let mut tampered = heist.clone();
    tampered.checksums[100] ^= 1;
    assert_eq!(verify_universe(&u, &islands, &tampered), Err(Refusal::Diverged(101)));
}

#[test]
fn rb29_a_realms_alarm_counts_from_when_the_crew_arrives() {
    // RB-29: §12.17's realm alarm climbs once every thirty seconds in the
    // realm the crew is in; each realm keeps its own, from when the crew
    // arrives (the harness the hold tables were measured on).
    use crate::universe::{Crossing, LinkKind};
    let arrive_at = |second: u32| {
        let (u, islands) = two_realms(LinkKind::Stone);
        let land = crate::reference::competent_universe(&u, &islands, 1, 3, None, None, None).unwrap().commands[0];
        let heist = Heist { seed: 1, island: u.digest(), rules: crate::rules_version(), ticks: 4_950, crew: 3, era: None,
                            manifest: None, commands: vec![Command { tick: 0, ..land }], checksums: Vec::new() };
        let mut c = Crossing::new(&u, &islands, &heist).unwrap();
        c.step();
        let w = &mut c.world;
        w.wards.clear();
        w.tick = second * TICKS_PER_SECOND;
        let beside = w.grid.neighbours(w.vault.tile).into_iter().flatten().find(|&t| w.grid.standable(t)).unwrap();
        let (x, y) = w.grid.centre(beside);
        for r in w.raiders.iter_mut() {
            r.at = Point { x, y };
            r.route.clear();
        }
        c.step();
        assert_eq!(c.leg, 1, "crossed to the Heart");
        c
    };
    // Across at about 151 s: the Heart's alarm starts at 0, not at 5.
    let mut c = arrive_at(151);
    let guards = c.world.guards.len();
    c.step();
    assert_eq!((c.world.alarm, c.world.reinforced, c.world.guards.len()), (0, false, guards),
               "the Heart's alarm on the crew's first tick there");
    // Across at 61 s: thirty seconds in the Heart, counted from its first
    // tick, is one level, not three.
    let mut c = arrive_at(61);
    for _ in 0..=crate::guard::ALARM_STEP_TICKS {
        c.step();
    }
    let w = &c.world;
    assert_eq!(w.alarm, (1 + w.knockouts_discovered + w.bells_rung).min(crate::guard::ALARM_MAX),
               "one level for thirty seconds in the realm, and one a body or bell");
}

#[test]
fn a_rift_on_the_route_holds_the_crew_thirty_seconds_after_an_alarm_in_the_realm() {
    // §5.3's Rift: "Closes for 30 seconds when an alarm sounds in either
    // realm". The crew waits at the way on, and crosses once it opens.
    use crate::universe::{Crossing, LinkKind, RIFT_CLOSED_TICKS};
    let ready = |kind: LinkKind, alarm_ago: Option<u32>| {
        let (u, islands) = two_realms(kind);
        let land = crate::reference::competent_universe(&u, &islands, 1, 3, None, None, None).unwrap().commands[0];
        let heist = Heist { seed: 1, island: u.digest(), rules: crate::rules_version(), ticks: 4_950, crew: 3, era: None,
                            manifest: None, commands: vec![Command { tick: 0, ..land }], checksums: Vec::new() };
        let mut c = Crossing::new(&u, &islands, &heist).unwrap();
        c.step();
        let w = &mut c.world;
        w.wards.clear();                  // nothing pulls them off the spot
        w.tick = RIFT_CLOSED_TICKS + 30;   // far enough in for an alarm long ago
        let beside = w.grid.neighbours(w.vault.tile).into_iter().flatten().find(|&t| w.grid.standable(t)).unwrap();
        let (x, y) = w.grid.centre(beside);
        for r in w.raiders.iter_mut() {
            r.at = Point { x, y };
        }
        // An alarm `ago` ticks before the tick the crew stands there.
        let here = c.realm_now();
        c.alarms[here] = alarm_ago.map(|ago| c.world.tick + 1 - ago);
        (c.step(), c.leg)
    };
    assert_eq!(ready(LinkKind::Stone, Some(0)).1, 1, "a bridge stays open");
    assert_eq!(ready(LinkKind::Rift, None).1, 1, "a Rift with no alarm is open");
    assert_eq!(ready(LinkKind::Rift, Some(0)).1, 0, "closed");
    assert_eq!(ready(LinkKind::Rift, Some(RIFT_CLOSED_TICKS - 1)).1, 0, "for thirty seconds");
    assert_eq!(ready(LinkKind::Rift, Some(RIFT_CLOSED_TICKS)).1, 1);
    // "in either realm": an alarm in the Heart, kept while the crew was away.
    let (u, islands) = two_realms(LinkKind::Rift);
    let land = crate::reference::competent_universe(&u, &islands, 1, 3, None, None, None).unwrap().commands[0];
    let heist = Heist { seed: 1, island: u.digest(), rules: crate::rules_version(), ticks: 4_950, crew: 3, era: None,
                        manifest: None, commands: vec![Command { tick: 0, ..land }], checksums: Vec::new() };
    let mut c = Crossing::new(&u, &islands, &heist).unwrap();
    c.step();
    c.world.wards.clear();
    let w = &mut c.world;
    let beside = w.grid.neighbours(w.vault.tile).into_iter().flatten().find(|&t| w.grid.standable(t)).unwrap();
    let (x, y) = w.grid.centre(beside);
    for r in w.raiders.iter_mut() {
        r.at = Point { x, y };
    }
    c.alarms[0] = Some(c.world.tick);
    c.step();
    assert_eq!(c.leg, 0, "shut by the Heart's alarm");
}

#[test]
fn the_wanderers_rift_opens_for_twenty_seconds_between_two_realms_the_crew_has_been_in_and_goes_both_ways() {
    // §11.7: "Rift: open a two-way rift between two realms already visited
    // for 20 s (1 use)."
    use crate::universe::{Crossing, LinkKind};
    // On one island there is no other realm: the power does nothing and
    // spends nothing.
    let mut alone = sage_world(&["stormhound"], 4);
    call_at(&mut alone, 1, 5, 5);
    alone.step();
    assert_eq!((alone.sage.unwrap().uses[1], alone.rift_open), (1, None));
    // Across a universe: land on outer realm 1, cross to the Heart.
    let (u, islands) = two_realms(LinkKind::Stone);
    let land = crate::reference::competent_universe(&u, &islands, 1, 3, None, None, None).unwrap().commands[0];
    let mut crew = manifest(&["stormhound", "stormhound", "stormhound"]);
    crew.sage = 4;
    let heist = Heist { seed: 1, island: u.digest(), rules: crate::rules_version(), ticks: 4_950, crew: 3, era: None,
                        manifest: Some(crew), commands: vec![land], checksums: Vec::new() };
    let mut c = Crossing::new(&u, &islands, &heist).unwrap();
    let stand = |c: &mut Crossing, t: crate::grid::TileIndex| {
        let (x, y) = c.world.grid.centre(t);
        c.world.wards.clear();
        for r in c.world.raiders.iter_mut() {
            r.at = Point { x, y };
            r.route.clear();
        }
    };
    let open = |w: &World, near: crate::grid::TileIndex| w.grid.neighbours(near).into_iter().flatten()
        .find(|&t| w.grid.standable(t)).unwrap();
    // An open tile more than a tile from `t`.
    let away_from = |w: &World, t: crate::grid::TileIndex| {
        let (tx, ty) = w.grid.coords(t);
        (0..w.grid.len() as crate::grid::TileIndex).find(|&o| {
            let (x, y) = w.grid.coords(o);
            w.grid.standable(o) && (x.abs_diff(tx) > 1 || y.abs_diff(ty) > 1)
        }).unwrap()
    };
    c.step();
    let outer_landing = c.world.landing.unwrap();
    let way = open(&c.world, c.world.vault.tile);
    stand(&mut c, way);
    c.step();
    assert_eq!(c.leg, 1, "at the Heart");
    // The Rift, aimed at an open tile away from the crew at the Heart.
    let r0 = &c.world.raiders[0];
    let far = away_from(&c.world, c.world.grid.tile_at(r0.at.x, r0.at.y).unwrap());
    let (fx, fy) = c.world.grid.coords(far);
    c.give(1, Kind::Sage, fx as i16 * 256 + 128, fy as i16 * 256 + 128);
    c.step();
    let opened = c.world.tick;
    let rift = c.rift.expect("open");
    assert_eq!(rift.ends, [(1, far), (0, outer_landing)], "to where the crew entered the realm behind it");
    assert_eq!(rift.until, opened - 1 + 20 * TICKS_PER_SECOND);
    assert_eq!(c.world.sage.unwrap().uses[1], 0, "one use");
    // Through it: the crew stands at its end and comes out where it landed,
    // the Heart kept as it left it, the skiff 5 seconds away.
    c.step();                                             // away from it first
    c.world.bells_rung = 7;                               // a mark on this Heart
    stand(&mut c, far);
    c.step();
    assert_eq!((c.leg, c.ahead.len()), (0, 1), "back in outer realm 1");
    let r0 = &c.world.raiders[0];
    assert_eq!(c.world.grid.tile_at(r0.at.x, r0.at.y), Some(outer_landing));
    assert_eq!(c.world.skiff_ticks, crate::heist::SKIFF_OUTER_TICKS);
    // Not straight back: the crew must leave its end and come again.
    c.step();
    assert_eq!(c.leg, 0);
    let away = away_from(&c.world, outer_landing);
    stand(&mut c, away);
    c.step();
    stand(&mut c, outer_landing);
    c.step();
    assert_eq!((c.leg, c.ahead.len()), (1, 0), "two-way: back to the Heart as it was");
    assert_eq!(c.world.bells_rung, 7, "the same Heart, as the crew left it");
    // Shut after 20 seconds.
    while c.world.tick < rift.until {
        let elsewhere = away_from(&c.world, far);
        stand(&mut c, elsewhere);
        c.step();
    }
    stand(&mut c, far);
    c.step();
    assert_eq!((c.leg, c.rift), (1, None), "shut");
}

#[test]
fn a_crew_entering_at_a_fault_jumps_through_the_crack_to_the_hearts_entrance_on_its_realms_clock() {
    // §5.4: "faults open: cracks a crew can jump through once per heist,
    // ignoring the links. A fault joins an outer realm to the Heart", and the
    // entry is "Any edge tile of any outer realm, or a fault".
    use crate::reference::competent_universe;
    use crate::universe::{verified, LinkKind, FAULT_ENTRY};
    let (mut u, islands) = two_realms(LinkKind::Stone);
    assert!(competent_universe(&u, &islands, 1, 3, Some((FAULT_ENTRY | 1) as usize), None, None).is_none(),
            "no fault, no entry at one");
    u.faults = vec![1];
    let heist = competent_universe(&u, &islands, 1, 3, Some((FAULT_ENTRY | 1) as usize), None, None).unwrap();
    assert_eq!((heist.commands[0].kind, heist.commands[0].actor), (Kind::Land, FAULT_ENTRY | 1));
    assert_eq!(heist.ticks, 165 * TICKS_PER_SECOND, "the clock of the realm the fault opens from, by its links");
    let c = verified(&u, &islands, &heist).expect("verified");
    assert_eq!((c.landed, c.at_fault, c.route.clone(), c.crossed.len(), c.clock_links()), (1, true, vec![0], 0, 1));
    assert_eq!(c.world.landing, Some(c.world.entrance), "at the Heart's entrance");
    assert_eq!(c.world.skiff_ticks, crate::heist::SKIFF_HEART_TICKS);
    assert_eq!(c.reports().iter().map(|r| r.0).collect::<Vec<_>>(), vec![0], "the Heart alone");
    // A fault the universe does not have is no entry.
    let mut other = heist.clone();
    other.commands[0].actor = FAULT_ENTRY | 2;
    assert_eq!(crate::universe::verify_universe(&u, &islands, &other), Err(crate::Refusal::Landing));
}

#[test]
fn laws_flicker_off_for_two_seconds_in_an_overloaded_universe_every_ten_seconds_at_cracking_and_five_at_breaking() {
    // §5.5: Cracking, "each law has a 5% chance every 10 seconds of
    // blinking off for 2 seconds"; Breaking, "laws flicker twice as often".
    use crate::island::Island;
    use crate::universe::{FLICKER_EVERY_TICKS, FLICKER_TICKS};
    let island = Island::example();
    assert!(!island.laws.is_empty());
    let blinks = |flicker: u8, seed: u64| {
        let heist = Heist { seed, island: island.digest(), rules: crate::rules_version(), ticks: 7_200, crew: 3,
                            era: None, manifest: None, commands: Vec::new(), checksums: Vec::new() };
        let mut w = World::from_island(&island, &heist);
        w.flicker = flicker;
        for _ in 0..7_200 {
            w.step();
        }
        w.log.of(|e| matches!(e, E::LawOff { .. }))
    };
    let mut counts = [0usize; 3];
    for seed in 0..20u64 {
        for flicker in 0..3u8 {
            let off = blinks(flicker, seed);
            let every = if flicker == 0 { u32::MAX } else { FLICKER_EVERY_TICKS / flicker as u32 };
            for &(t, e) in &off {
                assert!(t > 0 && t % every == 0, "drawn every {every} ticks: {t}");
                assert!(matches!(e, E::LawOff { until, .. } if until == t + FLICKER_TICKS), "off for 2 s");
            }
            counts[flicker as usize] += off.len();
        }
    }
    // 20 heists of 240 s: 24 draws a law at Cracking, 48 at Breaking, 5% each.
    let draws = 20 * island.laws.len();
    assert_eq!(counts[0], 0, "a universe not overloaded never flickers");
    assert!(counts[1] * 100 > draws * 24 * 2 && counts[1] * 100 < draws * 24 * 9, "about 5%: {counts:?}");
    assert!(counts[2] > counts[1] * 3 / 2, "twice as often: {counts:?}");
    assert_eq!(blinks(1, 3), blinks(1, 3), "the same heist flickers the same everywhere");
}

#[test]
fn rb40_an_entrance_in_a_wall_or_on_the_vault_is_not_published() {
    // RB-40: the alarm-5 Warden spawns at the entrance, so an entrance in a
    // wall or on the Vault weakens the alarm-5 penalty. The gate refuses it.
    use crate::island::Island;
    let open = Island::example_open();
    assert_eq!(open.check(), vec![]);
    let mut walled = open.clone();
    walled.entrance = (0, 5);                             // the ruin wall
    assert!(!walled.check().is_empty(), "an entrance in the ruin wall: {:?}", walled.check());
    let mut vault = open.clone();
    vault.entrance = vault.vault;
    assert!(!vault.check().is_empty(), "an entrance on the Vault: {:?}", vault.check());
}

#[test]
fn rb50_weaving_a_law_onto_the_vault_is_refused_and_keeps_the_law() {
    // RB-50: the builder's law tool on the Vault took the law away.
    use crate::island::Island;
    let mut island = Island::example_open();
    assert!(island.weave("haste", 1, 10));
    let (vx, vy) = island.vault;
    assert!(!island.weave("haste", vx, vy), "the Vault cannot be covered");
    assert_eq!(island.laws, vec![("haste".to_string(), 1, 10)], "the law stays where it was");
}

#[test]
fn rb57_a_ward_or_pylon_on_a_guard_in_tall_grass_replaces_the_grass_too() {
    // RB-57: claim cleared the guard and left the grass under it, so the
    // ward or pylon put there made the island Crowded.
    use crate::heist::WardKind;
    use crate::island::{Island, Post};
    let mut island = Island::example_open();
    assert_eq!(island.tile(2, 7).and_then(|t| t.feature), Some(crate::grid::Feature::TallGrass));
    island.guards.push(Post { row: 0, x: 2, y: 7, facing: 0 });  // hidden in the grass
    assert_eq!(island.check(), vec![]);
    let mut ward = island.clone();
    assert!(ward.place_ward(WardKind::TimeSnare, 2, 7));
    assert_eq!((ward.guards.len(), ward.tile(2, 7).and_then(|t| t.feature)), (0, None));
    assert_eq!(ward.check(), vec![], "the ward replaced whatever stood there");
    let mut pylon = island.clone();
    assert!(pylon.weave("haste", 2, 7));
    assert_eq!((pylon.guards.len(), pylon.tile(2, 7).and_then(|t| t.feature)), (0, None));
    assert_eq!(pylon.check(), vec![], "the pylon replaced whatever stood there");
}

#[test]
fn candidate_7_the_same_law_twice_is_not_published() {
    // Bug report, unproven candidate 7: one law on two pylons passed the
    // gate, and the sheet applied it twice (guard speed 5/4 became
    // 441/256). A realm weaves each law once.
    use crate::island::Island;
    let mut twice = Island::example();
    assert_eq!(twice.laws.len(), 2);
    twice.laws[1].0 = twice.laws[0].0.clone();            // haste at (1, 10) and (11, 2)
    assert!(Island::decode(&twice.encode()).is_err() || !twice.check().is_empty(),
            "the same law twice passes the gate: {:?}", twice.check());
}

#[test]
fn candidate_34_a_tunnel_mouth_under_a_raised_wall_is_no_way_out() {
    // Bug report, unproven candidate 34: a crew's Crystal Wall raised on a
    // tunnel's far mouth still let routes come up through it, into the wall.
    let mut world = vault_world(1);
    for y in 0..14 {
        world.grid.place(4, y, Feature::RockPillar);
    }
    let at = |w: &World, x, y| w.grid.index(x, y).unwrap();
    let (from, to) = (at(&world, 2, 2), at(&world, 8, 2));
    world.grid.dig_tunnel(at(&world, 3, 2), at(&world, 6, 2));
    assert!(path::find_through(&world.grid, from, to).is_some(), "through the tunnel");
    world.grid.set_raised(at(&world, 6, 2), true);
    let route = path::find_through(&world.grid, from, to);
    assert!(route.as_ref().is_none_or(|r| r.iter().all(|&t| world.grid.at(t).passable())),
            "a route comes up into the raised wall: {route:?}");
}
