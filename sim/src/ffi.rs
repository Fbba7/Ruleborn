//! The WebAssembly surface: what the server calls. §24.7: the same library,
//! "compiled into the app as a native extension on iPhone and Android, and to
//! WebAssembly for the server function".
//!
//! Numbers in, numbers out, and one shared buffer for bytes. The host asks for
//! the buffer's address once (`rb_buffer`), writes a replay or an island into
//! it, and calls; results come back in the same buffer. The buffer is a
//! `Vec` that is allocated once and never grows, so its address never moves,
//! and the crate performs no unsafe operation to use it: the host writes the
//! module's memory between calls, which is what WebAssembly memory is for,
//! and Rust reads it through the `Vec` as its own.
//!
//! Every function here is a symbol-name declaration and nothing else unsafe:
//! Rust requires `unsafe(no_mangle)` because two libraries could claim one
//! symbol. That is the whole of the crate's exception to `deny(unsafe_code)`.
//!
//! Status codes are negative, so a caller can never read a failure as a
//! length or a verdict:
//!
//! | code | meaning |
//! | --- | --- |
//! | -1 | the replay does not decode |
//! | -2 | the island does not decode |
//! | -3 | the replay names another island |
//! | -4 | the replay names another rules version |
//! | -5 | a crew outside 3 to 5 (§12.5) |
//! | -6 | outside 4,500 to 7,200 ticks (§24.10) |
//! | -7 | commands out of order, or past the end |
//! | -8 | not one checksum a second |
//! | -9 | the input does not fit the buffer, or a replay over 2 KB (§24.10) |
//! | -10 | an era that is not one (`rb_record`, `rb_record_drawn`) |
//! | -11 | the crew never landed: no landing at tick 0 on an open edge tile (§5.4) |

use std::sync::Mutex;

use crate::heist::Grade;
use crate::island::Island;
use crate::replay::{Command, Heist, Kind, Manifest, MAX_HEIST_BYTES};
use crate::era::Era;
use crate::{digest, draw, fixture, record_in, record_with, rules_version, verify_on, Refusal};

/// Room for the largest island (14 x 14 tiles at three bytes, and its lists)
/// and a replay beside it, many times over.
pub const BUFFER_BYTES: usize = 1 << 16;

static BUFFER: Mutex<Vec<u8>> = Mutex::new(Vec::new());

fn with_buffer<T>(f: impl FnOnce(&mut Vec<u8>) -> T) -> T {
    let mut guard = BUFFER.lock().unwrap_or_else(|e| e.into_inner());
    if guard.len() != BUFFER_BYTES {
        *guard = vec![0; BUFFER_BYTES];
    }
    f(&mut guard)
}

fn refusal_code(r: Refusal) -> i32 {
    match r {
        Refusal::Island => -3,
        Refusal::Rules => -4,
        Refusal::Crew => -5,
        Refusal::Length => -6,
        Refusal::Log => -7,
        Refusal::Checksums => -8,
        Refusal::Landing => -11,
        Refusal::Diverged(second) => second as i32,
    }
}

fn fits(start: u32, len: u32) -> bool {
    (start as usize).saturating_add(len as usize) <= BUFFER_BYTES
}

/// The shared buffer's address in the module's memory, and its size.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_buffer() -> *mut u8 {
    with_buffer(|b| b.as_mut_ptr())
}

#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_buffer_bytes() -> u32 {
    BUFFER_BYTES as u32
}

/// The rules version this build is (§24.11), written to the buffer's first
/// 32 bytes.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_rules_version() -> u32 {
    let version = rules_version();
    with_buffer(|b| b[..32].copy_from_slice(&version));
    32
}

/// Read an island of `len` bytes from the buffer. On success its SHA-256 is
/// written to the buffer's first 32 bytes and the return is the mask of
/// `island::Problem`s it has — zero for an island that may be published. On
/// failure, -2.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_island(len: u32) -> i32 {
    if !fits(0, len) {
        return -9;
    }
    with_buffer(|b| {
        let Ok(island) = Island::decode(&b[..len as usize]) else { return -2 };
        b[..32].copy_from_slice(&island.digest());
        island.check().iter().fold(0u32, |mask, p| mask | p.bit()) as i32
    })
}

/// §24.12's "Validate": a replay of `replay_len` bytes at the start of the
/// buffer and the island it claims at `replay_len`, re-simulated.
///
/// Returns 0 when every second agrees, the first second that does not when
/// one does not, or a negative status (see the module docstring). On 0 the
/// verdict is written to the buffer's first 24 bytes — the re-simulation's,
/// never the device's:
///
/// ```text
/// grade u8 (0 clean, 1 loud, 2 partial, 3 foiled), out u8, caught u8,
/// crew u8, banked i32 LE, capacity i32 LE, pages u32 LE, cracked u32 LE,
/// left i32 LE
/// ```
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_verify(replay_len: u32, island_len: u32) -> i32 {
    if !fits(replay_len, island_len) {
        return -9;
    }
    if replay_len as usize > MAX_HEIST_BYTES {
        return -9;
    }
    with_buffer(|b| {
        let (r, i) = (replay_len as usize, island_len as usize);
        let Some(heist) = Heist::decode(&b[..r]) else { return -1 };
        let Ok(island) = Island::decode(&b[r..r + i]) else { return -2 };
        match verify_on(&island, &heist) {
            Ok(outcome) => {
                let grade = match outcome.grade {
                    Grade::Clean => 0,
                    Grade::Loud => 1,
                    Grade::Partial => 2,
                    Grade::Foiled => 3,
                };
                b[0] = grade;
                b[1] = outcome.out as u8;
                b[2] = outcome.caught as u8;
                b[3] = heist.crew;
                b[4..8].copy_from_slice(&outcome.banked.to_le_bytes());
                b[8..12].copy_from_slice(&outcome.capacity.to_le_bytes());
                b[12..16].copy_from_slice(&outcome.pages.to_le_bytes());
                b[16..20].copy_from_slice(&outcome.cracked.to_le_bytes());
                b[20..24].copy_from_slice(&outcome.left.to_le_bytes());
                0
            }
            Err(refusal) => refusal_code(refusal),
        }
    })
}

/// A player the server's tests can call: the island of `island_len` bytes in
/// the buffer, played with `draw`'s seeded command log and recorded as the
/// device would record it. The replay is written to the buffer and its length
/// returned, or -2 for an island that does not decode. Nothing on the
/// server's own path calls it. `era` is §18.3's era's wire value, 0 for none;
/// -10 for one that is not an era.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_record_drawn(seed_hi: u32, seed_lo: u32, ticks: u32, crew: u32,
                                  island_len: u32, era: u32) -> i32 {
    let Some(era) = Era::from_u8(era.min(255) as u8) else { return -10 };
    if !fits(0, island_len) {
        return -9;
    }
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    with_buffer(|b| {
        let Ok(island) = Island::decode(&b[..island_len as usize]) else { return -2 };
        let crew = crew.min(u8::MAX as u32) as u8;
        let bytes = record_in(&island, seed, ticks, crew, era, draw(&island, seed, ticks, crew)).encode();
        if bytes.len() > BUFFER_BYTES {
            return -9;
        }
        b[..bytes.len()].copy_from_slice(&bytes);
        bytes.len() as i32
    })
}

/// The device's half of §24.12: play a command log on an island and record
/// the replay. The island's `island_len` bytes are at the start of the
/// buffer and `count` commands follow it, ten bytes each —
///
/// ```text
/// tick u32 LE, crew member u8, kind u8 (replay::Kind), x i16 LE, y i16 LE
/// ```
///
/// — in tick order. The replay is written to the buffer and its length
/// returned; -2 for an island that does not decode, -7 for a command that is
/// not one, or out of order, -10 for an `era` that is not one (0 is none).
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_record(seed_hi: u32, seed_lo: u32, ticks: u32, crew: u32,
                            island_len: u32, count: u32, era: u32) -> i32 {
    let Some(era) = Era::from_u8(era.min(255) as u8) else { return -10 };
    if !fits(island_len, count.saturating_mul(10)) {
        return -9;
    }
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    with_buffer(|b| {
        let Ok(island) = Island::decode(&b[..island_len as usize]) else { return -2 };
        let mut commands = Vec::with_capacity(count as usize);
        for i in 0..count as usize {
            let c = &b[island_len as usize + i * 10..island_len as usize + i * 10 + 10];
            let Some(kind) = Kind::from_u8(c[5]) else { return -7 };
            commands.push(Command {
                tick: u32::from_le_bytes([c[0], c[1], c[2], c[3]]),
                actor: c[4],
                kind,
                x: i16::from_le_bytes([c[6], c[7]]),
                y: i16::from_le_bytes([c[8], c[9]]),
            });
        }
        if !commands.windows(2).all(|w| w[0].tick <= w[1].tick) {
            return -7;
        }
        let crew = crew.min(u8::MAX as u32) as u8;
        let bytes = record_in(&island, seed, ticks, crew, era, commands).encode();
        if bytes.len() > BUFFER_BYTES {
            return -9;
        }
        b[..bytes.len()].copy_from_slice(&bytes);
        bytes.len() as i32
    })
}

/// `rb_record`, with §12.5's crew manifest: its `manifest_len` bytes follow
/// the commands in the buffer, in the replay's own wire form (`Manifest::
/// write`), for `crew` members. The replay is an `RBH3`. -12 for a manifest
/// that does not read, or has bytes left over.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub extern "C" fn rb_record_crew(seed_hi: u32, seed_lo: u32, ticks: u32, crew: u32,
                                 island_len: u32, count: u32, era: u32,
                                 manifest_len: u32) -> i32 {
    let Some(era) = Era::from_u8(era.min(255) as u8) else { return -10 };
    let commands_len = count.saturating_mul(10);
    if !fits(island_len, commands_len.saturating_add(manifest_len)) {
        return -9;
    }
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    let crew = crew.min(u8::MAX as u32) as u8;
    with_buffer(|b| {
        let Ok(island) = Island::decode(&b[..island_len as usize]) else { return -2 };
        let start = (island_len + commands_len) as usize;
        let end = start + manifest_len as usize;
        let mut at = start;
        let Some(manifest) = Manifest::read(&b[..end], &mut at, crew) else { return -12 };
        if at != end {
            return -12;
        }
        let mut commands = Vec::with_capacity(count as usize);
        for i in 0..count as usize {
            let c = &b[island_len as usize + i * 10..island_len as usize + i * 10 + 10];
            let Some(kind) = Kind::from_u8(c[5]) else { return -7 };
            commands.push(Command {
                tick: u32::from_le_bytes([c[0], c[1], c[2], c[3]]),
                actor: c[4],
                kind,
                x: i16::from_le_bytes([c[6], c[7]]),
                y: i16::from_le_bytes([c[8], c[9]]),
            });
        }
        if !commands.windows(2).all(|w| w[0].tick <= w[1].tick) {
            return -7;
        }
        let bytes = record_with(&island, seed, ticks, crew, era, Some(manifest), commands).encode();
        if bytes.len() > BUFFER_BYTES {
            return -9;
        }
        b[..bytes.len()].copy_from_slice(&bytes);
        bytes.len() as i32
    })
}

/// `Island::example()`, a legal realm-3 Heart, written to the buffer; its
/// length is returned. `open` non-zero gives `Island::example_open()`, the
/// same realm undefended. For the server's tests.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_example_island(open: u32) -> i32 {
    let island = if open != 0 { Island::example_open() } else { Island::example() };
    let bytes = island.encode();
    with_buffer(|b| b[..bytes.len()].copy_from_slice(&bytes));
    bytes.len() as i32
}

/// The cross-target spike's number: one call in, one number out.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_digest(seed_hi: u32, seed_lo: u32, ticks: u32) -> u64 {
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    digest(&fixture(seed, ticks, 3))
}
