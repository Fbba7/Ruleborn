//! The simulation, inside Godot (§24.7: "written once and compiled for every
//! target it runs on").
//!
//! The client does not draw a recording. It re-simulates the replay with the
//! same crate the server validates with, one tick at a time, and draws the
//! world after each; every second it compares its own checksum with the one
//! the replay carries, so a client that drifted from the server would say so
//! on screen rather than show a different heist (§24.10).

mod island;
#[cfg(test)]
mod tests;

use godot::prelude::*;
use ruleborn_sim as sim;
use sim::fixed::{Ang, Fx, ANG_TURN, FX_ONE};
use sim::island::Island;
use sim::replay::Heist;
use sim::universe::{Crossing, Universe, FAULT_ENTRY};
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
    /// §18.3's era the next `start` plays in, as the lease named it.
    era: Option<sim::era::Era>,
    /// A heist across a universe (§5.4): the universe and its islands, the
    /// realm a landing now would be in and whether at its fault, and, once
    /// the crew has landed, the crossing. Until then `world` is the realm
    /// on show in the landing picker.
    universe: Option<(Universe, Vec<Island>)>,
    entry: (usize, bool),
    crossing: Option<Crossing>,
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

/// Whether a replay from elsewhere — the server's copy of a heist, which it
/// keeps before it has checked it — is one the simulation would play: the
/// crew and the clock inside what `verified` allows. A crew past eight
/// overflows the out mask, which aborts the app, and a clock of billions of
/// ticks never ends its stepping (the security review's SR-08).
fn playable(heist: &Heist) -> bool {
    (3..=5).contains(&heist.crew)
        && (sim::MIN_TICKS..=sim::MAX_TICKS + sim::era::extra_ticks(heist.era)).contains(&heist.ticks)
}

/// A recorded replay, or none past the limit the server reads (SIM-2): the
/// server refuses a replay over `MAX_HEIST_BYTES` unread.
fn under_limit(bytes: Vec<u8>) -> Vec<u8> {
    if bytes.len() > sim::replay::MAX_HEIST_BYTES { Vec::new() } else { bytes }
}

fn hex(bytes: &[u8]) -> GString {
    let s: String = bytes.iter().map(|b| format!("{b:02x}")).collect();
    GString::from(&s)
}

impl RulebornReplay {
    /// The world on show: the crossing's realm once a heist across a
    /// universe has landed, else the one world.
    fn w(&self) -> Option<&World> {
        self.crossing.as_ref().map(|c| &c.world).or(self.world.as_ref())
    }

    fn w_mut(&mut self) -> Option<&mut World> {
        match self.crossing.as_mut() {
            Some(c) => Some(&mut c.world),
            None => self.world.as_mut(),
        }
    }

    /// The island of the realm on show.
    fn realm(&self) -> Option<&Island> {
        self.crossing.as_ref().map(|c| c.island_now()).or(self.island.as_ref())
    }

    /// One heist's checksum for the second just ended, against the replay's.
    fn compare(&mut self, tick: u32, sum: u64) {
        let Some(heist) = self.heist.as_ref() else { return };
        if tick % sim::TICKS_PER_SECOND == 0 {
            let second = (tick / sim::TICKS_PER_SECOND) as usize;
            match heist.checksums.get(second - 1) {
                Some(&kept) if kept == sim::truncate(sum) => self.agreed += 1,
                Some(_) if self.mismatch == 0 => self.mismatch = second as i64,
                _ => {}
            }
        }
    }

    /// `record`'s bytes, outside Godot's types so a cargo test can read
    /// them; empty when there is nothing to record.
    fn recorded(&self) -> Vec<u8> {
        if let (Some(c), Some((u, islands)), Some(heist)) =
            (self.crossing.as_ref(), self.universe.as_ref(), self.heist.as_ref())
        {
            let Ok(h) = sim::universe::record_universe(u, islands, heist.seed, heist.ticks, heist.crew, heist.era,
                                                       heist.manifest.clone(), c.commands().to_vec())
            else {
                return Vec::new();
            };
            return under_limit(h.encode());
        }
        let (Some(world), Some(heist), Some(realm)) =
            (self.w(), self.heist.as_ref(), self.realm())
        else {
            return Vec::new();
        };
        under_limit(sim::record_with(realm, heist.seed, heist.ticks, heist.crew, heist.era,
                                     heist.manifest.clone(), world.commands().to_vec()).encode())
    }

    /// Whether one more command, given now, leaves the replay inside the
    /// limit the server reads (`MAX_HEIST_BYTES`): the log so far and this
    /// command as the recorder keeps them, with a checksum a second.
    fn room_for(&self, command: sim::replay::Command) -> bool {
        let (Some(heist), Some(world)) = (self.heist.as_ref(), self.w()) else { return false };
        let log = self.crossing.as_ref().map_or(world.commands(), |c| c.commands());
        let commands = log.iter().copied().chain([command]).filter(|c| c.actor < 16).collect();
        let checksums = vec![0; (heist.ticks / sim::TICKS_PER_SECOND) as usize];
        Heist { commands, checksums, ..heist.clone() }.encode().len() <= sim::replay::MAX_HEIST_BYTES
    }
}

#[godot_api]
impl RulebornReplay {
    /// The rules version this build computes, which a replay's header must name.
    #[func]
    fn rules_version() -> GString {
        hex(&sim::rules_version())
    }

    /// §11.1's numbers for each role as the simulation plays them, keyed by
    /// the role's name: `{"health", "speed" (tiles a second), "power",
    /// "carry"}`. The Character screen's Stats tab shows these.
    #[func]
    fn role_numbers() -> VarDictionary {
        let mut out = VarDictionary::new();
        for role in [sim::Role::Scout, sim::Role::Warden, sim::Role::Breaker, sim::Role::Carrier, sim::Role::Mender] {
            let mut d = VarDictionary::new();
            d.set("health", role.health() as i64);
            d.set("speed", role.speed_tenths() as f64 / 10.0);
            d.set("power", role.power() as i64);
            d.set("carry", role.carry() as i64);
            out.set(&GString::from(&format!("{role:?}")), &d);
        }
        out
    }

    /// Load a replay onto the realm it was played in. With no island, the
    /// fixture realm the golden replays are recorded on. False if either does
    /// not decode, the replay is not one the simulation plays (`playable`),
    /// or the realm is not the one the replay names: with no island too, so a
    /// heist played elsewhere is never shown on the fixture realm (RB-43).
    #[func]
    fn load(&mut self, replay: PackedByteArray, island: PackedByteArray) -> bool {
        let Some(heist) = Heist::decode(replay.as_slice()) else { return false };
        if !playable(&heist) {
            return false;
        }
        let Some(realm) = realm_of(&island) else { return false };
        if realm.digest() != heist.island {
            return false;
        }
        self.world = Some(World::from_island(&realm, &heist));
        self.island = Some(realm);
        self.heist = Some(heist);
        self.universe = None;
        self.crossing = None;
        self.mismatch = 0;
        self.agreed = 0;
        true
    }

    /// The era the next heist is played in (§18.3), by its content id as a
    /// lease names it; empty for none. False for an id that is not an era.
    #[func]
    fn set_era(&mut self, id: GString) -> bool {
        let id = id.to_string();
        if id.is_empty() {
            self.era = None;
            return true;
        }
        match sim::era::Era::from_id(&id) {
            Some(era) => {
                self.era = Some(era);
                true
            }
            None => false,
        }
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
        self.start_planned(seed, ticks, crew, PackedByteArray::new(), island)
    }

    /// `start`, with the planner's crew (§12.5): `manifest` is the replay's
    /// own wire form of it — each member's kind, form, level and traits, the
    /// Sage and the casts — which the replay then carries (`RBH3`) and the
    /// server checks against the roster. Empty plays the crew by role. False
    /// if it does not read for `crew` members.
    #[func]
    fn start_planned(&mut self, seed: GString, ticks: i64, crew: i64, manifest: PackedByteArray,
                     island: PackedByteArray) -> bool {
        if !(3..=5).contains(&crew) || ticks <= 0 {
            return false;
        }
        // CLI-23: a clock past u32 is refused, not wrapped onto another.
        let Ok(ticks) = u32::try_from(ticks) else { return false };
        let manifest = if manifest.is_empty() {
            None
        } else {
            let mut at = 0usize;
            match sim::replay::Manifest::read(manifest.as_slice(), &mut at, crew as u8) {
                Some(m) if at == manifest.len() => Some(m),
                _ => return false,
            }
        };
        let Ok(seed) = seed.to_string().parse::<u64>() else { return false };
        let Some(realm) = realm_of(&island) else { return false };
        let heist = Heist {
            seed,
            island: realm.digest(),
            rules: sim::rules_version(),
            ticks,
            crew: crew as u8,
            era: self.era,
            // §12.5: the planner's crew, or by role when there is none.
            manifest,
            commands: Vec::new(),
            checksums: Vec::new(),
        };
        self.world = Some(World::from_island(&realm, &heist));
        self.heist = Some(heist);
        self.island = Some(realm);
        self.universe = None;
        self.crossing = None;
        self.mismatch = 0;
        self.agreed = 0;
        true
    }

    /// Start a heist across a universe (§5.4): `universe` its `RBU1` bundle
    /// and `islands` its realms' islands in its order, as the lease names
    /// them, with this seed and crew and the planner's manifest (empty for
    /// none). Nothing is landed yet: `preview` shows a realm for the landing
    /// picker, and the landing (`give` of Land at tick 0) lands there. False
    /// if anything does not decode or the islands are not the universe's.
    #[func]
    fn start_universe(&mut self, seed: GString, crew: i64, manifest: PackedByteArray, universe: PackedByteArray,
                      islands: Array<PackedByteArray>) -> bool {
        let Some(u) = Universe::decode(universe.as_slice()) else { return false };
        let realms: Vec<Island> = islands.iter_shared().filter_map(|b| Island::decode(b.as_slice()).ok()).collect();
        if realms.len() != u.realms.len() || realms.iter().zip(&u.realms).any(|(i, r)| i.digest() != r.1) {
            return false;
        }
        // The heist header, on the Heart's clock until a realm is previewed.
        if !self.start_planned(seed, sim::universe::clock_ticks(0) as i64, crew, manifest,
                               PackedByteArray::from(realms[0].encode().as_slice())) {
            return false;
        }
        if let Some(h) = self.heist.as_mut() {
            h.island = u.digest();
        }
        self.universe = Some((u, realms));
        self.entry = (0, false);
        true
    }

    /// The universe's realms, in its order: each its code (0 the Heart, k
    /// outer realm k), the links on its shortest route to the Heart (-1 for
    /// none), whether a fault opens from it, and its island's side. Empty
    /// for a heist of one island.
    #[func]
    fn universe_realms(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some((u, islands)) = self.universe.as_ref() else { return out };
        for (place, (code, _)) in u.realms.iter().enumerate() {
            let mut d = VarDictionary::new();
            d.set("code", *code as i64);
            d.set("links", u.route(place).map_or(-1, |r| r.len() as i64 - 1));
            d.set("fault", u.faults.contains(&(place as u8)));
            d.set("side", islands[place].side() as i64);
            out.push(&d);
        }
        out
    }

    /// The landing picker's realm on show: `place`'s island to land on its
    /// edge, or — with `fault` — the Heart, which an entry at `place`'s fault
    /// comes straight into; on a clock of `ticks`, the lease's for that
    /// realm. False before the crew has landed only if there is no such
    /// realm; always false once it has.
    #[func]
    fn preview(&mut self, place: i64, fault: bool, ticks: i64) -> bool {
        if self.crossing.is_some() || ticks <= 0 {
            return false;
        }
        let Some((u, islands)) = self.universe.as_ref() else { return false };
        let place = place as usize;
        if place == 0 || place >= islands.len() || (fault && !u.faults.contains(&(place as u8))) {
            return false;
        }
        let shown = islands[if fault { 0 } else { place }].clone();
        let Ok(ticks) = u32::try_from(ticks) else { return false };
        let Some(heist) = self.heist.as_mut() else { return false };
        heist.ticks = ticks;
        self.world = Some(World::from_island(&shown, heist));
        self.island = Some(shown);
        self.entry = (place, fault);
        true
    }

    /// The realm the crew is in, by its code (0 the Heart, k outer realm
    /// k), and the realms still on its route to the Heart after it; -1 and
    /// 0 for a heist of one island or before the crew has landed.
    #[func]
    fn realm_code(&self) -> i64 {
        match (self.crossing.as_ref(), self.universe.as_ref()) {
            (Some(c), Some((u, _))) => u.realms[c.realm_now()].0 as i64,
            _ => -1,
        }
    }

    #[func]
    fn realms_to_go(&self) -> i64 {
        self.crossing.as_ref().map_or(0, |c| (c.route.len() - 1 - c.leg) as i64)
    }

    /// The realms the crew has been through, by code, in the route's order.
    #[func]
    fn realms_crossed(&self) -> PackedInt32Array {
        match (self.crossing.as_ref(), self.universe.as_ref()) {
            (Some(c), Some((u, _))) => c.route[..=c.leg].iter().map(|&p| u.realms[p].0 as i32).collect(),
            _ => PackedInt32Array::new(),
        }
    }

    /// A command, now: `kind` is replay.rs's Kind (0 MoveTo, 1 Gait, 2 Halt,
    /// 3 Crack, 4 Load, 5 Skiff, 6 Attack, 7 Break, 8 Drop, 9 Disarm, 10
    /// Drag, 11 Land), `x` and `y` a tile position at 1/256 of a tile or the
    /// kind's own argument. False if there is no such kind or the clock has
    /// run out. A landing counts only at tick 0 (§5.4). False too for an
    /// actor the replay cannot carry, a position that is no i16 (CLI-23),
    /// and a command the replay has no room left for (SIM-2): the device
    /// stops taking commands before the replay would pass the limit.
    #[func]
    fn give(&mut self, actor: i64, kind: i64, x: i64, y: i64) -> bool {
        let Some(kind) = u8::try_from(kind).ok().and_then(sim::replay::Kind::from_u8) else { return false };
        let (Ok(x), Ok(y)) = (i16::try_from(x), i16::try_from(y)) else { return false };
        // Across a universe, the landing makes the crossing: in the realm
        // previewed, or at its fault, the Land command's nibble naming it.
        if let (Some((u, islands)), None) = (self.universe.as_ref(), self.crossing.as_ref()) {
            let Some(heist) = self.heist.as_ref() else { return false };
            if kind != sim::replay::Kind::Land {
                return false;
            }
            let (place, fault) = self.entry;
            let actor = place as u8 | if fault { FAULT_ENTRY } else { 0 };
            let land = sim::replay::Command { tick: 0, actor, kind, x, y };
            let header = Heist { commands: vec![land], ..heist.clone() };
            return match Crossing::new(u, islands, &header) {
                Ok(c) => {
                    self.crossing = Some(c);
                    true
                }
                Err(_) => false,
            };
        }
        // The replay packs the actor in four bits (RB-55).
        let Some(actor) = u8::try_from(actor).ok().filter(|&a| a < 16) else { return false };
        let Some(tick) = self.w().map(|w| w.tick) else { return false };
        if !self.room_for(sim::replay::Command { tick, actor, kind, x, y }) {
            return false;
        }
        if let Some(c) = self.crossing.as_mut() {
            return c.give(actor, kind, x, y);
        }
        let Some(world) = self.w_mut() else { return false };
        world.give(actor, kind, x, y)
    }

    /// A rehearsal (§13): the crew of `style` (1 cautious, 2 greedy, 3
    /// fast) against `island` (empty for the fixture realm) with this seed,
    /// clock and crew, as the simulation's own policy plays it. The replay's
    /// bytes, for `load`; empty if the island or style does not read.
    #[func]
    fn rehearse(island: PackedByteArray, style: i64, seed: GString, ticks: i64, crew: i64) -> PackedByteArray {
        let (Some(realm), Some(style), Ok(seed)) = (realm_of(&island),
            sim::reference::Style::from_u8(style.clamp(0, 255) as u8), seed.to_string().parse::<u64>())
        else {
            return PackedByteArray::new();
        };
        let heist = sim::reference::rehearse(&realm, seed, ticks.clamp(1, 18_000) as u32, crew.clamp(3, 5) as u8,
                                             style);
        PackedByteArray::from(heist.encode().as_slice())
    }

    /// The heist as played so far, written down as the replay a device queues
    /// (§24.12): the header, the command log and a checksum a second, made by
    /// re-simulating the log from the start.
    #[func]
    fn record(&self) -> PackedByteArray {
        PackedByteArray::from(self.recorded().as_slice())
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

    /// One tick. False once the heist's clock has run out, and across a
    /// universe before the crew has landed.
    #[func]
    fn step(&mut self) -> bool {
        let Some(ticks) = self.heist.as_ref().map(|h| h.ticks) else { return false };
        if self.universe.is_some() {
            let Some(c) = self.crossing.as_mut() else { return false };
            if c.world.tick >= ticks {
                return false;
            }
            let sum = c.step();
            let tick = c.world.tick;
            self.compare(tick, sum);
            return true;
        }
        let Some(world) = self.world.as_mut() else { return false };
        if world.tick >= ticks {
            return false;
        }
        let sum = world.step();
        let tick = world.tick;
        self.compare(tick, sum);
        true
    }

    /// `validate` for a heist across a universe: its bundle and islands as
    /// `start_universe` takes them.
    #[func]
    fn validate_universe(replay: PackedByteArray, universe: PackedByteArray,
                         islands: Array<PackedByteArray>) -> VarDictionary {
        let mut d = VarDictionary::new();
        let realms: Vec<Island> = islands.iter_shared().filter_map(|b| Island::decode(b.as_slice()).ok()).collect();
        let (Some(heist), Some(u)) = (Heist::decode(replay.as_slice()), Universe::decode(universe.as_slice())) else {
            d.set("ok", false);
            d.set("refused", &GString::from("malformed"));
            return d;
        };
        match sim::universe::verify_universe(&u, &realms, &heist) {
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
        let log = match (self.crossing.as_ref(), self.w()) {
            (Some(c), _) => c.commands(),
            (None, Some(w)) => w.commands(),
            _ => return out,
        };
        for c in log {
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
        self.w().map_or(0, |w| w.tick as i64)
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
        self.w().map_or(Vector2i::ZERO, |w| {
            Vector2i::new(w.grid.width as i32, w.grid.height as i32)
        })
    }

    /// Each tile, row by row: 0 for open ground, 1 + the feature's code
    /// otherwise, in `sim::grid::Feature`'s order.
    #[func]
    fn features(&self) -> PackedByteArray {
        let Some(w) = self.w() else { return PackedByteArray::new() };
        (0..w.grid.len())
            .map(|i| w.grid.feature(i as _).map_or(0, |f| f as u8 + 1))
            .collect()
    }

    /// The way each tile's directional feature faces, row by row: 0 north,
    /// 1 east, 2 south, 3 west, and 255 where nothing faces (G56).
    #[func]
    fn facings(&self) -> PackedByteArray {
        let Some(w) = self.w() else { return PackedByteArray::new() };
        (0..w.grid.len())
            .map(|i| match w.grid.feature(i as _) {
                Some(f) if f.directional() => w.grid.facing(i as _),
                _ => 255,
            })
            .collect()
    }

    /// The tiles a Glass golem's crystal wall stands on this tick (§11.11).
    #[func]
    fn walls(&self) -> Array<Vector2i> {
        let mut out = Array::new();
        let Some(w) = self.w() else { return out };
        for i in 0..w.grid.len() {
            if w.grid.is_raised(i as _) {
                let (x, y) = w.grid.coords(i as _);
                out.push(Vector2i::new(x as i32, y as i32));
            }
        }
        out
    }

    /// §6.2's tunnels, each its two mouths as tiles, the lower first.
    #[func]
    fn tunnels(&self) -> Array<Vector2i> {
        let mut out = Array::new();
        let Some(w) = self.w() else { return out };
        for i in 0..w.grid.len() {
            if let Some(far) = w.grid.tunnel_exit(i as _).filter(|&f| f as usize > i) {
                let ((ax, ay), (bx, by)) = (w.grid.coords(i as _), w.grid.coords(far));
                out.push(Vector2i::new(ax as i32, ay as i32));
                out.push(Vector2i::new(bx as i32, by as i32));
            }
        }
        out
    }

    /// Each tile's surface, row by row: 0 plain, 1 gravel, 2 water, 3 moss,
    /// in `sim::grid::Surface`'s order.
    #[func]
    fn surfaces(&self) -> PackedByteArray {
        let Some(w) = self.w() else { return PackedByteArray::new() };
        (0..w.grid.len()).map(|i| w.grid.surface(i as _) as u8).collect()
    }

    /// Each tile's height in levels, row by row.
    #[func]
    fn heights(&self) -> PackedByteArray {
        let Some(w) = self.w() else { return PackedByteArray::new() };
        (0..w.grid.len()).map(|i| w.grid.height(i as _)).collect()
    }

    /// §5.4's landing spots on the heist's island: every open edge tile, in
    /// row order. What a landing picker offers.
    #[func]
    fn landings(&self) -> Array<Vector2i> {
        let mut out = Array::new();
        let Some(realm) = self.realm() else { return out };
        for (x, y) in realm.landings() {
            out.push(Vector2i::new(x as i32, y as i32));
        }
        out
    }

    /// §5.4's landing picker: each open edge tile with whether a landing
    /// there goes unheard, read from the terrain alone (`landing_covered`),
    /// so the mark is the same whatever guards and wards the island places.
    #[func]
    fn landing_marks(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some(realm) = self.realm() else { return out };
        for (x, y) in realm.landings() {
            let mut d = VarDictionary::new();
            d.set("at", Vector2i::new(x as i32, y as i32));
            d.set("covered", realm.landing_covered(x, y));
            out.push(&d);
        }
        out
    }

    /// §5.4: how many walked tiles a landing is heard across, a law's noise
    /// radius stretching the six (`World::landing_reach`).
    #[func]
    fn landing_reach(&self) -> i64 {
        self.w().map_or(sim::heist::LANDING_HEARD_TILES as i64, |w| w.landing_reach() as i64)
    }

    /// The landings from which the crew can walk to the Vault: what a
    /// default landing chooses from (`Island::reaching`).
    #[func]
    fn reaching(&self) -> Array<Vector2i> {
        let mut out = Array::new();
        let Some(realm) = self.realm() else { return out };
        for (x, y) in realm.reaching() {
            out.push(Vector2i::new(x as i32, y as i32));
        }
        out
    }

    /// Whether the crew is on the island yet: it has landed, or the heist
    /// is past its first tick. Before that the crew stands nowhere a raider
    /// would meet it, so nothing should draw it.
    #[func]
    fn has_landed(&self) -> bool {
        self.w().is_some_and(|w| w.landing.is_some() || w.tick > 0)
    }

    #[func]
    fn crew(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some(w) = self.w() else { return out };
        for r in &w.raiders {
            let mut d = VarDictionary::new();
            d.set("at", Vector2::new(tiles(r.at.x), tiles(r.at.y)));
            d.set("role", &GString::from(&format!("{:?}", r.role)));
            d.set("carried", r.carried);
            d.set("carry", r.role.carry());
            d.set("health", r.health);
            d.set("standing", &GString::from(&format!("{:?}", r.standing)));
            d.set("gait", &GString::from(&format!("{:?}", r.gait)));
            // §21.8's portrait: its kind (§12.5's manifest) and ability uses left.
            let kind = r.kind.and_then(|k| sim::ruleborn::RULEBORN.get(k as usize)).map_or("", |k| k.id);
            d.set("kind", &GString::from(kind));
            d.set("uses", r.uses as i64);
            d.set("ready", r.ready);
            out.push(&d);
        }
        out
    }

    #[func]
    fn guards(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some(w) = self.w() else { return out };
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
        let Some(w) = self.w() else { return out };
        for ward in &w.wards {
            let mut d = VarDictionary::new();
            let (x, y) = w.grid.centre(ward.tile);
            d.set("at", Vector2::new(tiles(x), tiles(y)));
            d.set("kind", &GString::from(&format!("{:?}", ward.kind)));
            // Its level, which the kit draws (§21.5: a level-2 ward's gold inlay).
            d.set("level", ward.level as i64);
            d.set("live", ward.live());
            out.push(&d);
        }
        out
    }

    /// Each woven law's pylon: where it stands, whether it is still up (§7.1:
    /// breaking the pylon ends the law), its law's id and its school.
    #[func]
    fn pylons(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some(w) = self.w() else { return out };
        for law in &w.laws {
            let mut d = VarDictionary::new();
            let (x, y) = w.grid.centre(law.pylon);
            d.set("at", Vector2::new(tiles(x), tiles(y)));
            d.set("standing", law.broken_at.is_none());
            // The law woven in it and its school (§21.5: a pylon is crowned
            // with its school's shape).
            let def = &sim::laws_table::LAWS[law.def];
            d.set("law", &GString::from(def.id));
            d.set("school", &GString::from(&def.school.to_lowercase()));
            out.push(&d);
        }
        out
    }

    /// The Sage on the heist (§11.7): its id, each power's name and uses left,
    /// and the tick its cooldown ends; empty without one.
    #[func]
    fn sage(&self) -> VarDictionary {
        let mut d = VarDictionary::new();
        let Some(s) = self.w().and_then(|w| w.sage) else { return d };
        let def = &sim::ruleborn::SAGES[s.sage as usize];
        d.set("id", &GString::from(def.id));
        let mut powers = Array::<VarDictionary>::new();
        for (i, (power, _)) in def.powers.iter().enumerate() {
            let mut p = VarDictionary::new();
            p.set("power", &GString::from(&format!("{power:?}")));
            p.set("uses", s.uses[i] as i64);
            powers.push(&p);
        }
        d.set("powers", &powers);
        d.set("cooling_until", s.cooling_until as i64);
        d
    }

    /// The casts the manifest carries (§12.5), by law id, and whether each
    /// has been used.
    #[func]
    fn casts(&self) -> Array<VarDictionary> {
        let mut out = Array::new();
        let Some(w) = self.w() else { return out };
        for (i, row) in w.casts.iter().enumerate() {
            let mut d = VarDictionary::new();
            let law = sim::laws_table::LAWS.get(*row as usize).map_or("", |l| l.id);
            d.set("law", &GString::from(law));
            d.set("used", w.casts_used & (1 << i) != 0);
            out.push(&d);
        }
        out
    }

    /// The Vault's tile, its health and what is left to load.
    #[func]
    fn vault(&self) -> VarDictionary {
        let mut d = VarDictionary::new();
        if let Some(w) = self.w() {
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
        let Some(w) = self.w() else { return PackedInt32Array::new() };
        if index < 0 {
            return PackedInt32Array::new();
        }
        w.seen_tiles(index as usize).into_iter().map(|t| t as i32).collect()
    }

    #[func]
    fn alarm(&self) -> i64 {
        self.w().map_or(0, |w| w.alarm as i64)
    }

    /// §13.2's report of the heist played so far on one island (TD.39), in
    /// the server's shape: `{"held"` seconds, `"alarm"`, `"bells"`, `"seen"`
    /// [{crew, x, y}], `"fired"` [{ward, x, y, times}], `"caught_by"` [{row,
    /// x, y}]}`; empty across a universe or with nothing loaded.
    #[func]
    fn report(&self) -> VarDictionary {
        const WARDS: [&str; 6] = ["crystal_wall", "thorn_hedge", "static_coil", "gravity_well", "time_snare",
                                  "lantern_glare"];
        let mut d = VarDictionary::new();
        let (None, Some(w), Some(realm)) = (self.crossing.as_ref(), self.w(), self.island.as_ref()) else { return d };
        let r = w.report(realm);
        d.set("held", r.held as i64);
        d.set("alarm", r.alarm as i64);
        d.set("bells", r.bells as i64);
        let place = |x: u8, y: u8| {
            let mut e = VarDictionary::new();
            e.set("x", x as i64);
            e.set("y", y as i64);
            e
        };
        let mut seen: Array<VarDictionary> = Array::new();
        for &(c, x, y) in &r.seen {
            let mut e = place(x, y);
            e.set("crew", c as i64);
            seen.push(&e);
        }
        d.set("seen", &seen);
        let mut fired: Array<VarDictionary> = Array::new();
        for &(k, x, y, n) in &r.fired {
            let mut e = place(x, y);
            e.set("ward", WARDS.get(k as usize).copied().unwrap_or(""));
            e.set("times", n as i64);
            fired.push(&e);
        }
        d.set("fired", &fired);
        let mut caught: Array<VarDictionary> = Array::new();
        for &(row, x, y) in &r.caught_by {
            let mut e = place(x, y);
            if row != 255 {
                e.set("row", row as i64);
            }
            caught.push(&e);
        }
        d.set("caught_by", &caught);
        d
    }

    /// What the heist came to (§12.9), as the re-simulation reads it: across
    /// a universe, every realm's.
    #[func]
    fn outcome(&self) -> VarDictionary {
        let mut d = VarDictionary::new();
        let o = match (self.crossing.as_ref(), self.w()) {
            (Some(c), _) => Some(c.outcome()),
            (None, Some(w)) => Some(w.outcome()),
            _ => None,
        };
        if let Some(o) = o {
            d.set("grade", &GString::from(&format!("{:?}", o.grade)));
            d.set("banked", o.banked);
            d.set("capacity", o.capacity);
            d.set("caught", o.caught as i64);
            d.set("out", o.out as i64);
        }
        d
    }
}

/// §5.5's stability, priced by the simulation's one function (TD.14), the
/// same the server charges with: a weave's price on screen is the price
/// paid.
#[derive(GodotClass)]
#[class(base = RefCounted, init)]
pub struct RulebornStability {}

#[godot_api]
impl RulebornStability {
    /// The universe in `sim::stability::decode`'s wire form, priced:
    /// `{"ok", "band", "capacity", "draw", "total", "strain", "chords":
    /// [{"realm", "chord"}], "lines": [{"cost", "micro", "harmonies",
    /// "resonances", "chords", "dissonances", "harmony_notes",
    /// "dissonance_notes"}]}`, or `{"ok": false}` if it does not read. Amounts
    /// are points for showing, and each line's `micro` the simulation's
    /// exact millionths.
    #[func]
    fn price(wire: PackedByteArray) -> VarDictionary {
        let mut d = VarDictionary::new();
        let Some((laws, schools, capacity, era)) = sim::stability::decode(wire.as_slice()) else {
            d.set("ok", false);
            return d;
        };
        let p = sim::stability::price(&laws, &schools, capacity, era);
        let points = |v: u64| v as f64 / sim::stability::POINT as f64;
        d.set("ok", true);
        d.set("band", p.band as i64);
        d.set("capacity", points(p.capacity));
        d.set("draw", points(p.draw));
        d.set("total", points(p.total));
        d.set("total_micro", p.total as i64);
        d.set("strain", points(p.strain));
        let mut chords: Array<VarDictionary> = Array::new();
        for (realm, c) in &p.chords {
            let mut cd = VarDictionary::new();
            cd.set("realm", *realm as i64);
            let row = sim::laws_table::CHORDS.iter().position(|(k, _)| k == c).unwrap_or(0);
            cd.set("chord", &GString::from(sim::laws_table::CHORD_IDS[row]));
            chords.push(&cd);
        }
        d.set("chords", &chords);
        let mut lines: Array<VarDictionary> = Array::new();
        for l in &p.lines {
            let mut ld = VarDictionary::new();
            ld.set("cost", points(l.cost));
            ld.set("micro", l.cost as i64);
            ld.set("harmonies", l.harmonies as i64);
            ld.set("resonances", l.resonances as i64);
            ld.set("chords", l.chords as i64);
            ld.set("dissonances", l.dissonances as i64);
            ld.set("harmony_notes", l.harmony_notes as i64);
            ld.set("dissonance_notes", l.dissonance_notes as i64);
            lines.push(&ld);
        }
        d.set("lines", &lines);
        d
    }

    /// The simulation's laws, in the rows the wire names them by.
    #[func]
    fn law_ids() -> PackedStringArray {
        sim::laws_table::LAWS.iter().map(|l| GString::from(l.id)).collect()
    }
}
