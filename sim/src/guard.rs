//! What a guard is doing. §12.17's table, as a state machine:
//!
//! | State         | At                           | What the guard does                              |
//! |---------------|------------------------------|--------------------------------------------------|
//! | Unaware       | under 200                    | Patrols or holds its post                        |
//! | Suspicious    | 200 to 599                   | Stops, turns toward it, stays on route           |
//! | Investigating | 600, or on hearing something | Walks to the spot and searches nearby for 10 s   |
//! | Alerted       | 1000                         | Calls out, converges, raises the alarm           |
//! | Searching     | After losing sight           | Twenty seconds of wider, faster searching        |
//! | Returning     | After giving up              | Walks home, still easily re-alerted              |
//!
//! And one rule about all of them: "A state cannot fall back for half a
//! second once reached, so nothing flickers at the edge of a zone." Rising is
//! immediate; falling waits `HOLD_TICKS`.
//!
//! Two words in the table are not numbers and are not invented here:
//! Searching's "wider, faster" has no figure, so a searching guard sweeps at
//! its ordinary turn rate; and no section gives a guard's walking speed, so a
//! guard walks at §12.18's crew walk, the only walk speed the document states.

use crate::TICKS_PER_SECOND;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
#[repr(u8)]
pub enum State {
    Unaware = 0,
    Suspicious = 1,
    Investigating = 2,
    Alerted = 3,
    Searching = 4,
    Returning = 5,
}

impl State {
    /// How alarmed. Rising in rank is immediate; falling is held. Returning
    /// ranks with Unaware because the table says it is "still easily
    /// re-alerted", and Searching with Investigating because both are looking.
    pub fn rank(self) -> u8 {
        match self {
            State::Unaware | State::Returning => 0,
            State::Suspicious => 1,
            State::Investigating | State::Searching => 2,
            State::Alerted => 3,
        }
    }

    /// The state suspicion alone implies, at §12.17's thresholds.
    pub fn from_suspicion(suspicion: i32) -> State {
        if suspicion >= crate::ALERTED_AT {
            State::Alerted
        } else if suspicion >= crate::INVESTIGATING_AT {
            State::Investigating
        } else if suspicion >= crate::SUSPICIOUS_AT {
            State::Suspicious
        } else {
            State::Unaware
        }
    }
}

/// "A state cannot fall back for half a second once reached."
pub const HOLD_TICKS: u32 = TICKS_PER_SECOND / 2;
/// Investigating: "searches nearby for ten seconds".
pub const SEARCH_SPOT_TICKS: u32 = TICKS_PER_SECOND * 10;
/// Searching: "twenty seconds of wider, faster searching".
pub const SEARCHING_TICKS: u32 = TICKS_PER_SECOND * 20;
/// "Guards within four metres start investigating half a second later."
pub const SPREAD_METRES: i32 = 4;
/// A Lantern Glare shows the crew to the guards within this of it (F33,
/// decided): a fixed reach, which laws that widen the alarm do not change
/// (F52, decided), where §10.3 still reads "every guard in the realm".
pub const GLARE_METRES: i32 = 4;
pub const SPREAD_DELAY_TICKS: u32 = TICKS_PER_SECOND / 2;
/// The realm alarm "climbs from 0 to 6 — once every thirty seconds and once
/// per knocked-out guard discovered — and at 5 another Warden arrives".
pub const ALARM_STEP_TICKS: u32 = TICKS_PER_SECOND * 30;
pub const ALARM_MAX: i32 = 6;
pub const REINFORCE_AT: i32 = 5;
