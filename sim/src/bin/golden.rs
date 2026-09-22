//! Write the golden replays. T3.2: "golden replays, portable from day one".
//!
//!     cargo run --release --bin golden -- --write
//!
//! A golden replay is a heist encoded today and committed. `tests.rs` decodes
//! each one and re-simulates it, so any change to the simulation that moves a
//! number fails the build and says which second it moved at.
//!
//! §24.9 is the reason they are files rather than a test that regenerates
//! them: a test that computes the expected answer with the same code it is
//! testing passes whatever the code does. These bytes were produced by a
//! build that is now history, and nothing in the repository can quietly
//! change them.
//!
//! Regenerating is therefore a decision, and the one failure mode to guard
//! against is making it reflexively. The rule is: work out what moved and why
//! before running this, put the rewrite in the same commit as the change that
//! needed it — splitting them leaves a commit whose tests fail — and say in
//! the message which second moved.

use ruleborn_sim::{fixture, planned, replay::{Heist, MAX_HEIST_BYTES}};
use std::path::Path;

/// (name, seed, ticks, crew). Chosen to span what §24.10 and §12.5 allow: the
/// short and long ends of "4,500 to 7,200 ticks", and a crew of three, four
/// and five.
const GOLDEN: &[(&str, u64, u32, u8)] = &[
    ("short-crew3", 0x0000_0000_0000_0001, 4_500, 3),
    ("long-crew5", 0x5EED_0000_0000_0001, 7_200, 5),
    ("mid-crew4", 0x0BAD_C0FF_EE00_1234, 6_000, 4),
    ("edge-seed-max", u64::MAX, 4_500, 3),
];

fn main() {
    let write = std::env::args().any(|a| a == "--write");
    let dir = Path::new(env!("CARGO_MANIFEST_DIR")).join("golden");
    // The seeded heists, and one played as a player would: the seeded ones
    // almost never open the Vault, so without it no golden would carry
    // cracking, loading, a fight or a graded outcome.
    let mut all: Vec<(&str, Heist)> = GOLDEN.iter()
        .map(|(name, seed, ticks, crew)| (*name, fixture(*seed, *ticks, *crew)))
        .collect();
    all.push(("planned-clean", planned()));
    for (name, heist) in all {
        let bytes = heist.encode();
        assert!(bytes.len() <= MAX_HEIST_BYTES,
                "{name} is {} bytes, over the limit", bytes.len());
        let path = dir.join(format!("{name}.rbh"));
        if write {
            std::fs::write(&path, &bytes).expect("write golden replay");
            println!("wrote {:<16} {:>5} bytes  {} commands  {} seconds",
                     format!("{name}.rbh"), bytes.len(),
                     heist.commands.len(), heist.checksums.len());
        } else {
            let on_disk = std::fs::read(&path).expect("read golden replay");
            let same = on_disk == bytes;
            println!("{:<16} {:>5} bytes  {}", format!("{name}.rbh"),
                     bytes.len(), if same { "matches" } else { "DIFFERS" });
            if !same {
                std::process::exit(1);
            }
        }
    }
}
