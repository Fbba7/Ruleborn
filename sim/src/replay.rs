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

use crate::fixed::Fx;

/// `RBH1` — the format, so a decoder can refuse a file it does not know.
pub const MAGIC: [u8; 4] = *b"RBH1";
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
}

impl Kind {
    fn from_u8(v: u8) -> Option<Kind> {
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
    pub commands: Vec<Command>,
    /// One a second, truncated. See the module docstring.
    pub checksums: Vec<u32>,
}

impl Heist {
    /// Bytes. Little-endian throughout, and varint tick deltas, because a
    /// command every few seconds would otherwise spend four bytes saying so.
    pub fn encode(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(MAX_HEIST_BYTES);
        out.extend_from_slice(&MAGIC);
        out.extend_from_slice(&self.seed.to_le_bytes());
        out.extend_from_slice(&self.island);
        out.extend_from_slice(&self.rules);
        out.extend_from_slice(&self.ticks.to_le_bytes());
        out.push(self.crew);
        out.extend_from_slice(&(self.commands.len() as u16).to_le_bytes());
        out.extend_from_slice(&(self.checksums.len() as u16).to_le_bytes());

        let mut previous = 0u32;
        for command in self.commands.iter() {
            debug_assert!(command.tick >= previous, "commands must be in tick order");
            write_varint(&mut out, (command.tick - previous) as u64);
            previous = command.tick;
            // Actor in the high nibble, kind in the low one. A crew is at most
            // five (§12.5) and there are ten kinds, so one byte is plenty
            // and the packing is stated rather than assumed.
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
        if take(&mut at, 4)? != MAGIC {
            return None;
        }
        let seed = u64::from_le_bytes(take(&mut at, 8)?.try_into().ok()?);
        let island: [u8; 32] = take(&mut at, 32)?.try_into().ok()?;
        let rules: [u8; 32] = take(&mut at, 32)?.try_into().ok()?;
        let ticks = u32::from_le_bytes(take(&mut at, 4)?.try_into().ok()?);
        let crew = take(&mut at, 1)?[0];
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
        Some(Heist { seed, island, rules, ticks, crew, commands, checksums })
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
