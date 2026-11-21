//! A heist across a universe's realms (§5.3, §5.4; D71, T3.3).
//!
//! §5.4: "The crew lands on any edge tile of any outer realm the raider
//! chooses. The Heart is ringed by strong winds, so skiffs can't land
//! there." §12.6 splits a heist into Entry, Crossing, Vault and Escape, and
//! "Crossing a link plays a one-second swoop to the next realm."
//!
//! A universe is a bundle of its own, `RBU1`, addressed by its SHA-256 as an
//! island is: its realms in order, each its code (0 the Heart, k outer realm
//! k) and its island's digest, and its links (§5.3), each its kind and the
//! two realms it joins by their place in that order, a Chute running from
//! the first to the second. A replay of a heist across it names the universe
//! in its header where a one-island replay names the island; the islands
//! travel beside it.
//!
//! The crossing is the harness's (tools/heist_harness/sim.py `_cross`),
//! which the hold tables were measured on: the crew goes realm by realm along
//! the shortest route from its landing realm to the Heart, in links, a Chute
//! only its own way and ties to the realm earlier in the universe's order. In
//! an outer realm the island's Vault is "the way on toward the Heart" (§13.3)
//! and holds no loot; when every crew member still on the realm stands
//! beside it, the crew crosses together and arrives at the next realm's
//! entrance, and that realm's guards, wards and laws begin. Its alarm does
//! not follow: §12.17's alarm is the realm's. A Rift on the route "closes for
//! 30 seconds when an alarm sounds in either realm" — a guard reaching
//! Alerted — and the crew waits for it. The clock is the heist's: one clock
//! across the realms, set in the replay from the landing realm's route, as
//! §5.4's "150 seconds plus 15 seconds for each link" counts it (the
//! server's to hold the replay to). The skiff takes §5.4's 5 seconds to an
//! outer realm and 20 to the Heart, and it comes to the realm the crew is
//! in. What each kind of link does to the crossing's time is not modelled:
//! every crossing is the swoop.
//!
//! The landing names its realm: in a universe's replay, the Land command's
//! crew-member nibble is the landing realm's place in the universe's order,
//! and a landing on the Heart is refused (§5.4's winds).
//!
//! An overloaded universe (§5.5) carries its faults and its flicker in the
//! bundle, as the server read them when it leased the heist. A fault is an
//! entry: §5.4's landing picker offers "Any edge tile of any outer realm, or
//! a fault", and a fault "joins an outer realm to the Heart", so a crew
//! entering at one jumps through the crack straight to the Heart's entrance —
//! the Land command's nibble is 8 and the fault's realm — on the clock of the
//! realm it opens from, counted by links as every landing is. Its laws
//! flicker in every realm the crew is in: at Cracking "each law has a 5%
//! chance every 10 seconds of blinking off for 2 seconds", and at Breaking
//! "laws flicker twice as often", every 5 seconds (G88).

use crate::heist::{self, Outcome, Standing, Task};
use crate::island::Island;
use crate::replay::{Command, Heist, Kind};
use crate::sha256::sha256;
use crate::{grid, guard, Refusal, Report, World, TICKS_PER_SECOND};

pub const MAGIC: [u8; 4] = *b"RBU1";
/// §5.2: a Heart and up to six outer realms.
pub const MAX_REALMS: usize = 7;

/// §5.3's four links, in the order the bundle numbers them.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
#[repr(u8)]
pub enum LinkKind {
    Stone = 0,
    Rope = 1,
    Chute = 2,
    Rift = 3,
}

impl LinkKind {
    pub fn from_u8(v: u8) -> Option<LinkKind> {
        [LinkKind::Stone, LinkKind::Rope, LinkKind::Chute, LinkKind::Rift].get(v as usize).copied()
    }
}

/// §5.4's clock: "150 seconds plus 15 seconds for each link on the
/// shortest route from the landing realm to the Heart, up to 240 seconds"
/// (tools/design_facts.py's HEIST_CLOCK).
pub const HEIST_CLOCK: (u32, u32, u32) = (150, 15, 240);

/// §5.4's clock in ticks for a landing `links` links from the Heart.
pub fn clock_ticks(links: u32) -> u32 {
    HEIST_CLOCK.2.min(HEIST_CLOCK.0 + HEIST_CLOCK.1 * links) * TICKS_PER_SECOND
}

/// A Rift "Closes for 30 seconds when an alarm sounds in either realm".
pub const RIFT_CLOSED_TICKS: u32 = 30 * TICKS_PER_SECOND;

/// §5.5's flicker: a 5% chance for each law, every 10 seconds at Cracking
/// and every 5 at Breaking, of blinking off for 2 seconds.
pub const FLICKER_CHANCE: u64 = 5;
pub const FLICKER_EVERY_TICKS: u32 = 10 * TICKS_PER_SECOND;
pub const FLICKER_TICKS: u32 = 2 * TICKS_PER_SECOND;
/// §5.5: "four faults" at most.
pub const MAX_FAULTS: usize = 4;
/// The Land command's nibble for an entry at a fault: this, and the realm.
pub const FAULT_ENTRY: u8 = 8;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Universe {
    /// Each realm's code (0 the Heart, k outer realm k) and island digest,
    /// in code order.
    pub realms: Vec<(u8, [u8; 32])>,
    /// Each link: its kind and the two realms by their place in `realms`,
    /// a Chute running from the first to the second.
    pub links: Vec<(LinkKind, u8, u8)>,
    /// §5.5's flicker: 0 none, 1 Cracking's, 2 Breaking's twice as often.
    pub flicker: u8,
    /// The outer realms a fault opens from, by place, rising.
    pub faults: Vec<u8>,
}

impl Universe {
    pub fn encode(&self) -> Vec<u8> {
        let mut out = MAGIC.to_vec();
        out.push(self.realms.len() as u8);
        for (code, digest) in &self.realms {
            out.push(*code);
            out.extend_from_slice(digest);
        }
        out.push(self.links.len() as u8);
        for (kind, a, b) in &self.links {
            out.extend_from_slice(&[*kind as u8, *a, *b]);
        }
        out.push(self.flicker);
        out.push(self.faults.len() as u8);
        out.extend_from_slice(&self.faults);
        out
    }

    /// The inverse, refusing anything `encode` would not write: realms in
    /// rising code order with the Heart first and no code twice, links
    /// joining two different realms that exist, each pair once, a flicker of
    /// 0 to 2, up to four faults from outer realms in rising order, and no
    /// bytes after.
    pub fn decode(bytes: &[u8]) -> Option<Universe> {
        let mut at = 0usize;
        let mut take = |n: usize| -> Option<&[u8]> {
            let s = bytes.get(at..at + n)?;
            at += n;
            Some(s)
        };
        if take(4)? != MAGIC {
            return None;
        }
        let n = take(1)?[0] as usize;
        if !(2..=MAX_REALMS).contains(&n) {
            return None;
        }
        let mut realms = Vec::with_capacity(n);
        for _ in 0..n {
            let code = take(1)?[0];
            let mut digest = [0u8; 32];
            digest.copy_from_slice(take(32)?);
            realms.push((code, digest));
        }
        if realms[0].0 != 0 || realms.windows(2).any(|w| w[0].0 >= w[1].0) || realms[n - 1].0 > 6 {
            return None;
        }
        let m = take(1)?[0] as usize;
        let mut links = Vec::with_capacity(m);
        for _ in 0..m {
            let l = take(3)?;
            let kind = LinkKind::from_u8(l[0])?;
            let (a, b) = (l[1], l[2]);
            if a == b || a as usize >= n || b as usize >= n {
                return None;
            }
            if links.iter().any(|&(_, x, y)| (x, y) == (a, b) || (x, y) == (b, a)) {
                return None;
            }
            links.push((kind, a, b));
        }
        let flicker = take(1)?[0];
        if flicker > 2 {
            return None;
        }
        let f = take(1)?[0] as usize;
        let faults = take(f)?.to_vec();
        if f > MAX_FAULTS || faults.iter().any(|&p| p == 0 || p as usize >= n) || faults.windows(2).any(|w| w[0] >= w[1]) {
            return None;
        }
        if at != bytes.len() {
            return None;
        }
        Some(Universe { realms, links, flicker, faults })
    }

    pub fn digest(&self) -> [u8; 32] {
        sha256(&self.encode())
    }

    /// The shortest route in links from realm `from` to the Heart, as the
    /// realms' places in order, `from` first and the Heart last; a Chute
    /// crossed only its own way, ties to the realm earlier in the order.
    /// `None` when none reaches the Heart.
    pub fn route(&self, from: usize) -> Option<Vec<usize>> {
        let n = self.realms.len();
        let mut came: Vec<Option<usize>> = vec![None; n];
        let mut seen = vec![false; n];
        let mut frontier = std::collections::VecDeque::new();
        seen[from] = true;
        frontier.push_back(from);
        while let Some(at) = frontier.pop_front() {
            if at == 0 {
                let mut out = vec![0];
                let mut t = 0;
                while let Some(p) = came[t] {
                    out.push(p);
                    t = p;
                }
                out.reverse();
                return Some(out);
            }
            let mut next: Vec<usize> = self.links.iter().filter_map(|&(kind, a, b)| {
                let (a, b) = (a as usize, b as usize);
                if a == at {
                    Some(b)
                } else if b == at && kind != LinkKind::Chute {
                    Some(a)
                } else {
                    None
                }
            }).collect();
            next.sort_unstable();
            for x in next {
                if !seen[x] {
                    seen[x] = true;
                    came[x] = Some(at);
                    frontier.push_back(x);
                }
            }
        }
        None
    }

    /// The link joining realms `a` and `b`, either way.
    pub fn link(&self, a: usize, b: usize) -> Option<LinkKind> {
        self.links.iter().find(|&&(_, x, y)| (x as usize, y as usize) == (a, b) || (x as usize, y as usize) == (b, a))
            .map(|l| l.0)
    }
}

/// A heist across the realms: the world of the realm the crew is in, the
/// worlds of the realms behind it and ahead of it on its route, and where it
/// goes next.
pub struct Crossing {
    pub universe: Universe,
    islands: Vec<Island>,
    /// The replay's header with no commands: each realm's world is made from
    /// it, so the crew, its manifest, the seed and the clock are the heist's.
    header: Heist,
    /// The realm the crew landed on, by place, and whether it came in at its
    /// fault, straight to the Heart.
    pub landed: usize,
    pub at_fault: bool,
    /// The realms the crew goes through, by place, landing realm first —
    /// the Heart alone for an entry at a fault.
    pub route: Vec<usize>,
    /// How far along `route` the crew is.
    pub leg: usize,
    pub world: World,
    /// The worlds of the realms behind the crew on its route, in order, and
    /// of those ahead it has been in and come back from by the Sage's rift,
    /// the next last.
    pub crossed: Vec<World>,
    pub ahead: Vec<World>,
    commands: Vec<Command>,
    next_command: usize,
    /// When an alarm last sounded in each realm, by place: the last guard
    /// to reach Alerted there (§5.3's Rift, "when an alarm sounds in either
    /// realm"). Kept while the crew is elsewhere, so a Rift link the crew
    /// comes back to is still shut.
    pub alarms: Vec<Option<u32>>,
    /// The Wanderer's rift, once open: its two ends, each a leg of the route
    /// and a tile there, the tick it shuts, and whether the crew has been
    /// away from the end it is at since it opened or came through.
    pub rift: Option<SageRift>,
}

/// The Wanderer's Rift between two realms the crew has been in (§11.7).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SageRift {
    pub ends: [(usize, grid::TileIndex); 2],
    pub until: u32,
    pub armed: bool,
}

impl Crossing {
    /// The heist's crossing, from its universe and islands: refused when the
    /// islands are not the universe's, when the heist never lands at tick 0,
    /// lands on the Heart, lands where no route of links reaches the Heart,
    /// or enters at a fault the universe does not have.
    pub fn new(universe: &Universe, islands: &[Island], heist: &Heist) -> Result<Crossing, Refusal> {
        if islands.len() != universe.realms.len()
            || islands.iter().zip(&universe.realms).any(|(i, r)| i.digest() != r.1)
        {
            return Err(Refusal::Island);
        }
        let land = heist.commands.iter().take_while(|c| c.tick == 0).find(|c| c.kind == Kind::Land)
            .ok_or(Refusal::Landing)?;
        let at_fault = land.actor & FAULT_ENTRY != 0;
        let landed = (land.actor & !FAULT_ENTRY) as usize;
        if landed == 0 || landed >= islands.len() || (at_fault && !universe.faults.contains(&(landed as u8))) {
            return Err(Refusal::Landing);
        }
        // Every landing's clock is counted by links, so a realm a fault
        // opens from still needs a route of them.
        let route = universe.route(landed).ok_or(Refusal::Landing)?;
        let route = if at_fault { vec![0] } else { route };
        let header = Heist { commands: Vec::new(), checksums: Vec::new(), ..heist.clone() };
        let mut world = Self::realm(&islands[route[0]], &header, at_fault, universe.flicker);
        if at_fault {
            // Through the crack to the Heart's entrance, where it lands.
            let entrance = Self::standable_near(&world, world.entrance);
            let (x, y) = world.grid.centre(entrance);
            world.landing = Some(entrance);
            for r in world.raiders.iter_mut() {
                r.at = crate::Point { x, y };
                r.came_from = entrance;
                r.last_tile = Some(entrance);
            }
        }
        Ok(Crossing { universe: universe.clone(), islands: islands.to_vec(), header, landed, at_fault, route, leg: 0,
                      world, crossed: Vec::new(), ahead: Vec::new(), commands: heist.commands.clone(),
                      next_command: 0, alarms: vec![None; universe.realms.len()], rift: None })
    }

    /// One realm's world for the heist: an outer realm's Vault is its way on
    /// and holds nothing, and the skiff comes to it in §5.4's 5 seconds; and
    /// the universe's laws flicker in it (§5.5).
    fn realm(island: &Island, header: &Heist, heart: bool, flicker: u8) -> World {
        let mut world = World::from_island(island, header);
        if !heart {
            world.vault.exposed = 0;
            world.skiff_ticks = heist::SKIFF_OUTER_TICKS;
        }
        world.flicker = flicker;
        world
    }

    /// The links on the shortest route from the realm landed on to the
    /// Heart, which §5.4's clock counts, a fault's realm's as any other's.
    pub fn clock_links(&self) -> u32 {
        self.universe.route(self.landed).map_or(0, |r| r.len() as u32 - 1)
    }

    /// The island of the realm the crew is in.
    pub fn island_now(&self) -> &Island {
        &self.islands[self.realm_now()]
    }

    /// The realm the crew is in, by place in the universe's order.
    pub fn realm_now(&self) -> usize {
        self.route[self.leg]
    }

    /// Whether the crew has reached the Heart.
    pub fn at_heart(&self) -> bool {
        self.leg + 1 == self.route.len()
    }

    /// A command given now, to the realm the crew is in, as `World::give`.
    pub fn give(&mut self, actor: u8, kind: Kind, x: i16, y: i16) -> bool {
        if self.world.tick >= self.world.clock {
            return false;
        }
        self.commands.push(Command { tick: self.world.tick, actor, kind, x, y });
        true
    }

    /// The input log so far, the landing naming its realm.
    pub fn commands(&self) -> &[Command] {
        &self.commands
    }

    /// A tick: the commands given at it to the realm the crew is in, the
    /// realm's world stepped, and the crew through the Sage's rift or on to
    /// the next realm if it is ready. The checksum is the world's with the
    /// realm the crew is in folded into the bits a replay keeps (`truncate`),
    /// so two machines that disagree on where the crew is part company at
    /// once.
    pub fn step(&mut self) -> u64 {
        let now = self.world.tick;
        while let Some(&c) = self.commands.get(self.next_command) {
            if c.tick > now {
                break;
            }
            self.next_command += 1;
            if c.tick == now {
                // The landing's nibble is its realm; to the world it is the
                // crew's one landing. An entry at a fault has landed already.
                if c.kind == Kind::Land && self.at_fault {
                    continue;
                }
                let actor = if c.kind == Kind::Land { 0 } else { c.actor };
                self.world.give(actor, c.kind, c.x, c.y);
            }
        }
        let logged = self.world.log.events.len();
        let sum = self.world.step();
        if let Some(&(t, _)) = self.world.log.events[logged..].iter().rev()
            .find(|(_, e)| matches!(e, crate::events::Event::Guard { to: guard::State::Alerted, .. }))
        {
            let here = self.realm_now();
            self.alarms[here] = Some(t);
        }
        self.open_rift();
        if !self.through_rift() {
            self.cross();
        }
        sum ^ ((self.realm_now() as u64) << 24)
    }

    /// The world of leg `leg` of the route, if the crew has been there.
    fn world_of(&self, leg: usize) -> Option<&World> {
        if leg < self.leg {
            self.crossed.get(leg)
        } else if leg == self.leg {
            Some(&self.world)
        } else {
            self.ahead.len().checked_sub(leg - self.leg).and_then(|i| self.ahead.get(i))
        }
    }

    /// Whether every crew member still on the realm stands up within a tile
    /// of `tile`; never when none is.
    fn all_beside(&self, tile: grid::TileIndex) -> bool {
        let w = &self.world;
        let (vx, vy) = w.grid.coords(tile);
        let here: Vec<&crate::Raider> = w.raiders.iter()
            .filter(|r| r.half_of.is_none() && matches!(r.standing, Standing::Active | Standing::Down))
            .collect();
        !here.is_empty() && here.iter().all(|r| {
            r.standing == Standing::Active && w.grid.tile_at(r.at.x, r.at.y).is_some_and(|t| {
                let (x, y) = w.grid.coords(t);
                x.abs_diff(vx) <= 1 && y.abs_diff(vy) <= 1
            })
        })
    }

    /// Whether any crew member still on the realm is within a tile of `tile`.
    fn any_beside(&self, tile: grid::TileIndex) -> bool {
        let w = &self.world;
        let (vx, vy) = w.grid.coords(tile);
        w.raiders.iter().filter(|r| r.half_of.is_none() && r.standing == Standing::Active).any(|r| {
            w.grid.tile_at(r.at.x, r.at.y).is_some_and(|t| {
                let (x, y) = w.grid.coords(t);
                x.abs_diff(vx) <= 1 && y.abs_diff(vy) <= 1
            })
        })
    }

    /// The Wanderer's rift, as the Sage opened it this tick: from its tile
    /// here to where the crew entered the realm behind it on the route, or,
    /// in the landing realm, the realm ahead it came back from.
    fn open_rift(&mut self) {
        let Some((tile, until)) = self.world.rift_open.take() else { return };
        let other = if self.leg > 0 { self.leg - 1 } else { self.leg + 1 };
        let Some(far) = self.world_of(other).and_then(|w| w.landing) else { return };
        self.rift = Some(SageRift { ends: [(self.leg, tile), (other, far)], until, armed: false });
    }

    /// The crew through the Sage's rift, while it is open, once every crew
    /// member still on the realm stands beside its end here, having been
    /// away from it since it opened or since the crew came through.
    fn through_rift(&mut self) -> bool {
        let Some(mut rift) = self.rift else { return false };
        if self.world.tick >= rift.until {
            self.rift = None;
            return false;
        }
        let Some(i) = rift.ends.iter().position(|&(leg, _)| leg == self.leg) else { return false };
        let (here, (there, far)) = (rift.ends[i].1, rift.ends[1 - i]);
        if !rift.armed {
            rift.armed = !self.any_beside(here);
            self.rift = Some(rift);
            return false;
        }
        if !self.all_beside(here) {
            return false;
        }
        rift.armed = false;
        self.rift = Some(rift);
        self.go(there, Some(far));
        true
    }

    /// The crew on to the next realm, once every crew member still on this
    /// one stands up beside its way on and the link is open. A crew member
    /// down holds the crew until it is revived or caught.
    fn cross(&mut self) {
        if self.at_heart() || !self.all_beside(self.world.vault.tile) {
            return;
        }
        let (from, to) = (self.route[self.leg], self.route[self.leg + 1]);
        if self.universe.link(from, to) == Some(LinkKind::Rift)
            && [from, to].iter().any(|&r| self.alarms[r].is_some_and(|a| self.world.tick < a + RIFT_CLOSED_TICKS))
        {
            return;
        }
        self.go(self.leg + 1, None);
    }

    /// The crew to leg `to` of the route, one either side of where it is: to
    /// the realm's world as the crew left it, or a new one, arriving at
    /// `arrive`, else at the realm's entrance or the nearest tile to it a
    /// crew member can stand on. The clock, the alarm raised, the Sage, the
    /// casts and a law the Wanderer copied go with the crew; whoever is out
    /// or caught stays so.
    fn go(&mut self, to: usize, arrive: Option<grid::TileIndex>) {
        let back = to < self.leg;
        let kept = if back { self.crossed.pop() } else { self.ahead.pop() };
        let mut next = kept.unwrap_or_else(|| {
            let mut w = Self::realm(&self.islands[self.route[to]], &self.header, to + 1 == self.route.len(),
                                    self.universe.flicker);
            // Where the crew entered the realm is its landing there: where
            // Ghost tide sends the knocked-out back to, and the report's.
            w.landing = Some(Self::standable_near(&w, w.entrance));
            // Its alarm counts from the crew's arrival (§12.17's ladder, a
            // realm at a time); a realm the crew comes back to keeps its own.
            w.alarm_from = self.world.tick;
            w
        });
        let prev = &self.world;
        next.tick = prev.tick;
        next.clock = prev.clock;
        next.clock_run = prev.clock_run;
        next.alarm_raised |= prev.alarm_raised;
        next.sage = prev.sage;
        next.tailwind_until = prev.tailwind_until;
        next.renew_from = prev.renew_from;
        next.casts = prev.casts.clone();
        next.casts_used = prev.casts_used;
        next.zones.retain(|z| z.at.is_some());
        next.zones.extend(prev.zones.iter().filter(|z| z.at.is_none()).cloned());
        let tile = arrive.unwrap_or_else(|| Self::standable_near(&next, next.entrance));
        let (cx, cy) = next.grid.centre(tile);
        next.raiders = prev.raiders.iter().map(|r| {
            let mut r = r.clone();
            if matches!(r.standing, Standing::Active | Standing::Down) {
                r.at = crate::Point { x: cx, y: cy };
            }
            r.route.clear();
            r.along = 0;
            r.came_from = tile;
            r.last_tile = Some(tile);
            r.prev_tile = None;
            r.task = Task::None;
            r.swing = 0;
            r.still_for = 0;
            r
        }).collect();
        let prev = std::mem::replace(&mut self.world, next);
        if back {
            self.ahead.push(prev);
        } else {
            self.crossed.push(prev);
        }
        self.leg = to;
        self.world.rift_back = self.leg > 0 || !self.ahead.is_empty();
    }

    fn standable_near(world: &World, tile: grid::TileIndex) -> grid::TileIndex {
        if world.grid.standable(tile) {
            return tile;
        }
        let (ex, ey) = world.grid.coords(tile);
        (0..world.grid.len() as grid::TileIndex).filter(|&t| world.grid.standable(t))
            .min_by_key(|&t| {
                let (x, y) = world.grid.coords(t);
                (x.abs_diff(ex) + y.abs_diff(ey), t)
            })
            .unwrap_or(tile)
    }

    /// §12.9's outcome across the realms: the crew's standings and what it
    /// banked where it is now, the pylons broken and the gardens cracked in
    /// every realm it has been in, and the loot dropped in each. The alarm
    /// raised anywhere is carried, so Loud is the heist's.
    pub fn outcome(&self) -> Outcome {
        let mut o = self.world.outcome();
        for w in self.crossed.iter().chain(&self.ahead) {
            let p = w.outcome();
            o.pages += p.pages;
            o.broken |= p.broken;
            o.cracked += p.cracked;
            o.left += w.dropped.iter().map(|&(_, n)| n).sum::<i32>();
        }
        o
    }

    /// Each realm's report for its island's defender (§13.2), by its place
    /// in the universe's order, in the route's order: every realm the crew
    /// has been in. "held" is the heist's: the seconds to the last crew
    /// member out or caught in whichever realm, or the whole clock if one
    /// was still inside when it ran out.
    pub fn reports(&self) -> Vec<(usize, Report)> {
        let worlds: Vec<&World> = self.crossed.iter().chain(std::iter::once(&self.world))
            .chain(self.ahead.iter().rev()).collect();
        let mut last = 0u32;
        let mut done = std::collections::BTreeSet::new();
        for w in &worlds {
            for &(t, e) in &w.log.events {
                if let crate::events::Event::Out { crew, .. } | crate::events::Event::Caught { crew, .. } = e {
                    last = last.max(t);
                    done.insert(crew);
                }
            }
        }
        let ended = if self.world.crew_all_in(&done) { last } else { self.world.clock };
        let held = (ended / TICKS_PER_SECOND).min(u16::MAX as u32) as u16;
        worlds.iter().enumerate()
            .map(|(leg, w)| {
                let realm = self.route[leg];
                (realm, Report { held, ..w.report(&self.islands[realm]) })
            })
            .collect()
    }
}

/// `verify_on` for a heist across a universe.
pub fn verify_universe(universe: &Universe, islands: &[Island], heist: &Heist) -> Result<Outcome, Refusal> {
    verified(universe, islands, heist).map(|c| c.outcome())
}

/// The crossing played to its end on its universe, every second's checksum
/// compared on the way: the checks `verify_on` makes of a one-island heist,
/// with the universe's digest in the header where the island's would be.
pub fn verified(universe: &Universe, islands: &[Island], heist: &Heist) -> Result<Crossing, Refusal> {
    if heist.island != universe.digest() {
        return Err(Refusal::Island);
    }
    if heist.rules != crate::rules_version() {
        return Err(Refusal::Rules);
    }
    if !(3..=5).contains(&heist.crew) {
        return Err(Refusal::Crew);
    }
    if !(crate::MIN_TICKS..=crate::MAX_TICKS + crate::era::extra_ticks(heist.era)).contains(&heist.ticks) {
        return Err(Refusal::Length);
    }
    if !heist.commands.windows(2).all(|w| w[0].tick <= w[1].tick)
        || heist.commands.iter().any(|c| c.tick >= heist.ticks)
    {
        return Err(Refusal::Log);
    }
    if heist.checksums.len() != (heist.ticks / TICKS_PER_SECOND) as usize {
        return Err(Refusal::Checksums);
    }
    let mut c = Crossing::new(universe, islands, heist)?;
    let mut second = 0usize;
    for _ in 0..heist.ticks {
        let sum = c.step();
        if c.world.tick == 1 && c.world.landing.is_none() {
            return Err(Refusal::Landing);
        }
        if c.world.tick % TICKS_PER_SECOND == 0 {
            if crate::truncate(sum) != heist.checksums[second] {
                return Err(Refusal::Diverged(second + 1));
            }
            second += 1;
        }
    }
    Ok(c)
}

/// A heist across `universe` recorded from its commands: its checksums
/// worked out by playing it, as `record_with` does for one island.
#[allow(clippy::too_many_arguments)]
pub fn record_universe(universe: &Universe, islands: &[Island], seed: u64, ticks: u32, crew: u8,
                       era: Option<crate::era::Era>, manifest: Option<crate::replay::Manifest>,
                       commands: Vec<Command>) -> Result<Heist, Refusal> {
    let mut heist = Heist { seed, island: universe.digest(), rules: crate::rules_version(), ticks, crew, era, manifest,
                            commands, checksums: Vec::new() };
    let mut c = Crossing::new(universe, islands, &heist)?;
    for _ in 0..ticks {
        let sum = c.step();
        if c.world.tick % TICKS_PER_SECOND == 0 {
            heist.checksums.push(crate::truncate(sum));
        }
    }
    Ok(heist)
}
