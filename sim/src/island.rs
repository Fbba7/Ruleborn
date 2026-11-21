//! An island as bytes: the bundle §24.8 stores under its own hash.
//!
//! §24.8: "Small mutable rows in the database, large immutable things in
//! storage, addressed by the hash of their contents. … Publishing writes an
//! immutable bundle to storage under its own hash. Nothing is ever updated in
//! place." §24.11: a heist is "reproducible forever from four things: the
//! seed, the input log, the island and the rules version" — and a replay's
//! header carries the island as exactly this hash.
//!
//! So an island has one canonical encoding, and its digest is SHA-256 of it.
//! `decode` refuses anything `encode` would not have written — trailing
//! bytes, an unknown code, a pace of exactly 100 (which is written as 0) or
//! one the rules do not define (`PACES`), a flag bit nobody defined — because two encodings of one island would be two
//! hashes for one island, and the server could not tell a republish from a
//! new one.
//!
//! What an island says and what it leaves to others
//! -------------------------------------------------
//! Each fact about a tile has one home. The ground layer carries §6.2's
//! features, pace, surface, height, light and climbing aids; the Vault, the
//! pylons and the Crystal Walls are not written into it, because each comes
//! from its own list — the Vault's position, the laws, the wards — and a
//! Vault written twice could be written in two places.
//!
//! The format
//! ----------
//! ```text
//! "RBI1"                                  magic and version
//! realm level u8 (1-5), Vault level u8 (1-10), exposed u32 LE (bag units)
//! Vault x, y u8; entrance x, y u8
//! side x side tiles, row-major, 3 bytes each:
//!     feature (low 4 bits) | surface << 4 | height << 6
//!     pace, per cent of normal speed; 0 for normal
//!     flags: 1 unlit, 2 climbable; bits 2-3 the feature's high bits;
//!            bits 4-5 the way a directional feature faces
//! ```
//! A feature's code is six bits, its low four in the first byte and its high
//! two in the flags, so every island written before features past code 15
//! keeps its bytes and its hash (TD.15). A ramp, stairs, vines, a waterfall
//! and rapids face one of four ways, north, east, south or west, which their
//! owner sets (G56, TD.38); any other tile's facing bits are 0.
//! ```text
//! guards u8, then (role row u8 | facing << 4, x u8, y u8) each
//! wards u8, then (kind u8, x u8, y u8) each
//! laws u8, then (id length u8, id, x u8, y u8) each
//! ```
//! A law is named by its id rather than its row in the table, because an
//! island outlives a rules version (§24.11: a re-tuned law re-costs the
//! island; a removed one's "name is never reused").
//! ```text
//! buildings, only if there are any: count u8 (1 or more), then
//!     (code u8, x u8, y u8) each, x and y its footprint's north-west tile
//! ```
//! §10.1: "Buildings sit on the realm grid and block movement and sight.
//! Most are 2 by 2 tiles; the Spire and Vault are 3 by 3." A building's code
//! is `BUILDING_CODES`', and its footprint the code's. An island with no
//! building ends at its laws, so every island written before buildings
//! keeps its bytes and its hash. The Vault, the pylons, the guard posts and
//! the wards are §10.2's buildings too, and are written by their own lists;
//! the Vault still stands on one tile (G45).
//! ```text
//! tunnels, only if there are any: the buildings list first, its count 0 if
//!     there are no buildings; then count u8 (1 or more), then
//!     (x1 u8, y1 u8, x2 u8, y2 u8) each
//! ```
//! A tunnel is "a hidden path joining two points up to 6 tiles apart"
//! (§6.2): its two mouths, the first the lower tile index, the tunnels in
//! order of their first mouths, no mouth shared, 2 to 6 tiles apart as a
//! walk counts them. One home for each: the ground layer does not carry a
//! mouth, the list does. A held post faces where its owner sets (G56); north
//! is 0, the way every post faced before, so an island written before keeps
//! its bytes.
//!
//! Where the crew lands
//! --------------------
//! §5.4: "The crew lands on any edge tile of any outer realm the raider
//! chooses", and "the defender cannot choose where you arrive". The landing
//! is in the input log (`replay::Kind::Land`), so an island promises only
//! that there is somewhere to land: `check` requires one open edge tile
//! (`LandingBlocked`) and a walkable route from some open edge tile to the
//! Vault (`Sealed`, §5.3's "At least one walkable route must reach the Heart
//! from every outer realm's edge"). `landings` lists the tiles a crew may
//! choose.

use crate::grid::{Feature, Grid, Surface};
use crate::heist::WardKind;
use crate::laws_table::LAWS;
use crate::sha256::sha256;

pub const MAGIC: [u8; 4] = *b"RBI1";

/// §5.2's budgets by realm level 1 to 5 (v3.7): "the smaller of the wards it
/// needs to reach its hold band and eight … 8, 8, 6, 2 and 0", on "1, 1, 2, 1
/// and 1" guard posts (10.2); and the law slots in its table. `content_gate.py` checks all three against `design_facts`.
pub const WARD_LIMITS: [u8; 5] = [8, 8, 6, 2, 0];
pub const GUARD_POSTS: [u8; 5] = [1, 1, 2, 1, 1];
pub const LAW_SLOTS: [u8; 5] = [1, 1, 2, 2, 3];


/// How far from an edge a generated island's wards keep: a crew lands on
/// any edge tile (§5.4), and a ward whose sensor reaches the landing decides
/// the raid before it starts (the harness's rule).
pub const WARD_EDGE: u8 = 2;

/// One tile of the ground layer.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct Tile {
    pub feature: Option<Feature>,
    /// Per cent of normal speed; 0 means normal. §6.2's mud is 60, a fast
    /// path 115.
    pub pace: u8,
    pub surface: Surface,
    /// §6.2's raised ground, 0 to 3.
    pub height: u8,
    pub unlit: bool,
    pub climbable: bool,
    /// The way a directional feature faces, `grid::NORTH` to `grid::WEST`;
    /// 0 for any other tile.
    pub facing: u8,
}

/// A guard post: §12.17's role row (0 Scout, 1 Warden, 2 Breaker, 3 Carrier,
/// 4 Mender) and its tile.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Post {
    pub row: u8,
    pub x: u8,
    pub y: u8,
    /// The way a held post faces (G56), `grid::NORTH` to `grid::WEST`.
    pub facing: u8,
}

#[derive(Clone, PartialEq, Eq, Debug)]
pub struct Island {
    pub realm_level: u8,
    /// §9.6's V: the target's Vault level, 1 to 10, which sets B(V) and the
    /// Vault's health.
    pub vault_level: u8,
    /// What the snapshot exposes, in bag units (§9.6: "a full five-crew's
    /// carry × the richness ratio"). The haul is minted from a snapshot, so
    /// what was exposed when it was taken travels with it.
    pub exposed: u32,
    pub vault: (u8, u8),
    /// Where §12.17's reinforcing Warden arrives.
    pub entrance: (u8, u8),
    pub tiles: Vec<Tile>,
    pub guards: Vec<Post>,
    pub wards: Vec<(WardKind, u8, u8)>,
    pub laws: Vec<(String, u8, u8)>,
    /// §10.1's buildings: (code, x, y), x and y the footprint's north-west
    /// tile.
    pub buildings: Vec<(u8, u8, u8)>,
    /// §6.2's tunnels, each its two mouths, in the order `decode` requires.
    pub tunnels: Vec<((u8, u8), (u8, u8))>,
}

/// Why a bundle is not an island.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Malformed {
    Magic,
    RealmLevel,
    VaultLevel,
    Truncated,
    TrailingBytes,
    OffGrid,
    UnknownFeature,
    UnknownWard,
    UnknownRole,
    FlagBits,
    /// A pace of 100, which is written as 0, or a pace on a tile nobody can
    /// enter: either is a second encoding of the same island.
    NonCanonicalPace,
    /// A pace the rules do not define: a bare tile is normal (0), mud (60)
    /// or a fast path (115), and nothing slower or faster (SEC-22).
    Pace,
    LawId,
    /// A building code nobody defined.
    UnknownBuilding,
    /// A buildings list of none, which is written by leaving it out.
    NoBuildings,
    /// A tunnels list of none, a mouth shared or out of order, or mouths
    /// nearer than 2 tiles or further than 6.
    Tunnel,
    /// An exposure above `i32::MAX`, which the rules cannot hold: it would be
    /// read as a negative one (SEC-17).
    Exposed,
}

/// What stands on a tile, by its place in the island's list.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Occupant {
    None,
    Vault,
    Pylon(usize),
    Ward(usize),
    Guard(usize),
    Building(usize),
    /// A mouth of tunnel `i`.
    Tunnel(usize),
}

/// Why an island may not be published. Each is a rule of the document's,
/// and `Problem::bit` is its place in the mask the WebAssembly build returns.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Problem {
    /// §5.2's ward limit for the realm level.
    TooManyWards,
    /// §5.2's guard posts for the realm level.
    TooManyGuards,
    /// §5.2's law slots for the realm level.
    TooManyLaws,
    /// A law this rules version does not have.
    UnknownLaw,
    /// Two things on one tile, or a post, pylon, ward or the Vault on a tile
    /// that already holds a feature.
    Crowded,
    /// A guard posted where it cannot stand.
    PostBlocked,
    /// No edge tile is open, so a crew has nowhere to land (see the module
    /// docstring).
    LandingBlocked,
    /// §6.1: "never seal the last path to the Heart". With every Crystal
    /// Wall standing, no route from any open edge tile reaches a tile beside
    /// the Vault.
    Sealed,
    /// A side with fewer than half its tiles open to land on, with every
    /// Crystal Wall standing (F51, decided): a Keeper may make the edge a
    /// puzzle, and may not close it to one gate.
    EdgeClosed,
    /// The entrance on the Vault or on a tile nobody can stand on, with
    /// every Crystal Wall standing. The alarm-5 Warden comes in there
    /// (RB-40).
    EntranceBlocked,
    /// One law on two pylons: a realm weaves each law once, and the sheet
    /// would apply it twice (bug report candidate 7).
    DuplicateLaw,
}

impl Problem {
    pub const ALL: [Problem; 11] = [
        Problem::TooManyWards, Problem::TooManyGuards, Problem::TooManyLaws,
        Problem::UnknownLaw, Problem::Crowded, Problem::PostBlocked,
        Problem::LandingBlocked, Problem::Sealed, Problem::EdgeClosed,
        Problem::EntranceBlocked, Problem::DuplicateLaw,
    ];

    pub fn bit(self) -> u32 {
        1 << Problem::ALL.iter().position(|p| *p == self).unwrap_or(31)
    }
}

/// §6.2's ground features by their code in the bundle. The code is part of
/// every island's bytes, so it is written out and never reused.
pub const FEATURE_CODES: [(Feature, &str, u8); 36] = [
    (Feature::RockPillar, "rock_pillar", 1),
    (Feature::RuinWall, "ruin_wall", 2),
    (Feature::Fence, "fence", 3),
    (Feature::FogBank, "fog_bank", 4),
    (Feature::TallGrass, "tall_grass", 5),
    (Feature::Stream, "stream", 6),
    (Feature::Bush, "bush", 7),
    (Feature::Hedge, "hedge", 8),
    (Feature::Tree, "tree", 9),
    (Feature::Thicket, "thicket", 10),
    (Feature::Boulder, "boulder", 11),
    (Feature::GravelPath, "gravel_path", 12),
    (Feature::Scree, "scree", 13),
    (Feature::CrystalOutcrop, "crystal_outcrop", 14),
    (Feature::LanternPost, "lantern_post", 15),
    (Feature::ShadeCanopy, "shade_canopy", 16),
    (Feature::EmberVent, "ember_vent", 17),
    (Feature::LavaCrack, "lava_crack", 18),
    (Feature::StaticStone, "static_stone", 19),
    (Feature::Statue, "statue", 20),
    (Feature::HotSpring, "hot_spring", 21),
    (Feature::Arch, "arch", 22),
    (Feature::Marsh, "marsh", 23),
    (Feature::FlowerMeadow, "flower_meadow", 24),
    (Feature::IceSheet, "ice_sheet", 25),
    (Feature::Pond, "pond", 26),
    (Feature::BellPost, "bell_post", 27),
    (Feature::SteppingStones, "stepping_stones", 28),
    (Feature::BounceMushroom, "bounce_mushroom", 29),
    (Feature::UpdraftVent, "updraft_vent", 30),
    (Feature::Pit, "pit", 31),
    (Feature::Ramp, "ramp", 32),
    (Feature::Stairs, "stairs", 33),
    (Feature::ClimbingVines, "climbing_vines", 34),
    (Feature::Waterfall, "waterfall", 35),
    (Feature::Rapids, "rapids", 36),
];

/// §10.1's buildings that stand on the grid, by their code in the bundle,
/// with the side of their square footprint: "Most are 2 by 2 tiles; the
/// Spire and Vault are 3 by 3." The id is content/buildings.json's, and
/// `content_gate.py` holds the table to it and to `design_facts`. The Vault,
/// the Law Pylon, the guardian post and the ward have their own lists. A
/// code is part of every island's bytes, so it is written out and never
/// reused.
pub const BUILDING_CODES: [(&str, u8, u8); 13] = [
    ("keeper_s_spire", 1, 3),
    ("anchor_stone", 2, 2),
    ("star_well", 3, 2),
    ("aether_spring", 4, 2),
    ("garden", 5, 2),
    ("storehouse", 6, 2),
    ("hearth", 7, 2),
    ("nursery", 8, 2),
    ("library", 9, 2),
    ("resonance_lab", 10, 2),
    ("observatory", 11, 2),
    ("beacon", 12, 2),
    ("visitor_s_dock", 13, 2),
];

/// The side of a building's footprint, by its code; `None` for a code no
/// building has.
pub fn footprint(code: u8) -> Option<u8> {
    BUILDING_CODES.iter().find(|&&(_, c, _)| c == code).map(|&(_, _, side)| side)
}

/// A building's code, by its id.
pub fn building_code(id: &str) -> Option<u8> {
    BUILDING_CODES.iter().find(|&&(i, _, _)| i == id).map(|&(_, c, _)| c)
}

fn feature_code(f: Option<Feature>) -> Option<u8> {
    match f {
        None => Some(0),
        // The Vault, pylons, Crystal Walls and tunnel mouths are written by
        // their own lists, never into the ground layer.
        Some(f) => FEATURE_CODES.iter().find(|(g, _, _)| *g == f).map(|&(_, _, c)| c),
    }
}

fn feature_from(code: u8) -> Result<Option<Feature>, Malformed> {
    if code == 0 {
        return Ok(None);
    }
    FEATURE_CODES.iter().find(|&&(_, _, c)| c == code).map(|&(f, _, _)| Some(f))
        .ok_or(Malformed::UnknownFeature)
}

fn surface_code(s: Surface) -> u8 {
    match s {
        Surface::Plain => 0,
        Surface::Gravel => 1,
        Surface::Water => 2,
        Surface::Moss => 3,
    }
}

fn surface_from(code: u8) -> Surface {
    [Surface::Plain, Surface::Gravel, Surface::Water, Surface::Moss][code as usize & 3]
}

pub fn ward_from(code: u8) -> Result<WardKind, Malformed> {
    Ok(match code {
        0 => WardKind::CrystalWall,
        1 => WardKind::ThornHedge,
        2 => WardKind::StaticCoil,
        3 => WardKind::GravityWell,
        4 => WardKind::TimeSnare,
        5 => WardKind::LanternGlare,
        _ => return Err(Malformed::UnknownWard),
    })
}

/// The paces a bare tile may carry, per cent of normal speed: 0 for normal
/// (100 is written as 0), §6.2's mud at 60 and a fast path at 115 (SEC-22).
pub const PACES: [u8; 3] = [0, 60, 115];

/// Whether a feature stops feet, so a pace on it would mean nothing.
fn blocks_feet(f: Option<Feature>) -> bool {
    f.is_some_and(|f| !f.terrain().passable())
}

/// Whether a feature sets the tile's pace or surface itself, so a pace or a
/// surface written beside it would be a second encoding of the same ground.
fn sets_pace(f: Option<Feature>) -> bool {
    blocks_feet(f) || f.is_some_and(|f| matches!(f.terrain(), crate::grid::Terrain::Pace(_)))
}

impl Island {
    /// §5.2: 10 by 10 at realm level 1 up to 14 by 14 at 5.
    pub fn side(&self) -> u16 {
        9 + self.realm_level.clamp(1, 5) as u16
    }

    fn tile_mut(&mut self, x: u16, y: u16) -> &mut Tile {
        let side = self.side() as usize;
        &mut self.tiles[y as usize * side + x as usize]
    }

    /// An empty realm of a level: open, plain, lit ground and nothing on it.
    pub fn empty(realm_level: u8) -> Island {
        let side = 9 + realm_level.clamp(1, 5) as usize;
        Island {
            realm_level: realm_level.clamp(1, 5),
            vault_level: 1,
            exposed: 0,
            vault: (0, 0),
            entrance: (0, 0),
            tiles: vec![Tile::default(); side * side],
            guards: Vec::new(),
            wards: Vec::new(),
            laws: Vec::new(),
            buildings: Vec::new(),
            tunnels: Vec::new(),
        }
    }

    /// Every tile of building `i`'s footprint, as (x, y).
    pub fn footprint_tiles(&self, i: usize) -> Vec<(u8, u8)> {
        let (code, x, y) = self.buildings[i];
        let side = footprint(code).unwrap_or(0);
        (0..side).flat_map(|dy| (0..side).map(move |dx| (x + dx, y + dy))).collect()
    }

    pub fn encode(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(16 + self.tiles.len() * 3 + 64);
        out.extend_from_slice(&MAGIC);
        out.push(self.realm_level);
        out.push(self.vault_level);
        out.extend_from_slice(&self.exposed.to_le_bytes());
        out.extend_from_slice(&[self.vault.0, self.vault.1, self.entrance.0, self.entrance.1]);
        for t in &self.tiles {
            let feature = feature_code(t.feature).unwrap_or(0);
            out.push(feature & 15 | surface_code(t.surface) << 4 | (t.height.min(3)) << 6);
            out.push(if t.pace == 100 { 0 } else { t.pace });
            let facing = if t.feature.is_some_and(|f| f.directional()) { t.facing & 3 } else { 0 };
            out.push(t.unlit as u8 | (t.climbable as u8) << 1 | (feature >> 4) << 2 | facing << 4);
        }
        out.push(self.guards.len() as u8);
        for g in &self.guards {
            out.extend_from_slice(&[g.row | (g.facing & 3) << 4, g.x, g.y]);
        }
        out.push(self.wards.len() as u8);
        for (kind, x, y) in &self.wards {
            out.extend_from_slice(&[*kind as u8, *x, *y]);
        }
        out.push(self.laws.len() as u8);
        for (id, x, y) in &self.laws {
            out.push(id.len() as u8);
            out.extend_from_slice(id.as_bytes());
            out.extend_from_slice(&[*x, *y]);
        }
        if !self.buildings.is_empty() || !self.tunnels.is_empty() {
            out.push(self.buildings.len() as u8);
            for (code, x, y) in &self.buildings {
                out.extend_from_slice(&[*code, *x, *y]);
            }
        }
        if !self.tunnels.is_empty() {
            out.push(self.tunnels.len() as u8);
            for ((ax, ay), (bx, by)) in &self.tunnels {
                out.extend_from_slice(&[*ax, *ay, *bx, *by]);
            }
        }
        out
    }

    pub fn decode(bytes: &[u8]) -> Result<Island, Malformed> {
        let at = std::cell::Cell::new(0usize);
        let take = |n: usize| -> Result<&[u8], Malformed> {
            let s = bytes.get(at.get()..at.get() + n).ok_or(Malformed::Truncated)?;
            at.set(at.get() + n);
            Ok(s)
        };
        if take(4)? != MAGIC {
            return Err(Malformed::Magic);
        }
        let head = take(10)?;
        let (realm_level, vault_level) = (head[0], head[1]);
        if !(1..=5).contains(&realm_level) {
            return Err(Malformed::RealmLevel);
        }
        if !(1..=10).contains(&vault_level) {
            return Err(Malformed::VaultLevel);
        }
        let exposed = u32::from_le_bytes([head[2], head[3], head[4], head[5]]);
        if exposed > i32::MAX as u32 {
            return Err(Malformed::Exposed);
        }
        let side = 9 + realm_level as u16;
        let on_grid = |x: u8, y: u8| (x as u16) < side && (y as u16) < side;
        let vault = (head[6], head[7]);
        let entrance = (head[8], head[9]);
        if !on_grid(vault.0, vault.1) || !on_grid(entrance.0, entrance.1) {
            return Err(Malformed::OffGrid);
        }
        let mut tiles = Vec::with_capacity(side as usize * side as usize);
        for _ in 0..side as usize * side as usize {
            let t = take(3)?;
            if t[2] & !63 != 0 {
                return Err(Malformed::FlagBits);
            }
            let feature = feature_from(t[0] & 15 | (t[2] >> 2 & 3) << 4)?;
            let facing = t[2] >> 4 & 3;
            // Only a directional feature faces: a facing anywhere else is a
            // second encoding of the same tile.
            if facing != 0 && !feature.is_some_and(|f| f.directional()) {
                return Err(Malformed::FlagBits);
            }
            if t[1] == 100 || (t[1] != 0 && sets_pace(feature)) {
                return Err(Malformed::NonCanonicalPace);
            }
            // Only a pace the rules define: a hand-edited 1% on every open
            // tile made an island no crew could cross in time (SEC-22). A new
            // surface adds its pace here in the change that documents it.
            if !PACES.contains(&t[1]) {
                return Err(Malformed::Pace);
            }
            // A stream is water and a gravel path gravel: any other surface
            // written under one is a second encoding of the same island.
            if feature.and_then(|f| f.surface())
                .is_some_and(|s| surface_code(s) != t[0] >> 4 & 3)
            {
                return Err(Malformed::NonCanonicalPace);
            }
            tiles.push(Tile {
                feature,
                pace: t[1],
                surface: surface_from(t[0] >> 4 & 3),
                height: t[0] >> 6,
                unlit: t[2] & 1 != 0,
                climbable: t[2] & 2 != 0,
                facing,
            });
        }
        let n = take(1)?[0];
        let mut guards = Vec::with_capacity(n as usize);
        for _ in 0..n {
            let g = take(3)?;
            if g[0] & 15 > 4 || g[0] & !0x3f != 0 {
                return Err(Malformed::UnknownRole);
            }
            if !on_grid(g[1], g[2]) {
                return Err(Malformed::OffGrid);
            }
            guards.push(Post { row: g[0] & 15, x: g[1], y: g[2], facing: g[0] >> 4 & 3 });
        }
        let n = take(1)?[0];
        let mut wards = Vec::with_capacity(n as usize);
        for _ in 0..n {
            let w = take(3)?;
            if !on_grid(w[1], w[2]) {
                return Err(Malformed::OffGrid);
            }
            wards.push((ward_from(w[0])?, w[1], w[2]));
        }
        let n = take(1)?[0];
        let mut laws = Vec::with_capacity(n as usize);
        for _ in 0..n {
            let len = take(1)?[0] as usize;
            let id = take(len)?;
            if id.is_empty() || !id.iter().all(|b| b.is_ascii_lowercase() || *b == b'_') {
                return Err(Malformed::LawId);
            }
            let id = String::from_utf8(id.to_vec()).map_err(|_| Malformed::LawId)?;
            let p = take(2)?;
            if !on_grid(p[0], p[1]) {
                return Err(Malformed::OffGrid);
            }
            laws.push((id, p[0], p[1]));
        }
        let mut buildings = Vec::new();
        if at.get() < bytes.len() {
            let n = take(1)?[0];
            // None is written only ahead of a tunnels list.
            if n == 0 && at.get() == bytes.len() {
                return Err(Malformed::NoBuildings);
            }
            for _ in 0..n {
                let b = take(3)?;
                let size = footprint(b[0]).ok_or(Malformed::UnknownBuilding)? as u16;
                if b[1] as u16 + size > side || b[2] as u16 + size > side {
                    return Err(Malformed::OffGrid);
                }
                buildings.push((b[0], b[1], b[2]));
            }
        }
        let mut tunnels: Vec<((u8, u8), (u8, u8))> = Vec::new();
        if at.get() < bytes.len() {
            let n = take(1)?[0];
            if n == 0 {
                return Err(Malformed::Tunnel);
            }
            let index = |(x, y): (u8, u8)| y as u16 * side + x as u16;
            let mut mouths: Vec<u16> = Vec::new();
            for _ in 0..n {
                let m = take(4)?;
                let (a, b) = ((m[0], m[1]), (m[2], m[3]));
                if !on_grid(a.0, a.1) || !on_grid(b.0, b.1) {
                    return Err(Malformed::OffGrid);
                }
                let walk = a.0.abs_diff(b.0) as u16 + a.1.abs_diff(b.1) as u16;
                let after = tunnels.last().is_none_or(|&(p, _)| index(p) < index(a));
                if index(a) >= index(b) || !after
                    || !(crate::grid::TUNNEL_MIN_TILES..=crate::grid::TUNNEL_TILES).contains(&walk)
                    || mouths.contains(&index(a)) || mouths.contains(&index(b))
                {
                    return Err(Malformed::Tunnel);
                }
                mouths.extend([index(a), index(b)]);
                tunnels.push((a, b));
            }
        }
        if at.get() != bytes.len() {
            return Err(Malformed::TrailingBytes);
        }
        Ok(Island { realm_level, vault_level, exposed, vault, entrance, tiles, guards, wards, laws, buildings,
                    tunnels })
    }

    /// §24.8's content address.
    pub fn digest(&self) -> [u8; 32] {
        sha256(&self.encode())
    }

    /// The ground as the simulation reads it: the tile layer, §10.1's
    /// buildings on every tile of their footprints, and the Vault.
    /// The pylons and Crystal Walls are placed by `World::from_island` as it
    /// weaves the laws and places the wards, which is what they are.
    pub fn ground(&self) -> Grid {
        let mut grid = Grid::for_realm_level(self.realm_level);
        let side = self.side();
        for y in 0..side {
            for x in 0..side {
                let t = self.tiles[y as usize * side as usize + x as usize];
                if let Some(f) = t.feature {
                    grid.place(x, y, f);
                }
                if t.pace != 0 {
                    grid.set(x, y, crate::grid::Terrain::Pace(t.pace));
                }
                grid.set_surface(x, y, t.surface);
                grid.set_height(x, y, t.height);
                if t.unlit {
                    grid.darken(x, y);
                }
                if t.climbable {
                    grid.make_climbable(x, y);
                }
                if t.feature.is_some_and(|f| f.directional()) {
                    grid.set_facing(x, y, t.facing);
                }
            }
        }
        for &((ax, ay), (bx, by)) in &self.tunnels {
            if let (Some(a), Some(b)) = (grid.index(ax as u16, ay as u16), grid.index(bx as u16, by as u16)) {
                grid.dig_tunnel(a, b);
            }
        }
        for i in 0..self.buildings.len() {
            for (x, y) in self.footprint_tiles(i) {
                grid.place(x as u16, y as u16, Feature::Building);
            }
        }
        grid.place(self.vault.0 as u16, self.vault.1 as u16, Feature::Vault);
        grid
    }

    /// The rules an island must keep to be published, as problems found.
    /// Empty means it may be.
    pub fn check(&self) -> Vec<Problem> {
        let mut found = Vec::new();
        let level = (self.realm_level.clamp(1, 5) - 1) as usize;
        if self.wards.len() > WARD_LIMITS[level] as usize {
            found.push(Problem::TooManyWards);
        }
        if self.guards.len() > GUARD_POSTS[level] as usize {
            found.push(Problem::TooManyGuards);
        }
        if self.laws.len() > LAW_SLOTS[level] as usize {
            found.push(Problem::TooManyLaws);
        }
        if self.laws.iter().any(|(id, _, _)| !LAWS.iter().any(|l| l.id == id)) {
            found.push(Problem::UnknownLaw);
        }

        // One thing a tile: the Vault, each pylon, each ward, each post, each
        // tile of a building's footprint. The Vault, a pylon, a ward and a
        // building also need bare ground under them; a guard
        // may stand in tall grass or fog, which is where a Keeper would hide
        // one (whether it can stand at all is `PostBlocked`'s question).
        let side = self.side();
        let mut taken = vec![false; side as usize * side as usize];
        let mut crowded = false;
        let mut claim = |x: u8, y: u8, bare: bool| {
            let i = y as usize * side as usize + x as usize;
            if taken[i] || (bare && self.tiles[i].feature.is_some()) {
                crowded = true;
            }
            taken[i] = true;
        };
        claim(self.vault.0, self.vault.1, true);
        self.laws.iter().for_each(|(_, x, y)| claim(*x, *y, true));
        self.wards.iter().for_each(|(_, x, y)| claim(*x, *y, true));
        self.guards.iter().for_each(|g| claim(g.x, g.y, false));
        (0..self.buildings.len()).flat_map(|i| self.footprint_tiles(i))
            .for_each(|(x, y)| claim(x, y, true));
        // A tunnel's mouth is dug in bare ground.
        self.tunnels.iter().flat_map(|&(a, b)| [a, b]).for_each(|(x, y)| claim(x, y, true));
        if crowded {
            found.push(Problem::Crowded);
        }

        let grid = self.standing();
        let open = |x: u16, y: u16| grid.index(x, y).is_some_and(|i| grid.at(i).passable());
        if self.guards.iter().any(|g| !open(g.x as u16, g.y as u16)) {
            found.push(Problem::PostBlocked);
        }
        let landings = Self::open_edge(&grid);
        if landings.is_empty() {
            found.push(Problem::LandingBlocked);
        } else if !self.reaches_vault(&grid, &landings) {
            found.push(Problem::Sealed);
        }
        // Each side keeps at least half its tiles open, a corner counting on
        // both of its sides (F51).
        let n = side;
        let sides: [Box<dyn Fn(u16) -> (u16, u16)>; 4] = [
            Box::new(|i| (i, 0)), Box::new(move |i| (n - 1, i)),
            Box::new(move |i| (i, n - 1)), Box::new(|i| (0, i)),
        ];
        if sides.iter().any(|at| 2 * (0..n).filter(|&i| { let (x, y) = at(i); open(x, y) }).count() < n as usize) {
            found.push(Problem::EdgeClosed);
        }
        if self.entrance == self.vault || !open(self.entrance.0 as u16, self.entrance.1 as u16) {
            found.push(Problem::EntranceBlocked);
        }
        if self.laws.iter().enumerate().any(|(i, (id, _, _))| self.laws[..i].iter().any(|(e, _, _)| e == id)) {
            found.push(Problem::DuplicateLaw);
        }
        found
    }

    /// Everything that blocks feet at the start of a heist: the ground, a
    /// pylon under every law and every Crystal Wall standing.
    fn standing(&self) -> Grid {
        let mut grid = self.ground();
        for (_, x, y) in &self.laws {
            grid.place(*x as u16, *y as u16, Feature::Pylon);
        }
        for (kind, x, y) in &self.wards {
            if *kind == WardKind::CrystalWall {
                grid.place(*x as u16, *y as u16, Feature::CrystalWall);
            }
        }
        grid
    }

    fn open_edge(grid: &Grid) -> Vec<crate::grid::TileIndex> {
        (0..grid.len() as crate::grid::TileIndex)
            .filter(|&i| grid.is_edge(i) && grid.at(i).passable())
            .collect()
    }

    /// The landings from which a crew can walk to the Vault, with every
    /// Crystal Wall standing: what a default landing chooses from, since
    /// `check` promises only that one exists and a Keeper may leave closed
    /// pockets along the edge.
    /// §5.4: whether a landing on (x, y) goes unheard — fog, tall grass or
    /// unlit ground on the spot — read from the terrain alone, as the scout
    /// shows it, so a landing picker's mark is the same whatever guards and
    /// wards the island places (§12.4, D77).
    pub fn landing_covered(&self, x: u8, y: u8) -> bool {
        if !self.on_grid(x, y) {
            return false;
        }
        let t = &self.tiles[y as usize * self.side() as usize + x as usize];
        matches!(t.feature, Some(Feature::FogBank | Feature::TallGrass)) || t.unlit
    }

    pub fn reaching(&self) -> Vec<(u8, u8)> {
        let grid = self.standing();
        Self::open_edge(&grid).into_iter()
            .filter(|&t| self.reaches_vault(&grid, &[t]))
            .map(|i| {
                let (x, y) = grid.coords(i);
                (x as u8, y as u8)
            })
            .collect()
    }

    /// Where a crew may land (§5.4): every open edge tile, as (x, y), in
    /// row-major order. A landing anywhere else is dropped by the simulation
    /// and refused by `verify_on`.
    pub fn landings(&self) -> Vec<(u8, u8)> {
        let grid = self.standing();
        Self::open_edge(&grid).into_iter()
            .map(|i| {
                let (x, y) = grid.coords(i);
                (x as u8, y as u8)
            })
            .collect()
    }

    // -- Editing: what a builder does to an island ------------------------
    //
    // Each edit keeps the island one `encode` can write, and nothing more:
    // whether the result may be published is `check`'s to say, so a builder
    // shows the problems rather than a second copy of the rules refusing taps.

    /// A blank realm to build on: `empty`, with the Vault near the middle of
    /// the south side and the entrance in the south-east corner. A crew may
    /// land on any edge tile (§5.4), so neither is placed against a landing.
    pub fn blank(realm_level: u8) -> Island {
        let mut island = Island::empty(realm_level);
        let side = island.side() as u8;
        island.vault = (side / 2, side - 3);
        island.entrance = (side - 1, side - 1);
        island.vault_level = 1;
        island
    }

    fn on_grid(&self, x: u8, y: u8) -> bool {
        (x as u16) < self.side() && (y as u16) < self.side()
    }

    /// What stands on a tile, beyond its ground: the Vault, a pylon, a ward,
    /// a guard post or a building.
    pub fn occupant(&self, x: u8, y: u8) -> Occupant {
        if self.vault == (x, y) {
            return Occupant::Vault;
        }
        if let Some(i) = self.laws.iter().position(|(_, lx, ly)| (*lx, *ly) == (x, y)) {
            return Occupant::Pylon(i);
        }
        if let Some(i) = self.wards.iter().position(|(_, wx, wy)| (*wx, *wy) == (x, y)) {
            return Occupant::Ward(i);
        }
        if let Some(i) = self.guards.iter().position(|g| (g.x, g.y) == (x, y)) {
            return Occupant::Guard(i);
        }
        if let Some(i) = (0..self.buildings.len()).find(|&i| self.footprint_tiles(i).contains(&(x, y))) {
            return Occupant::Building(i);
        }
        if let Some(i) = self.tunnels.iter().position(|&(a, b)| a == (x, y) || b == (x, y)) {
            return Occupant::Tunnel(i);
        }
        Occupant::None
    }

    pub fn tile(&self, x: u8, y: u8) -> Option<Tile> {
        self.on_grid(x, y).then(|| self.tiles[y as usize * self.side() as usize + x as usize])
    }

    /// §6.2's ground: a feature, or none. Only the ground features — the
    /// Vault, pylons and Crystal Walls come from their own lists — and a
    /// feature that stops feet drops the tile's pace, which would mean
    /// nothing on it (a second encoding, which `decode` refuses).
    pub fn set_feature(&mut self, x: u8, y: u8, feature: Option<Feature>) -> bool {
        if !self.on_grid(x, y) || feature_code(feature).is_none() {
            return false;
        }
        let t = self.tile_mut(x as u16, y as u16);
        t.feature = feature;
        if !feature.is_some_and(|f| f.directional()) {
            t.facing = 0;
        }
        if sets_pace(feature) {
            t.pace = 0;
        }
        if let Some(s) = feature.and_then(|f| f.surface()) {
            t.surface = s;
        }
        true
    }

    /// The ground underfoot; refused under a feature that is its own ground
    /// (a stream is water).
    pub fn set_surface(&mut self, x: u8, y: u8, surface: Surface) -> bool {
        if !self.on_grid(x, y) {
            return false;
        }
        let t = self.tile_mut(x as u16, y as u16);
        if t.feature.and_then(|f| f.surface()).is_some_and(|s| s != surface) {
            return false;
        }
        t.surface = surface;
        true
    }

    /// §6.2's raised ground, 0 to 3.
    pub fn set_height(&mut self, x: u8, y: u8, height: u8) -> bool {
        if !self.on_grid(x, y) || height > 3 {
            return false;
        }
        self.tile_mut(x as u16, y as u16).height = height;
        true
    }

    /// Take whatever stands on a tile away — a pylon and its law, a ward, a
    /// post, the building whose footprint it is in — or, with nothing
    /// standing there, its ground feature. The Vault
    /// is moved, never removed. True if anything changed.
    pub fn clear(&mut self, x: u8, y: u8) -> bool {
        match self.occupant(x, y) {
            Occupant::Vault => false,
            Occupant::Pylon(i) => {
                self.laws.remove(i);
                true
            }
            Occupant::Ward(i) => {
                self.wards.remove(i);
                true
            }
            Occupant::Guard(i) => {
                self.guards.remove(i);
                true
            }
            Occupant::Building(i) => {
                self.buildings.remove(i);
                true
            }
            Occupant::Tunnel(i) => {
                self.tunnels.remove(i);
                true
            }
            Occupant::None => self.tile(x, y).is_some_and(|t| t.feature.is_some())
                && self.set_feature(x, y, None),
        }
    }

    /// Put something on a tile, replacing whatever stood there. The Vault
    /// cannot be covered.
    fn claim(&mut self, x: u8, y: u8) -> bool {
        if !self.on_grid(x, y) || self.occupant(x, y) == Occupant::Vault {
            return false;
        }
        // A guard may stand in tall grass or fog: clear both (RB-57).
        while self.clear(x, y) {}
        true
    }

    pub fn place_ward(&mut self, kind: WardKind, x: u8, y: u8) -> bool {
        self.claim(x, y) && {
            self.wards.push((kind, x, y));
            true
        }
    }

    /// A guard post of §12.17's role `row`, 0 to 4, facing the way §13.3's
    /// generator would face it (`default_facing`) until its owner turns it.
    pub fn post_guard(&mut self, row: u8, x: u8, y: u8) -> bool {
        row < 5 && self.claim(x, y) && {
            self.guards.push(Post { row, x, y, facing: 0 });
            let i = self.guards.len() - 1;
            self.guards[i].facing = self.default_facing(i);
            true
        }
    }

    /// Face a directional feature or a guard post on a tile one of the four
    /// ways (G56). False if nothing there faces.
    pub fn face(&mut self, x: u8, y: u8, facing: u8) -> bool {
        if let Occupant::Guard(i) = self.occupant(x, y) {
            self.guards[i].facing = facing & 3;
            return true;
        }
        match self.tile(x, y) {
            Some(t) if t.feature.is_some_and(|f| f.directional()) => {
                self.tile_mut(x as u16, y as u16).facing = facing & 3;
                true
            }
            _ => false,
        }
    }

    /// The way a directional feature or a post on a tile faces, if one does.
    pub fn facing(&self, x: u8, y: u8) -> Option<u8> {
        if let Occupant::Guard(i) = self.occupant(x, y) {
            return Some(self.guards[i].facing);
        }
        self.tile(x, y).filter(|t| t.feature.is_some_and(|f| f.directional())).map(|t| t.facing)
    }

    /// Dig a tunnel between two tiles (§6.2), taking away what stood on
    /// each and any tunnel already using either. Refused for mouths off the
    /// grid, on the Vault, or nearer than 2 tiles or further than 6.
    pub fn dig_tunnel(&mut self, a: (u8, u8), b: (u8, u8)) -> bool {
        let walk = a.0.abs_diff(b.0) as u16 + a.1.abs_diff(b.1) as u16;
        if !self.on_grid(a.0, a.1) || !self.on_grid(b.0, b.1) || a == self.vault || b == self.vault
            || !(crate::grid::TUNNEL_MIN_TILES..=crate::grid::TUNNEL_TILES).contains(&walk)
        {
            return false;
        }
        for (x, y) in [a, b] {
            while self.clear(x, y) {}
        }
        let side = self.side();
        let index = |(x, y): (u8, u8)| y as u16 * side + x as u16;
        let (a, b) = if index(a) < index(b) { (a, b) } else { (b, a) };
        let at = self.tunnels.iter().position(|&(p, _)| index(p) > index(a)).unwrap_or(self.tunnels.len());
        self.tunnels.insert(at, (a, b));
        true
    }

    /// The way §13.3's generator faces a held post (G56): toward the nearest
    /// tile on a shortest route from a landing edge to the Vault (§12.17's
    /// "toward the route a crew takes"), as the one of the four ways nearest
    /// its bearing. A route tile is one whose walk from the nearest open edge
    /// plus its walk to beside the Vault is the least any tile has; the
    /// nearest is by the walk's count of tiles, ties to the lower index; the
    /// way is along the longer of the two offsets, a tie to the first in
    /// north, east, south, west. With no route, or the post on it, north.
    pub fn default_facing(&self, i: usize) -> u8 {
        let Some(post) = self.guards.get(i) else { return crate::grid::NORTH };
        let mut grid = self.standing();
        // The post's own tile is open ground for the route: a guard does not
        // close its own path.
        if let Some(p) = grid.index(post.x as u16, post.y as u16) {
            if !grid.at(p).passable() {
                return crate::grid::NORTH;
            }
        }
        let n = grid.len();
        let field = |starts: &[crate::grid::TileIndex], grid: &mut Grid| -> Vec<u32> {
            let mut d = vec![u32::MAX; n];
            let mut q = std::collections::VecDeque::new();
            for &s in starts {
                d[s as usize] = 0;
                q.push_back(s);
            }
            while let Some(t) = q.pop_front() {
                for nb in grid.neighbours(t).into_iter().flatten() {
                    if d[nb as usize] == u32::MAX && grid.can_step(t, nb) {
                        d[nb as usize] = d[t as usize] + 1;
                        q.push_back(nb);
                    }
                }
            }
            d
        };
        let from_edge = field(&Self::open_edge(&grid), &mut grid);
        let (vx, vy) = (self.vault.0 as i32, self.vault.1 as i32);
        let beside: Vec<crate::grid::TileIndex> = (0..n as crate::grid::TileIndex)
            .filter(|&t| {
                let (x, y) = grid.coords(t);
                (x as i32 - vx).abs() + (y as i32 - vy).abs() == 1 && grid.at(t).passable()
            })
            .collect();
        // Toward the Vault is the walk back from beside it, so the field from
        // there runs over reversed steps.
        let to_vault = {
            let mut d = vec![u32::MAX; n];
            let mut q = std::collections::VecDeque::new();
            for &s in &beside {
                d[s as usize] = 0;
                q.push_back(s);
            }
            while let Some(t) = q.pop_front() {
                for nb in grid.neighbours(t).into_iter().flatten() {
                    if d[nb as usize] == u32::MAX && grid.can_step(nb, t) {
                        d[nb as usize] = d[t as usize] + 1;
                        q.push_back(nb);
                    }
                }
            }
            d
        };
        let total = |t: usize| from_edge[t].checked_add(to_vault[t]);
        let Some(best) = (0..n).filter_map(total).min() else { return crate::grid::NORTH };
        let (px, py) = (post.x as i32, post.y as i32);
        let Some(near) = (0..n).filter(|&t| total(t) == Some(best))
            .min_by_key(|&t| {
                let (x, y) = grid.coords(t as crate::grid::TileIndex);
                ((x as i32 - px).abs() + (y as i32 - py).abs(), t)
            }) else { return crate::grid::NORTH };
        let (x, y) = grid.coords(near as crate::grid::TileIndex);
        let (dx, dy) = (x as i32 - px, y as i32 - py);
        let ways = [(crate::grid::NORTH, -dy), (crate::grid::EAST, dx),
                    (crate::grid::SOUTH, dy), (crate::grid::WEST, -dx)];
        match ways.iter().max_by_key(|&&(w, v)| (v, std::cmp::Reverse(w))) {
            Some(&(w, v)) if v > 0 => w,
            _ => crate::grid::NORTH,
        }
    }

    /// Weave a law this rules version has, with its pylon on the tile. A law
    /// already woven moves its pylon here, since a realm weaves a law once.
    pub fn weave(&mut self, id: &str, x: u8, y: u8) -> bool {
        // Refused before the law is lifted from its old pylon (RB-50).
        if !LAWS.iter().any(|l| l.id == id) || !self.on_grid(x, y) || self.occupant(x, y) == Occupant::Vault {
            return false;
        }
        if let Some(i) = self.laws.iter().position(|(l, _, _)| l == id) {
            self.laws.remove(i);
        }
        self.claim(x, y) && {
            self.laws.push((id.to_string(), x, y));
            true
        }
    }

    /// Put building `code` with its footprint's north-west tile on (x, y),
    /// taking away whatever stood on the footprint. Refused for a code no
    /// building has, a footprint off the grid or one over the Vault.
    pub fn place_building(&mut self, code: u8, x: u8, y: u8) -> bool {
        let Some(size) = footprint(code) else { return false };
        let side = self.side();
        if x as u16 + size as u16 > side || y as u16 + size as u16 > side {
            return false;
        }
        let tiles: Vec<(u8, u8)> = (0..size).flat_map(|dy| (0..size).map(move |dx| (x + dx, y + dy))).collect();
        if tiles.contains(&self.vault) {
            return false;
        }
        for &(tx, ty) in &tiles {
            while self.clear(tx, ty) {}
        }
        self.buildings.push((code, x, y));
        true
    }

    /// Move the Vault to a tile, taking what stood there away.
    pub fn set_vault(&mut self, x: u8, y: u8) -> bool {
        if !self.on_grid(x, y) {
            return false;
        }
        if self.vault != (x, y) {
            self.clear(x, y);
        }
        self.vault = (x, y);
        true
    }

    /// §6.1: a route from the landing to a tile beside the Vault, on feet.
    fn reaches_vault(&self, grid: &Grid, from: &[crate::grid::TileIndex]) -> bool {
        let (vx, vy) = (self.vault.0 as i32, self.vault.1 as i32);
        let mut seen = vec![false; grid.len()];
        let mut frontier = from.to_vec();
        for &start in from {
            seen[start as usize] = true;
        }
        while let Some(at) = frontier.pop() {
            let (x, y) = grid.coords(at);
            if (x as i32 - vx).abs() + (y as i32 - vy).abs() == 1 {
                return true;
            }
            for n in grid.neighbours(at).into_iter().flatten() {
                if !seen[n as usize] && grid.can_step(at, n) {
                    seen[n as usize] = true;
                    frontier.push(n);
                }
            }
            // A tunnel is a route a crew can walk.
            if let Some(n) = grid.tunnel_exit(at) {
                if !seen[n as usize] {
                    seen[n as usize] = true;
                    frontier.push(n);
                }
            }
        }
        false
    }

    /// The simulation's fixture realm, as an island: the Heart every test and
    /// golden replay has been played in. It is a test realm and not a legal
    /// one — five guard posts where §5.2 allows three at realm level 5, so
    /// that every row of §12.17's guard table stands somewhere — and `check`
    /// says so.
    pub fn fixture() -> Island {
        use crate::grid::Feature::*;
        // §5.2's realm 5 is 14x14, the largest, so the fixture uses it. The
        // features are §6.2's, chosen because they pull feet and eyes apart:
        //
        //   a ruin wall with one gap    blocks both; the gap makes a route
        //                               bend, so the neighbour order and the
        //                               tie-breaking are observable
        //   a rock pillar               blocks both, in open ground
        //   a fence                     blocks walking, "doesn't block sight"
        //   a fog bank                  walkable, blocks sight through it
        //   mud and a fast path         §6.2's "40% slower" and "15% faster"
        let mut island = Island::empty(crate::FIXTURE_REALM_LEVEL);
        let side = island.side();
        for y in 0..side {
            if y != 6 {
                island.tile_mut(7, y).feature = Some(RuinWall);
            }
        }
        island.tile_mut(4, 5).feature = Some(RockPillar);
        for x in 9..12 {
            island.tile_mut(x, 7).feature = Some(Fence);
        }
        island.tile_mut(5, 8).feature = Some(FogBank);
        island.tile_mut(6, 8).feature = Some(FogBank);
        island.tile_mut(3, 3).pace = 60;
        island.tile_mut(10, 9).pace = 115;
        // §12.17's remaining modifiers, each where a route or a guard meets it:
        //   tall grass west of the wall   invisible if still, until a guard
        //                                 walks into the tile
        //   a gravel run through the gap  louder, at the one place every
        //                                 crossing has to use
        //   moss in the south-east        quieter
        //   a dark corner by the entrance "an unlit tile halves it again"
        for x in 1..4 {
            island.tile_mut(x, 7).feature = Some(TallGrass);
        }
        for x in 5..10 {
            island.tile_mut(x, 6).surface = Surface::Gravel;
        }
        for x in 8..11 {
            island.tile_mut(x, 12).surface = Surface::Moss;
        }
        // Moss behind two posts. A crouched walk carries 1 m and the tile
        // behind a guard is 1 m away, so the last step of any approach on
        // plain ground is heard; on moss a crouched walk carries nothing.
        // Without these §12.8's ambush has no way in (see the README). And
        // behind two more, since v3.3's crack noise brings every guard in the
        // Heart to the Vault five seconds into cracking: a crew that wants to
        // load has to have put the guards down first, and the moss is the
        // Keeper's decision that allows it (§6.1). The Warden's rise has no
        // way behind it, so one guard always answers the noise.
        for (x, y) in [(9, 5), (12, 3), (2, 11), (11, 11)] {
            island.tile_mut(x, y).surface = Surface::Moss;
        }
        for y in 10..14 {
            for x in 10..14 {
                island.tile_mut(x, y).unlit = true;
            }
        }
        // A rise for the Warden's post: §6.2's raised ground, one level, with a
        // ramp up from the north. From up there it sees a metre further toward
        // anyone below (§12.17); a raider up there hides its far zone from the
        // guards below.
        for y in 12..14 {
            for x in 4..7 {
                island.tile_mut(x, y).height = 1;
            }
        }
        island.tile_mut(5, 11).climbable = true;
        // The Vault, past the wall's gap and the gravel, between the Breaker's
        // post and the Mender's: the fixture realm is the Heart.
        island.vault = (crate::VAULT_AT.0 as u8, crate::VAULT_AT.1 as u8);
        island.vault_level = 1;
        island.exposed = crate::heist::FIXTURE_EXPOSED as u32;
        // Where §12.17's reinforcing Warden arrives: the south-east corner,
        // on the guards' side of the wall, and far from the planned heist's
        // landing at (1, 0).
        island.entrance = ((side - 1) as u8, (side - 1) as u8);
        // Guards on tile centres, on both sides of the wall, so that the wall,
        // the fence and the fog each stand between some guard and some route.
        // One on each of §12.17's five rows, in row order.
        island.guards = [(2, 10), (5, 12), (9, 4), (11, 10), (12, 2)]
            .iter()
            .enumerate()
            .map(|(row, (x, y))| Post { row: row as u8, x: *x, y: *y, facing: 0 })
            .collect();
        island.wards = crate::FIXTURE_WARDS.iter()
            .map(|(k, (x, y))| (*k, *x as u8, *y as u8))
            .collect();
        island.laws = crate::FIXTURE_LAWS.iter()
            .map(|(id, (x, y))| (id.to_string(), *x as u8, *y as u8))
            .collect();
        island
    }

    /// A legal Heart at realm level 3, for the server's tests: §5.2's two
    /// posts and two law slots, four of its six wards, a wall across the
    /// north half whose one gap every route from the north edge has to take
    /// (where the server's tests land), and the Vault in the south half. Built by hand rather than generated, so what it is does not
    /// move when the generator does.
    pub fn example() -> Island {
        use crate::grid::Feature::*;
        let mut island = Island::empty(3);
        let side = island.side();
        for x in 0..side {
            if x != 9 {
                island.tile_mut(x, 5).feature = Some(RuinWall);
            }
        }
        island.tile_mut(9, 5).surface = Surface::Gravel;
        for x in 2..5 {
            island.tile_mut(x, 7).feature = Some(TallGrass);
        }
        island.tile_mut(5, 3).feature = Some(FogBank);
        island.tile_mut(3, 2).pace = 60;
        island.tile_mut(10, 8).surface = Surface::Moss;
        for y in 9..12 {
            for x in 0..3 {
                island.tile_mut(x, y).unlit = true;
            }
        }
        island.vault = (6, 9);
        island.vault_level = 3;
        island.exposed = crate::heist::FIXTURE_EXPOSED as u32;
        island.entrance = ((side - 1) as u8, (side - 1) as u8);
        island.guards = vec![Post { row: 2, x: 9, y: 7, facing: 0 }, Post { row: 1, x: 4, y: 10, facing: 0 }];
        island.wards = vec![
            (WardKind::TimeSnare, 9, 6),
            (WardKind::GravityWell, 10, 10),
            (WardKind::StaticCoil, 1, 3),
            (WardKind::LanternGlare, 3, 9),
        ];
        island.laws = vec![("haste".to_string(), 1, 10), ("brittle_stone".to_string(), 11, 2)];
        island
    }

    /// §12.22's generated target, made from a seed: "the game's own", which
    /// the server offers when a raider's list runs thin, and §12.12's ruins
    /// draw on (D66, TD.16). The same seed makes the same island on every
    /// machine, and every one passes `check`.
    ///
    /// What it lays is §13.2's five layers, each to §5.2's budget for the
    /// realm level and no further:
    ///
    /// - **Geometry.** The Vault near the middle, the place furthest from
    ///   every edge a crew can land on. Rings of ruin wall around it, each
    ///   with a two-tile gap on alternating sides, so the way in winds round
    ///   rather than running straight — F16's shaped layout, which the
    ///   harness measured; no ring touches an edge, so every side stays open
    ///   to land on (F51). Tall grass in clumps, and a few rock pillars, off
    ///   the shortest route.
    /// - **Guards.** §5.2's posts for the level: Warden, Scout, Breaker in
    ///   turn, the first beside the Vault on the shortest way in and the rest
    ///   at the ring gaps, each facing as the generator faces a post
    ///   (`default_facing`).
    /// - **Wards.** §5.2's count: on the shortest route, then beside it,
    ///   then on the open tiles nearest the Vault, never within `WARD_EDGE`
    ///   tiles of an edge, since a crew lands where it likes (§5.4); the
    ///   kinds in turn, the Crystal Wall left out, since on the route it
    ///   would seal it.
    /// - **Laws.** §5.2's slots, filled from §7.10's launch laws, each pylon
    ///   beside the Vault off the route.
    ///
    /// The Vault is the realm level's, and it exposes a full five-crew's
    /// carry (§9.6), as the fixture's does. A layout that fails `check` is
    /// drawn again from the next seed, which the next draw always is.
    pub fn generated(seed: u64, realm_level: u8) -> Island {
        let level = realm_level.clamp(1, 5);
        let mut attempt = 0u64;
        loop {
            let island = Island::draw(seed.wrapping_add(attempt), level);
            if island.check().is_empty() || attempt >= 64 {
                return island;
            }
            attempt += 1;
        }
    }

    /// §13.3's curation: the generator's layout for a player's own realm —
    /// "pick a different generated layout". `generated`'s draw from `seed`,
    /// with the realm's buildings standing where its owner placed them
    /// (§10.1), the Vault at the level its owner has built, and the laws the
    /// realm has woven on the generator's pylon spots in place of its own
    /// draw: the generator never weaves for a player, only lays out what
    /// they have (G54). A draw that loses a building, a law, a post or a
    /// ward to a building's footprint, or that fails `check`, is drawn again
    /// from the next seed; after 64 the last is answered, problems and all,
    /// for the server to refuse by name.
    pub fn curated(seed: u64, realm_level: u8, vault_level: u8, buildings: &[(u8, u8, u8)],
                   laws: &[&str]) -> Island {
        let level = realm_level.clamp(1, 5);
        let mut last = Island::empty(level);
        for attempt in 0..64u64 {
            let mut island = Island::draw(seed.wrapping_add(attempt), level);
            island.vault_level = vault_level.clamp(1, 10);
            let spots: Vec<(u8, u8)> = island.laws.iter().map(|&(_, x, y)| (x, y)).collect();
            island.laws.clear();
            let (guards, wards) = (island.guards.len(), island.wards.len());
            let mut whole = laws.len() <= spots.len();
            for (id, &(x, y)) in laws.iter().zip(&spots) {
                whole &= island.weave(id, x, y);
            }
            for &(code, x, y) in buildings {
                whole &= island.place_building(code, x, y);
            }
            whole &= island.laws.len() == laws.len() && island.buildings.len() == buildings.len()
                && island.guards.len() == guards && island.wards.len() == wards;
            if whole && island.check().is_empty() {
                return island;
            }
            last = island;
        }
        last
    }

    /// The digest of an island's terrain alone: its ground, the Vault, the
    /// entrance and the tunnels, with no post, ward, law or building. §13.3:
    /// "A curated defence keeps the generated origin while only curation's
    /// verbs are used, and is authored once its terrain is edited" — the
    /// server keeps a curated layout's and compares a republished island's.
    pub fn terrain_digest(&self) -> [u8; 32] {
        let mut bare = self.clone();
        bare.guards.clear();
        bare.wards.clear();
        bare.laws.clear();
        bare.buildings.clear();
        bare.vault_level = 1;
        bare.exposed = 0;
        bare.digest()
    }

    #[cfg(test)]
    pub(crate) fn draw_for_test(seed: u64, level: u8) -> Island {
        Island::draw(seed, level)
    }

    fn draw(seed: u64, level: u8) -> Island {
        use crate::grid::Feature::*;
        use crate::rng::{Rng, Stream};
        let mut rng = Rng::new(seed, Stream::Generator);
        let mut island = Island::empty(level);
        let side = island.side() as u8;
        let li = (level - 1) as usize;
        island.vault_level = level;
        island.exposed = crate::heist::FIXTURE_EXPOSED as u32;
        island.entrance = (side - 1, side - 1);
        // The Vault near the middle, the place furthest from every edge a
        // crew can land on (§5.4).
        let c = side / 2;
        let vx = c - 1 + rng.below(3) as u8;
        let vy = c - 1 + rng.below(3) as u8;
        island.vault = (vx, vy);
        // Rings of ruin wall around it, each with a gap two tiles wide, the
        // gaps on alternating sides, so the way in winds round the Vault
        // rather than running straight at it — F16's shaped layout. No ring
        // touches an edge, so every side stays open to land on (F51).
        let reach = vx.min(vy).min(side - 1 - vx).min(side - 1 - vy);
        let radii: Vec<u8> = [2u8, 4].into_iter().filter(|&r| r + 2 <= reach).collect();
        let first = rng.below(4) as u8;
        let mut gaps: Vec<(u8, u8)> = Vec::new();
        for (i, &r) in radii.iter().enumerate() {
            let way = (first + 2 * i as u8) % 4;           // N, E, S, W
            let (r, cx, cy) = (r as i32, vx as i32, vy as i32);
            let gap: [(i32, i32); 2] = match way {
                0 => [(cx, cy - r), (cx + 1, cy - r)],
                1 => [(cx + r, cy), (cx + r, cy + 1)],
                2 => [(cx, cy + r), (cx - 1, cy + r)],
                _ => [(cx - r, cy), (cx - r, cy - 1)],
            };
            for dy in -r..=r {
                for dx in -r..=r {
                    if dx.abs().max(dy.abs()) != r {
                        continue;
                    }
                    let (x, y) = (cx + dx, cy + dy);
                    if gap.contains(&(x, y)) {
                        gaps.push((x as u8, y as u8));
                        continue;
                    }
                    island.tile_mut(x as u16, y as u16).feature = Some(RuinWall);
                }
            }
        }
        let route = island.way_in();
        // Cover off the route: clumps of tall grass, and a few rock pillars.
        let clumps = 3 + rng.below(3);
        for _ in 0..clumps {
            let (cx, cy) = (1 + rng.below((side - 3) as u64) as u8, 1 + rng.below((side - 3) as u64) as u8);
            for (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1)] {
                let (x, y) = (cx + dx, cy + dy);
                if island.bare(x, y) && !route.contains(&(x, y)) {
                    island.tile_mut(x as u16, y as u16).feature = Some(TallGrass);
                }
            }
        }
        for _ in 0..1 + rng.below(3) {
            let (x, y) = (1 + rng.below((side - 2) as u64) as u8, 1 + rng.below((side - 2) as u64) as u8);
            if island.bare(x, y) && !route.contains(&(x, y)) {
                island.tile_mut(x as u16, y as u16).feature = Some(RockPillar);
            }
        }
        let route = island.way_in();
        // Guards: the first beside the Vault on the way in, the rest at the
        // band gaps.
        let rows = [1u8, 0, 2];
        let mut spots: Vec<(u8, u8)> = route.iter().rev().take(1).copied().collect();
        spots.extend(route.iter().filter(|t| gaps.contains(t)).copied());
        spots.extend(gaps.iter().copied());
        for i in 0..GUARD_POSTS[li] as usize {
            let Some(&(x, y)) = spots.get(i) else { break };
            island.post_guard(rows[i % rows.len()], x, y);
        }
        // Wards on the route, away from the edges.
        let kinds = [WardKind::TimeSnare, WardKind::ThornHedge, WardKind::StaticCoil,
                     WardKind::GravityWell, WardKind::LanternGlare];
        let start = rng.below(kinds.len() as u64) as usize;
        let far = |&(x, y): &(u8, u8)| x >= WARD_EDGE && y >= WARD_EDGE
            && (x as u16) + (WARD_EDGE as u16) < side as u16 && (y as u16) + (WARD_EDGE as u16) < side as u16;
        let open = |t: &(u8, u8)| island.occupant(t.0, t.1) == Occupant::None && *t != island.vault
            && island.tile(t.0, t.1).is_some_and(|tile| tile.feature.is_none());
        // The route's own tiles first, then the tiles beside it.
        let mut free: Vec<(u8, u8)> = route.iter().filter(|t| far(t) && open(t)).copied().collect();
        for &(x, y) in &route {
            for (dx, dy) in [(0i32, -1i32), (1, 0), (0, 1), (-1, 0)] {
                let t = ((x as i32 + dx) as u8, (y as i32 + dy) as u8);
                if far(&t) && open(&t) && !free.contains(&t) && !route.contains(&t) {
                    free.push(t);
                }
            }
        }
        // Then, where the budget is still larger than the route allows, the
        // open tiles nearest the Vault: a ward guarding the approach.
        let mut rest: Vec<(u8, u8)> = (0..side).flat_map(|y| (0..side).map(move |x| (x, y)))
            .filter(|t| far(t) && open(t) && !free.contains(t) && !route.contains(t))
            .collect();
        rest.sort_by_key(|&(x, y)| (x.abs_diff(vx) as u16 + y.abs_diff(vy) as u16, y, x));
        free.extend(rest);
        let count = (WARD_LIMITS[li] as usize).min(free.len());
        for (k, &(x, y)) in free.iter().take(count).enumerate() {
            island.wards.push((kinds[(start + k) % kinds.len()], x, y));
        }
        // Laws: chapter 1's twelve, drawn without repeats, their pylons
        // beside the Vault off the route. Chapter 1 is open to every Keeper
        // (§7.6), and matchmaking shows only universes running laws from a
        // raider's open chapters, so the game's own islands, offered to any
        // raider whose list runs thin (§12.22), run only laws every raider
        // may meet.
        let launch: Vec<&str> = LAWS.iter().filter(|l| l.launch && l.chapter == 1).map(|l| l.id).collect();
        let mut chosen: Vec<&str> = Vec::new();
        while chosen.len() < LAW_SLOTS[li] as usize && chosen.len() < launch.len() {
            let id = launch[rng.below(launch.len() as u64) as usize];
            if !chosen.contains(&id) {
                chosen.push(id);
            }
        }
        let route: Vec<(u8, u8)> = island.way_in();
        let mut pylon_spots = Vec::new();
        for r in 1..side {
            for dy in -(r as i32)..=r as i32 {
                for dx in -(r as i32)..=r as i32 {
                    if dx.abs().max(dy.abs()) != r as i32 {
                        continue;
                    }
                    let (x, y) = (vx as i32 + dx, vy as i32 + dy);
                    if x < 1 || y < 1 || x >= side as i32 - 1 || y >= side as i32 - 1 {
                        continue;
                    }
                    let t = (x as u8, y as u8);
                    if island.bare(t.0, t.1) && island.occupant(t.0, t.1) == Occupant::None
                        && !route.contains(&t) && !pylon_spots.contains(&t)
                    {
                        pylon_spots.push(t);
                    }
                }
            }
            if pylon_spots.len() >= chosen.len() * 3 {
                break;
            }
        }
        for (i, id) in chosen.iter().enumerate() {
            if let Some(&(x, y)) = pylon_spots.get(i * 3) {
                island.laws.push((id.to_string(), x, y));
            }
        }
        island
    }

    /// Open ground with no feature on it.
    fn bare(&self, x: u8, y: u8) -> bool {
        self.tile(x, y).is_some_and(|t| t.feature.is_none()) && self.vault != (x, y)
    }

    /// The shortest way in: from the nearest open edge tile to a tile beside
    /// the Vault, by §12.18's walk, every Crystal Wall standing — the route
    /// the generator lays its defence along, as (x, y).
    fn way_in(&self) -> Vec<(u8, u8)> {
        let grid = self.standing();
        let landings = Self::open_edge(&grid);
        let (vx, vy) = (self.vault.0 as i32, self.vault.1 as i32);
        let beside: Vec<crate::grid::TileIndex> = (0..grid.len() as crate::grid::TileIndex)
            .filter(|&t| {
                let (x, y) = grid.coords(t);
                (x as i32 - vx).abs() + (y as i32 - vy).abs() == 1 && grid.at(t).passable()
            })
            .collect();
        let mut best: Option<Vec<crate::grid::TileIndex>> = None;
        for &from in &landings {
            for &to in &beside {
                if let Some(route) = crate::path::find(&grid, from, to) {
                    if best.as_ref().is_none_or(|b| route.len() + 1 < b.len()) {
                        let mut whole = vec![from];
                        whole.extend(route);
                        best = Some(whole);
                    }
                }
            }
        }
        best.unwrap_or_default().into_iter()
            .map(|t| {
                let (x, y) = grid.coords(t);
                (x as u8, y as u8)
            })
            .collect()
    }

    /// `example()` with nothing defending it: no guards, no wards, no laws.
    /// Still a legal island — §5.2 sets maximums, not minimums — and the one
    /// the server's tests raid when they need a heist that banks loot, since
    /// a drawn command log almost never opens a defended Vault.
    pub fn example_open() -> Island {
        let mut island = Island::example();
        island.guards.clear();
        island.wards.clear();
        island.laws.clear();
        island
    }
}
