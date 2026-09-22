//! The tile grid. §12.18: "Both, deliberately. Terrain, laws and building are
//! per tile; position and facing are continuous, in millitiles. That is the
//! only reading under which one-metre tiles and sub-metre vision zones are
//! both true."
//!
//! So a tile decides what is *there* and a position decides where a character
//! *is*. This file is the first half. `Fx` carries positions at 2^-32 of a
//! tile, which is finer than §12.18's millitiles and therefore satisfies it —
//! a coarser unit would not.
//!
//! Terrain comes in three kinds and only the first affects a route:
//!
//!   blocking      §6.2's "Blocks movement", "Impassable line", deep water
//!   slowing       "40% slower", "15% faster" — these change the walk, not
//!                 the path, because §12.18 specifies breadth-first and
//!                 breadth-first counts tiles rather than seconds
//!   special       launches, pushes, hidden paths — out of scope here
//!
//! That separation is the spec's, not a simplification: a pathfinder that
//! routed around mud would be choosing for the player, which §12.18 forbids
//! in the same table.

use crate::fixed::Fx;

/// A tile, by index. §12.18: "ties broken by tile index", so the index is part
/// of the contract rather than an implementation detail.
pub type TileIndex = u32;

/// What a tile does to a character standing on or entering it.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Terrain {
    /// Open ground.
    #[default]
    Open,
    /// §6.2's blocking features. A route may not pass through.
    Blocked,
    /// Passable and slower or faster, as a percentage of normal speed.
    /// 60 is §6.2's "40% slower"; 115 is its "15% faster".
    Pace(u8),
}

impl Terrain {
    /// Whether a route may enter this tile.
    pub fn passable(self) -> bool {
        !matches!(self, Terrain::Blocked)
    }

    /// Speed here, as a fraction of the character's own speed.
    pub fn pace(self) -> Fx {
        match self {
            Terrain::Pace(percent) => Fx::from_ratio(percent as i64, 100),
            _ => Fx::ONE,
        }
    }
}

/// One realm's tiles. §5.2 sizes them 10x10 at realm level 1 up to 14x14 at 5.
#[derive(Clone, Debug)]
pub struct Grid {
    pub width: u16,
    pub height: u16,
    tiles: Vec<Terrain>,
    /// Whether a tile stops sight, which is a separate question from whether
    /// it stops feet. §6.2 is explicit that they come apart: a fence "blocks
    /// walking" and "doesn't block sight"; a fog bank blocks sight and can be
    /// walked through; a rock pillar does both. One flag for both would make
    /// two of those three wrong.
    sight_blocked: Vec<bool>,
    /// The feature placed on each tile, if any, so a rule that reads one
    /// (§12.17's tall grass) asks the tile rather than a second list.
    features: Vec<Option<Feature>>,
    /// §12.17: "an unlit tile halves it again". Lit unless made dark.
    unlit: Vec<bool>,
    /// §12.17: "Gravel and water are louder, moss is quieter (6.1)."
    surfaces: Vec<Surface>,
}

/// What a tile is underfoot, for noise. §12.17 names three that differ from
/// plain ground; the spec gives the factors: louder x1.25, quieter x0.75.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Surface {
    #[default]
    Plain,
    Gravel,
    Water,
    Moss,
}

/// Louder surfaces carry a sound five quarters as far, quieter three quarters.
/// As (numerator, denominator), so the one division happens once, at the end.
pub const LOUD_SURFACE: (u16, u16) = (5, 4);
pub const QUIET_SURFACE: (u16, u16) = (3, 4);

impl Surface {
    pub fn carry(self) -> (u16, u16) {
        match self {
            Surface::Gravel | Surface::Water => LOUD_SURFACE,
            Surface::Moss => QUIET_SURFACE,
            Surface::Plain => (1, 1),
        }
    }
}

/// §6.2's features, by what they do to feet and to eyes. Named from the
/// document so a fixture that uses them can be traced back to it.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Feature {
    /// "Blocks; can't be broken" / "Blocks sight".
    RockPillar,
    /// "Blocks, with gaps" / "Cover; blocks sight".
    RuinWall,
    /// "Blocks walking; can be leapt" / "Doesn't block sight".
    Fence,
    /// Walkable / "Hides anyone inside and blocks sight through it".
    FogBank,
    /// Walkable, and does not block sight. §12.17: "standing still in tall
    /// grass makes you invisible until a guard walks into the tile" — which
    /// is a rule about the one standing in it, not about the line through it.
    TallGrass,
    /// §12.6's Vault: a structure, walled on every side, cracked and loaded
    /// from the tiles beside it.
    Vault,
    /// §10.2's Law Pylon: one per law, walled like the Vault, but thin — it
    /// does not stop sight.
    Pylon,
}

impl Feature {
    fn terrain(self) -> Terrain {
        match self {
            Feature::RockPillar | Feature::RuinWall | Feature::Fence | Feature::Vault
            | Feature::Pylon => {
                Terrain::Blocked
            }
            Feature::FogBank | Feature::TallGrass => Terrain::Open,
        }
    }

    fn blocks_sight(self) -> bool {
        !matches!(self, Feature::Fence | Feature::TallGrass | Feature::Pylon)
    }
}

impl Grid {
    pub fn new(width: u16, height: u16) -> Grid {
        let n = width as usize * height as usize;
        Grid {
            width,
            height,
            tiles: vec![Terrain::Open; n],
            sight_blocked: vec![false; n],
            features: vec![None; n],
            unlit: vec![false; n],
            surfaces: vec![Surface::Plain; n],
        }
    }

    /// §5.2's grid for a realm level, 1 to 5: 10x10, 11x11, 12x12, 13x13, 14x14.
    pub fn for_realm_level(level: u8) -> Grid {
        let side = 9 + level.clamp(1, 5) as u16;
        Grid::new(side, side)
    }

    pub fn len(&self) -> usize {
        self.tiles.len()
    }

    pub fn is_empty(&self) -> bool {
        self.tiles.is_empty()
    }

    /// Row-major, which is what makes a tile index comparable: §12.18 breaks
    /// ties by it, so the ordering has to be stated rather than inherited.
    pub fn index(&self, x: u16, y: u16) -> Option<TileIndex> {
        if x >= self.width || y >= self.height {
            return None;
        }
        Some(y as TileIndex * self.width as TileIndex + x as TileIndex)
    }

    pub fn coords(&self, index: TileIndex) -> (u16, u16) {
        ((index % self.width as TileIndex) as u16, (index / self.width as TileIndex) as u16)
    }

    pub fn at(&self, index: TileIndex) -> Terrain {
        self.tiles.get(index as usize).copied().unwrap_or(Terrain::Blocked)
    }

    pub fn set(&mut self, x: u16, y: u16, terrain: Terrain) {
        if let Some(i) = self.index(x, y) {
            self.tiles[i as usize] = terrain;
        }
    }

    /// Place one of §6.2's features: its effect on feet and on eyes together.
    pub fn place(&mut self, x: u16, y: u16, feature: Feature) {
        if let Some(i) = self.index(x, y) {
            self.tiles[i as usize] = feature.terrain();
            self.sight_blocked[i as usize] = feature.blocks_sight();
            self.features[i as usize] = Some(feature);
        }
    }

    pub fn feature(&self, index: TileIndex) -> Option<Feature> {
        self.features.get(index as usize).copied().flatten()
    }

    pub fn darken(&mut self, x: u16, y: u16) {
        if let Some(i) = self.index(x, y) {
            self.unlit[i as usize] = true;
        }
    }

    pub fn is_unlit(&self, index: TileIndex) -> bool {
        self.unlit.get(index as usize).copied().unwrap_or(false)
    }

    pub fn set_surface(&mut self, x: u16, y: u16, surface: Surface) {
        if let Some(i) = self.index(x, y) {
            self.surfaces[i as usize] = surface;
        }
    }

    pub fn surface(&self, index: TileIndex) -> Surface {
        self.surfaces.get(index as usize).copied().unwrap_or_default()
    }

    /// Whether this tile stops a line of sight. Off the grid counts as
    /// blocking, so a guard at the edge cannot see past the realm.
    pub fn blocks_sight(&self, index: TileIndex) -> bool {
        self.sight_blocked.get(index as usize).copied().unwrap_or(true)
    }

    /// The centre of a tile, in tiles. A character walks between centres; the
    /// half-tile offset is what makes a one-metre tile and a sub-metre vision
    /// zone consistent, which is §12.18's stated reason for having both.
    pub fn centre(&self, index: TileIndex) -> (Fx, Fx) {
        let (x, y) = self.coords(index);
        (Fx::from_ratio(x as i64 * 2 + 1, 2), Fx::from_ratio(y as i64 * 2 + 1, 2))
    }

    /// The tile a position falls in, or `None` outside the grid.
    pub fn tile_at(&self, x: Fx, y: Fx) -> Option<TileIndex> {
        if x.0 < 0 || y.0 < 0 {
            return None;
        }
        self.index(x.to_int() as u16, y.to_int() as u16)
    }

    /// Whether two tiles are the same or side by side. §12.20's "an ally
    /// standing adjacent" in the grid's own four-neighbour sense.
    pub fn adjacent(&self, a: TileIndex, b: TileIndex) -> bool {
        a == b || self.neighbours(a).contains(&Some(b))
    }

    /// On the realm's edge. §5.4: the skiff comes "to any edge tile".
    pub fn is_edge(&self, index: TileIndex) -> bool {
        let (x, y) = self.coords(index);
        x == 0 || y == 0 || x + 1 == self.width || y + 1 == self.height
    }

    /// The four neighbours, **in this order**: north, east, south, west.
    ///
    /// §12.18: "a fixed neighbour order, ties broken by tile index". The order
    /// is fixed here and nowhere else, so changing it changes every route in
    /// every replay ever recorded — which is why it is written out rather
    /// than generated.
    ///
    /// Four rather than eight, because §12.18 specifies breadth-first and
    /// breadth-first counts steps. With eight neighbours a diagonal step
    /// counts the same as an orthogonal one, which is geometrically false
    /// — it is 1.41 tiles of walking, not 1 — so the "shortest" path would
    /// not be the shortest. With four, breadth-first is exactly shortest in
    /// the metric it is counting.
    pub fn neighbours(&self, index: TileIndex) -> [Option<TileIndex>; 4] {
        let (x, y) = self.coords(index);
        [
            if y > 0 { self.index(x, y - 1) } else { None },              // north
            self.index(x + 1, y),                                          // east
            self.index(x, y + 1),                                          // south
            if x > 0 { self.index(x - 1, y) } else { None },              // west
        ]
    }
}
