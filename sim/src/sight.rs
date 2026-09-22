//! Line of sight on the tile grid.
//!
//! §21.12: "Sharp edges, no gradients. A tile is inside or outside." So sight
//! is a property of tiles, not of rays: a tile is seen or it is not, and the
//! question this answers is whether any tile *between* a guard and a target
//! stops sight.
//!
//! Which tiles are between
//! -----------------------
//! Every tile the straight segment between the two tile centres passes
//! through — a *supercover* line. The one case that needs a rule is a segment
//! that passes exactly through a corner, touching four tiles at a point. This
//! counts both of the side tiles as crossed, so a diagonal gap between two
//! pillars that meet at a corner is not a window.
//!
//! That choice is made for determinism before it is made for taste. The
//! common alternative — step in x or y whichever the error term prefers, and
//! pick one on a tie — gives a different set of tiles from each end, so a
//! guard could see a raider the raider's line to the guard says is hidden.
//! Counting both on a tie makes the set of tiles the same whichever end it is
//! walked from, and `a_line_is_the_same_from_either_end` checks that.
//!
//! All integer arithmetic: an error term in doubled units, no division, no
//! slope. The same tiles on every target by construction.

use crate::grid::{Grid, TileIndex};

/// Every tile a line from the centre of `from` to the centre of `to` passes
/// through, in order, both ends included.
pub fn line(grid: &Grid, from: TileIndex, to: TileIndex) -> Vec<TileIndex> {
    let (x0, y0) = grid.coords(from);
    let (x1, y1) = grid.coords(to);
    let (x0, y0, x1, y1) = (x0 as i32, y0 as i32, x1 as i32, y1 as i32);
    let dx = (x1 - x0).abs();
    let dy = (y1 - y0).abs();
    let sx = (x1 - x0).signum();
    let sy = (y1 - y0).signum();

    let mut out = Vec::with_capacity((dx + dy + 1) as usize);
    let push = |x: i32, y: i32, out: &mut Vec<TileIndex>| {
        if let Some(i) = grid.index(x as u16, y as u16) {
            out.push(i);
        }
    };

    let (mut x, mut y) = (x0, y0);
    push(x, y, &mut out);
    // Measured in doubled units so a centre-to-centre line needs no halves.
    let mut error = dx - dy;
    let (dx2, dy2) = (dx * 2, dy * 2);
    // Each step moves one tile closer in x, y or both, so dx + dy steps is an
    // upper bound; stating it means a mistake here loops a bounded number of
    // times rather than forever.
    for _ in 0..(dx + dy) {
        if x == x1 && y == y1 {
            break;
        }
        if error > 0 {
            x += sx;
            error -= dy2;
        } else if error < 0 {
            y += sy;
            error += dx2;
        } else {
            // Exactly through a corner: both side tiles are crossed.
            push(x + sx, y, &mut out);
            push(x, y + sy, &mut out);
            x += sx;
            y += sy;
            error += dx2 - dy2;
        }
        push(x, y, &mut out);
    }
    out
}

/// Whether a guard standing on `from` can see a character on `to`.
///
/// The guard's own tile never blocks — it is looking out of it. The target's
/// tile does: §6.2's fog bank "hides anyone inside", which is the target's
/// tile blocking sight and nothing else. Everything between blocks as §6.2
/// says it does.
pub fn visible(grid: &Grid, from: TileIndex, to: TileIndex) -> bool {
    line(grid, from, to).into_iter().skip(1).all(|tile| !grid.blocks_sight(tile))
}
