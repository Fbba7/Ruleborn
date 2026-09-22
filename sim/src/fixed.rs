//! Fixed-point arithmetic. §24.7: "No floating point appears anywhere in the
//! simulation, because the same expression can produce different results on
//! different processors."
//!
//! Two widths, as the document specifies:
//!
//!   `Fx`  64-bit with 32 fractional bits — positions, speeds, distances
//!   `Ang` 32-bit with 16 fractional bits — angles and small values
//!
//! Every operation here is integer arithmetic. `i64` and `i32` multiply, shift
//! and divide identically on every target Rust compiles to: the width is
//! defined by the language, two's complement is defined by the language, and
//! shifts of a defined amount are defined behaviour. That is the property the
//! whole architecture rests on, and it is why this file exists instead of a
//! `f64`.
//!
//! Overflow is checked in release as well as debug (see Cargo.toml). A
//! simulation that wraps silently on one target and not another is exactly the
//! divergence this is written to prevent, so it is made to abort instead.

/// A 64-bit fixed-point number with 32 fractional bits.
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug, Default)]
pub struct Fx(pub i64);

/// The number of fractional bits in `Fx`. §24.10 states it as a contract.
pub const FX_BITS: u32 = 32;
/// `Fx` representing one.
pub const FX_ONE: i64 = 1i64 << FX_BITS;

impl Fx {
    pub const ZERO: Fx = Fx(0);
    pub const ONE: Fx = Fx(FX_ONE);

    /// From a whole number.
    pub const fn from_int(n: i32) -> Fx {
        Fx((n as i64) << FX_BITS)
    }

    /// From a ratio, rounded toward negative infinity so that the rounding is
    /// the same for negative values as for positive ones. `round()` toward
    /// zero would make `-1/2` and `1/2` round in opposite directions, which is
    /// a difference that accumulates.
    pub const fn from_ratio(num: i64, den: i64) -> Fx {
        Fx(div_floor(num << FX_BITS, den))
    }

    /// The whole part, rounded toward negative infinity.
    pub const fn to_int(self) -> i64 {
        self.0 >> FX_BITS
    }

    /// Multiply. The intermediate needs 128 bits: two 64-bit fixed-point
    /// numbers produce up to 128 significant bits before the shift, and
    /// truncating to 64 first is a silent loss that differs by operand size.
    pub fn mul(self, other: Fx) -> Fx {
        let wide = (self.0 as i128) * (other.0 as i128);
        Fx(shr_floor_i128(wide, FX_BITS) as i64)
    }

    /// Divide, rounding toward negative infinity for the same reason as
    /// `from_ratio`.
    pub fn div(self, other: Fx) -> Fx {
        debug_assert!(other.0 != 0, "fixed-point divide by zero");
        let wide = (self.0 as i128) << FX_BITS;
        Fx(div_floor_i128(wide, other.0 as i128) as i64)
    }

    pub fn abs(self) -> Fx {
        Fx(self.0.abs())
    }

    /// Square root, by Newton's method on integers. §24.7: "integer square
    /// roots". Returns zero for negative input rather than panicking, because
    /// a squared distance is never negative and a caller that produced one has
    /// a bug the checksum will find.
    pub fn sqrt(self) -> Fx {
        if self.0 <= 0 {
            return Fx::ZERO;
        }
        // sqrt(x * 2^32) = sqrt(x) * 2^16, so the integer root of the raw
        // value needs shifting up by half the fractional bits.
        Fx((isqrt_u64(self.0 as u64) as i64) << (FX_BITS / 2))
    }
}

impl core::ops::Add for Fx {
    type Output = Fx;
    fn add(self, other: Fx) -> Fx {
        Fx(self.0 + other.0)
    }
}

impl core::ops::Sub for Fx {
    type Output = Fx;
    fn sub(self, other: Fx) -> Fx {
        Fx(self.0 - other.0)
    }
}

impl core::ops::Neg for Fx {
    type Output = Fx;
    fn neg(self) -> Fx {
        Fx(-self.0)
    }
}

/// Integer square root, Newton's method. Exact and identical everywhere: it
/// terminates on integers rather than converging on a real.
pub const fn isqrt_u64(n: u64) -> u64 {
    if n == 0 {
        return 0;
    }
    // A starting guess above the root, from the bit length.
    let mut x = 1u64 << ((64 - n.leading_zeros()).div_ceil(2));
    loop {
        let next = (x + n / x) / 2;
        if next >= x {
            return x;
        }
        x = next;
    }
}

/// Floor division for i64. Rust's `/` truncates toward zero.
pub const fn div_floor(a: i64, b: i64) -> i64 {
    let q = a / b;
    if (a % b != 0) && ((a < 0) != (b < 0)) {
        q - 1
    } else {
        q
    }
}

const fn div_floor_i128(a: i128, b: i128) -> i128 {
    let q = a / b;
    if (a % b != 0) && ((a < 0) != (b < 0)) {
        q - 1
    } else {
        q
    }
}

/// Arithmetic shift right with floor semantics. On i128 this is already
/// floor for negatives, but stating it means the intent survives a rewrite.
const fn shr_floor_i128(a: i128, bits: u32) -> i128 {
    a >> bits
}

/// A 32-bit fixed-point number with 16 fractional bits, for angles and small
/// values. §24.7: "Angles are stored as a fraction of a turn, which removes
/// rounding around π entirely" — so a full turn is `ANG_TURN`, and there is no
/// π in the simulation at all.
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug, Default)]
pub struct Ang(pub i32);

/// One full turn. Angles wrap within this, so there is no accumulated error
/// from repeatedly adding a fraction of π.
pub const ANG_TURN: i32 = 1 << 16;

impl Ang {
    pub const ZERO: Ang = Ang(0);

    /// From a fraction of a turn: `Ang::from_turn_ratio(1, 4)` is a quarter
    /// turn, which is what the document's degrees become.
    pub const fn from_turn_ratio(num: i32, den: i32) -> Ang {
        Ang(((num as i64 * ANG_TURN as i64) / den as i64) as i32)
    }

    /// From degrees, which is how §12.17 states guard cones.
    pub const fn from_degrees(deg: i32) -> Ang {
        Ang::from_turn_ratio(deg, 360)
    }

    /// Reduced to a single turn, always non-negative.
    pub const fn wrapped(self) -> Ang {
        Ang(self.0.rem_euclid(ANG_TURN))
    }

    /// The shortest signed distance between two angles, in the range
    /// (-half a turn, half a turn]. Comparing cone widths needs this rather
    /// than a raw subtraction, which would read 359° and 1° as far apart.
    pub fn delta(self, other: Ang) -> Ang {
        let half = ANG_TURN / 2;
        let d = (self.0 - other.0).rem_euclid(ANG_TURN);
        Ang(if d > half { d - ANG_TURN } else { d })
    }
}
