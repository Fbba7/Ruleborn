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
    if !grid.standable(to) || !grid.standable(from) {
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

/// The shortest route for the crew, which may go through a tunnel: §6.2's
/// "hidden path joining two points up to 6 tiles apart" (TD.38). A tunnel is
/// one more way out of its mouth, after the four neighbours, as long as the
/// walk between the mouths, so a route through one is the shortest by the
/// tiles it walks. With no tunnel on the grid it is `find` itself.
///
/// Breadth-first still, by distance: a bucket for each distance, each a queue
/// in the order tiles were put in it, so the ties are §12.18's — the fixed
/// neighbour order, then the order tiles were reached. A tile reached again by
/// a shorter way moves to the nearer bucket; one already taken out is final.
/// Guards keep to the surface and use `find`: the defender built the tunnel
/// for the crew to look for.
pub fn find_through(grid: &Grid, from: TileIndex, to: TileIndex) -> Option<Route> {
    if !grid.has_tunnels() {
        return find(grid, from, to);
    }
    if from == to {
        return Some(Vec::new());
    }
    if !grid.standable(to) || !grid.standable(from) {
        return None;
    }
    let n = grid.len();
    let mut dist = vec![u32::MAX; n];
    let mut done = vec![false; n];
    let mut came_from: Vec<Option<TileIndex>> = vec![None; n];
    let mut buckets: Vec<std::collections::VecDeque<TileIndex>> = Vec::new();
    let put = |buckets: &mut Vec<std::collections::VecDeque<TileIndex>>, d: u32, t: TileIndex| {
        while buckets.len() <= d as usize {
            buckets.push(std::collections::VecDeque::new());
        }
        buckets[d as usize].push_back(t);
    };
    dist[from as usize] = 0;
    put(&mut buckets, 0, from);
    let mut d = 0usize;
    while d < buckets.len() {
        let Some(tile) = buckets[d].pop_front() else {
            d += 1;
            continue;
        };
        if done[tile as usize] || dist[tile as usize] != d as u32 {
            continue;
        }
        done[tile as usize] = true;
        if tile == to {
            return Some(walk_back(&came_from, from, to));
        }
        let mut ways: Vec<(TileIndex, u32)> = grid.neighbours(tile).into_iter().flatten()
            .filter(|&nb| grid.can_step(tile, nb))
            .map(|nb| (nb, 1))
            .collect();
        // A mouth under a raised wall is no way out (bug report candidate 34).
        if let Some(exit) = grid.tunnel_exit(tile).filter(|&e| grid.at(e).passable()) {
            ways.push((exit, grid.walk_tiles(tile, exit) as u32));
        }
        for (next, cost) in ways {
            let nd = d as u32 + cost;
            if done[next as usize] || nd >= dist[next as usize] {
                continue;
            }
            dist[next as usize] = nd;
            came_from[next as usize] = Some(tile);
            put(&mut buckets, nd, next);
        }
    }
    None
}

/// The shortest route that may float over one wall: Drifting echoes'
/// "returning echoes float and can pass over one wall". A wall is a tile
/// nobody can stand on, and passing over it goes from the tile before it to
/// the tile beyond, in a straight line, with the wall itself on the route.
/// The same breadth-first search in §12.18's order, over (tile, wall used),
/// with a tile's plain steps tried before the float from it. Returns the
/// route and whether it used the wall.
pub fn find_over_wall(grid: &Grid, from: TileIndex, to: TileIndex) -> Option<(Route, bool)> {
    if from == to {
        return Some((Vec::new(), false));
    }
    if !grid.standable(to) || !grid.standable(from) {
        return None;
    }
    let n = grid.len();
    let state = |t: TileIndex, used: bool| t as usize * 2 + used as usize;
    // For each state: the state it came from, and the wall floated over.
    let mut came: Vec<Option<(usize, Option<TileIndex>)>> = vec![None; n * 2];
    let mut seen = vec![false; n * 2];
    let mut frontier = std::collections::VecDeque::new();
    seen[state(from, false)] = true;
    frontier.push_back((from, false));
    while let Some((tile, used)) = frontier.pop_front() {
        let here = state(tile, used);
        let mut steps: Vec<(TileIndex, bool, Option<TileIndex>)> = Vec::new();
        for next in grid.neighbours(tile).into_iter().flatten() {
            if grid.can_step(tile, next) {
                steps.push((next, used, None));
            }
        }
        if !used {
            let (tx, ty) = grid.coords(tile);
            for wall in grid.neighbours(tile).into_iter().flatten() {
                if grid.at(wall).passable() {
                    continue;
                }
                let (wx, wy) = grid.coords(wall);
                let (bx, by) = (2 * wx as i32 - tx as i32, 2 * wy as i32 - ty as i32);
                if bx < 0 || by < 0 {
                    continue;
                }
                if let Some(beyond) = grid.index(bx as u16, by as u16) {
                    if grid.at(beyond).passable() {
                        steps.push((beyond, true, Some(wall)));
                    }
                }
            }
        }
        for (next, u, wall) in steps {
            let s = state(next, u);
            if seen[s] {
                continue;
            }
            seen[s] = true;
            came[s] = Some((here, wall));
            if next == to {
                let mut route = Vec::new();
                let mut at = s;
                while at != state(from, false) {
                    route.push((at / 2) as TileIndex);
                    let (prev, wall) = came[at].expect("every state reached has a parent");
                    if let Some(w) = wall {
                        route.push(w);
                    }
                    at = prev;
                }
                route.reverse();
                return Some((route, u));
            }
            frontier.push_back((next, u));
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
                grid.standable(neighbour)
            } else {
                grid.standable(neighbour) && grid.can_step(neighbour, tile)
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
