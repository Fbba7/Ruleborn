//! The simulation, inside Godot (§24.7: "written once and compiled for every
//! target it runs on").
//!
//! The client does not draw a recording. It re-simulates the replay with the
//! same crate the server validates with, one tick at a time, and draws the
//! world after each; every second it compares its own checksum with the one
//! the replay carries, so a client that drifted from the server would say so
//! on screen rather than show a different heist (§24.10).

use godot::prelude::*;
use ruleborn_sim as sim;
use sim::fixed::{Ang, Fx, ANG_TURN, FX_ONE};
use sim::island::Island;
use sim::replay::Heist;
use sim::World;

struct Ruleborn;

#[gdextension]
unsafe impl ExtensionLibrary for Ruleborn {}

/// One heist, re-simulated a tick at a time.
#[derive(GodotClass)]
#[class(base = RefCounted, init)]
pub struct RulebornReplay {
    heist: Option<Heist>,
    world: Option<World>,
    /// The realm being played or watched; the fixture when none was given.
    island: Option<Island>,
    /// The first second whose checksum disagreed with the replay's, or 0.
    mismatch: i64,
    /// Seconds whose checksums have been compared and agreed.
    agreed: i64,
}

fn tiles(f: Fx) -> f32 {
    (f.0 as f64 / FX_ONE as f64) as f32
}

fn radians(a: Ang) -> f32 {
    (a.0 as f64 / ANG_TURN as f64 * std::f64::consts::TAU) as f32
}

/// An island from its bundle bytes, or the fixture realm for none.
fn realm_of(bytes: &PackedByteArray) -> Option<Island> {
    if bytes.is_empty() {
        Some(Island::fixture())
    } else {
        Island::decode(bytes.as_slice()).ok()
    }
}

fn hex(bytes: &[u8]) -> GString {
    let s: String = bytes.iter().map(|b| format!("{b:02x}")).collect();
    GString::from(&s)
}

#[godot_api]
impl RulebornReplay {
    /// The rules version this build computes, which a replay's header must name.
    #[func]
    fn rules_version() -> GString {
        hex(&sim::rules_version())
    }

    /// Load a replay onto the realm it was played in. With no island, the
    /// fixture realm the golden replays are recorded on. False if either does
    /// not decode, or the island is not the one the replay names.
    #[func]
    fn load(&mut self, replay: PackedByteArray, island: PackedByteArray) -> bool {
        let Some(heist) = Heist::decode(replay.as_slice()) else { return false };
        let Some(realm) = realm_of(&island) else { return false };
        if !island.is_empty() && realm.digest() != heist.island {
            return false;
        }
        self.world = Some(World::from_island(&realm, &heist));
        self.island = Some(realm);
        self.heist = Some(heist);
        self.mismatch = 0;
        self.agreed = 0;
        true
    }

    /// Start a heist to be played rather than watched: on `island` (a
    /// bundle, as a lease names it; empty for the fixture realm), with this
    /// seed, clock and crew, and no commands yet. Taps become commands
    /// through `give`, and `record` writes the replay the server checks.
    #[func]
    ///
    /// The seed is decimal text: a lease's seed is an unsigned 64-bit number,
    /// and GDScript's integers are signed, so half of all seeds would not
    /// survive the trip as one.
    fn start(&mut self, seed: GString, ticks: i64, crew: i64, island: PackedByteArray) -> bool {
        if !(3..=5).contains(&crew) || ticks <= 0 {
            return false;
        }
        let Ok(seed) = seed.to_string().parse::<u64>() else { return false };
        let Some(realm) = realm_of(&island) else { return false };
        let heist = Heist {
            seed,
            island: realm.digest(),
            rules: sim::rules_version(),
            ticks: ticks as u32,
            crew: crew as u8,
            commands: Vec::new(),
            checksums: Vec::new(),
        };
        self.world = Some(World::from_island(&realm, &heist));
        self.heist = Some(heist);
        self.island = Some(realm);
        self.mismatch = 0;
        self.agreed = 0;
        true
    }

    /// A command, now: `kind` is replay.rs's Kind (0 MoveTo, 1 Gait, 2 Halt,
    /// 3 Crack, 4 Load, 5 Skiff, 6 Attack, 7 Break, 8 Drop, 9 Disarm, 10
    /// Drag), `x` and `y` a tile position at 1/256 of a tile or the kind's
    /// own argument. False if there is no such kind or the clock has run out.
    #[func]
    fn give(&mut self, actor: i64, kind: i64, x: i64, y: i64) -> bool {
        let (Some(world), Some(kind)) = (self.world.as_mut(), sim::replay::Kind::from_u8(kind as u8))
        else {
            return false;
        };
        world.give(actor as u8, kind, x as i16, y as i16)
    }

    /// The heist as played so far, written down as the replay a device queues
    /// (§24.12): the header, the command log and a checksum a second, made by
    /// re-simulating the log from the start.
    #[func]
    fn record(&self) -> PackedByteArray {
        let (Some(world), Some(heist), Some(realm)) =
            (self.world.as_ref(), self.heist.as_ref(), self.island.as_ref())
        else {
            return PackedByteArray::new();
        };
        let bytes = sim::record(realm, heist.seed, heist.ticks, heist.crew,
                                world.commands().to_vec()).encode();
        PackedByteArray::from(bytes.as_slice())
    }

    /// What the server does with a replay (§24.12's Validate), on `island`
    /// (empty for the fixture realm): `{"ok": true, "grade": …}` or
    /// `{"ok": false, "refused": …}`.
    #[func]
    fn validate(replay: PackedByteArray, island: PackedByteArray) -> VarDictionary {
        let mut d = VarDictionary::new();
        let (Some(heist), Some(realm)) = (Heist::decode(replay.as_slice()), realm_of(&island)) else {
            d.set("ok", false);
            d.set("refused", &GString::from("malformed"));
            return d;
        };
        match sim::verify_on(&realm, &heist) {
            Ok(o) => {
                d.set("ok", true);
                d.set("grade", &GString::from(&format!("{:?}", o.grade)));
                d.set("banked", o.banked);
            }
            Err(r) => {
                d.set("ok", false);
                d.set("refused", &GString::from(&format!("{r:?}")));
            }
        }
        d
    }

    /// One tick. False once the heist's clock has run out.
    #[func]
    fn step(&mut self) -> bool {
        let (Some(world), Some(heist)) = (self.world.as_mut(), self.heist.as_ref()) else {
            return false;
        };
        if world.tick >= heist.ticks {
            return false;
        }
        let sum = world.step();
        if world.tick % sim::TICKS_PER_SECOND == 0 {
            let second = (world.tick / sim::TICKS_PER_SECOND) as usize;
            match heist.checksums.get(second - 1) {
                Some(&kept) if kept == sim::truncate(sum) => self.agreed += 1,
                Some(_) if self.mismatch == 0 => self.mismatch = second as i64,
                _ => {}
            }
        }
        true
    }

    /// The rules version the loaded replay's header names.
    #[func]
    fn rules(&self) -> GString {
        self.heist.as_ref().map_or(GString::new(), |h| hex(&h.rules))
    }

    /// The command log so far, one dictionary a command: tick, actor, kind
    /// (replay.rs's number), x, y.
    #[func]
    fn commands(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some(w) = self.world.as_ref() else { return out };
        for c in w.commands() {
            let mut d = VarDictionary::new();
            d.set("tick", c.tick as i64);
            d.set("actor", c.actor as i64);
            d.set("kind", c.kind as u8 as i64);
            d.set("x", c.x as i64);
            d.set("y", c.y as i64);
            out.push(&d);
        }
        out
    }

    /// The loaded or started heist's seed, as decimal text (see `start`), and
    /// its crew size.
    #[func]
    fn seed(&self) -> GString {
        self.heist.as_ref().map_or(GString::new(), |h| GString::from(&h.seed.to_string()))
    }

    #[func]
    fn crew_size(&self) -> i64 {
        self.heist.as_ref().map_or(0, |h| h.crew as i64)
    }

    #[func]
    fn tick(&self) -> i64 {
        self.world.as_ref().map_or(0, |w| w.tick as i64)
    }

    #[func]
    fn ticks(&self) -> i64 {
        self.heist.as_ref().map_or(0, |h| h.ticks as i64)
    }

    #[func]
    fn ticks_per_second() -> i64 {
        sim::TICKS_PER_SECOND as i64
    }

    /// The first second the re-simulation and the replay disagree, or 0.
    #[func]
    fn mismatch(&self) -> i64 {
        self.mismatch
    }

    #[func]
    fn seconds_agreed(&self) -> i64 {
        self.agreed
    }

    #[func]
    fn size(&self) -> Vector2i {
        self.world.as_ref().map_or(Vector2i::ZERO, |w| {
            Vector2i::new(w.grid.width as i32, w.grid.height as i32)
        })
    }

    /// Each tile, row by row: 0 for open ground, 1 + the feature's code
    /// otherwise, in `sim::grid::Feature`'s order.
    #[func]
    fn features(&self) -> PackedByteArray {
        let Some(w) = self.world.as_ref() else { return PackedByteArray::new() };
        (0..w.grid.len())
            .map(|i| w.grid.feature(i as _).map_or(0, |f| f as u8 + 1))
            .collect()
    }

    /// Each tile's height in levels, row by row.
    #[func]
    fn heights(&self) -> PackedByteArray {
        let Some(w) = self.world.as_ref() else { return PackedByteArray::new() };
        (0..w.grid.len()).map(|i| w.grid.height(i as _)).collect()
    }

    #[func]
    fn crew(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some(w) = self.world.as_ref() else { return out };
        for r in &w.raiders {
            let mut d = VarDictionary::new();
            d.set("at", Vector2::new(tiles(r.at.x), tiles(r.at.y)));
            d.set("role", &GString::from(&format!("{:?}", r.role)));
            d.set("carried", r.carried);
            d.set("carry", r.role.carry());
            d.set("health", r.health);
            d.set("standing", &GString::from(&format!("{:?}", r.standing)));
            d.set("gait", &GString::from(&format!("{:?}", r.gait)));
            out.push(&d);
        }
        out
    }

    #[func]
    fn guards(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some(w) = self.world.as_ref() else { return out };
        for g in &w.guards {
            let mut d = VarDictionary::new();
            d.set("at", Vector2::new(tiles(g.at.x), tiles(g.at.y)));
            d.set("facing", radians(g.facing));
            d.set("cone", radians(g.cone));
            d.set("far", tiles(g.far));
            d.set("state", &GString::from(&format!("{:?}", g.state)));
            d.set("down", g.knocked_out);
            out.push(&d);
        }
        out
    }

    /// §10.3's wards on the island: kind, tile, and whether it still acts.
    #[func]
    fn wards(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some(w) = self.world.as_ref() else { return out };
        for ward in &w.wards {
            let mut d = VarDictionary::new();
            let (x, y) = w.grid.centre(ward.tile);
            d.set("at", Vector2::new(tiles(x), tiles(y)));
            d.set("kind", &GString::from(&format!("{:?}", ward.kind)));
            d.set("live", ward.live());
            out.push(&d);
        }
        out
    }

    /// The Vault's tile, its health and what is left to load.
    #[func]
    fn vault(&self) -> VarDictionary {
        let mut d = VarDictionary::new();
        if let Some(w) = self.world.as_ref() {
            let (x, y) = w.grid.centre(w.vault.tile);
            d.set("at", Vector2::new(tiles(x), tiles(y)));
            d.set("health", w.vault.health);
            d.set("exposed", w.vault.exposed);
            d.set("open", w.vault.opened_at.is_some());
        }
        d
    }

    /// The tiles guard `index`'s cone reaches, by `World::seen_tiles` — the
    /// simulation's own sight rule, so what is drawn is what is decided.
    #[func]
    fn seen(&self, index: i64) -> PackedInt32Array {
        let Some(w) = self.world.as_ref() else { return PackedInt32Array::new() };
        if index < 0 {
            return PackedInt32Array::new();
        }
        w.seen_tiles(index as usize).into_iter().map(|t| t as i32).collect()
    }

    #[func]
    fn alarm(&self) -> i64 {
        self.world.as_ref().map_or(0, |w| w.alarm as i64)
    }

    /// What the heist came to (§12.9), as the re-simulation reads it.
    #[func]
    fn outcome(&self) -> VarDictionary {
        let mut d = VarDictionary::new();
        if let Some(w) = self.world.as_ref() {
            let o = w.outcome();
            d.set("grade", &GString::from(&format!("{:?}", o.grade)));
            d.set("banked", o.banked);
            d.set("capacity", o.capacity);
            d.set("caught", o.caught as i64);
            d.set("out", o.out as i64);
        }
        d
    }
}
