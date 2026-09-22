//! Angles, sines and cosines. §24.7: "Integer lookup tables with fixed-point
//! interpolation, and integer square roots. Angles are stored as a fraction of
//! a turn, which removes rounding around π entirely."
//!
//! The table holds a quarter turn of sine at `Fx` precision and the other three
//! quadrants are reflections of it, so the values are exact reflections rather
//! than separately rounded — `sin(x)` and `sin(-x)` are exactly opposite, which
//! a per-quadrant table would not guarantee.
//!
//! The table itself is generated at build time by `build_table.py`, from
//! rational arithmetic, and checked in. It is not computed at start-up: a
//! start-up computation would use floating point somewhere, which is the one
//! thing this simulation may not contain.

use crate::fixed::{Ang, Fx, ANG_TURN};

include!("sin_table.rs");

/// Entries in the quarter-turn table, minus the shared endpoint.
pub const QUARTER: i32 = ANG_TURN / 4;

/// Sine of an angle given as a fraction of a turn.
pub fn sin(a: Ang) -> Fx {
    let t = a.wrapped().0;                     // 0 .. ANG_TURN-1
    let quadrant = t / QUARTER;
    let within = t % QUARTER;
    let value = match quadrant {
        0 => lerp_quarter(within),
        1 => lerp_quarter(QUARTER - within),
        2 => -lerp_quarter(within),
        _ => -lerp_quarter(QUARTER - within),
    };
    value
}

/// Cosine, as sine a quarter turn ahead. Defining it this way rather than with
/// a second table means the identity holds exactly instead of to within two
/// roundings.
pub fn cos(a: Ang) -> Fx {
    sin(Ang(a.0.wrapping_add(QUARTER)))
}

/// Linear interpolation inside the quarter-turn table.
fn lerp_quarter(within: i32) -> Fx {
    let steps = SIN_TABLE.len() as i32 - 1;
    let scaled = (within as i64) * (steps as i64);
    let index = (scaled / QUARTER as i64) as usize;
    if index >= steps as usize {
        return Fx(SIN_TABLE[steps as usize]);
    }
    let frac = scaled % QUARTER as i64;        // 0 .. QUARTER-1
    let a = SIN_TABLE[index];
    let b = SIN_TABLE[index + 1];
    // (b - a) * frac / QUARTER, in 128-bit so the product cannot overflow.
    let delta = ((b - a) as i128 * frac as i128) / QUARTER as i128;
    Fx(a + delta as i64)
}
