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
//! bytes, an unknown code, a pace of exactly 100 (which is written as 0), a
//! flag bit nobody defined — because two encodings of one island would be two
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
//!     flags: 1 unlit, 2 climbable
//! guards u8, then (role row u8, x u8, y u8) each
//! wards u8, then (kind u8, x u8, y u8) each
//! laws u8, then (id length u8, id, x u8, y u8) each
//! ```
//! A law is named by its id rather than its row in the table, because an
//! island outlives a rules version (§24.11: a re-tuned law re-costs the
//! island; a removed one's "name is never reused").
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

/// §5.2's budgets by realm level 1 to 5: "the smaller of the wards it needs to
/// reach its hold band and eight … 8, 8, 6, 7 and 8"; guard posts "Levels 3
/// to 5 keep 2, 3 and 3", with one at levels 1 and 2; and the law slots in
/// its table. `content_gate.py` checks all three against `design_facts`.
pub const WARD_LIMITS: [u8; 5] = [8, 8, 6, 7, 8];
pub const GUARD_POSTS: [u8; 5] = [1, 1, 2, 3, 3];
pub const LAW_SLOTS: [u8; 5] = [1, 1, 2, 2, 3];


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
}

/// A guard post: §12.17's role row (0 Scout, 1 Warden, 2 Breaker, 3 Carrier,
/// 4 Mender) and its tile.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Post {
    pub row: u8,
    pub x: u8,
    pub y: u8,
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
    LawId,
}

/// What stands on a tile, by its place in the island's list.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Occupant {
    None,
    Vault,
    Pylon(usize),
    Ward(usize),
    Guard(usize),
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
}

impl Problem {
    pub const ALL: [Problem; 9] = [
        Problem::TooManyWards, Problem::TooManyGuards, Problem::TooManyLaws,
        Problem::UnknownLaw, Problem::Crowded, Problem::PostBlocked,
        Problem::LandingBlocked, Problem::Sealed, Problem::EdgeClosed,
    ];

    pub fn bit(self) -> u32 {
        1 << Problem::ALL.iter().position(|p| *p == self).unwrap_or(31)
    }
}

fn feature_code(f: Option<Feature>) -> Option<u8> {
    Some(match f {
        None => 0,
        Some(Feature::RockPillar) => 1,
        Some(Feature::RuinWall) => 2,
        Some(Feature::Fence) => 3,
        Some(Feature::FogBank) => 4,
        Some(Feature::TallGrass) => 5,
        // Written by their own lists, never into the ground layer.
        Some(Feature::Vault | Feature::Pylon | Feature::CrystalWall) => return None,
    })
}

fn feature_from(code: u8) -> Result<Option<Feature>, Malformed> {
    Ok(match code {
        0 => None,
        1 => Some(Feature::RockPillar),
        2 => Some(Feature::RuinWall),
        3 => Some(Feature::Fence),
        4 => Some(Feature::FogBank),
        5 => Some(Feature::TallGrass),
        _ => return Err(Malformed::UnknownFeature),
    })
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

/// Whether a feature stops feet, so a pace on it would mean nothing.
fn blocks_feet(f: Option<Feature>) -> bool {
    matches!(f, Some(Feature::RockPillar | Feature::RuinWall | Feature::Fence))
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
        }
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
            out.push(feature | surface_code(t.surface) << 4 | (t.height.min(3)) << 6);
            out.push(if t.pace == 100 { 0 } else { t.pace });
            out.push(t.unlit as u8 | (t.climbable as u8) << 1);
        }
        out.push(self.guards.len() as u8);
        for g in &self.guards {
            out.extend_from_slice(&[g.row, g.x, g.y]);
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
        out
    }

    pub fn decode(bytes: &[u8]) -> Result<Island, Malformed> {
        let mut at = 0usize;
        let mut take = |n: usize| -> Result<&[u8], Malformed> {
            let s = bytes.get(at..at + n).ok_or(Malformed::Truncated)?;
            at += n;
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
            let feature = feature_from(t[0] & 15)?;
            if t[2] & !3 != 0 {
                return Err(Malformed::FlagBits);
            }
            if t[1] == 100 || (t[1] != 0 && blocks_feet(feature)) {
                return Err(Malformed::NonCanonicalPace);
            }
            tiles.push(Tile {
                feature,
                pace: t[1],
                surface: surface_from(t[0] >> 4 & 3),
                height: t[0] >> 6,
                unlit: t[2] & 1 != 0,
                climbable: t[2] & 2 != 0,
            });
        }
        let n = take(1)?[0];
        let mut guards = Vec::with_capacity(n as usize);
        for _ in 0..n {
            let g = take(3)?;
            if g[0] > 4 {
                return Err(Malformed::UnknownRole);
            }
            if !on_grid(g[1], g[2]) {
                return Err(Malformed::OffGrid);
            }
            guards.push(Post { row: g[0], x: g[1], y: g[2] });
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
        if at != bytes.len() {
            return Err(Malformed::TrailingBytes);
        }
        Ok(Island { realm_level, vault_level, exposed, vault, entrance, tiles, guards, wards, laws })
    }

    /// §24.8's content address.
    pub fn digest(&self) -> [u8; 32] {
        sha256(&self.encode())
    }

    /// The ground as the simulation reads it: the tile layer and the Vault.
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

        // One thing a tile: the Vault, each pylon, each ward, each post. The
        // Vault, a pylon and a ward also need bare ground under them; a guard
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

    /// What stands on a tile, beyond its ground: the Vault, a pylon, a ward
    /// or a guard post.
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
        if blocks_feet(feature) {
            t.pace = 0;
        }
        true
    }

    pub fn set_surface(&mut self, x: u8, y: u8, surface: Surface) -> bool {
        if !self.on_grid(x, y) {
            return false;
        }
        self.tile_mut(x as u16, y as u16).surface = surface;
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
    /// post — or, with nothing standing there, its ground feature. The Vault
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
        self.clear(x, y);
        true
    }

    pub fn place_ward(&mut self, kind: WardKind, x: u8, y: u8) -> bool {
        self.claim(x, y) && {
            self.wards.push((kind, x, y));
            true
        }
    }

    /// A guard post of §12.17's role `row`, 0 to 4.
    pub fn post_guard(&mut self, row: u8, x: u8, y: u8) -> bool {
        row < 5 && self.claim(x, y) && {
            self.guards.push(Post { row, x, y });
            true
        }
    }

    /// Weave a law this rules version has, with its pylon on the tile. A law
    /// already woven moves its pylon here, since a realm weaves a law once.
    pub fn weave(&mut self, id: &str, x: u8, y: u8) -> bool {
        if !LAWS.iter().any(|l| l.id == id) || !self.on_grid(x, y) {
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
            .map(|(row, (x, y))| Post { row: row as u8, x: *x, y: *y })
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
        island.guards = vec![Post { row: 2, x: 9, y: 7 }, Post { row: 1, x: 4, y: 10 }];
        island.wards = vec![
            (WardKind::TimeSnare, 9, 6),
            (WardKind::GravityWell, 10, 10),
            (WardKind::StaticCoil, 1, 3),
            (WardKind::LanternGlare, 3, 9),
        ];
        island.laws = vec![("haste".to_string(), 1, 10), ("brittle_stone".to_string(), 11, 2)];
        island
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
