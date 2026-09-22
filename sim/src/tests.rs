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
fn a_breaker_cracks_at_double_damage_one_hit_every_eight_tenths() {
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
    assert_eq!(world.vault.health, 1500 - 12 - 2 * 40, "Scout 12, Breaker twice 40");
}

#[test]
fn cracking_takes_ten_to_twenty_five_seconds_only_with_a_breaker() {
    // §12.19: "Cracking is 10 to 25 seconds." At Vault level 1, 1,500 health.
    let secs = |roles: &[usize]| ticks_to_open(roles) / TICKS_PER_SECOND;
    let breaker = secs(&[1]);
    let three = secs(&[0, 1, 2]);
    for (label, s) in [("a Breaker alone", breaker), ("Scout, Breaker, Carrier", three)] {
        assert!((10..=25).contains(&s), "{label}: {s} s, outside 12.19's band");
    }
    // A full crew hits for 126 every 0.8 s: twelve hits, 9.6 s — just under
    // the band's floor. Pinned at its value rather than rounded into it.
    assert_eq!(ticks_to_open(&[0, 1, 2, 3, 4]), 12 * h::HIT_TICKS);
    // Without one it is not: four crew with no Breaker hit for 46 every 0.8 s.
    let no_breaker = secs(&[0, 2, 3, 4]);
    assert!(no_breaker > 25, "no Breaker: {no_breaker} s — the band assumes one");
}

#[test]
fn a_hit_on_the_vault_is_heard_five_steps_away() {
    // §12.17's "Breaking something — 5 m". A guard five steps from the
    // cracker, facing away, investigates when the hit lands.
    let mut world = vault_world(2);
    put(&mut world, 1, 5, 6);                     // the Breaker, west of the Vault
    world.raiders[1].task = Task::Crack;
    put(&mut world, 0, 13, 13);
    let mut g = make_guard(0, 0, world.grid.index(0, 6).unwrap(), &world.grid);
    g.facing = Ang::from_degrees(180);            // west, away
    world.guards.push(g);
    for _ in 0..h::HIT_TICKS {
        world.step();
    }
    assert_eq!(world.guards[0].state, State::Investigating);
}

#[test]
fn the_crack_noise_empties_before_it_can_matter() {
    // §12.6: "every 5 seconds adds 100 suspicion to every guard in the
    // Heart". §12.17 empties suspicion at 20 a tick, so an unaware guard's
    // 100 is gone in five ticks and it never reaches Suspicious at 200.
    // This pins the collision between the two sections, measured rather
    // than argued: see the README.
    let mut world = vault_world(2);
    put(&mut world, 1, 5, 6);
    world.raiders[1].task = Task::Crack;
    put(&mut world, 0, 13, 13);
    // Far enough that the hit itself is not heard, and facing away.
    let mut g = make_guard(0, 1, world.grid.index(13, 0).unwrap(), &world.grid);
    g.facing = Ang::from_degrees(0);
    world.guards.push(g);
    let mut peak = 0;
    let mut state_seen = State::Unaware;
    for _ in 0..(20 * TICKS_PER_SECOND) {
        world.step();
        peak = peak.max(world.guards[0].suspicion);
        if world.guards[0].state != State::Unaware {
            state_seen = world.guards[0].state;
        }
    }
    assert!(world.vault.first_hit.is_some(), "cracking happened");
    assert_eq!(peak, h::CRACK_NOISE, "the 100 arrives");
    assert_eq!(state_seen, State::Unaware, "and never moves the guard");
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
    assert_eq!(world.vault.exposed, 0, "560 exposed, 560 carried");
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
        world.law_pace = Fx::ONE;
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
    assert_eq!(health, 120 / 4, "back at a quarter — the simulation's reading");
    let (_, by_mender, _) = down(Some(4));
    assert_eq!(by_mender, Some(h::MENDER_REVIVE_TICKS), "a Mender: one and a half");
}

#[test]
fn two_ambush_hits_knock_out_a_guard_of_equal_level_in_every_pairing() {
    // §12.8: triple Power or half the guard's full health, whichever is
    // greater, "so two ambush hits now knock out a guard of equal level in
    // every pairing". All 25, from §11.1's columns.
    let roles = [Role::Scout, Role::Warden, Role::Breaker, Role::Carrier, Role::Mender];
    for a in roles {
        for g in roles {
            let hit = (a.power() * 3).max(g.health() / 2);
            assert!(2 * hit >= g.health(), "{a:?} on {g:?}");
        }
    }
    // And in the world: a Scout and a Breaker behind the Warden guard (420).
    let mut world = vault_world(2);
    let gi = post(&mut world, 1, 3, 3);
    put(&mut world, 0, 3, 4);
    put(&mut world, 1, 3, 4);
    for ri in 0..2 {
        world.raiders[ri].task = Task::Attack;
        world.raiders[ri].target = gi as u32;
    }
    for _ in 0..h::HIT_TICKS {
        world.step();
    }
    assert!(world.guards[gi].knocked_out, "210 and 210: down in one exchange");
    assert!(!world.alarm_raised, "an ambush raises nothing");
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
    let mut world = World::new(heist.seed, heist.crew, heist.commands.clone());
    world.clock = heist.ticks;
    for _ in 0..heist.ticks {
        world.step();
    }
    let o = world.outcome();
    assert_eq!(o.grade, Grade::Clean, "{o:?}");
    assert_eq!(o.banked, o.capacity, "every bag full");
    assert_eq!(world.guards.iter().filter(|g| g.knocked_out).count(), 2,
               "two guards ambushed, and nobody found them");
    assert!(heist.size_fits());
}
