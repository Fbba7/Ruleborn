//! Which second each golden replay diverges at under the current build.
//!
//!     cargo run --release --example where_diverge
//!
//! Run this before regenerating the goldens: it is the "work out what moved"
//! step that `golden_replays_still_verify` asks for.
use ruleborn_sim::{replay::Heist, verify};

fn main() {
    let dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("golden");
    let mut paths: Vec<_> = std::fs::read_dir(&dir).unwrap().flatten().map(|e| e.path()).collect();
    paths.sort();
    for p in paths {
        let h = Heist::decode(&std::fs::read(&p).unwrap()).unwrap();
        let verdict = match verify(&h) {
            Ok(()) => "verifies".to_string(),
            Err(s) => format!("diverges at second {s} of {}", h.checksums.len()),
        };
        println!("{:<20} {verdict}", p.file_name().unwrap().to_string_lossy());
    }
}
