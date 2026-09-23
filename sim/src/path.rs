//! Pathfinding. §12.18: "Breadth-first on the tile graph with a fixed
//! neighbour order, ties broken by tile index. Deterministic by construction
//! (24.10)."
//!
//! Breadth-first rather than A*, and that is a decision the document makes
//! rather than an economy. A* is faster and its result depends on the
//! heuristic, on the tie-breaking inside the open set, and on the order a
//! priority queue returns equal keys in — three places two implementations
//! can differ while both being correct. Breadth-first on a small grid has one
//! answer and reaching it needs no ordering beyond the neighbour order and the
//! tile index, both of which are stated.
//!
//! §12.18 also says what is stored: "The command, never the path. A
//! destination and a tick, so the same route is recomputed identically on the
//! server." So this runs on both sides and has to agree; it is not an
//! optimisation the client may vary.

use crate::grid::{Grid, TileIndex};

/// A route as tiles to walk, from the tile after the start to the goal.
/// Empty means the crew member is already there; `None` means no route exists,
/// and §12.18 says what happens then: nothing. "No automatic re-routing around
/// a guard the player walked them into, no picking a different door."
pub type Route = Vec<TileIndex>;

/// The shortest route from `from` to `to`, or `None` if there is none.
///
/// Ties are broken twice over, and both are §12.18's: the frontier is walked
/// in the order tiles entered it, and each tile's neighbours are visited in
/// the fixed north-east-south-west order. Two tiles at the same distance can
/// therefore never be reached in an order that depends on anything but the
/// grid itself.
pub fn find(grid: &Grid, from: TileIndex, to: TileIndex) -> Option<Route> {
    if from == to {
        return Some(Vec::new());
    }
    if !grid.at(to).passable() || !grid.at(from).passable() {
        return None;
    }
    // A vector indexed by tile, not a map: §24.10's "iterating a map in
    // whatever order it happens to be in is one of the three classic causes
    // of divergence". Nothing here iterates it, but the habit is the point.
    let mut came_from: Vec<Option<TileIndex>> = vec![None; grid.len()];
    let mut seen = vec![false; grid.len()];
    let mut frontier = std::collections::VecDeque::with_capacity(grid.len());

    seen[from as usize] = true;
    frontier.push_back(from);

    while let Some(tile) = frontier.pop_front() {
        for neighbour in grid.neighbours(tile).into_iter().flatten() {
            // Height makes a step one-way: down a cliff, never up it.
            if seen[neighbour as usize] || !grid.can_step(tile, neighbour) {
                continue;
            }
            seen[neighbour as usize] = true;
            came_from[neighbour as usize] = Some(tile);
            if neighbour == to {
                return Some(walk_back(&came_from, from, to));
            }
            frontier.push_back(neighbour);
        }
    }
    None
}

/// How many steps each tile is from walking to `to`, up to `limit`; `None`
/// beyond it or where no walk exists. §12.6 (v3.4): the crack calls "every
/// guard within the crack's reach of the Vault, 5 m by the walking path".
///
/// Breadth-first backwards from `to`, in §12.18's neighbour order, so a step
/// counts in the direction it is walked: a tile above a drop can reach the
/// tile below it and not the other way round. `to` itself may be impassable —
/// the Vault is — and its neighbours are then one step from it.
pub fn steps_to(grid: &Grid, to: TileIndex, limit: u16) -> Vec<Option<u16>> {
    let mut steps: Vec<Option<u16>> = vec![None; grid.len()];
    let mut frontier = std::collections::VecDeque::with_capacity(grid.len());
    steps[to as usize] = Some(0);
    frontier.push_back(to);
    while let Some(tile) = frontier.pop_front() {
        let here = steps[tile as usize].unwrap_or(0);
        if here >= limit {
            continue;
        }
        for neighbour in grid.neighbours(tile).into_iter().flatten() {
            let walks = if tile == to {
                grid.at(neighbour).passable()
            } else {
                grid.at(neighbour).passable() && grid.can_step(neighbour, tile)
            };
            if steps[neighbour as usize].is_some() || !walks {
                continue;
            }
            steps[neighbour as usize] = Some(here + 1);
            frontier.push_back(neighbour);
        }
    }
    steps
}

fn walk_back(came_from: &[Option<TileIndex>], from: TileIndex, to: TileIndex) -> Route {
    let mut route = Vec::new();
    let mut at = to;
    while at != from {
        route.push(at);
        match came_from[at as usize] {
            Some(previous) => at = previous,
            None => break,
        }
    }
    route.reverse();
    route
}
