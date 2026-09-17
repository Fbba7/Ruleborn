"""Day-by-day economy simulation for Ruleborn.

Rebuilds the model §24 says generated the tables in §10.2, §14.2, §14.3 and §5.5,
which is not itself in the design document (docs/analysis/04-specification-gaps.md,
gap G7). Everything it needs is in `data.py`; every choice the document leaves
open is in `config.py`.

The simulation runs at one-day granularity. Within a day it:

  1. collects production (bounded by 12-hour storage and sessions per day),
  2. runs heists,
  3. spends Starlight on upgrades under the §14.1 purchase policy,
  4. awards Keeper experience and applies any level-ups.
"""

from dataclasses import dataclass, field

from . import data
from .config import Config


@dataclass
class Realm:
    """The Heart or one outer realm."""
    kind: str                       # "heart" | "outer"
    level: int = 1                  # outer realms only; the Heart tracks the Spire
    buildings: dict[str, list[int]] = field(default_factory=dict)

    def levels(self, name: str) -> list[int]:
        return self.buildings.setdefault(name, [])


@dataclass
class State:
    day: int = 0
    keeper_level: int = 1
    keeper_xp: int = 0
    spire_level: int = 1
    starlight: float = 0.0
    aether: float = 0.0
    essence: float = 0.0
    starlight_spent: float = 0.0
    laws_restored: int = 3          # Half gravity, Slow rivers, Bloom (§7.6)
    pages: float = 0.0
    realms: list[Realm] = field(default_factory=list)
    log: list[dict] = field(default_factory=list)
    milestones: dict[str, int] = field(default_factory=dict)
    keeper_level_days: dict[int, int] = field(default_factory=dict)

    def mark(self, name: str) -> None:
        self.milestones.setdefault(name, self.day)


class EconomyModel:
    def __init__(self, config: Config | None = None):
        self.cfg = config or Config()
        self.arch = data.ARCHETYPES[self.cfg.archetype]
        self.s = State()
        heart = Realm("heart")
        heart.levels("Star Well").append(1)
        heart.levels("Aether Spring").append(1)
        heart.levels("Garden").append(1)
        heart.levels("Vault").append(1)
        heart.levels("Hearth").append(1)
        self.s.realms.append(heart)
        self.s.keeper_level_days[1] = 0

    # -- capacity ---------------------------------------------------------

    def roster_size(self) -> int:
        """§11.5: three places at the Spire plus the places in every Hearth."""
        homes = 0
        for realm in self.s.realms:
            for lvl in realm.levels("Hearth"):
                homes += data.HEARTH_HOMES[lvl - 1]
        return 3 + homes

    def stability_capacity(self) -> int:
        cap = data.spire_stability(self.s.spire_level)
        for realm in self.s.realms:
            for lvl in realm.levels("Anchor Stone"):
                cap += data.anchor_stability(lvl)
        return cap

    def law_slots(self) -> int:
        """Realm law slots plus crown slots (§5.1, §5.2)."""
        slots = data.HEART_LAW_SLOTS
        for realm in self.s.realms[1:]:
            slots += data.REALM_LAW_SLOTS[realm.level - 1]
        crown = 0
        if self.s.spire_level >= 2:
            crown += 1
        if self.s.spire_level >= 5:
            crown += 1
        return slots + crown

    def laws_woven(self) -> int:
        return min(self.s.laws_restored, self.law_slots())

    def strain(self) -> float:
        """Approximate strain, for reporting against §5.5's worked example.

        §5.5's cost formula needs each law's identity. The model uses the mean
        stability cost of the ranks a player is likely to own at that point,
        with the school-match discount the config assumes.
        """
        woven = self.laws_woven()
        if woven == 0:
            return 0.0
        mean_cost = 13.6 if self.s.laws_restored <= 12 else 16.0   # §05 finding 5
        discount = 0.8 if self.cfg.laws_match_realm_school else 1.0
        return (woven * mean_cost * discount) / max(1, self.stability_capacity())

    def band_multiplier(self) -> float:
        strain = self.strain()
        for upper, mult, _ in data.STRAIN_BANDS:
            if strain < upper:
                return mult
        return 1.15

    def band_name(self) -> str:
        strain = self.strain()
        for upper, _, name in data.STRAIN_BANDS:
            if strain < upper:
                return name
        return "Breaking"

    # -- production -------------------------------------------------------

    def crew_size(self) -> int:
        """§12.5: 3 characters, 4 from Keeper level 8, 5 from level 16."""
        if self.s.keeper_level >= 16:
            return 5
        if self.s.keeper_level >= 8:
            return 4
        return 3

    def workers_withheld_by_raiding(self) -> float:
        """How much of the roster raiding actually costs, as whole-day equivalents.

        A heist is 3 minutes (§12.6) and a clean escape rests the crew 45 minutes
        (§11.6, §12.9), so a raider is unavailable for ~0.8 hours per heist, not
        for the day. This is what §11.6 calls the core trade-off of the game.
        """
        if self.cfg.crew_assigned_not_timed:
            # §5.9: the crew is assigned to the heist, like a guard to a post.
            # Whether they raid once or four times a day does not change it.
            return float(self.crew_size()) if self.arch.heists_per_day else 0.0
        hours_away = self.crew_size() * self.arch.heists_per_day * data.CREW_HOURS_PER_HEIST
        return hours_away / 24.0

    def producer_slots(self) -> int:
        """Total worker slots across every producing building the player owns."""
        total = 0
        for realm in self.s.realms:
            for spec in data.BUILDINGS.values():
                if not spec.resource:
                    continue
                for lvl in realm.levels(spec.name):
                    total += spec.slots[lvl - 1]
        return total

    def _workers_for(self, slots: int, available: float) -> int:
        if available == float("inf"):
            return slots
        return min(slots, max(0, int(available)))

    def hourly_production(self) -> dict[str, float]:
        """Output per hour across the whole universe, fully staffed where possible."""
        if self.cfg.enforce_worker_cap:
            workers_left = self.roster_size() - self.workers_withheld_by_raiding()
        else:
            workers_left = float("inf")
        out = {"starlight": 0.0, "aether": 0.0, "essence": 0.0}
        band = self.band_multiplier()
        self._last_unstaffed_slots = 0

        producers = [b for b in data.BUILDINGS.values() if b.resource]
        for realm in self.s.realms:
            law_slots = (
                data.HEART_LAW_SLOTS if realm.kind == "heart"
                else data.REALM_LAW_SLOTS[realm.level - 1]
            )
            for spec in producers:
                for lvl in realm.levels(spec.name):
                    slots = spec.slots[lvl - 1]
                    workers = self._workers_for(slots, workers_left)
                    workers_left -= workers
                    self._last_unstaffed_slots += slots - workers
                    if workers == 0:
                        continue
                    staffing = self._staffing(workers, slots)
                    law_bonus = 1.0
                    realm_match = 1.0
                    if self.cfg.laws_match_realm_school and realm.kind == "outer":
                        law_bonus += data.REALM_LAW_BONUS * min(law_slots, self.s.laws_restored)
                        realm_match = data.REALM_MATCH_BONUS
                    if self.s.spire_level >= 2:
                        law_bonus += data.CROWN_LAW_BONUS
                    out[spec.resource] += (
                        spec.hourly[lvl - 1] * staffing * law_bonus * realm_match * band
                    )
        return out

    def _staffing(self, workers: int, slots: int) -> float:
        """§9.2's table, or §5.8's pro-rata share. See Config.staffing_rule.

        §5.8 was §5.9 until v3.1 renumbered the chapter, and this line said
        §5.9 until C27 was re-checked — which is the fault the register calls
        a renumbering never being only clerical, committed by the code that
        implements the rule.

        §9.3's formula states the same table a third time, as the coefficient
        `staffing (0.6, 0.85 or 1.0)`. That is the one this function is, and
        it is why switching `staffing_rule` measures something.
        """
        if self.cfg.staffing_rule == "pro_rata":
            return workers / slots
        if workers == slots and self.cfg.full_staffing_is_always_100:
            return 1.0
        return data.STAFFING[min(workers, 3)]

    def daily_production(self) -> dict[str, float]:
        """What actually reaches the player, after the 12-hour storage cap (§14.1)."""
        collected_hours = min(24, self.arch.sessions_per_day * data.STORAGE_HOURS)
        hourly = self.hourly_production()
        return {k: v * collected_hours for k, v in hourly.items()}

    # -- raiding ----------------------------------------------------------

    def vault_level(self) -> int:
        levels = self.s.realms[0].levels("Vault")
        return levels[0] if levels else 1

    def mean_realm_level(self) -> int:
        outer = self.s.realms[1:]
        return round(sum(r.level for r in outer) / len(outer)) if outer else 1

    def heist_income(self, daily_starlight: float) -> float:
        n = self.arch.heists_per_day
        if self.cfg.faucet == "share":
            # §9.4: a successful heist brings about a fifth of a day's production.
            rate = data.heist_success_rate(self.s.day)
            return daily_starlight * data.HEIST_SHARE_OF_DAILY_PRODUCTION * n * rate
        if self.cfg.faucet == "pegged":
            # docs/design/spec/economy.md: B(L) replaced by the raider's own
            # daily production. Every other term of §9.6 is unchanged, so the
            # fatigue curve and the average-per-attempt factor still apply.
            fatigue = sum(data.HAUL_FATIGUE ** i for i in range(n))
            return (daily_starlight * self.cfg.peg_share
                    * self._value_per_attempt() * fatigue)
        # §9.6: minted from the raider's own level, decaying through the day.
        level = self.cfg.haul_level(
            self.vault_level(), self.mean_realm_level(), self.s.keeper_level
        )
        base = data.HAUL_BASE * data.HAUL_GROWTH ** (level - 1)
        fatigue = sum(data.HAUL_FATIGUE ** i for i in range(n))
        return base * self._value_per_attempt() * fatigue

    def _value_per_attempt(self) -> float:
        """§9.6's 0.46, times v3.0's `fill` term where it is being applied.

        §9.6 calls 0.46 "the number the progression curve is built on" and then
        v3.0 multiplied the haul by `fill` without re-deriving it. `apply_fill`
        puts the measured value in, which is how the size of that omission gets
        a number rather than an argument.
        """
        value = data.HAUL_VALUE_PER_ATTEMPT
        if self.cfg.apply_fill:
            value *= data.MEASURED_FILL_ON_SUCCESS
        return value

    # -- spending ---------------------------------------------------------

    def _spire_upgrade(self) -> tuple[str, int, int] | None:
        nxt = self.s.spire_level + 1
        if nxt > 10:
            return None
        if self.s.keeper_level < data.SPIRE_KEEPER_LEVEL[nxt - 1]:
            return None
        return ("Keeper's Spire", nxt, data.SPIRE.costs[nxt - 1])

    def _available_upgrades(self) -> list[tuple[float, str, Realm, str, int]]:
        """Every purchase the player could make now, as (cost, kind, realm, name, level)."""
        options: list[tuple[float, str, Realm, str, int]] = []

        # A new outer realm.
        owned_outer = len(self.s.realms) - 1
        if owned_outer < 6:
            need = data.REALM_UNLOCK_KEEPER_LEVEL[owned_outer]
            if self.s.keeper_level >= need:
                options.append((data.REALM_OPEN_COST, "realm-open", self.s.realms[0], "", 0))

        for realm in self.s.realms:
            # Raising an outer realm's level.
            if realm.kind == "outer" and realm.level < 5:
                idx = realm.level - 1
                if self.s.spire_level >= data.REALM_LEVEL_SPIRE[idx]:
                    options.append(
                        (data.REALM_LEVEL_COSTS[idx], "realm-level", realm, "", realm.level + 1)
                    )

            for name, spec in data.BUILDINGS.items():
                if spec.placement == "heart" and realm.kind != "heart":
                    continue
                if spec.placement == "outer" and realm.kind != "outer":
                    continue
                if not self.cfg.buy_non_producers and not spec.resource:
                    if name not in ("Anchor Stone", "Hearth", "Vault"):
                        continue

                allowed = self._allowed_count(spec, realm)
                current = realm.levels(name)

                # Build a new one of this kind.
                if len(current) < allowed and self.s.spire_level >= spec.spire_required[0]:
                    options.append((spec.costs[0], "build", realm, name, 1))

                # Upgrade an existing one, cheapest (lowest-level) first.
                for i, lvl in enumerate(current):
                    if lvl >= len(spec.costs):
                        continue
                    if self.s.spire_level < spec.spire_required[lvl]:
                        continue
                    options.append((spec.costs[lvl], "upgrade", realm, name, i))
                    break

        return options

    def _allowed_count(self, spec: data.Building, realm: Realm) -> int:
        if not spec.resource:
            if spec.name == "Law Pylon":
                return (
                    data.HEART_LAW_SLOTS if realm.kind == "heart"
                    else data.REALM_LAW_SLOTS[realm.level - 1]
                )
            if spec.name == "Ward":
                return 3 + (1 if realm.kind == "heart" else realm.level)
            if spec.name == "Guardian Post":
                return 1 if realm.level < 4 else 3
            return spec.per_realm
        if self.cfg.producers_per_realm_override is not None:
            return self.cfg.producers_per_realm_override
        if realm.kind == "heart":
            return 2 if self.s.spire_level >= self.cfg.heart_second_producer_at_spire else 1
        return data.PRODUCERS_PER_REALM[realm.level - 1]

    def _buy(self, option: tuple[float, str, Realm, str, int]) -> None:
        cost, kind, realm, name, target = option
        self.s.starlight -= cost
        self.s.starlight_spent += cost
        if kind == "realm-open":
            new = Realm("outer", level=1)
            new.levels("Star Well").append(1)
            new.levels("Anchor Stone").append(1)
            self.s.realms.append(new)
            self.s.mark(f"Outer realm {len(self.s.realms) - 1} opens")
        elif kind == "realm-level":
            realm.level = target
        elif kind == "build":
            realm.levels(name).append(1)
        else:
            realm.levels(name)[target] += 1
            if name == "Vault":
                self.s.mark(f"Vault level {realm.levels(name)[target]}")

    def spend(self) -> None:
        """§14.1: save for the next Spire level first, then the cheapest upgrade."""
        for _ in range(60):   # bounded: at most sixty purchases in a day
            spire = self._spire_upgrade()
            if spire and self.s.starlight >= spire[2]:
                self.s.starlight -= spire[2]
                self.s.starlight_spent += spire[2]
                self.s.spire_level += 1
                self.s.mark(f"Spire level {self.s.spire_level}")
                continue
            # §14.1's "save for the next Spire level first" is read as a priority,
            # not a reserve: reserving the Spire's full cost would stall every other
            # purchase from Spire level 9 onward, when the Spire costs 1.2M Starlight.
            budget = self.s.starlight
            options = self._available_upgrades()
            if self.cfg.producers_first:
                options.sort(key=lambda o: (o[3] not in ("Star Well", "Aether Spring", "Garden"), o[0]))
            else:
                options.sort(key=lambda o: o[0])
            affordable = [o for o in options if o[0] <= max(budget, 0)]
            if not affordable:
                return
            self._buy(affordable[0])

    # -- progression ------------------------------------------------------

    def award_xp(self, successes: int, failures: int, spent: float) -> None:
        lvl = self.s.keeper_level
        xp = successes * (data.XP_PER_SUCCESSFUL_HEIST[0] + data.XP_PER_SUCCESSFUL_HEIST[1] * lvl)
        xp += failures * (data.XP_PER_FOILED_HEIST[0] + data.XP_PER_FOILED_HEIST[1] * lvl)
        xp += spent / data.STARLIGHT_PER_XP
        self.s.keeper_xp += xp
        while self.s.keeper_level < data.KEEPER_LEVEL_CAP:
            need = data.KEEPER_XP_TO_NEXT[self.s.keeper_level - 1]
            if self.s.keeper_xp < need:
                break
            self.s.keeper_xp -= need
            self.s.keeper_level += 1
            self.s.keeper_level_days.setdefault(self.s.keeper_level, self.s.day)

    def restore_laws(self) -> None:
        """A coarse page economy: §14.4 says an engaged player earns ~11 pages a day."""
        pages_per_heist = 2.5 + 1.0          # study + a pylon or a new law met
        self.s.pages += self.arch.heists_per_day * pages_per_heist + 2   # + daily goals
        # Restore in rank order: 18 commons at 15, then 18 rares at 30, then 12 deep at 60.
        while self.s.laws_restored < 48:
            n = self.s.laws_restored
            cost = 15 if n < 18 else (30 if n < 36 else 60)
            if self.s.pages < cost:
                break
            self.s.pages -= cost
            self.s.laws_restored += 1
            lvl = self.s.keeper_level
            self.s.keeper_xp += data.XP_PER_LAW_RESTORED[0] + data.XP_PER_LAW_RESTORED[1] * lvl
            if self.s.laws_restored in (12, 24, 36, 48):
                self.s.mark(f"{self.s.laws_restored} laws owned")

    # -- the loop ---------------------------------------------------------

    def step(self) -> None:
        self.s.day += 1
        produced = self.daily_production()
        self.s.starlight += produced["starlight"]
        self.s.aether += produced["aether"]
        self.s.essence += produced["essence"]

        self.s.starlight += self.heist_income(produced["starlight"])

        before = self.s.starlight_spent
        self.spend()
        spent_today = self.s.starlight_spent - before

        rate = data.heist_success_rate(self.s.day)
        successes = round(self.arch.heists_per_day * rate)
        failures = self.arch.heists_per_day - successes
        self.award_xp(successes, failures, spent_today)
        self.restore_laws()

        self.s.log.append({
            "day": self.s.day,
            "keeper_level": self.s.keeper_level,
            "spire": self.s.spire_level,
            "realms": len(self.s.realms) - 1,
            "starlight_per_day": produced["starlight"],
            "aether_per_day": produced["aether"],
            "essence_per_day": produced["essence"],
            "heist_income": self.heist_income(produced["starlight"]),
            "stability_capacity": self.stability_capacity(),
            "laws_restored": self.s.laws_restored,
            "laws_woven": self.laws_woven(),
            "strain": self.strain(),
            "band": self.band_name(),
            "roster": self.roster_size(),
        })

    def run(self, days: int | None = None) -> State:
        for _ in range(days or self.cfg.days):
            self.step()
        return self.s
