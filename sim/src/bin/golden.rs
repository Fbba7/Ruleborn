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

use ruleborn_sim::{fixture, planned, replay::{Heist, MAX_HEIST_BYTES}, GOLDEN};
use std::path::Path;

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
