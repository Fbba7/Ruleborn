"""§9.6's raid-worth check, run with the roster the model actually staffs.

    "At every Vault level, an average attempt pays at least what the same
    characters would have produced working over the heist and its rest —
    3 minutes away and 45 resting (11.6). The attempt is priced at the band's
    lower edge, with fatigue averaged over an engaged player's four heists a
    day (14.1)."

The document computed it from §10.2's ladders and build days and set the base
at 2,400, "the smallest hundred that passes at every level"; §32.9 hands the
re-check to this model: "if an attempt fails at any level, the base rises until
it passes, and the pacing is recomputed". So the check runs on every day of a
run, not only the day a Vault level is reached — a raid that pays less than
staying home on day 60 is as skipped as one on day 30 — and the day it binds
is the one reported.

What a character produces is all three currencies an hour per staffed worker,
which is how §9.6's "about 109 an hour a worker" at Vault level 2 reads: this
model gives 104 on the day an engaged player reaches it.
"""

from dataclasses import dataclass, replace

from . import data
from .config import Config
from .model import EconomyModel

#: 3 minutes away and 45 resting (§9.6, citing §11.6).
HOURS_AWAY = data.CREW_HOURS_PER_HEIST
#: "fatigue averaged over an engaged player's four heists a day (14.1)".
HEISTS = data.ARCHETYPES["engaged"].heists_per_day


@dataclass
class Level:
    vault: int
    first_day: int
    last_day: int
    binding_day: int        # the day staying home was worth most against a raid
    crew: int
    per_worker_hour: float  # all three currencies, on the binding day
    stay_home: float        # the crew's output over the heist and its rest
    attempt: float          # B(V) x the band's lower edge x average fatigue
    stay_home_first: float  # the same on the day the level is reached

    @property
    def ratio(self) -> float:
        return self.attempt / self.stay_home if self.stay_home else float("inf")

    @property
    def ratio_first(self) -> float:
        """The document's reading: §10.2's build days, the day a level arrives."""
        return self.attempt / self.stay_home_first if self.stay_home_first else float("inf")


def attempt_value(base: float, vault: int, edge: float, success: float = 0.0,
                  fee: bool = False) -> float:
    """B(V) x the band's lower edge x average fatigue, less the fee an attempt
    keeps in expectation when the fee is on (F39: 2% of B(V); C41: returned
    after a clean or loud heist and half after a partial one)."""
    fatigue = EconomyModel.fatigue_sum(HEISTS) / HEISTS
    b = base * data.HAUL_GROWTH ** (vault - 1)
    kept = data.ENTRY_FEE_RATE * b * (1 - success * data.FEE_RETURNED_SHARE_OF_SUCCESSES)
    return b * edge * fatigue - (kept if fee else 0.0)


def levels(cfg: Config, days: int) -> list[Level]:
    """One row per Vault level the run reaches, at the day it binds."""
    edge = data.ATTEMPT_BAND[0]
    model = EconomyModel(replace(cfg, archetype="engaged"))
    rows: dict[int, Level] = {}
    for _ in range(days):
        model.step()
        vault = model.vault_level()
        hourly = sum(model.hourly_production().values())
        staffed = min(model.producer_slots(),
                      model.roster_size() - model.workers_withheld_by_raiding())
        per_worker = hourly / staffed if staffed > 0 else 0.0
        crew = model.crew_size()
        stay = crew * per_worker * HOURS_AWAY
        row = rows.get(vault)
        if row is None:
            success = data.heist_success_rate(model.s.day)
            rows[vault] = Level(vault, model.s.day, model.s.day, model.s.day, crew,
                                per_worker, stay,
                                attempt_value(cfg.haul_base, vault, edge, success, cfg.entry_fee),
                                stay)
            continue
        row.last_day = model.s.day
        if stay > row.stay_home:
            row.binding_day, row.crew = model.s.day, crew
            row.per_worker_hour, row.stay_home = per_worker, stay
    return [rows[v] for v in sorted(rows)]


def passes(cfg: Config, days: int, first_day_only: bool = False) -> bool:
    return all((r.ratio_first if first_day_only else r.ratio) >= 1
               for r in levels(cfg, days))


def smallest_passing_base(cfg: Config, days: int, first_day_only: bool = False,
                          step: int = 100, ceiling: int = 100_000) -> int:
    """The smallest hundred at which an attempt pays at every level.

    Re-runs the whole model at each base, because the base changes the run:
    more raid income buys producers sooner, which raises what staying home is
    worth. Not monotone in principle, so it walks up from one step rather than
    bisecting.
    """
    base = step
    while base <= ceiling:
        if passes(replace(cfg, haul_base=base), days, first_day_only):
            return base
        base += step
    raise ValueError(f"no base up to {ceiling:,} passes the raid-worth check")
