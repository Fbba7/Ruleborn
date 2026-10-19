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
//! | -12 | a crew manifest that does not read (`rb_record_crew`) |
//! | -13 | the universe does not decode, or its islands do not frame (`rb_verify_universe`) |
//! | -14 | no outer realm the reference crew can land on reaches the Heart |

use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::Mutex;

use crate::heist::Grade;
use crate::island::Island;
use crate::replay::{Command, Heist, Kind, Manifest, MAX_HEIST_BYTES};
use crate::era::Era;
use crate::universe::Universe;
use crate::{digest, draw, fixture, record_in, record_with, rules_version, verify_report, Refusal};

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

/// Where `rb_verify` writes a verified heist's report (`Report::encode`),
/// after the verdict, and how long the last one was.
const REPORT_AT: usize = 64;
static REPORT_BYTES: AtomicU32 = AtomicU32::new(0);

/// The length of the report the last `rb_verify` wrote at byte 64 (TD.39).
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_report_bytes() -> u32 {
    REPORT_BYTES.load(Ordering::Relaxed)
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

/// §10.1's buildings that stand on the grid, so the server places one by
/// the simulation's own footprints: for each of `island::BUILDING_CODES`,
/// code u8, footprint side u8, id length u8 and the id, written to the
/// buffer. Returns the bytes written.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_building_kinds() -> i32 {
    with_buffer(|b| {
        let mut at = 0;
        for (id, code, side) in crate::island::BUILDING_CODES.iter() {
            b[at..at + 3].copy_from_slice(&[*code, *side, id.len() as u8]);
            b[at + 3..at + 3 + id.len()].copy_from_slice(id.as_bytes());
            at += 3 + id.len();
        }
        at as i32
    })
}

/// The buildings of an island of `len` bytes in the buffer, written over it:
/// count u8, then (code u8, x u8, y u8) each, x and y the footprint's
/// north-west tile. Returns the bytes written, or -2 if it does not decode.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_island_buildings(len: u32) -> i32 {
    if !fits(0, len) {
        return -9;
    }
    with_buffer(|b| {
        let Ok(island) = Island::decode(&b[..len as usize]) else { return -2 };
        b[0] = island.buildings.len() as u8;
        for (i, (code, x, y)) in island.buildings.iter().enumerate() {
            b[1 + 3 * i..4 + 3 * i].copy_from_slice(&[*code, *x, *y]);
        }
        1 + 3 * island.buildings.len() as i32
    })
}

/// The length of `rb_verify`'s verdict.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_verdict_bytes() -> u32 {
    34
}

/// §24.12's "Validate": a replay of `replay_len` bytes at the start of the
/// buffer and the island it claims at `replay_len`, re-simulated.
///
/// Returns 0 when every second agrees, the first second that does not when
/// one does not, or a negative status (see the module docstring). On 0 the
/// verdict is written to the buffer's first 34 bytes — the re-simulation's,
/// never the device's:
///
/// ```text
/// grade u8 (0 clean, 1 loud, 2 partial, 3 foiled), out u8, caught u8,
/// crew u8, banked i32 LE, capacity i32 LE, pages u32 LE, cracked u32 LE,
/// left i32 LE, broken u64 LE (bit n: §7.7's nth law's pylon), out u8 (bit n:
/// the crew's nth member got out), casts u8 (bit n: the manifest's nth cast
/// was used, which §12.5 bills)
/// ```
/// `rb_verdict_bytes` says how long the verdict is, so a host reading an
/// older build, which wrote 32 or 33, knows not to read past it. From byte
/// 64 the heist's report follows (`Report::encode`, TD.39), its length
/// `rb_report_bytes`.
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
        match verify_report(&island, &heist) {
            Ok((outcome, report)) => {
                verdict(b, &outcome, heist.crew);
                // TD.39: the report, after the verdict at REPORT_AT.
                let wire = report.encode();
                b[REPORT_AT..REPORT_AT + wire.len()].copy_from_slice(&wire);
                REPORT_BYTES.store(wire.len() as u32, Ordering::Relaxed);
                0
            }
            Err(refusal) => refusal_code(refusal),
        }
    })
}

/// A verified heist's verdict, at the buffer's start: grade (0 Clean, 1
/// Loud, 2 Partial, 3 Foiled), out, caught, crew, then banked, capacity,
/// pages, cracked and left as i32/u32 LE, the broken laws' bits as u64 LE,
/// the out mask and the casts used.
fn verdict(b: &mut [u8], outcome: &crate::heist::Outcome, crew: u8) {
    b[0] = match outcome.grade {
        Grade::Clean => 0,
        Grade::Loud => 1,
        Grade::Partial => 2,
        Grade::Foiled => 3,
    };
    b[1] = outcome.out as u8;
    b[2] = outcome.caught as u8;
    b[3] = crew;
    b[4..8].copy_from_slice(&outcome.banked.to_le_bytes());
    b[8..12].copy_from_slice(&outcome.capacity.to_le_bytes());
    b[12..16].copy_from_slice(&outcome.pages.to_le_bytes());
    b[16..20].copy_from_slice(&outcome.cracked.to_le_bytes());
    b[20..24].copy_from_slice(&outcome.left.to_le_bytes());
    b[24..32].copy_from_slice(&outcome.broken.to_le_bytes());
    b[32] = outcome.out_mask;
    b[33] = outcome.casts_used;
}

/// A universe and its islands from the buffer: the universe's `universe_len`
/// bytes at `at`, then its islands in its order, each its length as u16 LE
/// and its bytes, `islands_len` bytes in all. `Err` with the status code.
fn universe_at(b: &[u8], at: usize, universe_len: usize, islands_len: usize)
               -> Result<(Universe, Vec<Island>), i32> {
    let universe = Universe::decode(&b[at..at + universe_len]).ok_or(-13)?;
    let mut rest = &b[at + universe_len..at + universe_len + islands_len];
    let mut islands = Vec::with_capacity(universe.realms.len());
    while !rest.is_empty() {
        let Some(len) = rest.get(..2).map(|l| u16::from_le_bytes([l[0], l[1]]) as usize) else { return Err(-13) };
        let Some(bytes) = rest.get(2..2 + len) else { return Err(-13) };
        islands.push(Island::decode(bytes).map_err(|_| -2)?);
        rest = &rest[2 + len..];
    }
    Ok((universe, islands))
}

/// `rb_verify` for a heist across a universe (§5.4, D71): the replay's
/// `replay_len` bytes, then the universe's and its islands' as `universe_at`
/// reads them. The verdict is `rb_verify`'s, then the landing realm's place
/// and its route's links at bytes 34 and 35; after it, at byte 64, each realm
/// the crew went through: a count, then each realm's place in the universe's
/// order, its report's length as u16 LE and its report (`Report::encode`).
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_verify_universe(replay_len: u32, universe_len: u32, islands_len: u32) -> i32 {
    if !fits(replay_len, universe_len.saturating_add(islands_len)) || replay_len as usize > MAX_HEIST_BYTES {
        return -9;
    }
    with_buffer(|b| {
        let r = replay_len as usize;
        let Some(heist) = Heist::decode(&b[..r]) else { return -1 };
        let (universe, islands) = match universe_at(b, r, universe_len as usize, islands_len as usize) {
            Ok(u) => u,
            Err(code) => return code,
        };
        match crate::universe::verified(&universe, &islands, &heist) {
            Ok(crossing) => {
                verdict(b, &crossing.outcome(), heist.crew);
                // The realm landed on, by place, and its links to the Heart:
                // the server holds the replay's clock to them (§5.4).
                b[34] = crossing.route[0] as u8;
                b[35] = (crossing.route.len() - 1) as u8;
                let reports = crossing.reports();
                let mut wire = vec![reports.len() as u8];
                for (realm, report) in reports {
                    let bytes = report.encode();
                    wire.push(realm as u8);
                    wire.extend_from_slice(&(bytes.len() as u16).to_le_bytes());
                    wire.extend_from_slice(&bytes);
                }
                b[REPORT_AT..REPORT_AT + wire.len()].copy_from_slice(&wire);
                REPORT_BYTES.store(wire.len() as u32, Ordering::Relaxed);
                0
            }
            Err(refusal) => refusal_code(refusal),
        }
    })
}

/// A heist of the competent reference crew across the universe and islands
/// in the buffer (as `universe_at` reads them from byte 0), from `seed`:
/// its replay written to the buffer and its length returned, for the
/// server's tests. It lands on the realm at place `realm`, or the one its
/// seed draws for 0, on a clock of `ticks`, or §5.4's for 0, in §18.3's
/// `era` (its wire value, 0 for none; -10 for one that is not). -14 when no
/// outer realm it can land on reaches the Heart, or `realm` does not.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_competent_universe(seed_hi: u32, seed_lo: u32, crew: u32, realm: u32, ticks: u32, era: u32,
                                        universe_len: u32, islands_len: u32) -> i32 {
    let Some(era) = Era::from_u8(era.min(255) as u8) else { return -10 };
    if !fits(universe_len, islands_len) {
        return -9;
    }
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    with_buffer(|b| {
        let (universe, islands) = match universe_at(b, 0, universe_len as usize, islands_len as usize) {
            Ok(u) => u,
            Err(code) => return code,
        };
        let crew = crew.clamp(3, 5) as u8;
        let Some(heist) = crate::reference::competent_universe(&universe, &islands, seed, crew,
                                                                       (realm > 0).then_some(realm as usize),
                                                                       (ticks > 0).then_some(ticks), era)
        else {
            return -14;
        };
        let bytes = heist.encode();
        b[..bytes.len()].copy_from_slice(&bytes);
        bytes.len() as i32
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

/// §12.22's generated target for a seed and a realm level, 1 to 5
/// (`Island::generated`), written to the buffer as its bundle; the length is
/// returned. The server offers these when a raider's list runs thin.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_generate(seed_hi: u32, seed_lo: u32, realm_level: u32) -> i32 {
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    let bytes = Island::generated(seed, realm_level.clamp(1, 5) as u8).encode();
    with_buffer(|b| b[..bytes.len()].copy_from_slice(&bytes));
    bytes.len() as i32
}

/// §13.3's curation (`Island::curated`): the generator's layout of a
/// player's realm from a seed. The buffer's first `len` bytes say what the
/// realm holds: a building count u8 and (code u8, x u8, y u8) each, then a
/// law count u8 and (id length u8, id) each. The island's bundle is written
/// over them; returns its length, or -2 when the wire does not read.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_curated(seed_hi: u32, seed_lo: u32, realm_level: u32, vault_level: u32, len: u32) -> i32 {
    if !fits(0, len) {
        return -9;
    }
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    with_buffer(|b| {
        let wire = &b[..len as usize];
        let mut at = 0usize;
        let mut next = |n: usize| -> Option<&[u8]> {
            let out = wire.get(at..at + n)?;
            at += n;
            Some(out)
        };
        let Some(&[count]) = next(1) else { return -2 };
        let mut buildings = Vec::new();
        for _ in 0..count {
            let Some(&[code, x, y]) = next(3) else { return -2 };
            buildings.push((code, x, y));
        }
        let Some(&[count]) = next(1) else { return -2 };
        let mut ids = Vec::new();
        for _ in 0..count {
            let Some(&[n]) = next(1) else { return -2 };
            let Some(id) = next(n as usize) else { return -2 };
            let Ok(id) = std::str::from_utf8(id) else { return -2 };
            ids.push(id.to_string());
        }
        if at != wire.len() {
            return -2;
        }
        let laws: Vec<&str> = ids.iter().map(String::as_str).collect();
        let bytes = Island::curated(seed, realm_level.clamp(1, 5) as u8, vault_level.clamp(1, 10) as u8,
                                    &buildings, &laws).encode();
        b[..bytes.len()].copy_from_slice(&bytes);
        bytes.len() as i32
    })
}

/// An island's terrain digest (`Island::terrain_digest`): the island in the
/// buffer's first `len` bytes, its 32 bytes written over it. Returns 32, or
/// -2 when the island does not decode.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_terrain(len: u32) -> i32 {
    if !fits(0, len) {
        return -9;
    }
    with_buffer(|b| {
        let Ok(island) = Island::decode(&b[..len as usize]) else { return -2 };
        b[..32].copy_from_slice(&island.terrain_digest());
        32
    })
}

/// §13.3's hold measurement (`reference::hold`): `raids` heists of the
/// competent reference crew of `crew`, on a clock of `ticks`, on the island
/// in the buffer's first `len` bytes, from seed `seed` and those after it.
/// Returns how many it held (Foiled), or -2 when the island does not decode.
/// A queue measures an island in parts by moving the seed on.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_hold(seed_hi: u32, seed_lo: u32, raids: u32, ticks: u32, crew: u32, len: u32) -> i32 {
    if !fits(0, len) {
        return -9;
    }
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    with_buffer(|b| {
        let Ok(island) = Island::decode(&b[..len as usize]) else { return -2 };
        crate::reference::hold(&island, seed, raids, ticks, crew.clamp(3, 5) as u8).0 as i32
    })
}

/// The cross-target spike's number: one call in, one number out.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_digest(seed_hi: u32, seed_lo: u32, ticks: u32) -> u64 {
    let seed = ((seed_hi as u64) << 32) | seed_lo as u64;
    digest(&fixture(seed, ticks, 3))
}


/// §5.5's stability, priced (TD.14): the universe in the buffer's first
/// `len` bytes as `stability::decode` reads it, answered over it as
/// `stability::encode` writes it. Returns the bytes written, or -2 when the
/// universe does not read.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_stability(len: u32) -> i32 {
    if !fits(0, len) {
        return -9;
    }
    with_buffer(|b| {
        let Some((laws, schools, capacity, era)) = crate::stability::decode(&b[..len as usize]) else { return -2 };
        let out = crate::stability::encode(&crate::stability::price(&laws, &schools, capacity, era));
        if out.len() > b.len() {
            return -9;
        }
        b[..out.len()].copy_from_slice(&out);
        out.len() as i32
    })
}

/// The ids of `LAWS` (`which` 0) or of `CHORDS` (1), each followed by a NUL,
/// written to the buffer: the rows `rb_stability` names. Returns the bytes
/// written.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn rb_ids(which: u32) -> i32 {
    let ids: Vec<&str> = if which == 0 {
        crate::laws_table::LAWS.iter().map(|l| l.id).collect()
    } else {
        crate::laws_table::CHORD_IDS.to_vec()
    };
    with_buffer(|b| {
        let mut at = 0;
        for id in ids {
            b[at..at + id.len()].copy_from_slice(id.as_bytes());
            b[at + id.len()] = 0;
            at += id.len() + 1;
        }
        at as i32
    })
}

