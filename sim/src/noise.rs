//! Noise. §12.17: "Sound follows the walkable path rather than passing
//! through walls, so a wall genuinely muffles direction: a guard turns toward
//! the way around, not toward you."
//!
//! So a sound has a *walkable* distance, not a straight-line one, and a guard
//! that hears it turns toward the first step of the walk back to it — which,
//! behind a wall, is along the wall toward the gap and not at the raider on
//! the far side.
//!
//! How far a sound carries is §12.17's table, in metres, and §21.1 makes a
//! tile one metre. The table has half metres in it (walking is 2.5), so radii
//! are held in half metres and compared against twice the step count: all
//! integer, and a 2.5 m sound reaches exactly two steps, not three.
//!
//! Not modelled here, and named so they are not mistaken for done: §12.17's
//! "guards far off screen hear at half strength", which needs a camera; and
//! "gravel and water are louder, moss is quieter", which needs ground types
//! the fixture does not have.

use crate::grid::{Grid, TileIndex};

/// §12.17's "Heard within", in half metres.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Sound {
    /// "Crawling — silent."
    Crawling,
    /// "Crouched walk — 1 m."
    CrouchedWalk,
    /// "Landing from one level — 2 m."
    LandingOne,
    /// Landing from two. **Not in the document**: §12.17 gives one level
    /// (2 m) and three (4 m) and nothing between; 3 m is the line through them.
    LandingTwo,
    /// "Landing from three — 4 m."
    LandingThree,
    /// "Walking — 2.5 m."
    Walking,
    /// "Running — 4.5 m."
    Running,
    /// "Breaking something — 5 m."
    Breaking,
}

impl Sound {
    pub fn half_metres(self) -> u16 {
        match self {
            Sound::Crawling => 0,
            Sound::CrouchedWalk => 2,
            Sound::Walking => 5,
            Sound::Running => 9,
            Sound::Breaking => 10,
            Sound::LandingOne => 4,
            Sound::LandingTwo => 6,
            Sound::LandingThree => 8,
        }
    }

    /// The most steps a sound carries: the largest n with 2n <= radius.
    pub fn steps(self) -> u16 {
        self.half_metres() / 2
    }

    /// The same, made on a surface. The factor is applied to the radius before
    /// it is cut to whole steps, in one division, so walking on gravel carries
    /// 2.5 x 1.25 = 3.1 m — three steps — rather than 2 x 1.25 rounded.
    pub fn steps_on(self, surface: crate::grid::Surface) -> u16 {
        self.steps_scaled(surface, (1, 1))
    }

    /// The same, with a realm law's `noise_radius` on top, still in one
    /// division at the end.
    pub fn steps_scaled(self, surface: crate::grid::Surface, (ln, ld): (i64, i64)) -> u16 {
        let (num, den) = surface.carry();
        let reach = self.half_metres() as i64 * num as i64 * ln / (den as i64 * 2 * ld);
        reach.clamp(0, u16::MAX as i64 - 1) as u16
    }
}

/// Not reached within the radius.
pub const UNHEARD: u16 = u16::MAX;

/// Walkable distance in steps from `source` to every tile, out to `max_steps`.
///
/// Breadth-first in the grid's fixed neighbour order, the same walk
/// `path::find` uses — so a sound travels exactly the way §12.18 says a crew
/// walks, and "the way a crew walks" in §12.17's heading is literal.
pub fn field(grid: &Grid, source: TileIndex, max_steps: u16) -> Vec<u16> {
    let mut dist = vec![UNHEARD; grid.len()];
    if !grid.at(source).passable() {
        return dist;
    }
    dist[source as usize] = 0;
    let mut frontier = std::collections::VecDeque::new();
    frontier.push_back(source);
    while let Some(tile) = frontier.pop_front() {
        let d = dist[tile as usize];
        if d >= max_steps {
            continue;
        }
        for next in grid.neighbours(tile).into_iter().flatten() {
            if dist[next as usize] != UNHEARD || !grid.at(next).passable() {
                continue;
            }
            dist[next as usize] = d + 1;
            frontier.push_back(next);
        }
    }
    dist
}

/// The first step from a listener toward a sound: the neighbour one step
/// nearer on the walkable path, first in the fixed order on a tie.
///
/// This is "the way around". It is `None` when the listener is standing on
/// the source, which is the one case where turning toward the sound and
/// turning toward the raider are the same thing.
pub fn way_around(grid: &Grid, field: &[u16], listener: TileIndex) -> Option<TileIndex> {
    let d = *field.get(listener as usize)?;
    if d == 0 || d == UNHEARD {
        return None;
    }
    grid.neighbours(listener)
        .into_iter()
        .flatten()
        .find(|n| field[*n as usize] == d - 1)
}
