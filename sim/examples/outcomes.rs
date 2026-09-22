//! What the fixture's heists come to, by seed: §12.9's grade, the fill, and
//! how many were caught. A reading aid, not a test — the fixture's commands
//! are drawn from the seed, not played, so these are not a balance claim.
//!
//!     cargo run --release --example outcomes

use ruleborn_sim::{fixture, World};

fn main() {
    let mut grades = std::collections::BTreeMap::new();
    for seed in 1..=200u64 {
        let heist = fixture(seed, 150 * 30, 3);
        let mut world = World::from_heist(&heist);
        for _ in 0..heist.ticks {
            world.step();
        }
        let o = world.outcome();
        *grades.entry(format!("{:?}", o.grade)).or_insert(0u32) += 1;
        if seed <= 10 {
            println!("seed {seed:>3}: {:?}, banked {} of {}, {} out, {} caught, vault {} health, {} exposed left",
                     o.grade, o.banked, o.capacity, o.out, o.caught,
                     world.vault.health, world.vault.exposed);
        }
    }
    println!("over 200 seeds: {grades:?}");
}
