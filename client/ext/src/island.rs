//! An island being built, for the builder screen: `sim::island::Island` and
//! its own editing methods, so the client never writes the bundle format or
//! the publishing rules a second time. What an edit may make is the
//! simulation's to say (`check`); the builder shows it.

use godot::prelude::*;
use ruleborn_sim as sim;
use sim::combos::Combos;
use sim::grid::{Feature, Surface};
use sim::heist::WardKind;
use sim::island::{Island, Occupant, FEATURE_CODES, GUARD_POSTS, LAW_SLOTS, WARD_LIMITS};
use sim::laws_table::{note, CHORDS, CHORD_IDS, LAWS, RESONANCES, RES_IDS};

/// §6.2's ground the simulation models, by content id (content/terrain.json):
/// every feature in the island's codes (`sim::island::FEATURE_CODES`), in
/// their order, and raised ground. A feature not in the simulation yet is not
/// offered.
pub const GROUND: [&str; 22] = [
    "rock_pillar", "ruin_wall", "fence", "fog_bank", "tall_grass", "stream", "bush", "hedge",
    "tree", "thicket", "boulder", "gravel_path", "scree", "crystal_outcrop", "lantern_post",
    "shade_canopy", "ember_vent", "lava_crack", "static_stone", "statue", "hot_spring",
    "raised_ground",
];

/// §10.3's wards, by content id (content/wards.json).
pub const WARDS: [(&str, WardKind); 6] = [
    ("crystal_wall", WardKind::CrystalWall),
    ("thorn_hedge", WardKind::ThornHedge),
    ("static_coil", WardKind::StaticCoil),
    ("gravity_well", WardKind::GravityWell),
    ("time_snare", WardKind::TimeSnare),
    ("lantern_glare", WardKind::LanternGlare),
];

fn feature(id: &str) -> Option<Feature> {
    FEATURE_CODES.iter().find(|(_, i, _)| *i == id).map(|&(f, _, _)| f)
}

fn feature_id(f: Option<Feature>) -> &'static str {
    f.and_then(|f| FEATURE_CODES.iter().find(|(g, _, _)| *g == f)).map_or("", |&(_, i, _)| i)
}

fn strings(items: impl IntoIterator<Item = impl AsRef<str>>) -> PackedStringArray {
    let mut out = PackedStringArray::new();
    for s in items {
        out.push(&GString::from(s.as_ref()));
    }
    out
}

/// An island, edited in place.
#[derive(GodotClass)]
#[class(base = RefCounted)]
pub struct RulebornIsland {
    island: Island,
}

#[godot_api]
impl IRefCounted for RulebornIsland {
    fn init(_base: Base<RefCounted>) -> Self {
        RulebornIsland { island: Island::blank(3) }
    }
}

#[godot_api]
impl RulebornIsland {
    /// Start again on a blank realm of `level`, 1 to 5 (§5.2).
    #[func]
    fn reset(&mut self, level: i64) {
        self.island = Island::blank(level.clamp(1, 5) as u8);
    }

    /// Take the island a bundle holds. False, and nothing changed, if it
    /// does not decode.
    #[func]
    fn read(&mut self, bytes: PackedByteArray) -> bool {
        match Island::decode(bytes.as_slice()) {
            Ok(island) => {
                self.island = island;
                true
            }
            Err(_) => false,
        }
    }

    /// The island as the bundle §24.8 stores under its own hash.
    #[func]
    fn bytes(&self) -> PackedByteArray {
        PackedByteArray::from(self.island.encode().as_slice())
    }

    #[func]
    fn side(&self) -> i64 {
        self.island.side() as i64
    }

    #[func]
    fn realm_level(&self) -> i64 {
        self.island.realm_level as i64
    }

    /// The ground at a tile, as a `GROUND` id, or "" for bare, plain, level
    /// ground.
    #[func]
    fn ground(&self, x: i64, y: i64) -> GString {
        let Some(t) = self.island.tile(x as u8, y as u8) else { return GString::new() };
        let id = match (t.feature, t.surface, t.height) {
            (Some(f), _, _) => feature_id(Some(f)),
            (None, Surface::Gravel, _) => "gravel_path",
            (None, Surface::Water, _) => "stream",
            (None, _, h) if h > 0 => "raised_ground",
            _ => "",
        };
        GString::from(id)
    }

    /// Lay a `GROUND` id on a tile, replacing the ground that was there;
    /// "" makes it bare, plain and level.
    #[func]
    fn set_ground(&mut self, x: i64, y: i64, id: GString) -> bool {
        let (x, y) = (x as u8, y as u8);
        if self.island.tile(x, y).is_none() {
            return false;
        }
        let id = id.to_string();
        if !id.is_empty() && !GROUND.contains(&id.as_str()) {
            return false;
        }
        let i = &mut self.island;
        let f = feature(&id);
        i.set_feature(x, y, f);
        // A stream is water and a gravel path gravel by themselves; anything
        // else leaves the ground plain.
        i.set_surface(x, y, match f.and_then(|f| f.surface()) {
            Some(s) => s,
            None => Surface::Plain,
        });
        i.set_height(x, y, (id == "raised_ground") as u8);
        true
    }

    /// What stands on a tile: "vault", "pylon:<law>", "ward:<kind>",
    /// "guard:<row>", or "".
    #[func]
    fn occupant(&self, x: i64, y: i64) -> GString {
        let s = match self.island.occupant(x as u8, y as u8) {
            Occupant::None => String::new(),
            Occupant::Vault => "vault".into(),
            Occupant::Pylon(i) => format!("pylon:{}", self.island.laws[i].0),
            Occupant::Ward(i) => {
                let kind = self.island.wards[i].0;
                format!("ward:{}", WARDS.iter().find(|w| w.1 == kind).map_or("", |w| w.0))
            }
            Occupant::Guard(i) => format!("guard:{}", self.island.guards[i].row),
        };
        GString::from(&s)
    }

    #[func]
    fn clear(&mut self, x: i64, y: i64) -> bool {
        self.island.clear(x as u8, y as u8)
    }

    #[func]
    fn place_ward(&mut self, kind: GString, x: i64, y: i64) -> bool {
        let kind = kind.to_string();
        match WARDS.iter().find(|w| w.0 == kind) {
            Some(&(_, k)) => self.island.place_ward(k, x as u8, y as u8),
            None => false,
        }
    }

    /// A guard post of §12.17's role row: 0 Scout, 1 Warden, 2 Breaker, 3
    /// Carrier, 4 Mender.
    #[func]
    fn post_guard(&mut self, row: i64, x: i64, y: i64) -> bool {
        (0..5).contains(&row) && self.island.post_guard(row as u8, x as u8, y as u8)
    }

    #[func]
    fn weave(&mut self, law: GString, x: i64, y: i64) -> bool {
        self.island.weave(&law.to_string(), x as u8, y as u8)
    }

    #[func]
    fn set_vault(&mut self, x: i64, y: i64) -> bool {
        self.island.set_vault(x as u8, y as u8)
    }

    /// The laws woven, by id, in weaving order.
    #[func]
    fn laws(&self) -> PackedStringArray {
        strings(self.island.laws.iter().map(|(id, _, _)| id.as_str()))
    }

    /// How many of each the realm holds and §5.2 allows: {wards, guards,
    /// laws} each as [held, allowed].
    #[func]
    fn budget(&self) -> VarDictionary {
        let level = (self.island.realm_level.clamp(1, 5) - 1) as usize;
        let mut d = VarDictionary::new();
        let pair = |held: usize, allowed: u8| {
            let mut a = VarArray::new();
            a.push(&(held as i64).to_variant());
            a.push(&(allowed as i64).to_variant());
            a
        };
        d.set("wards", &pair(self.island.wards.len(), WARD_LIMITS[level]));
        d.set("guards", &pair(self.island.guards.len(), GUARD_POSTS[level]));
        d.set("laws", &pair(self.island.laws.len(), LAW_SLOTS[level]));
        d
    }

    /// Why it may not be published (`Island::check`), by name; empty when it
    /// may be.
    #[func]
    fn problems(&self) -> PackedStringArray {
        strings(self.island.check().iter().map(|p| format!("{p:?}")))
    }

    /// What its laws make together (§8), by content id: {harmonies,
    /// dissonances, resonances, chords}, a dissonance as its first note.
    #[func]
    fn combos(&self) -> VarDictionary {
        let rows: Vec<usize> = self.island.laws.iter()
            .filter_map(|(id, _, _)| LAWS.iter().position(|l| l.id == id)).collect();
        let c = Combos::of(&rows);
        let notes = (0..8).filter(|b| c.harmony(1 << b)).map(|b| note::IDS[b]);
        let clashes = note::OPPOSITES.iter().enumerate()
            .filter(|(i, _)| c.dissonances & (1 << i) != 0)
            .map(|(_, &(a, _))| note::IDS[a.trailing_zeros() as usize]);
        let res = RESONANCES.iter().filter(|(r, _, _)| c.resonance(*r))
            .map(|(r, _, _)| RES_IDS[*r as usize]);
        let chords = CHORDS.iter().filter(|(ch, _)| c.chord(*ch)).map(|(ch, _)| CHORD_IDS[*ch as usize]);
        let mut d = VarDictionary::new();
        d.set("harmonies", &strings(notes));
        d.set("dissonances", &strings(clashes));
        d.set("resonances", &strings(res));
        d.set("chords", &strings(chords));
        d
    }

    /// The ground a builder can lay, the wards, and the launch laws (§7.10),
    /// by content id.
    #[func]
    fn palette() -> VarDictionary {
        let mut d = VarDictionary::new();
        d.set("ground", &strings(GROUND));
        d.set("wards", &strings(WARDS.iter().map(|w| w.0)));
        d.set("laws", &strings(LAWS.iter().filter(|l| l.launch).map(|l| l.id)));
        d
    }
}
