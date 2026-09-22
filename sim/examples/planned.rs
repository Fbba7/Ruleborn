//! The planned heist, second by second: where the crew is, the Vault, and
//! every guard's state. `cargo run --release --example planned`
use ruleborn_sim::{planned, World, heist::Standing};

fn main() {
    let heist = planned();
    let mut world = World::new(heist.seed, heist.crew, heist.commands.clone());
    world.clock = heist.ticks;
    for _ in 0..heist.ticks {
        world.step();
        if world.tick % 30 == 0 {
            let crew: Vec<String> = world.raiders.iter().map(|r| {
                let t = world.grid.tile_at(r.at.x, r.at.y).map(|t| world.grid.coords(t));
                format!("{:?}{:?}h{}c{}", r.standing, t.unwrap_or((99, 99)), r.health, r.carried)
            }).collect();
            let guards: String = world.guards.iter().map(|g| if g.knocked_out { "K".into() } else { format!("{}", g.state as u8) }).collect::<Vec<String>>().join("");
            println!("{:>3}s vault {:>4}/{:>3} guards {} sus {:?} {}", world.tick / 30,
                     world.vault.health, world.vault.exposed, guards,
                     world.guards.iter().map(|g| g.suspicion).collect::<Vec<_>>(), crew.join(" "));
            if world.raiders.iter().all(|r| matches!(r.standing, Standing::Out | Standing::Caught)) {
                break;
            }
        }
    }
    println!("{:?}", world.outcome());
}
