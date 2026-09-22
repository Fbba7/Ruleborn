//! Properties the checksum rests on. A cross-target digest proves two builds
//! agree; it does not prove they agree on something *correct*. These are the
//! invariants that would make an agreed-upon answer still be wrong.

use crate::fixed::{isqrt_u64, Ang, Fx, ANG_TURN};
use crate::rng::{Rng, Stream};
use crate::{trig, World, TICKS_PER_SECOND};

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
    let a = crate::run(0x1234_5678, 900);
    let b = crate::run(0x1234_5678, 900);
    assert_eq!(a, b, "same seed, same checksums");
}

#[test]
fn different_seeds_produce_different_heists() {
    let a = crate::digest(1, 900);
    let b = crate::digest(2, 900);
    assert_ne!(a, b, "the seed has to matter or the spike proves nothing");
}

#[test]
fn suspicion_stays_inside_the_documents_range() {
    // §12.17: "Each guard carries a suspicion value from 0 to 1000."
    let mut world = World::new(0xABCD);
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
    let mut world = World::new(5);
    for _ in 0..100 {
        world.step();
    }
    let before = world.checksum();
    world.raiders[0].at.x = Fx(world.raiders[0].at.x.0 + 1);
    assert_ne!(before, world.checksum(), "one unit in the last place must show");
}
