//! §11.11's eighteen ruleborn, as the simulation plays them: each kind's role,
//! size band, whether it flies, and its ability. §12.5: "The simulation plays
//! each member by its kind's ability and numbers, not by its role alone."
//!
//! The table is in `content/ruleborn.json`'s order, which is §11.11's, and
//! `content_gate.py` holds every row to that file: the id, the role, the size
//! and whether it flies. A kind's index in it is its byte in a replay's crew
//! manifest, so the order is part of the wire format and never changes.
//!
//! §11.1's numbers (health, power, carry, speed) are still read by role: the
//! document gives them per role, and §11.4 to §11.6's levels and traits, which
//! change them per member, are TD.34's. What a kind changes here is its size
//! band — so a small Breaker takes Density's small band (G23, G63) — and its
//! ability.
//!
//! The ability rules are §12.6's: "each ruleborn's ability has two uses a
//! heist, with a lockout of one decision slot (10 seconds) between them, and
//! no cooldown", and "at most four abilities are ready at once".

use crate::{Role, Size, TICKS_PER_SECOND};

/// §11.11's eighteen abilities, one per kind, in the table's order.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Ability {
    /// Featherkin: "Glides 3 tiles in one move, crossing a gap and rising or
    /// dropping one height level on the way."
    Glide,
    /// Skyskipper: "Stuffs its satchel: loads at 60 a second instead of 30
    /// for 5 s."
    Satchel,
    /// Rambler: "Charges 4 tiles in a straight line and breaks the first
    /// wall, hedge or boulder in its way."
    Charge,
    /// Glass golem: "Raises a crystal wall 3 tiles long for 6 s: nothing
    /// passes it, and it does not block sight."
    CrystalWall,
    /// Quarryback: "Pounds: for 6 s its hits on the Vault, pylons and wards
    /// deal 50% more."
    Pound,
    /// Prism mite: "Splits into two mites for 8 s".
    Split,
    /// Tidewalker: "For 6 s nothing slows it: terrain, laws and its own load
    /// leave it at full speed."
    Unhindered,
    /// Hourkeeper: "Gives one ally back all the health it lost in the last
    /// 5 s."
    Rewind,
    /// Stillwatch: "Freezes one guard or ward for 2.5 s: it cannot move, act,
    /// see or grow suspicious."
    Freeze,
    /// Emberling: "Bursts, dealing triple its Power at once to every ward and
    /// pylon within 1 tile."
    Burst,
    /// Stormhound: "Sprints 60% faster for 4 s."
    Sprint,
    /// Sparkwright: "Cuts the Sage's cooldown by 10 s, so its next power
    /// comes sooner (11.7)."
    Quicken,
    /// Mossbear: "Roots in place for 6 s, taking half damage; it cannot move
    /// while rooted."
    Root,
    /// Bloomling: "Heals every ally within 3 tiles by 15% of its full health,
    /// at once."
    Bloom,
    /// Rootrunner: "Grows a root bridge over one gap of up to 3 tiles for
    /// 8 s; anyone can cross it, guards included."
    RootBridge,
    /// Echoplate: "Stands over the crew for 8 s: a crew member knocked out
    /// within 3 tiles of it, itself included, returns at once at 40% of its
    /// full health (12.20)."
    StandOver,
    /// Lantern wisp: "Reveals every hidden ward, hidden guard and illusion
    /// within 6 tiles for 6 s."
    Reveal,
    /// Soulmender: "Links the crew for 6 s: every hit on one of them is
    /// shared evenly across all."
    Link,
}

/// One of §11.11's kinds.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Ruleborn {
    pub id: &'static str,
    pub role: Role,
    pub size: Size,
    pub flies: bool,
    pub ability: Ability,
}

const fn kind(id: &'static str, role: Role, size: Size, flies: bool, ability: Ability) -> Ruleborn {
    Ruleborn { id, role, size, flies, ability }
}

use Ability::*;
use Role::*;
use Size::*;

/// §11.11, in `content/ruleborn.json`'s order. The index is the wire value.
pub const RULEBORN: [Ruleborn; 18] = [
    kind("featherkin", Scout, Standard, true, Glide),
    kind("skyskipper", Carrier, Standard, false, Satchel),
    kind("rambler", Breaker, Standard, false, Charge),
    kind("glass_golem", Warden, Large, false, CrystalWall),
    kind("quarryback", Breaker, Standard, false, Pound),
    kind("prism_mite", Carrier, Small, false, Split),
    kind("tidewalker", Carrier, Standard, false, Unhindered),
    kind("hourkeeper", Mender, Standard, false, Rewind),
    kind("stillwatch", Warden, Large, false, Freeze),
    kind("emberling", Breaker, Small, false, Burst),
    kind("stormhound", Scout, Standard, false, Sprint),
    kind("sparkwright", Mender, Standard, false, Quicken),
    kind("mossbear", Warden, Large, false, Root),
    kind("bloomling", Mender, Small, false, Bloom),
    kind("rootrunner", Carrier, Standard, false, RootBridge),
    kind("echoplate", Warden, Large, false, StandOver),
    kind("lantern_wisp", Scout, Small, true, Reveal),
    kind("soulmender", Mender, Standard, true, Link),
];

/// The kind with this id, by its wire value.
pub fn by_id(id: &str) -> Option<u8> {
    RULEBORN.iter().position(|k| k.id == id).map(|i| i as u8)
}

/// §12.6: "two uses a heist".
pub const USES: u8 = 2;
/// §12.6: "a lockout of one decision slot (10 seconds) between them".
pub const LOCKOUT_TICKS: u32 = TICKS_PER_SECOND * 10;
/// §12.6: "At most four abilities are ready at once, the working-memory
/// bound (32.4)."
pub const MAX_READY: usize = 4;

/// Each ability's own numbers, §11.11's words as constants.
pub const SATCHEL_TICKS: u32 = TICKS_PER_SECOND * 5;
/// "loads at 60 a second instead of 30": twice the rate.
pub const SATCHEL_RATE: i32 = 2;
pub const POUND_TICKS: u32 = TICKS_PER_SECOND * 6;
/// "deal 50% more".
pub const POUND_HIT: (i64, i64) = (3, 2);
pub const UNHINDERED_TICKS: u32 = TICKS_PER_SECOND * 6;
/// "all the health it lost in the last 5 s": the window kept per crew
/// member, a tick at a time.
pub const REWIND_WINDOW: u32 = TICKS_PER_SECOND * 5;
pub const REWIND_TICKS: usize = REWIND_WINDOW as usize;
/// "for 2.5 s".
pub const FREEZE_TICKS: u32 = TICKS_PER_SECOND * 5 / 2;
/// "triple its Power", "within 1 tile".
pub const BURST_POWER: i64 = 3;
pub const BURST_TILES: i32 = 1;
/// "Sprints 60% faster for 4 s."
pub const SPRINT_TICKS: u32 = TICKS_PER_SECOND * 4;
pub const SPRINT_PACE: (i64, i64) = (8, 5);
/// "Roots in place for 6 s, taking half damage".
pub const ROOT_TICKS: u32 = TICKS_PER_SECOND * 6;
pub const ROOT_DAMAGE: (i64, i64) = (1, 2);
/// "every ally within 3 tiles by 15% of its full health".
pub const BLOOM_TILES: i32 = 3;
pub const BLOOM_HEAL: (i32, i32) = (15, 100);
/// "for 8 s", "within 3 tiles", "at 40% of its full health".
pub const STAND_OVER_TICKS: u32 = TICKS_PER_SECOND * 8;
pub const STAND_OVER_TILES: i32 = 3;
pub const STAND_OVER_RETURN: (i64, i64) = (40, 100);
/// "Links the crew for 6 s".
pub const LINK_TICKS: u32 = TICKS_PER_SECOND * 6;

/// Every number above, for the rules version: changing one changes how a
/// heist with a manifest plays.
pub const NUMBERS: [i64; 27] = [
    USES as i64, LOCKOUT_TICKS as i64, MAX_READY as i64,
    SATCHEL_TICKS as i64, SATCHEL_RATE as i64, POUND_TICKS as i64, POUND_HIT.0, POUND_HIT.1,
    UNHINDERED_TICKS as i64, REWIND_TICKS as i64, FREEZE_TICKS as i64, BURST_POWER,
    BURST_TILES as i64, SPRINT_TICKS as i64, SPRINT_PACE.0, SPRINT_PACE.1, ROOT_TICKS as i64,
    ROOT_DAMAGE.0, ROOT_DAMAGE.1, BLOOM_TILES as i64, BLOOM_HEAL.0 as i64,
    BLOOM_HEAL.1 as i64, STAND_OVER_TICKS as i64, STAND_OVER_TILES as i64,
    STAND_OVER_RETURN.0, STAND_OVER_RETURN.1, LINK_TICKS as i64,
];

impl Ability {
    /// How long the ability's effect runs, for those that run; zero for the
    /// ones that act at once.
    pub fn ticks(self) -> u32 {
        match self {
            Satchel => SATCHEL_TICKS,
            Pound => POUND_TICKS,
            Unhindered => UNHINDERED_TICKS,
            Sprint => SPRINT_TICKS,
            Root => ROOT_TICKS,
            StandOver => STAND_OVER_TICKS,
            Link => LINK_TICKS,
            _ => 0,
        }
    }

    /// Whether the simulation carries it yet. The rest wait on what they act
    /// on: gaps and boulders (TD.15) for Glide, Charge and the root bridge; a
    /// wall a route can meet mid-walk for the crystal wall; the Sage for
    /// Quicken; a crew member that can be two for Split; and something hidden
    /// for Reveal to show. Until then their command is dropped and spends no
    /// use, like any command that cannot be carried out.
    pub fn built(self) -> bool {
        !matches!(self, Glide | Charge | CrystalWall | Split | Quicken | RootBridge | Reveal)
    }
}
