//! §18.3's eras: "Each week one rule changes for every universe, which
//! refreshes which laws and crews are strong. Eras are pure data, so they are
//! cheap to ship at launch."
//!
//! §7.3 places one on the rule sheet: "Apply the Era, then the Grand Law,
//! then crown laws, then the realm's laws". An era is chosen by the server
//! for the week and named in the replay's header (`replay::Heist::era`), so a
//! heist re-simulates under the era it was played in, whenever it is checked.
//!
//! Each era's figure is `laws_table::ERAS`', read by the generator from the
//! era's own rule; what the figure does is here. Two eras change only what
//! laws cost — Heavy Stars' "Motion laws cost 30% less" and High Tide's
//! "Slow rivers costs no stability" — which is the device's economy, not the
//! heist: the simulation leaves those halves alone.

use crate::heist::WardKind;
use crate::laws_table::{Param, ERAS};

/// The eight, in `laws_table::ERAS` order; the wire value is the index plus
/// one, and 0 is no era.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
#[repr(u8)]
pub enum Era {
    /// "Motion laws cost 30% less; gravity can't be set lower".
    HeavyStars = 1,
    /// "Vision is 30% shorter everywhere".
    TheLongNight = 2,
    /// "Slow rivers costs no stability" — a cost, and nothing in a heist.
    HighTide = 3,
    /// "Life laws are 25% stronger".
    Wildgrowth = 4,
    /// "Everyone returns once at 40% after being knocked out".
    EchoingSkies = 5,
    /// "Energy wards are 50% stronger".
    StaticStorm = 6,
    /// "Walls everywhere are see-through".
    GlassMoon = 7,
    /// "Heists are 30 seconds longer".
    QuietWeek = 8,
}

const ALL: [Era; 8] = [Era::HeavyStars, Era::TheLongNight, Era::HighTide, Era::Wildgrowth,
                       Era::EchoingSkies, Era::StaticStorm, Era::GlassMoon, Era::QuietWeek];

impl Era {
    /// The wire value's era: 0 is none, and a value past the table is not one.
    pub fn from_u8(v: u8) -> Option<Option<Era>> {
        match v {
            0 => Some(None),
            v if (v as usize) <= ALL.len() => Some(Some(ALL[v as usize - 1])),
            _ => None,
        }
    }

    pub fn from_id(id: &str) -> Option<Era> {
        ERAS.iter().position(|(e, _)| *e == id).map(|i| ALL[i])
    }

    pub fn id(self) -> &'static str {
        ERAS[self as usize - 1].0
    }

    /// The figure the era's rule states.
    pub fn figure(self) -> i64 {
        ERAS[self as usize - 1].1
    }
}

/// The era's own lines on the sheet, applied before any law: The Long
/// Night's shorter sight, and Glass Moon's see-through walls — the same line
/// the Glass law writes (§7.3's Sight row: "Walls become see-through").
pub fn first_lines(era: Option<Era>) -> Vec<(Param, i64, i64)> {
    match era {
        Some(e @ Era::TheLongNight) => vec![(Param::SightRange, 100 - e.figure(), 100)],
        Some(Era::GlassMoon) => vec![(Param::HideBehindWalls, 0, 1)],
        _ => Vec::new(),
    }
}

/// Heavy Stars: "gravity can't be set lower". A law that lowers gravity —
/// Half gravity, the one launch law that does — has no gravity to lower, so
/// its line does not apply; it is still woven, and its notes still sound.
pub fn suspends(era: Option<Era>, law: &str) -> bool {
    era == Some(Era::HeavyStars) && law == "half_gravity"
}

/// What a law's line becomes under the era. Wildgrowth makes every Life law
/// "25% stronger", and stronger reads by what the line is (G36): a time
/// comes 25% sooner, a rate or a share is 25% larger, a multiplier moves 25%
/// further from 1, and an on/off rule is what it was.
pub fn line(era: Option<Era>, school: &str, p: Param, n: i64, d: i64) -> (i64, i64) {
    let Some(e @ Era::Wildgrowth) = era else { return (n, d) };
    if school != "Life" {
        return (n, d);
    }
    let k = e.figure();                                   // 25
    match kind(p) {
        Kind::Time => (n * 100, d * (100 + k)),
        Kind::Rate => (n * (100 + k), d * 100),
        Kind::Multiplier => (100 * d + (100 + k) * (n - d), 100 * d),
        Kind::Rule => (n, d),
    }
}

/// Echoing Skies' Revival source: "Everyone returns once at 40%", which
/// §7.3's Revival row takes as one source among several, "the highest N".
pub fn revival_return(era: Option<Era>) -> Option<(i64, i64)> {
    match era {
        Some(e @ Era::EchoingSkies) => Some((e.figure(), 100)),
        _ => None,
    }
}

/// Static Storm: "Energy wards are 50% stronger". The one Energy ward is the
/// Static Coil (§10.3), and what an upgrade of it scales is "The shock's
/// damage", so that is what grows.
pub fn ward_strength(era: Option<Era>, ward: WardKind) -> (i64, i64) {
    match era {
        Some(e @ Era::StaticStorm) if ward == WardKind::StaticCoil => (100 + e.figure(), 100),
        _ => (1, 1),
    }
}

/// Quiet Week: "Heists are 30 seconds longer", in ticks. The server adds it
/// to the lease's clock; the simulation allows a heist that much longer.
pub fn extra_ticks(era: Option<Era>) -> u32 {
    match era {
        Some(e @ Era::QuietWeek) => e.figure() as u32 * crate::TICKS_PER_SECOND,
        _ => 0,
    }
}

enum Kind {
    Time,
    Rate,
    Multiplier,
    Rule,
}

/// Every line of the sheet by what it is, so "stronger" has one reading
/// each. Exhaustive: a parameter added to the sheet must be placed here.
fn kind(p: Param) -> Kind {
    use Param::*;
    match p {
        EffectDelaySeconds | LightBandSeconds | RegrowSeconds | TouchStunSeconds => Kind::Time,
        AllyHealing | ChainShare | RevivalReturn | RevivalSwap | StructureHealing | TouchDamage
        | UnlitDrain => Kind::Rate,
        AlarmRange | CarryWeight | ClockRate | ConeAngle | CrewSpeed | Damage | GuardSpeed
        | LargeHealth | LargeSpeed | LoadedSpeed | NoiseRadius | Rebound | SightRange
        | SmallHealth | SmallSpeed | StructureDamage | SuspicionDecay | SuspicionFill => Kind::Multiplier,
        ClimbLevels | HideBehindWalls | LeapObstacles | Slide | StillIsInvisible => Kind::Rule,
    }
}
