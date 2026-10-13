//! The event log. §24.10: "Beside the replay the simulation keeps an event
//! log — sightings, alerts, wards fired, bells, captures and escapes, each
//! with its tick, and every crew member's position once a second for sampled
//! re-simulation — outside the checksum, so a result can name a moment
//! without changing what is replayed."
//!
//! Nothing here is read back by the simulation and nothing here is in
//! `World::checksum`, so logging more, or less, never moves a replay. The
//! log is rebuilt by re-simulating; it is never transmitted as truth.
//!
//! Who reads it: the result's decisive moment (§12.13, `Log::moment`), the
//! heist's haptics and words, the defender's report (§13.2), Profile's facts,
//! the share clip, and the server's route, detection and failure heatmaps
//! from sampled re-simulations (§24.3).

use crate::guard::State;
use crate::heist::Grade;

/// Why a guard changed state.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Cause {
    /// It saw this crew member — the one it noticed most that tick.
    Saw(u8),
    /// A Lantern Glare showed it the crew (§10.3).
    Glare,
    /// It heard something (§12.17).
    Heard,
    /// An alert spreading from a guard nearby (§12.17).
    Spread,
    /// Something drew it: a Decoy's sapling, an illusion (§11.7, §8).
    Lured,
    /// The realm alarm at level 6 (§12.17).
    Alarm,
    /// The state table itself: a hold ending, a search ending, the walk home
    /// arriving, a rise queued under Delay landing.
    Table,
}

/// What knocked a crew member down.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Hurt {
    /// A guard's hit.
    Guard(u16),
    /// A ward: its index in `World::wards`.
    Ward(u16),
    /// A law or a combination: thorns, flames, a rebound.
    Law,
}

/// How a crew member knocked down came back.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Back {
    /// An ally beside it (§12.20).
    Ally,
    /// A Revival law returned it at once (§7.3).
    Law,
    /// The Echoplate standing over the crew (§11.11).
    Echoplate,
    /// The Archivist's Recall (§11.7).
    Recall,
    /// Ghost tide drifted it back to the landing spot (§8).
    GhostTide,
}

/// One thing that happened, at a tick.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Event {
    /// A guard's state changed, and why.
    Guard { guard: u16, from: State, to: State, cause: Cause },
    /// A guard knocked out.
    GuardDown { guard: u16 },
    /// A crew member knocked down, by what.
    Down { crew: u8, by: Hurt },
    /// A crew member back on its feet, and how.
    Back { crew: u8, how: Back },
    /// A crew member caught: down too long, or still inside at the clock.
    Caught { crew: u8, clock: bool },
    /// A crew member aboard the skiff, with what it carried.
    Out { crew: u8, carried: i32 },
    /// The realm alarm reached a level: by a knocked-out guard found, or by
    /// time (§12.17).
    Alarm { level: u8, found: bool },
    /// Alarm level 5's Warden arrived at the entrance.
    Reinforced { guard: u16 },
    /// A ward went off, on this crew member.
    Ward { ward: u16, crew: u8 },
    /// A Law Pylon broken: its law off for the rest of the heist.
    Pylon { law: u16 },
    /// The Vault cracked open.
    Vault,
    /// A law switched off for a while — Suspend — until the tick given. The
    /// law's blink §12.13 names at the moment.
    LawOff { law: u16, until: u32 },
    /// A law turned into its opposite — Invert — until the tick given.
    LawTurned { law: u16, until: u32 },
    /// A crew member's ability, used.
    Ability { crew: u8 },
    /// The Sage's power, used: its number, 0 to 2.
    Power { power: u8 },
    /// A footprint left in a marsh or a flower meadow, which stays for
    /// `grid::PRINT_SECONDS` (§6.2).
    Print { crew: u8, tile: u16 },
    /// A bell post bumped by a crew member (§6.2).
    Bell { crew: u8, tile: u16 },
}

/// The log of one heist.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Log {
    /// Every event, by tick, in the order the tick made them.
    pub events: Vec<(u32, Event)>,
    /// Every crew member on the island, once a second: (tick, crew member,
    /// x, y), the position at 1/256 of a tile as a command gives one.
    pub positions: Vec<(u32, u8, i16, i16)>,
    /// The closest call: the tick a guard not Alerted came nearest to it,
    /// and its suspicion then.
    pub closest: Option<(u32, u16, i32)>,
}

/// §12.13's decisive moment: what it was, and what is named with it.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Moment {
    pub tick: u32,
    pub kind: MomentKind,
    pub guard: Option<u16>,
    pub crew: Option<u8>,
    pub cause: Option<Cause>,
    /// "A fault or a law's blink at that tick is named": a law switched off
    /// at the moment. Faults are stability's (TD.37) and not built.
    pub blink: Option<u16>,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum MomentKind {
    /// Foiled or Partial: the first capture, at the tick its captor became
    /// Alerted to that crew member.
    Capture,
    /// Loud: the first guard Alerted.
    Alert,
    /// Clean: the closest call.
    CloseCall,
}

impl Log {
    pub fn push(&mut self, tick: u32, event: Event) {
        self.events.push((tick, event));
    }

    /// §12.13: "for a Foiled or Partial heist, the first capture, traced back
    /// to the tick its captor became Alerted to that crew member; for a Loud
    /// heist, the first guard Alerted and why; for a Clean heist, the closest
    /// call, the tick a guard came nearest to Alerted. A fault or a law's
    /// blink at that tick is named." A capture with no guard behind it — the
    /// clock, or a ward or a law that put the crew member down — is its own
    /// moment. `None` only for a Clean heist no guard ever grew suspicious in.
    pub fn moment(&self, grade: Grade) -> Option<Moment> {
        let found = match grade {
            Grade::Foiled | Grade::Partial => self.capture(),
            Grade::Loud => self.events.iter().find_map(|&(t, e)| match e {
                Event::Guard { guard, to: State::Alerted, cause, .. } => Some(Moment {
                    tick: t, kind: MomentKind::Alert, guard: Some(guard),
                    crew: saw(cause), cause: Some(cause), blink: None,
                }),
                _ => None,
            }),
            Grade::Clean => self.closest.map(|(t, guard, _)| Moment {
                tick: t, kind: MomentKind::CloseCall, guard: Some(guard), crew: None,
                cause: None, blink: None,
            }),
        }?;
        Some(Moment { blink: self.blink_at(found.tick), ..found })
    }

    fn capture(&self) -> Option<Moment> {
        let (caught_at, crew) = self.events.iter().find_map(|&(t, e)| match e {
            Event::Caught { crew, .. } => Some((t, crew)),
            _ => None,
        })?;
        let plain = Moment { tick: caught_at, kind: MomentKind::Capture, guard: None,
                             crew: Some(crew), cause: None, blink: None };
        // Its captor: the guard whose hit last put it down before it was taken.
        let Some((down_at, captor)) = self.events.iter()
            .filter(|&&(t, _)| t <= caught_at)
            .filter_map(|&(t, e)| match e {
                Event::Down { crew: c, by: Hurt::Guard(g) } if c == crew => Some((t, g)),
                _ => None,
            })
            .last() else { return Some(plain) };
        // The tick that guard became Alerted to that crew member; failing
        // that, to anything; failing that, the knockdown itself.
        let alerted = |to_crew: bool| self.events.iter()
            .filter(|&&(t, _)| t <= down_at)
            .filter_map(|&(t, e)| match e {
                Event::Guard { guard, to: State::Alerted, cause, .. } if guard == captor
                    && (!to_crew || cause == Cause::Saw(crew)) => Some((t, cause)),
                _ => None,
            })
            .last();
        let (tick, cause) = alerted(true).or_else(|| alerted(false))
            .map_or((down_at, None), |(t, c)| (t, Some(c)));
        Some(Moment { tick, guard: Some(captor), cause, ..plain })
    }

    fn blink_at(&self, tick: u32) -> Option<u16> {
        self.events.iter().filter(|&&(t, _)| t <= tick).find_map(|&(_, e)| match e {
            Event::LawOff { law, until } if tick < until => Some(law),
            _ => None,
        })
    }

    /// The events of one kind, for the readers that want only those.
    pub fn of(&self, keep: impl Fn(&Event) -> bool) -> Vec<(u32, Event)> {
        self.events.iter().filter(|(_, e)| keep(e)).copied().collect()
    }
}

fn saw(cause: Cause) -> Option<u8> {
    match cause {
        Cause::Saw(c) => Some(c),
        _ => None,
    }
}
