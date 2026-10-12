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

// §12.6 (v3.4) had every hit on the Vault heard within 5 m and every 5
// seconds of cracking call the guards within 5 m of the walk. The owner
// decided no guard hears the Vault (F35): neither is simulated.

/// §11.1 (v3.3): "While two or more characters work the same object, every
/// hit on it deals 25% more: the assist bonus. It does not stack."
pub const ASSIST_BONUS: (i64, i64) = (125, 100);

/// §12.19: "Every role can load, at 30 units a second" — one a tick.
pub const LOAD_PER_SECOND: i32 = 30;

/// §11.1, the Carrier: "15% slower when loaded".
pub const CARRIER_LOADED_PACE: (i64, i64) = (85, 100);

/// §12.17: "A guard standing a level higher sees a metre further." Per level.
pub const HIGHER_GROUND_METRES: i32 = 1;

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

/// §5.4: "A landing skiff can be heard: guards within 6 tiles of the landing
/// spot start at 250 of 1,000 suspicion (12.17), unless the spot is in fog,
/// darkness or tall grass."
pub const LANDING_HEARD_TILES: i32 = 6;
pub const LANDING_SUSPICION: i32 = 250;

/// §12.20 (v3.3, G14): a revived crew member "returns at 30% of its full
/// health: enough to reach the skiff, not enough to stand in a fight".
pub const REVIVE_HEALTH: (i32, i32) = (30, 100);

/// How much the fixture's Vault holds, in the units bags are measured in.
/// §9.6 (v3.3, G15): "exposed share in bag units = a full five-crew's carry ×
/// the richness ratio", so a target at its level median exposes 750 — the
/// sum of §11.1's Carry column. A full crew can empty it; a smaller one cannot.
pub const FIXTURE_EXPOSED: i32 = 750;

/// §12.8 (v3.3): "the first hit on a guard that has not noticed the crew
/// knocks it out, whatever its role or level ... it deals exactly what the
/// guard has left", and "the takedown takes 2 seconds, in which the attacker
/// does nothing else". §29.1 orders the two: "a knockout ... after a 2 s
/// takedown", and §12.8 requires the guard to be "still Unaware when the hit
/// lands" — so the hit lands at the end of the two seconds, and a guard that
/// notices before then takes an ordinary hit instead.
pub const TAKEDOWN_TICKS: u32 = TICKS_PER_SECOND * 2;

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
    /// Drag one knocked-out guard, by index. §12.8: "A crew member can drag
    /// a body at crouching speed and hide it."
    Drag = 6,
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
    /// Which: bit n is §7.7's nth law (`laws_table::LAWS`, content/laws.json's
    /// order), so the server knows whose page each is (§7.6).
    pub broken: u64,
    /// Structures broken while Cracked gardens sounds (§8.4): "broken
    /// structures leave Essence that the owner collects after the heist".
    /// How much each leaves is not stated (G25), so the count is reported
    /// and nothing is paid for it yet.
    pub cracked: u32,
    /// What the crew took from the Vault and did not bank: dropped when
    /// knocked down or by choice, or still carried by whoever was not out.
    /// §9.4's "what the crew was carrying", a share of which a foiled heist
    /// pays the defender.
    pub left: i32,
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
    /// Triggered (v3.7): "Shows the crew to every guard within 4 m of it for 5
    /// seconds (8 m from alarm level 4, 12.17) and blinds the crew for 2."
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
/// §10.3 (v3.3): "Every ward has 550 health a level", moved from 500 so a
/// level-2 ward outlasts a Tinker's disarm. One value since v3.4 (C34).
pub const WARD_HEALTH_PER_LEVEL: i32 = 550;
pub const HEDGE_DAMAGE: (i32, i32) = (5, 100);
pub const COIL_RADIUS: i32 = 2;
pub const COIL_PERIOD_TICKS: u32 = TICKS_PER_SECOND * 3;
/// §10.3 (v3.3): "Shocks everyone within 2 tiles every 3 seconds, for 8% of
/// their maximum health a shock" — spec/wards.md's proposal, now the document's.
pub const COIL_DAMAGE: (i32, i32) = (8, 100);
pub const WELL_RADIUS: i32 = 3;
pub const WELL_HOLD_TICKS: u32 = TICKS_PER_SECOND * 2;
pub const SNARE_FREEZE_TICKS: u32 = TICKS_PER_SECOND * 5 / 2;
pub const GLARE_REVEAL_TICKS: u32 = TICKS_PER_SECOND * 5;
/// §10.3 (v3.3), Lantern Glare's sensor: "a crew member comes within 2 tiles".
pub const GLARE_RADIUS: i32 = 2;
/// "blinds the crew for 2" (v3.7; v3.6's "them" was read the same way): unable
/// to act — the only sense the simulation has in which a crew member sees.
pub const GLARE_BLIND_TICKS: u32 = TICKS_PER_SECOND * 2;
/// §10.3 (v3.3): "The disarmer stands on the ward's tile for 15 seconds at
/// every ward level ... and cannot move, hide or use an ability until it
/// finishes; stepping off starts it again." The Tinker trait's 30% is not
/// modelled: the simulation has no traits yet.
pub const DISARM_TICKS: u32 = TICKS_PER_SECOND * 15;

/// Static (§7.4): "Moving builds charge; after 5 tiles, the next touch
/// stuns".
pub const STATIC_TILES: u32 = 5;

/// Chain lightning (§7.4): "Every hit jumps to a second target within 3
/// tiles", measured centre to centre.
pub const CHAIN_TILES: i32 = 3;

/// Aurora (§7.4): "Bands of light sweep the realm every 10 seconds". The
/// width is not given; two rows is this simulation's reading (G23).
pub const AURORA_BAND_ROWS: i64 = 2;

// §8's combinations. Where the document gives a figure it is quoted; where
// it does not, the figure is this simulation's reading and G25 lists it.

/// Glow harmony: "light and reveal ranges 2 tiles longer" — Aurora's band.
pub const GLOW_HARMONY_ROWS: i64 = 2;
/// Hush harmony: "hiding works 1 tile closer to guards", in tiles.
pub const HUSH_HARMONY_TILES: i32 = 1;
/// Gusts and lulls: "everyone's speed changes by ±20% at random every 10
/// seconds".
pub const GUST_TICKS: u32 = TICKS_PER_SECOND * 10;
/// Flicker: "every 15 seconds the realm goes fully bright or fully dark for
/// 3 seconds".
pub const FLICKER_TICKS: u32 = TICKS_PER_SECOND * 15;
pub const FLICKER_HOLD_TICKS: u32 = TICKS_PER_SECOND * 3;
/// Wildfire: grass and hedges "burn for 5 seconds, hurting anyone inside";
/// the hurt is a reading, the Thorn Hedge's 5% a second.
pub const BURN_TICKS: u32 = TICKS_PER_SECOND * 5;
pub const BURN_DAMAGE: (i32, i32) = (5, 100);
/// Déjà vu: "once per heist"; when is a reading — a random second in the
/// minute after the clash first sounds.
pub const DEJA_VU_WINDOW_TICKS: u64 = TICKS_PER_SECOND as u64 * 60;
/// Mangrove banks: "slow crews by a further 20%".
pub const MANGROVE_PACE: (i64, i64) = (4, 5);
/// Night runners: "anyone in darkness moves 30% faster".
pub const NIGHT_RUNNERS_PACE: (i64, i64) = (13, 10);
/// Storm grid: "chains jump to three targets".
pub const STORM_GRID_TARGETS: usize = 3;
/// Twin souls: "characters who swap places heal each other 20%".
pub const TWIN_SOULS_HEAL: (i32, i32) = (20, 100);
/// Shattered glass: shards "slow anyone by 30% for 5 seconds".
pub const SHARD_PACE: (i64, i64) = (7, 10);
pub const SHARD_TICKS: u32 = TICKS_PER_SECOND * 5;
/// Honey trap: "anyone touching one sticks for a second".
pub const HONEY_TICKS: u32 = TICKS_PER_SECOND;
/// Tempest: "every 20 seconds lightning lights the whole realm for a second".
pub const TEMPEST_TICKS: u32 = TICKS_PER_SECOND * 20;
pub const TEMPEST_FLASH_TICKS: u32 = TICKS_PER_SECOND;
/// Deep sleep: "every 20 seconds each guard dozes for 3 seconds".
pub const DEEP_SLEEP_TICKS: u32 = TICKS_PER_SECOND * 20;
pub const DOZE_TICKS: u32 = TICKS_PER_SECOND * 3;
/// Deep sleep's "flowers muffle footsteps": a footstep carries a step less.
pub const MUFFLED_STEPS: u16 = 1;
/// Fair lights: how often an illusion forms is a reading — Tempest's and
/// Deep sleep's twenty seconds.
pub const FAIR_LIGHTS_TICKS: u32 = TICKS_PER_SECOND * 20;
/// Iron bell: "guards hear 2 tiles further but see 2 tiles less".
pub const IRON_BELL_TILES: i32 = 2;
/// Clockwork: "every 15 seconds all wards in the realm trigger together".
pub const CLOCKWORK_TICKS: u32 = TICKS_PER_SECOND * 15;
/// Hidden garden: "tall grass spreads one tile a minute".
pub const HIDDEN_GARDEN_TICKS: u32 = TICKS_PER_SECOND * 60;
/// Lantern festival: "each character returns once at the revive health,
/// 30% of its role's health".
pub const LANTERN_RETURN: (i64, i64) = (3, 10);
/// Quicksand: "a few tiles become hidden pits that drop anyone a level". A
/// few is a reading: three. Climbing out holds whoever fell for a second.
pub const QUICKSAND_PITS: usize = 3;
pub const PIT_HOLD_TICKS: u32 = TICKS_PER_SECOND;

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
    /// Disarm progress, in ticks on the tile.
    pub disarm: u32,
    /// When it was broken, for a law that regrows it (Bloom).
    pub broken_at: Option<u32>,
    /// Grown back by Bloom, which Honey trap makes sticky.
    pub regrown: bool,
    /// Frozen by a Stillwatch until this tick (§11.11): it does nothing.
    pub held_until: u32,
}

impl Ward {
    pub fn new(kind: WardKind, tile: crate::grid::TileIndex) -> Ward {
        let health = if kind == WardKind::CrystalWall {
            CRYSTAL_WALL_HEALTH
        } else {
            WARD_HEALTH_PER_LEVEL
        };
        Ward { kind, tile, level: 1, health, armed_at: 0, disarmed: false, broken: false,
               disarm: 0, broken_at: None, regrown: false, held_until: 0 }
    }

    /// Still doing anything at all.
    pub fn live(&self) -> bool {
        !self.disarmed && !self.broken
    }

    pub fn disarm_ticks(&self) -> u32 {
        DISARM_TICKS
    }
}
