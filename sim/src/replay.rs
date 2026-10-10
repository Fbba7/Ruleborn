//! The heist as bytes. §24.10: "What is recorded — commands, never state. A
//! move or an ability with its tick, crew member and target. State is always
//! recoverable by re-simulating."
//!
//! §24.11 adds what has to be pinned: "Any past heist — reproducible forever
//! from four things: the seed, the input log, the island and the rules
//! version." All four are in the header, the island and the rule set as
//! digests, so a replay recorded today still runs after a balance change.
//!
//! The size budget
//! ---------------
//! §24.10 gives one: "Size of a heist — under 2 kilobytes. About 120 bytes of
//! header, 300 to 700 bytes of commands, and a checksum a second."
//!
//! Those numbers do not all fit together, and building it is what shows that.
//! A heist is 4,500 to 7,200 ticks, which is 150 to 240 seconds, so "a
//! checksum a second" is 150 to 240 of them. At the eight bytes a checksum
//! actually is:
//!
//! ```text
//! 120 + 700 + 240 x 8 = 2,740 bytes
//! ```
//!
//! which is over the limit the same row sets. At four bytes it is 1,780 and
//! fits. So the **stored** checksum is the low four bytes; the full eight are
//! still computed every tick in memory, as the same section requires. That
//! costs nothing the checksum is for: §24.10 wants the kept sums to "narrow a
//! divergence to thirty ticks", and a four-byte sum does that as well as an
//! eight-byte one — a collision would have to happen at the first second that
//! differs, at one chance in four billion.
//!
//! `Heist::encode` measures itself against the limit and `size_fits` is the
//! gate.

use crate::era::Era;
use crate::fixed::Fx;

/// `RBH1` — the format, so a decoder can refuse a file it does not know.
pub const MAGIC: [u8; 4] = *b"RBH1";
/// `RBH2` — the same, with one more byte after the crew: the era the heist
/// was played in (§18.3). A heist with no era is still written `RBH1`, byte
/// for byte as before, so every replay recorded before eras still reads.
pub const MAGIC_ERA: [u8; 4] = *b"RBH2";
/// `RBH3` — `RBH2`'s era byte, always present (0 for none), followed by
/// §12.5's crew manifest: "The lease and the replay carry the crew: each
/// member's kind, form, level and traits, the Sage and the casts carried".
/// A heist with no manifest is written `RBH1` or `RBH2` as before, and plays
/// its crew by role.
pub const MAGIC_CREW: [u8; 4] = *b"RBH3";
/// §24.10's limit, as a number the code can check itself against.
pub const MAX_HEIST_BYTES: usize = 2048;
/// The low bytes of each kept checksum. See the module docstring.
pub const CHECKSUM_BYTES: usize = 4;

/// What a player can do. One byte on the wire, so the numbers are written out:
/// changing one changes every replay ever recorded.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
#[repr(u8)]
pub enum Kind {
    /// Walk to a tile.
    MoveTo = 0,
    /// Change gait: `x` is 0 to walk, 1 to crouch, 2 to run. §12.17 prices
    /// all three; the number is the one byte a gait costs in the log.
    Gait = 1,
    /// Stand still.
    Halt = 2,
    /// Hit the Vault while standing next to it. §12.6: "Who cracks".
    Crack = 3,
    /// Load from the open Vault to `x` per cent of the bag. §12.6: "The
    /// player sets how full they want the crew before it leaves."
    Load = 4,
    /// Call the skiff to the edge tile at (`x`, `y`). §5.4: "At any time the
    /// crew can call the skiff to any edge tile of any realm."
    Skiff = 5,
    /// Attack guard number `x` while standing beside it. §12.20: "May a crew
    /// fight? Yes, at any moment."
    Attack = 6,
    /// Break the structure at (`x`, `y`) while standing beside it: a Law
    /// Pylon. §12.6: "breaking one switches its law off for the rest of the
    /// heist and gives a page of it."
    Break = 7,
    /// Drop `x` per cent of what it carries on the tile. §12.6: "whether to
    /// drop loot to run faster"; §12.19: it "costs exactly the fraction
    /// dropped".
    Drop = 8,
    /// Disarm the ward at (`x`, `y`), standing on its tile. §10.3 (v3.3):
    /// fifteen seconds at every level, silent; stepping off starts it again.
    Disarm = 9,
    /// Drag knocked-out guard number `x`. §12.8: "A crew member can drag a
    /// body at crouching speed and hide it."
    Drag = 10,
    /// Land the whole crew on the edge tile at (`x`, `y`), at tick 0. §5.4:
    /// "The crew lands on any edge tile of any outer realm the raider
    /// chooses", and the landing spot is one spot, so the crew stands on it
    /// together; which member gives it does not matter. Only the first
    /// landing at tick 0 on an open edge tile counts; `verify_on` refuses a
    /// heist that never lands.
    Land = 11,
    /// Fire the crew member's ability at (`x`, `y`). §12.7: "Fire the
    /// character's ability at the best target, while it has a use left and
    /// is ready (12.6)", or "Drag onto the world to aim". The device names
    /// the target either way; an ability that needs none does not read it.
    Ability = 12,
    /// Use the Sage's power number `actor` (0 to 2, in §11.7's order) at
    /// (`x`, `y`). §12.7: "Drag a power onto the world to aim it." The Sage
    /// is not a crew member, so the crew-member nibble names the power.
    Sage = 13,
}

impl Kind {
    pub fn from_u8(v: u8) -> Option<Kind> {
        match v {
            0 => Some(Kind::MoveTo),
            1 => Some(Kind::Gait),
            2 => Some(Kind::Halt),
            3 => Some(Kind::Crack),
            4 => Some(Kind::Load),
            5 => Some(Kind::Skiff),
            6 => Some(Kind::Attack),
            7 => Some(Kind::Break),
            8 => Some(Kind::Drop),
            9 => Some(Kind::Disarm),
            10 => Some(Kind::Drag),
            11 => Some(Kind::Land),
            12 => Some(Kind::Ability),
            13 => Some(Kind::Sage),
            _ => None,
        }
    }
}

/// One command. §24.10: "a move or an ability with its tick, crew member and
/// target."
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Command {
    pub tick: u32,
    pub actor: u8,
    pub kind: Kind,
    /// A tile position at 1/256 of a tile, which is finer than a player can
    /// aim and far coarser than the simulation's own precision. The command
    /// log records what was asked for, not what the simulation then computed.
    pub x: i16,
    pub y: i16,
}

impl Command {
    pub fn target(self) -> (Fx, Fx) {
        (Fx::from_ratio(self.x as i64, 256), Fx::from_ratio(self.y as i64, 256))
    }
}

/// One crew member as §12.5's manifest carries it: "each member's kind, form,
/// level and traits". `kind` is its index in `ruleborn::RULEBORN`; `form` is
/// 0 for the kind's own look and 1 to 3 for its forms in `content/forms.json`'s
/// order; `traits` are indexes into `content/traits.json`. The simulation
/// plays the kind; forms, levels and traits are carried for the server's
/// roster check and played from TD.34.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Member {
    pub kind: u8,
    pub form: u8,
    pub level: u8,
    pub traits: Vec<u8>,
}

/// §12.5's crew manifest: the members in portrait order, the Sage (0 for
/// none, else 1 to 4 in §11.7's order) and the casts carried, each a law's
/// index in `laws_table::LAWS`.
#[derive(Clone, Debug, PartialEq, Eq, Default)]
pub struct Manifest {
    pub members: Vec<Member>,
    pub sage: u8,
    pub casts: Vec<u8>,
}

/// The most traits a member carries on the wire, and the most casts: §12.5
/// gives "1 slot, 2 from Keeper level 12".
pub const MAX_TRAITS: usize = 8;
pub const MAX_CASTS: usize = 2;

impl Manifest {
    /// On the wire: each member's kind, form, level and trait count, then its
    /// traits; then the Sage, the cast count and the casts.
    pub fn write(&self, out: &mut Vec<u8>) {
        for m in self.members.iter() {
            out.extend_from_slice(&[m.kind, m.form, m.level, m.traits.len() as u8]);
            out.extend_from_slice(&m.traits);
        }
        out.push(self.sage);
        out.push(self.casts.len() as u8);
        out.extend_from_slice(&self.casts);
    }

    /// The inverse, for `crew` members, from `at`; `None` for a kind past the
    /// eighteen, a form past the kind's three, too many traits or casts, a
    /// Sage past the four, or bytes that run out.
    pub fn read(bytes: &[u8], at: &mut usize, crew: u8) -> Option<Manifest> {
        let mut take = |n: usize| -> Option<&[u8]> {
            let slice = bytes.get(*at..*at + n)?;
            *at += n;
            Some(slice)
        };
        let mut members = Vec::with_capacity(crew as usize);
        for _ in 0..crew {
            let head = take(4)?;
            let (kind, form, level, traits) = (head[0], head[1], head[2], head[3] as usize);
            if kind as usize >= crate::ruleborn::RULEBORN.len() || form > 3 || traits > MAX_TRAITS {
                return None;
            }
            members.push(Member { kind, form, level, traits: take(traits)?.to_vec() });
        }
        let sage = take(1)?[0];
        let casts = take(1)?[0] as usize;
        if sage > 4 || casts > MAX_CASTS {
            return None;
        }
        Some(Manifest { members, sage, casts: take(casts)?.to_vec() })
    }
}

/// A whole heist, in the four things §24.11 says it takes to reproduce one.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Heist {
    pub seed: u64,
    /// The island this was played against. A digest rather than the island
    /// itself: §24.8 stores bundles by content hash, so the bytes are already
    /// addressable by it.
    pub island: [u8; 32],
    /// §24.11: "Every island and every replay records the exact set of laws it
    /// was made under, so a balance change never invalidates the past."
    pub rules: [u8; 32],
    pub ticks: u32,
    pub crew: u8,
    /// §18.3's era of the week it was played in, if any: part of the rules
    /// it re-simulates under, so it travels with the heist.
    pub era: Option<Era>,
    /// §12.5's crew manifest, when the heist carries one; `crew` members by
    /// role when it does not.
    pub manifest: Option<Manifest>,
    pub commands: Vec<Command>,
    /// One a second, truncated. See the module docstring.
    pub checksums: Vec<u32>,
}

impl Heist {
    /// Bytes. Little-endian throughout, and varint tick deltas, because a
    /// command every few seconds would otherwise spend four bytes saying so.
    pub fn encode(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(MAX_HEIST_BYTES);
        out.extend_from_slice(match (&self.manifest, self.era) {
            (Some(_), _) => &MAGIC_CREW,
            (None, Some(_)) => &MAGIC_ERA,
            (None, None) => &MAGIC,
        });
        out.extend_from_slice(&self.seed.to_le_bytes());
        out.extend_from_slice(&self.island);
        out.extend_from_slice(&self.rules);
        out.extend_from_slice(&self.ticks.to_le_bytes());
        out.push(self.crew);
        if let Some(manifest) = &self.manifest {
            out.push(self.era.map_or(0, |e| e as u8));
            manifest.write(&mut out);
        } else if let Some(era) = self.era {
            out.push(era as u8);
        }
        out.extend_from_slice(&(self.commands.len() as u16).to_le_bytes());
        out.extend_from_slice(&(self.checksums.len() as u16).to_le_bytes());

        let mut previous = 0u32;
        for command in self.commands.iter() {
            debug_assert!(command.tick >= previous, "commands must be in tick order");
            write_varint(&mut out, (command.tick - previous) as u64);
            previous = command.tick;
            // Actor in the high nibble, kind in the low one. A crew is at most
            // five (§12.5), a Sage has three powers, and there are fourteen
            // kinds, so one byte is plenty and the packing is stated rather
            // than assumed.
            out.push((command.actor << 4) | (command.kind as u8));
            out.extend_from_slice(&command.x.to_le_bytes());
            out.extend_from_slice(&command.y.to_le_bytes());
        }
        for sum in self.checksums.iter() {
            out.extend_from_slice(&sum.to_le_bytes()[..CHECKSUM_BYTES]);
        }
        out
    }

    /// The inverse. Returns `None` rather than panicking on a malformed file:
    /// a replay arriving from a client is untrusted input, and the server
    /// re-simulates it.
    pub fn decode(bytes: &[u8]) -> Option<Heist> {
        let mut at = 0usize;
        let take = |at: &mut usize, n: usize| -> Option<&[u8]> {
            let slice = bytes.get(*at..*at + n)?;
            *at += n;
            Some(slice)
        };
        let magic = take(&mut at, 4)?;
        let (with_era, with_crew) = if magic == MAGIC {
            (false, false)
        } else if magic == MAGIC_ERA {
            (true, false)
        } else if magic == MAGIC_CREW {
            (true, true)
        } else {
            return None;
        };
        let seed = u64::from_le_bytes(take(&mut at, 8)?.try_into().ok()?);
        let island: [u8; 32] = take(&mut at, 32)?.try_into().ok()?;
        let rules: [u8; 32] = take(&mut at, 32)?.try_into().ok()?;
        let ticks = u32::from_le_bytes(take(&mut at, 4)?.try_into().ok()?);
        let crew = take(&mut at, 1)?[0];
        // An `RBH2` names its era, and never none: that is what `RBH1` is for.
        // An `RBH3` always has the byte, and 0 is none.
        let era = match (with_era, with_crew) {
            (true, false) => Some(Era::from_u8(take(&mut at, 1)?[0])??),
            (true, true) => Era::from_u8(take(&mut at, 1)?[0])?,
            _ => None,
        };
        let manifest = if with_crew { Some(Manifest::read(bytes, &mut at, crew)?) } else { None };
        let command_count = u16::from_le_bytes(take(&mut at, 2)?.try_into().ok()?);
        let checksum_count = u16::from_le_bytes(take(&mut at, 2)?.try_into().ok()?);

        let mut commands = Vec::with_capacity(command_count as usize);
        let mut tick = 0u32;
        for _ in 0..command_count {
            let delta = read_varint(bytes, &mut at)?;
            tick = tick.checked_add(delta as u32)?;
            let packed = take(&mut at, 1)?[0];
            let kind = Kind::from_u8(packed & 0x0f)?;
            let x = i16::from_le_bytes(take(&mut at, 2)?.try_into().ok()?);
            let y = i16::from_le_bytes(take(&mut at, 2)?.try_into().ok()?);
            commands.push(Command { tick, actor: packed >> 4, kind, x, y });
        }
        let mut checksums = Vec::with_capacity(checksum_count as usize);
        for _ in 0..checksum_count {
            let slice = take(&mut at, CHECKSUM_BYTES)?;
            let mut word = [0u8; 4];
            word[..CHECKSUM_BYTES].copy_from_slice(slice);
            checksums.push(u32::from_le_bytes(word));
        }
        if at != bytes.len() {
            return None;                  // trailing bytes are a malformed file
        }
        Some(Heist { seed, island, rules, ticks, crew, era, manifest, commands, checksums })
    }

    /// §24.10's gate, as a question the code can answer about itself.
    pub fn size_fits(&self) -> bool {
        self.encode().len() <= MAX_HEIST_BYTES
    }
}

fn write_varint(out: &mut Vec<u8>, mut value: u64) {
    loop {
        let byte = (value & 0x7f) as u8;
        value >>= 7;
        if value == 0 {
            out.push(byte);
            return;
        }
        out.push(byte | 0x80);
    }
}

fn read_varint(bytes: &[u8], at: &mut usize) -> Option<u64> {
    let mut value = 0u64;
    for shift in (0..64).step_by(7) {
        let byte = *bytes.get(*at)?;
        *at += 1;
        value |= ((byte & 0x7f) as u64) << shift;
        if byte & 0x80 == 0 {
            return Some(value);
        }
    }
    None                                   // a varint longer than u64 is malformed
}
