//! The native half of the determinism spike (T3.1).
//!
//!     cargo run --release --bin spike -- [seed] [ticks]
//!
//! Prints the per-second checksums and the digest over them. The WebAssembly
//! build runs the same library through `run_spike.sh` and the two are compared.

use ruleborn_sim::{digest, run, TICKS_PER_SECOND};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let seed: u64 = args.get(1).and_then(|s| s.parse().ok()).unwrap_or(0x5EED_0000_0000_0001);
    let ticks: u32 = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(7_200);

    let kept = run(seed, ticks);
    println!("seed {seed} ticks {ticks} ({} s at {TICKS_PER_SECOND} a second)",
             ticks / TICKS_PER_SECOND);
    println!("kept {} checksums, one a second", kept.len());
    for (i, sum) in kept.iter().enumerate().take(4) {
        println!("  second {:>3}  {sum:016x}", i + 1);
    }
    println!("  ...");
    if let Some(last) = kept.last() {
        println!("  second {:>3}  {last:016x}", kept.len());
    }
    println!("digest {:016x}", digest(seed, ticks));
}
