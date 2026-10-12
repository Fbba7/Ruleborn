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
    /// §6.2's raised ground: "Heights 0 to 3".
    heights: Vec<u8>,
    /// A ramp, stairs or vines: "climbing a level needs a ramp, stairs,
    /// vines or a leap".
    climbable: Vec<bool>,
    /// Anyone may climb one level anywhere: Honeycomb ("can climb walls and
    /// cliffs one level") or Half gravity ("turns one-level climbs into
    /// leaps"). Set each tick from the rule sheet.
    pub free_climb: bool,
    /// A law that leaps (Half gravity's "leap one obstacle"): stepping stones
    /// are a road and an updraft lifts two levels. Set each tick.
    pub leap: bool,
    /// Gap tiles under a bridge this tick — a Rootrunner's roots, a
    /// Tinkerer's plank — walkable "for anyone, guards included". Set each
    /// tick from the bridges standing.
    bridged: Vec<bool>,
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

/// §6.2's numbers for its features, as the table states them.
pub const STREAM_PACE: u8 = 80;
pub const GRAVEL_PACE: u8 = 115;
pub const THICKET_PACE: u8 = 70;
pub const THICKET_HIDES: i32 = 1;
pub const SHADE_HIDES: i32 = 3;
pub const STEAM_HIDES: i32 = 2;
/// "Lights 3 tiles"; "lanterns reach 2 tiles further past" a crystal outcrop.
pub const LANTERN_TILES: i32 = 3;
pub const OUTCROP_EXTRA_TILES: i32 = 2;
/// "Guards within 4 tiles notice 25% faster".
pub const SCREE_TILES: i32 = 4;
pub const SCREE_FILL: (i32, i32) = (5, 4);
/// "Heals 2% health a second".
pub const SPRING_HEAL: (i32, i32) = (2, 100);
/// "Bursts of flame every 8 seconds", "Lights 2 tiles when it bursts".
pub const EMBER_SECONDS: u32 = 8;
pub const EMBER_LIGHT_TILES: i32 = 2;
/// "Zaps anyone within 1 tile every 4 seconds".
pub const STONE_SECONDS: u32 = 4;
pub const STONE_TILES: i32 = 1;
/// "cut through in 3 seconds"; "a Breaker smashes it in about 6 seconds".
pub const HEDGE_CUT_SECONDS: u32 = 3;
pub const BOULDER_SMASH_SECONDS: u32 = 6;
/// A marsh: "40% slower; footprints stay for 10 seconds"; a flower meadow
/// "shows footprints for 10 seconds".
pub const MARSH_PACE: u8 = 60;
pub const PRINT_SECONDS: u32 = 10;
/// An ice sheet: "Slippery: stopping takes 1 tile".
pub const ICE_STOP_TILES: u16 = 1;
/// A bounce mushroom "launches anyone 3 tiles forward, noisily"; "the landing
/// can be heard 4 tiles away"; "Half gravity makes it 5 tiles".
pub const MUSHROOM_TILES: i32 = 3;
pub const MUSHROOM_LEAP_TILES: i32 = 5;
pub const MUSHROOM_HEARD_TILES: u16 = 4;
/// An updraft vent "lifts anyone one level"; "Half gravity sends people two
/// levels".
pub const UPDRAFT_LEVELS: u8 = 1;
pub const UPDRAFT_LEAP_LEVELS: u8 = 2;
/// A bell post "raises the realm's alarm one level (12.17)".
pub const BELL_LEVELS: i32 = 1;

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
    /// A tile of one of §10.1's buildings: "Buildings sit on the realm grid
    /// and block movement and sight." A structure like the Vault, not a wall
    /// (Thorns, `World::thorns`), and never broken.
    Building,
    /// §10.3's Crystal Wall: a wall until it is broken.
    CrystalWall,
    /// "Blocks; cut through in 3 seconds" / "Blocks sight".
    Hedge,
    /// "Walk around" / "Blocks sight in a line".
    Tree,
    /// "Blocks; a Breaker smashes it in about 6 seconds" / "Blocks sight".
    Boulder,
    /// "Blocks one tile" / "Cover for one character".
    Statue,
    /// "Blocks movement" / "See-through; bends light, so lanterns reach 2
    /// tiles further past it".
    CrystalOutcrop,
    /// "Impassable line" / "Glows". Low, so sight passes over it.
    LavaCrack,
    /// "Wading is 20% slower"; water underfoot, so louder (§12.17).
    Stream,
    /// "15% faster" / "Crunchy: louder underfoot (12.17)".
    GravelPath,
    /// "30% slower" / "Hides anyone inside beyond 1 tile".
    Thicket,
    /// "Hides anyone beyond 3 tiles".
    ShadeCanopy,
    /// "Hides one still character completely".
    Bush,
    /// "Heals 2% health a second while standing in it, for both sides" /
    /// "Steam hides anyone inside beyond 2 tiles".
    HotSpring,
    /// "Lights 3 tiles: nothing hides inside the light".
    LanternPost,
    /// "Loose stones" / "Guards within 4 tiles notice 25% faster".
    Scree,
    /// "Bursts of flame every 8 seconds; hurts anyone on it" / "Lights 2
    /// tiles when it bursts".
    EmberVent,
    /// "Zaps anyone within 1 tile every 4 seconds" / "Crackles".
    StaticStone,
    /// "Pass under" / "Blocks sight from above".
    Arch,
    /// "40% slower; footprints stay for 10 seconds".
    Marsh,
    /// "Shows footprints for 10 seconds".
    FlowerMeadow,
    /// "Slippery: stopping takes 1 tile".
    IceSheet,
    /// "Deep: only swimmers cross; everyone else goes round". No crew member
    /// swims yet: a trait is carried in the manifest and not played (§11.3).
    Pond,
    /// "Rings if bumped" / "Raises the realm's alarm one level (12.17)".
    BellPost,
    /// "Floating stones; crossing needs leaps": a road only under a law that
    /// leaps ("Half gravity or a Featherkin makes them a road").
    SteppingStones,
    /// "Launches anyone 3 tiles forward, noisily" / "The landing can be heard
    /// 4 tiles away".
    BounceMushroom,
    /// "Lifts anyone one level; flyers two".
    UpdraftVent,
    /// "Drops anyone to the level below": its floor is one level below the
    /// ground it is dug in.
    Pit,
}

impl Feature {
    pub fn terrain(self) -> Terrain {
        use Feature::*;
        match self {
            RockPillar | RuinWall | Fence | Vault | Pylon | Building | CrystalWall | Hedge | Tree
            | Boulder | Statue | CrystalOutcrop | LavaCrack | Pond | SteppingStones => Terrain::Blocked,
            Stream => Terrain::Pace(STREAM_PACE),
            Marsh => Terrain::Pace(MARSH_PACE),
            GravelPath => Terrain::Pace(GRAVEL_PACE),
            Thicket => Terrain::Pace(THICKET_PACE),
            FogBank | TallGrass | ShadeCanopy | Bush | HotSpring | LanternPost | Scree | EmberVent
            | StaticStone | Arch | FlowerMeadow | IceSheet | BellPost | BounceMushroom
            | UpdraftVent | Pit => Terrain::Open,
        }
    }

    fn blocks_sight(self) -> bool {
        use Feature::*;
        matches!(self, RockPillar | RuinWall | FogBank | Vault | Building | CrystalWall | Hedge
                 | Tree | Boulder | Statue)
    }

    /// The ground a feature is, for noise (§12.17): a stream is water, a
    /// gravel path gravel. `None` leaves the tile's own.
    pub fn surface(self) -> Option<Surface> {
        match self {
            Feature::Stream | Feature::Marsh | Feature::Pond => Some(Surface::Water),
            Feature::GravelPath => Some(Surface::Gravel),
            _ => None,
        }
    }

    /// "Hides anyone inside beyond N tiles": a guard further off than this
    /// cannot see whoever stands on it.
    pub fn hides_beyond(self) -> Option<i32> {
        match self {
            Feature::Thicket => Some(THICKET_HIDES),
            Feature::ShadeCanopy => Some(SHADE_HIDES),
            Feature::HotSpring => Some(STEAM_HIDES),
            _ => None,
        }
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
            heights: vec![0; n],
            climbable: vec![false; n],
            free_climb: false,
            leap: false,
            bridged: vec![false; n],
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
            if let Some(s) = feature.surface() {
                self.surfaces[i as usize] = s;
            }
        }
    }

    /// Take a feature away: the tile is open ground again. A broken Crystal
    /// Wall is the one thing that does this.
    pub fn clear(&mut self, index: TileIndex) {
        let i = index as usize;
        if i < self.tiles.len() {
            self.tiles[i] = Terrain::Open;
            self.sight_blocked[i] = false;
            self.features[i] = None;
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

    pub fn set_height(&mut self, x: u16, y: u16, h: u8) {
        if let Some(i) = self.index(x, y) {
            self.heights[i as usize] = h.min(3);
        }
    }

    pub fn height(&self, index: TileIndex) -> u8 {
        self.heights.get(index as usize).copied().unwrap_or(0)
    }

    /// A ramp, stairs or vines on this tile.
    pub fn make_climbable(&mut self, x: u16, y: u16) {
        if let Some(i) = self.index(x, y) {
            self.climbable[i as usize] = true;
        }
    }

    /// A gap: ground nobody walks onto that is not a wall, so something can
    /// cross it — a pond, a lava crack, stepping stones with no law to leap
    /// them. A glide crosses one, and roots or a plank bridge one.
    pub fn is_gap(&self, index: TileIndex) -> bool {
        match self.feature(index) {
            Some(Feature::Pond) | Some(Feature::LavaCrack) => true,
            Some(Feature::SteppingStones) => !self.leap,
            _ => false,
        }
    }

    /// Whether a tile can be stood on: open ground, a leapt stone or a bridge.
    pub fn standable(&self, index: TileIndex) -> bool {
        self.at(index).passable() || self.is_bridged(index)
            || (self.leap && self.feature(index) == Some(Feature::SteppingStones))
    }

    pub fn set_bridged(&mut self, index: TileIndex, on: bool) {
        if let Some(b) = self.bridged.get_mut(index as usize) {
            *b = on;
        }
    }

    pub fn is_bridged(&self, index: TileIndex) -> bool {
        self.bridged.get(index as usize).copied().unwrap_or(false)
    }

    /// Whether a ramp, stairs or vines stand on this tile.
    pub fn is_climbable(&self, index: TileIndex) -> bool {
        self.climbable.get(index as usize).copied().unwrap_or(false)
    }

    /// Whether a character may step from `a` to its neighbour `b`. §6.2:
    /// dropping is "free and one-way"; climbing one level needs a ramp,
    /// stairs or vines on either tile, or a law that lets anyone climb; two
    /// levels at once is a cliff.
    pub fn can_step(&self, a: TileIndex, b: TileIndex) -> bool {
        let stones = self.leap && self.feature(b) == Some(Feature::SteppingStones);
        if !self.at(b).passable() && !stones && !self.is_bridged(b) {
            return false;
        }
        let (ha, hb) = (self.level(a), self.level(b));
        if hb <= ha {
            return true;
        }
        // An updraft vent "lifts anyone one level"; under a law that leaps,
        // two.
        if self.feature(a) == Some(Feature::UpdraftVent) {
            let lift = if self.leap { UPDRAFT_LEAP_LEVELS } else { UPDRAFT_LEVELS };
            return hb <= ha + lift as i8;
        }
        hb == ha + 1
            && (self.free_climb
                || self.climbable.get(a as usize).copied().unwrap_or(false)
                || self.climbable.get(b as usize).copied().unwrap_or(false))
    }

    /// The level a character stands at on a tile: its height, one lower in
    /// a pit, whose floor is "the level below" the ground it is dug in.
    pub fn level(&self, index: TileIndex) -> i8 {
        self.height(index) as i8 - (self.feature(index) == Some(Feature::Pit)) as i8
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
