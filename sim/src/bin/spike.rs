//! The native half of the determinism spike (T3.1) and the replay gate (T3.2).
//!
//!     cargo run --release --bin spike -- [seed] [ticks]
//!
//! Prints the per-second checksums, the digest over them, and the encoded
//! size against §24.10's two-kilobyte limit. The WebAssembly build runs the
//! same library and the two digests are compared by `run_spike.sh`.

use ruleborn_sim::island::Island;
use ruleborn_sim::replay::{Heist, MAX_HEIST_BYTES};
use ruleborn_sim::sha256::{hex, sha256};
use ruleborn_sim::{digest, draw, fixture, record, rules_version, run, verify, verify_on,
                   TICKS_PER_SECOND};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let seed: u64 = args.get(1).and_then(|s| s.parse().ok())
        .unwrap_or(0x5EED_0000_0000_0001);
    let ticks: u32 = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(7_200);

    let heist = fixture(seed, ticks, 3);
    let kept = run(&heist);
    println!("seed {seed} ticks {ticks} ({} s at {TICKS_PER_SECOND} a second)",
             ticks / TICKS_PER_SECOND);
    println!("{} commands, {} checksums kept",
             heist.commands.len(), kept.len());
    for (i, sum) in kept.iter().enumerate().take(3) {
        println!("  second {:>3}  {sum:016x}", i + 1);
    }
    println!("  ...");
    if let Some(last) = kept.last() {
        println!("  second {:>3}  {last:016x}", kept.len());
    }

    let bytes = heist.encode();
    println!("encoded {} bytes of {MAX_HEIST_BYTES} ({} spare)",
             bytes.len(), MAX_HEIST_BYTES as i64 - bytes.len() as i64);

    match Heist::decode(&bytes) {
        Some(back) if back == heist => println!("round trip exact"),
        Some(_) => { println!("round trip CHANGED the heist"); std::process::exit(1) }
        None => { println!("round trip failed to decode"); std::process::exit(1) }
    }
    match verify(&heist) {
        Ok(()) => println!("re-simulation matches every kept checksum"),
        Err(second) => {
            println!("re-simulation diverges at second {second}");
            std::process::exit(1);
        }
    }
    println!("digest {:016x}", digest(&heist));

    // The server's half (§24.12): the rules version, the example island's
    // hash, a replay recorded on it from this seed, and the verdict of
    // re-simulating it. `wasm_spike.mjs` prints the same line from the
    // WebAssembly build, and `status.py` compares them.
    let island = Island::example();
    let replay = record(&island, seed, 4_500, 4, draw(&island, seed, 4_500, 4));
    let verdict = match verify_on(&island, &replay) {
        Ok(o) => format!("ok {:?} {} {} {} {}", o.grade, o.out, o.caught, o.banked, o.capacity),
        Err(r) => format!("refused {r:?}"),
    };
    println!("validator {} {} {} {verdict}", hex(&rules_version()), hex(&island.digest()),
             hex(&sha256(&replay.encode())));
}
