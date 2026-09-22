//! The Vault, the fight, and how a heist ends: §12.6, §12.19, §12.20, §12.9
//! and §5.4, as numbers. The rules that use them are in `lib.rs`, in the
//! states phase, because every one of them changes a state.
//!
//! Where the document gives a number it is quoted. Where the simulation had
//! to choose one it is named as a reading, and `content_gate.py` lists every
//! reading on the audit page so none passes for the document's.

use crate::TICKS_PER_SECOND;

/// §12.6: "The Vault: 1,500 health per Vault level; Breakers deal double
/// damage to it."
pub const VAULT_HEALTH_PER_LEVEL: i32 = 1500;
pub const BREAKER_VAULT_DAMAGE: (i32, i32) = (2, 1);

/// §12.20: "One hit every 0.8 seconds for damage equal to Power, on both
/// sides." §12.8: "every guard attack shows a 0.8-second wind-up" — so the
/// wind-up is the cadence: a hit lands 24 ticks after the swing starts.
pub const HIT_TICKS: u32 = TICKS_PER_SECOND * 8 / 10;

/// §12.6: "Cracking is loud: every 5 seconds adds 100 suspicion to every guard
/// in the Heart." The fixture realm is the Heart, so that is every guard.
pub const CRACK_NOISE_TICKS: u32 = TICKS_PER_SECOND * 5;
pub const CRACK_NOISE: i32 = 100;

/// §12.19: "Every role can load, at 30 units a second" — one a tick.
pub const LOAD_PER_SECOND: i32 = 30;

/// §11.1, the Carrier: "15% slower when loaded".
pub const CARRIER_LOADED_PACE: (i64, i64) = (85, 100);

/// §12.20: "Drops its loot on the tile and has ten seconds before capture. An
/// ally standing adjacent revives it in 3 seconds, a Mender in 1.5."
pub const DOWN_TICKS: u32 = TICKS_PER_SECOND * 10;
pub const REVIVE_TICKS: u32 = TICKS_PER_SECOND * 3;
pub const MENDER_REVIVE_TICKS: u32 = TICKS_PER_SECOND * 3 / 2;

/// §5.4: the skiff "takes 5 seconds to reach an outer realm and 20 seconds to
/// fight the winds around the Heart. The crew must hold the spot until it
/// arrives." The fixture realm is the Heart.
pub const SKIFF_OUTER_TICKS: u32 = TICKS_PER_SECOND * 5;
pub const SKIFF_HEART_TICKS: u32 = TICKS_PER_SECOND * 20;

/// How much health a revived crew member gets back. **Not in the document**:
/// §12.20 says an ally "revives it" and not with what. A quarter, so a revive
/// is a second chance rather than a full reset.
pub const REVIVE_HEALTH: (i32, i32) = (1, 4);

/// How much the fixture's Vault holds, in the units bags are measured in.
/// **Not a document number**: §9.6 prices the exposed share in Starlight and
/// the bags in §11.1's Carry, and nothing converts one to the other. 560 is a
/// five-crew's Carry, so a full crew can empty it and a smaller one cannot.
pub const FIXTURE_EXPOSED: i32 = 560;

/// §12.8: "the first hit on a guard that has not noticed the crew stuns it
/// for 2 seconds and deals triple Power, or half the guard's full health,
/// whichever is greater."
pub const AMBUSH_STUN_TICKS: u32 = TICKS_PER_SECOND * 2;
pub const AMBUSH_POWER: (i32, i32) = (3, 1);
pub const AMBUSH_HEALTH_FLOOR: (i32, i32) = (1, 2);

/// §10.2, the Law Pylon at level 1: "600 health".
pub const PYLON_HEALTH: i32 = 600;

/// §7, Stillness: "Anyone standing still for 1.5 seconds becomes invisible to
/// guards and wards."
pub const STILL_TICKS: u32 = TICKS_PER_SECOND * 3 / 2;

/// What a crew member is doing, beyond walking. §12.18: the crew "never makes
/// a decision the player did not make", so each of these is set by a command
/// and stays until another replaces it.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Task {
    #[default]
    None = 0,
    Crack = 1,
    Load = 2,
    /// Hit one guard, by index.
    Attack = 3,
    /// Break one structure, by tile.
    Break = 4,
    /// Disarm one ward, by tile.
    Disarm = 5,
}

/// Where a crew member stands in the heist.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Standing {
    #[default]
    Active = 0,
    /// At zero health, loot dropped, with ten seconds to be revived.
    Down = 1,
    /// "Sent home, rested longer, and its share of the haul lost."
    Caught = 2,
    /// Aboard the skiff, with what it carried banked.
    Out = 3,
}

/// §12.9's four outcomes.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Grade {
    /// "No alarm; everyone out with loot."
    Clean,
    /// "Alarm raised; everyone out."
    Loud,
    /// "Some caught; some loot out."
    Partial,
    /// "No loot out."
    Foiled,
}

/// The Vault. One tile, walled: it is cracked and loaded from beside it.
#[derive(Clone, Debug)]
pub struct Vault {
    pub tile: crate::grid::TileIndex,
    pub health: i32,
    /// What is left to load. §12.6: loading stops when "the exposed share is
    /// gone".
    pub exposed: i32,
    /// The tick of the first hit, for the crack noise.
    pub first_hit: Option<u32>,
    pub opened_at: Option<u32>,
}

/// A called skiff: where, and when it arrives.
#[derive(Clone, Copy, Debug)]
pub struct Skiff {
    pub tile: crate::grid::TileIndex,
    pub arrives: u32,
}

/// What a heist came to.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Outcome {
    pub grade: Grade,
    pub banked: i32,
    /// The crew's whole Carry: `banked * 100 / capacity` is §12.19's fill.
    pub capacity: i32,
    pub caught: u32,
    pub out: u32,
    /// Laws whose pylon the crew broke: a page of each (§12.6).
    pub pages: u32,
}

// --------------------------------------------------------------------------
// Wards (§10.3), as spec/wards.md reads them at level 1
// --------------------------------------------------------------------------

/// §10.3's six wards.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum WardKind {
    /// Passive: "A breakable wall (800 health) that blocks a path."
    CrystalWall = 0,
    /// Passive: "Blocks a path and hurts anyone pushing through (5% health a
    /// second)". A wall you choose to push through (spec/wards.md): passable,
    /// and it hurts.
    ThornHedge = 1,
    /// Aura: "Shocks anyone within 2 tiles every 3 seconds."
    StaticCoil = 2,
    /// Triggered: "Pulls anyone within 3 tiles to its centre and holds them 2
    /// seconds."
    GravityWell = 3,
    /// Triggered: "Freezes the first character to step on it for 2.5 seconds."
    TimeSnare = 4,
    /// Triggered: "Shows the crew to every guard in the realm for 5 seconds
    /// and blinds them for 2."
    LanternGlare = 5,
}

impl WardKind {
    pub fn passive(self) -> bool {
        matches!(self, WardKind::CrystalWall | WardKind::ThornHedge)
    }

    /// §10.3's "Resets after", at level 1. §10.2's row says 10 s for every
    /// ward; §10.3 gives Time Snare 12 and Lantern Glare 20. The simulation
    /// takes each ward's own section (C32).
    pub fn reset_ticks(self) -> u32 {
        match self {
            WardKind::GravityWell => TICKS_PER_SECOND * 10,
            WardKind::TimeSnare => TICKS_PER_SECOND * 12,
            WardKind::LanternGlare => TICKS_PER_SECOND * 20,
            _ => 0,
        }
    }
}

pub const CRYSTAL_WALL_HEALTH: i32 = 800;
/// spec/wards.md: "ward health = 500 × level" — **a proposal, not the
/// document's**: §11.1 gives Breakers "double damage to wards", so wards must
/// have health, and §10.3 gives it to the Crystal Wall alone.
pub const WARD_HEALTH_PER_LEVEL: i32 = 500;
pub const HEDGE_DAMAGE: (i32, i32) = (5, 100);
pub const COIL_RADIUS: i32 = 2;
pub const COIL_PERIOD_TICKS: u32 = TICKS_PER_SECOND * 3;
/// spec/wards.md: "Static Coil's 8% is new. The document gives it no damage at
/// all." **A proposal, not the document's.**
pub const COIL_DAMAGE: (i32, i32) = (8, 100);
pub const WELL_RADIUS: i32 = 3;
pub const WELL_HOLD_TICKS: u32 = TICKS_PER_SECOND * 2;
pub const SNARE_FREEZE_TICKS: u32 = TICKS_PER_SECOND * 5 / 2;
pub const GLARE_REVEAL_TICKS: u32 = TICKS_PER_SECOND * 5;
/// "blinds them for 2": the crew, read as unable to act — the only sense the
/// simulation has in which a crew member sees.
pub const GLARE_BLIND_TICKS: u32 = TICKS_PER_SECOND * 2;
/// spec/wards.md: "3 s + 1 s per ward level", silent; "moving cancels it;
/// progress is kept for 5 s".
pub const DISARM_BASE_TICKS: u32 = TICKS_PER_SECOND * 3;
pub const DISARM_PER_LEVEL_TICKS: u32 = TICKS_PER_SECOND;
pub const DISARM_KEEP_TICKS: u32 = TICKS_PER_SECOND * 5;

/// A ward on the island.
#[derive(Clone, Debug)]
pub struct Ward {
    pub kind: WardKind,
    pub tile: crate::grid::TileIndex,
    pub level: u8,
    pub health: i32,
    /// A triggered ward is inert until this tick.
    pub armed_at: u32,
    pub disarmed: bool,
    pub broken: bool,
    /// Disarm progress, and the tick it last advanced.
    pub disarm: u32,
    pub disarm_touched: u32,
}

impl Ward {
    pub fn new(kind: WardKind, tile: crate::grid::TileIndex) -> Ward {
        let health = if kind == WardKind::CrystalWall {
            CRYSTAL_WALL_HEALTH
        } else {
            WARD_HEALTH_PER_LEVEL
        };
        Ward { kind, tile, level: 1, health, armed_at: 0, disarmed: false, broken: false,
               disarm: 0, disarm_touched: 0 }
    }

    /// Still doing anything at all.
    pub fn live(&self) -> bool {
        !self.disarmed && !self.broken
    }

    pub fn disarm_ticks(&self) -> u32 {
        DISARM_BASE_TICKS + DISARM_PER_LEVEL_TICKS * self.level as u32
    }
}
