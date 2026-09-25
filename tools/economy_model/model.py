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
    #: The resource its school boosts (§5.2); the Heart has none.
    resource: str = ""
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
    owned: int = data.STARTING_ROSTER   # ruleborn in the roster (v34_economy only)
    #: Every character's level; the first five are the main crew.
    crew_levels: list[int] = field(default_factory=lambda: [1] * 5)
    #: Strays owed and not yet housed, as a running fraction (§11.5, §18.2).
    strays: float = 0.0
    realms: list[Realm] = field(default_factory=list)
    log: list[dict] = field(default_factory=list)
    milestones: dict[str, int] = field(default_factory=dict)
    keeper_level_days: dict[int, int] = field(default_factory=dict)
    #: §10.2's two day columns: (building, level) -> (day, income hours), for
    #: the first building of a kind to reach each level.
    built: dict[tuple[str, int], tuple[int, float]] = field(default_factory=dict)

    def mark(self, name: str) -> None:
        self.milestones.setdefault(name, self.day)


class EconomyModel:
    #: What a new universe's Heart holds at level 1 (§11.5, §10.2).
    STARTING = ("Star Well", "Aether Spring", "Garden", "Vault", "Hearth")

    def __init__(self, config: Config | None = None):
        self.cfg = config or Config()
        self.arch = data.ARCHETYPES[self.cfg.archetype]
        self.v34 = self.cfg.v34_economy
        #: §10.2's ladders: read from content/ under v3.4, transcribed otherwise.
        self.B = data.buildings_v34() if self.v34 else data.BUILDINGS
        self.codex = data.codex(self.cfg.codex == "launch") if self.v34 else []
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

    def housing(self) -> int:
        """§11.5: three places at the Spire plus the places in every Hearth."""
        homes = 0
        for realm in self.s.realms:
            for lvl in realm.levels("Hearth"):
                homes += data.HEARTH_HOMES[lvl - 1]
        return 3 + homes

    def roster_size(self) -> int:
        """The characters the player has. Before v3.4 the model filled every
        home for free; §9.5 prices each birth in Essence, so under v3.4 the
        roster is what was bought, up to the homes there are."""
        if self.v34:
            return min(self.housing(), self.s.owned)
        return self.housing()

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
            # §5.8: the crew is assigned to the heist, like a guard to a post.
            # Whether they raid once or four times a day does not change it.
            return float(self.crew_size()) if self.arch.heists_per_day else 0.0
        hours_away = self.crew_size() * self.arch.heists_per_day * data.CREW_HOURS_PER_HEIST
        return hours_away / 24.0

    def producer_slots(self) -> int:
        """Total worker slots across every producing building the player owns."""
        total = 0
        for realm in self.s.realms:
            for spec in self.B.values():
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
            workers_left = (self.roster_size() - self.workers_withheld_by_raiding()
                            - self.posts_staffed())
        else:
            workers_left = float("inf")
        out = {"starlight": 0.0, "aether": 0.0, "essence": 0.0}
        band = self.band_multiplier()
        self._last_unstaffed_slots = 0

        producers = [b for b in self.B.values() if b.resource]
        buildings = [(realm, spec, i, lvl) for realm in self.s.realms for spec in producers
                     for i, lvl in enumerate(realm.levels(spec.name))]
        staffed = self._assign_workers(buildings, workers_left)
        for (realm, spec, _, lvl), workers in zip(buildings, staffed):
            slots = spec.slots[lvl - 1]
            self._last_unstaffed_slots += slots - workers
            if workers == 0:
                continue
            staffing = self._staffing(workers, slots)
            if self.cfg.school_bonuses:
                bonus = self._school_bonus(realm, spec.resource)
            else:
                law_slots = (data.HEART_LAW_SLOTS if realm.kind == "heart"
                             else data.REALM_LAW_SLOTS[realm.level - 1])
                law_bonus = 1.0
                realm_match = 1.0
                if self.cfg.laws_match_realm_school and realm.kind == "outer":
                    law_bonus += data.REALM_LAW_BONUS * min(law_slots, self.s.laws_restored)
                    realm_match = data.REALM_MATCH_BONUS
                if self.s.spire_level >= 2:
                    law_bonus += data.CROWN_LAW_BONUS
                bonus = law_bonus * realm_match
            out[spec.resource] += spec.hourly[lvl - 1] * staffing * bonus * band
        return out

    def _assign_workers(self, buildings: list, available: float) -> list[int]:
        """Who works where. See Config.staffing_order: §9.2 leaves it to the
        player — "choosing which producer goes short is the decision"."""
        slots = [spec.slots[lvl - 1] for _, spec, _, lvl in buildings]
        if available == float("inf"):
            return slots
        left = max(0, int(available))
        if self.cfg.staffing_order == "even":
            given = [0] * len(slots)
            while left > 0 and any(g < n for g, n in zip(given, slots)):
                for i, n in enumerate(slots):
                    if left and given[i] < n:
                        given[i] += 1
                        left -= 1
            return given
        given = []
        for n in slots:
            w = min(n, left)
            given.append(w)
            left -= w
        return given

    def woven(self) -> tuple[int, dict[int, int]]:
        """How many of the restored laws are woven where: crown slots first,
        since a crown law acts in every realm, then the Heart's two realm
        slots, then each outer realm's in the order it opened (§5.1, §5.2)."""
        left = self.s.laws_restored
        crown = min(left, (1 if self.s.spire_level >= 2 else 0) + (1 if self.s.spire_level >= 5 else 0))
        left -= crown
        per_realm = {}
        for i, realm in enumerate(self.s.realms):
            slots = data.HEART_LAW_SLOTS if realm.kind == "heart" else data.REALM_LAW_SLOTS[realm.level - 1]
            per_realm[i] = min(left, slots)
            left -= per_realm[i]
        return crown, per_realm

    def _school_bonus(self, realm: Realm, resource: str) -> float:
        """§9.3: "× (1 + 0.10 per realm law of a matching school + 0.05 per
        matching crown law) × 1.1 in a realm of that school". The laws a
        realm weaves are its own school's; the Heart's and the crown's are
        Config.heart_law_resource and Config.crown_law_resource."""
        crown, per_realm = self.woven()
        index = self.s.realms.index(realm)
        law_school = realm.resource if realm.kind == "outer" else self.cfg.heart_law_resource
        bonus = 1.0
        if law_school == resource:
            bonus += data.REALM_LAW_BONUS * per_realm.get(index, 0)
        if self.cfg.crown_law_resource == resource:
            bonus += data.CROWN_LAW_BONUS * crown
        if realm.kind == "outer" and realm.resource == resource:
            bonus *= data.REALM_MATCH_BONUS
        return bonus

    def posts_staffed(self) -> int:
        """One ruleborn at every Guardian Post built, when Config.staff_posts."""
        if not self.cfg.staff_posts:
            return 0
        return sum(len(r.levels("Guardian Post")) for r in self.s.realms)

    # -- storage (§9.1) --------------------------------------------------------

    def capacity(self) -> float:
        """Starlight and Essence each: "Vault and Storehouses" (§9.1)."""
        if not self.cfg.storage_caps:
            return float("inf")
        total = 0
        for realm in self.s.realms:
            for name in ("Vault", "Storehouse"):
                spec = self.B[name]
                for lvl in realm.levels(name):
                    total += spec.holds[lvl - 1] if spec.holds else 0
        return float(total)

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
            return (daily_starlight * self.cfg.peg_share
                    * self._value_per_attempt() * self.fatigue_sum(n))
        # §9.6: minted from a Vault level's base, decaying through the day.
        return self.haul_base() * self._value_per_attempt() * self.fatigue_sum(n)

    def haul_base(self) -> float:
        """B(V) at the level `Config.haul_level_source` reads (§9.6)."""
        level = self.cfg.haul_level(
            self.vault_level(), self.mean_realm_level(), self.s.keeper_level
        )
        return self.cfg.haul_base * data.HAUL_GROWTH ** (level - 1)

    @staticmethod
    def fatigue_sum(n: int) -> float:
        """What n raids in a day are worth in first raids: 0.85 each after the
        first (§9.6), so four are worth 3.19 and six 4.15."""
        return sum(data.HAUL_FATIGUE ** i for i in range(n))

    def _value_per_attempt(self) -> float:
        """§9.6's 0.46, times v3.0's `fill` term where it is being applied.

        §9.6 calls 0.46 "the number the progression curve is built on" and then
        v3.0 multiplied the haul by `fill` without re-deriving it. `apply_fill`
        puts the measured value in, which is how the size of that omission gets
        a number rather than an argument.
        """
        if self.cfg.attempt_value is not None:
            return self.cfg.attempt_value         # §9.6's band: grade and fill in it
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

            for name, spec in self.B.items():
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
                if (len(current) < allowed and self.s.spire_level >= spec.spire_required[0]
                        and self._keeper_allows(spec, 0)):
                    options.append((spec.costs[0], "build", realm, name, 1))

                # Upgrade an existing one, cheapest (lowest-level) first.
                for i, lvl in enumerate(current):
                    if lvl >= len(spec.costs):
                        continue
                    if (self.s.spire_level < spec.spire_required[lvl]
                            or not self._keeper_allows(spec, lvl)):
                        continue
                    options.append((spec.costs[lvl], "upgrade", realm, name, i))
                    break

        return options

    def _keeper_allows(self, spec: data.Building, index: int) -> bool:
        return not spec.keeper_required or self.s.keeper_level >= spec.keeper_required[index]

    def _allowed_count(self, spec: data.Building, realm: Realm) -> int:
        if self.v34 and spec.name in ("Ward", "Guardian Post"):
            # §5.2: by realm level. The Heart counts as realm level 3, as the
            # owner decided (G19).
            table = data.WARDS_BY_REALM_LEVEL if spec.name == "Ward" else data.GUARD_POSTS
            return table[realm.level - 1] if realm.kind == "outer" else table[2]
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

    def _record(self, name: str, level: int, cost: float) -> None:
        """§10.2: "the day an engaged player's first building of that kind
        reaches the level", and the cost over that moment's hourly Starlight."""
        if level == 1 and name in self.STARTING:
            return                     # the Heart starts with one; no build day
        if (name, level) not in self.s.built:
            hourly = self.hourly_production()["starlight"]
            self.s.built[(name, level)] = (self.s.day, cost / hourly if hourly else float("inf"))

    def _buy(self, option: tuple[float, str, Realm, str, int]) -> None:
        cost, kind, realm, name, target = option
        if kind in ("build", "upgrade"):
            level = 1 if kind == "build" else realm.levels(name)[target] + 1
            self._record(name, level, cost)
        self.s.starlight -= cost
        self.s.starlight_spent += cost
        if kind == "realm-open":
            opened = len(self.s.realms) - 1
            new = Realm("outer", level=1, resource=self.cfg.realm_order[opened % 6])
            if not self.v34:
                # The model before v3.4 gave a new realm a Well and an Anchor
                # Stone; no rule does (§14.2 opens "Outer realm 1 and its
                # Nursery"), so the document's run builds them.
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

    PRODUCERS = ("Star Well", "Aether Spring", "Garden")

    def spend(self) -> None:
        """§14.1: save for the next Spire level first, then the cheapest upgrade."""
        for _ in range(80):   # bounded: at most eighty purchases in a day
            spire = self._spire_upgrade()
            if spire and self.s.starlight >= spire[2]:
                self._record("Keeper's Spire", spire[1], spire[2])
                self.s.starlight -= spire[2]
                self.s.starlight_spent += spire[2]
                self.s.spire_level += 1
                self.s.mark(f"Spire level {self.s.spire_level}")
                continue
            # "Save for the next Spire level first". As a reserve (Config.
            # spire_reserve), the Spire's cost is set aside once its Keeper gate
            # is open, and only what is above it is spent — except on storage
            # while the Spire costs more than the Vault and Storehouses hold,
            # since saving for it needs somewhere to keep it. As a priority,
            # the Spire is bought when a day's stock covers it.
            reserve = spire[2] if (spire and self.cfg.spire_reserve) else 0.0
            short_of_room = reserve > self.capacity()
            options = self._available_upgrades()
            first = self.PRODUCERS + (("",) if self.cfg.realm_open_first else ())
            if self.cfg.producers_first:
                options.sort(key=lambda o: (o[3] not in first or (o[3] == "" and o[1] != "realm-open"),
                                            o[0]))
            else:
                options.sort(key=lambda o: o[0])

            def room(o):
                if short_of_room and o[3] in ("Vault", "Storehouse"):
                    return self.s.starlight
                return self.s.starlight - reserve
            affordable = [o for o in options if o[0] <= max(room(o), 0)]
            if not affordable:
                return
            self._buy(affordable[0])

    # -- progression ------------------------------------------------------

    def award_xp(self, successes: float, failures: float, spent: float) -> None:
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
        if self.v34:
            return self._restore_laws_v34()
        pages_per_heist = 2.5 + 1.0          # study + a pylon or a new law met
        self.s.pages += self.arch.heists_per_day * pages_per_heist + 2   # + daily goals
        # Restore in rank order: 18 commons at 15, then 18 rares at 30, then 12 deep at 60.
        while self.s.laws_restored < 48:
            n = self.s.laws_restored
            cost = 15 if n < 18 else (30 if n < 36 else 60)
            if self.s.pages < cost:
                break
            self.s.pages -= cost
            self._restored()

    def _restored(self) -> None:
        self.s.laws_restored += 1
        lvl = self.s.keeper_level
        self.s.keeper_xp += data.XP_PER_LAW_RESTORED[0] + data.XP_PER_LAW_RESTORED[1] * lvl
        if self.s.laws_restored in (12, 24, 36, 48):
            self.s.mark(f"{self.s.laws_restored} laws owned")
        if self.s.laws_restored == len(self.codex):
            self.s.mark("Codex restored")

    def pages_today(self) -> float:
        """§7.6 and §14.4, source by source.

        A successful heist studies a law (2 pages, 3 if clean) and breaks a
        pylon (1); a foiled one gives 1; daily goals about 2; the Library its
        §10.4 rate. Meeting a law for the first time (1 each, at most 45 in a
        life) and Lab experiments that find nothing are left out, so this errs
        low. A player who never raids earns the Library alone (§14.4).
        """
        library = sum(data.LIBRARY_PAGES[lvl] for lvl in self.s.realms[0].levels("Library"))
        n = self.arch.heists_per_day
        track = data.FREE_TRACK_PAGES * self._track_share() / data.SEASON_DAYS
        if not n:
            # A non-raider's daily goals, one a day needing no heist (F37).
            goals = data.PAGES_DAILY_GOALS if self.cfg.decided_income else 0
            return float(library + goals + track)
        rate = data.heist_success_rate(self.s.day)
        study = data.PAGES_STUDY + data.PAGES_STUDY_CLEAN_BONUS * data.CLEAN_SHARE_OF_SUCCESSES
        return (n * rate * (study + data.PAGES_PYLON) + n * (1 - rate) * data.PAGES_FOILED
                + data.PAGES_DAILY_GOALS + library + track)

    def _track_share(self) -> float:
        """The share of the season track's free tiers this player buys in a
        season (G28): its stars over a season, at 10 a tier, of 49."""
        if not self.cfg.decided_income:
            return 0.0
        stars = self.arch.heists_per_day * data.STARS_PER_ATTEMPT * data.SEASON_DAYS
        return min(data.TRACK_TIERS, stars // data.TIER_STARS) / data.TRACK_TIERS

    def codex_open(self) -> int:
        """§7.6's chapters: how many laws the Codex holds at this Keeper level."""
        open_ = max(count for level, count in data.CODEX_CHAPTERS
                    if self.s.keeper_level >= level)
        return min(open_, len(self.codex))

    def _restore_laws_v34(self) -> None:
        """Cheapest open law first; the three starting commons are owned.

        Which laws each chapter holds is not stated by rank, so the cheapest
        remaining law is always taken to be open — the fastest the Codex can
        fill, which is the reading §14.4's own arithmetic uses."""
        self.s.pages += self.pages_today()
        while self.s.laws_restored < self.codex_open():
            cost = self.codex[self.s.laws_restored]
            if self.s.pages < cost:
                break
            self.s.pages -= cost
            self._restored()

    # -- Essence: births and levels (§9.5) -----------------------------------

    def character_cap(self) -> int:
        """§10.2's Hearth: characters rise to the level the best Hearth allows."""
        best = max((lvl for r in self.s.realms for lvl in r.levels("Hearth")), default=0)
        return data.HEARTH_CHARACTER_CAP[best - 1] if best else 1

    def spend_essence(self) -> None:
        """§14.1: "births and levels are bought whenever Essence allows, after
        upkeep and the roster's keep". Births first, because a character works;
        then levels, the main crew's first and then everyone else's, lowest
        first — §9.5 prices "every character" to level 10."""
        while self.s.owned < self.housing():
            growth = self.cfg.birth_growth or data.BIRTH_GROWTH_V34
            price = data.BIRTH_BASE * growth ** self.s.owned
            if self.s.essence < price:
                break
            self.s.essence -= price
            self._join()
        cap = self.character_cap()
        levels = self.s.crew_levels
        while len(levels) < self.s.owned:
            levels.append(1)
        for group in (range(min(5, len(levels))), range(len(levels))):
            while True:
                i = min(group, key=levels.__getitem__)
                nxt = levels[i] + 1
                if nxt > cap:
                    break
                price = data.CHARACTER_LEVEL_BASE * data.CHARACTER_LEVEL_GROWTH ** (nxt - 2)
                if self.s.essence < price:
                    break
                self.s.essence -= price
                levels[i] = nxt
                crew = min(levels[:5])
                if crew in (4, 6, 8, 10):
                    self.s.mark(f"Main crew at level {crew}")

    def _join(self) -> None:
        """A character joins the roster, born or found."""
        self.s.owned += 1
        if self.s.owned in (10, 20, 30, data.ROSTER_CEILING):
            self.s.mark(f"{self.s.owned} ruleborn")

    def _strays(self, successes: float) -> None:
        """§11.5: one heist in eight finds a stray, and carrying it out adds
        it; §18.2: the season track's free tier gives one a season. A stray
        with no free home waits (the model keeps it owed)."""
        self.s.strays += successes * self.cfg.heist_stray_chance
        if self.cfg.season_strays and self.s.day % data.SEASON_DAYS == 0:
            self.s.strays += 1
        if self.cfg.priced_strays:
            return          # it joins at the next birth's price: a birth (F38)
        while self.s.strays >= 1 and self.s.owned < self.housing():
            self.s.strays -= 1
            self._join()

    def _mark_buildings(self) -> None:
        """§14.3's building milestones, once every realm is open."""
        if len(self.s.realms) < 7:
            return
        wells = [max(r.levels("Star Well"), default=0) for r in self.s.realms]
        for level in (5, 8, 10):
            if min(wells) >= level:
                self.s.mark(f"Every Star Well at level {level}")
        if self.s.spire_level == 10 and not self._available_upgrades():
            self.s.mark("Everything built and at its highest level")

    def entry_fees(self, rate: float) -> float:
        """What a day's raids cost in fees kept, in expectation, as the owner
        answered F39 and C41: 2% of B(V) at the target, never more than is
        held, returned after a clean or loud heist and half after a partial
        one. (§9.4 still reads "2% of the raider's Starlight, from 100 to
        25,000, returned in full after a clean heist".)"""
        if not self.cfg.entry_fee or not self.arch.heists_per_day:
            return 0.0
        fee = min(max(0.0, self.s.starlight), data.ENTRY_FEE_RATE * self.haul_base())
        kept = 1 - rate * data.FEE_RETURNED_SHARE_OF_SUCCESSES
        return self.arch.heists_per_day * fee * kept

    def _mark_realm_levels(self) -> None:
        """§5.2's "Engaged" column: the first day any outer realm reaches each
        level."""
        for realm in self.s.realms[1:]:
            for level in range(2, realm.level + 1):
                self.s.mark(f"A realm at level {level}")

    # -- the loop ---------------------------------------------------------

    def step(self) -> None:
        self.s.day += 1
        produced = self.daily_production()
        self.s.starlight += produced["starlight"]
        self.s.aether += produced["aether"]
        haul = self.heist_income(produced["starlight"])
        rate = data.heist_success_rate(self.s.day)
        if self.v34:
            # §9.5: the keep is "taken as it is collected and never from stock";
            # half of each haul is Essence (G17).
            self.s.essence += produced["essence"] * (1 - data.ROSTER_KEEP_SHARE)
            self.s.essence += haul * data.HAUL_ESSENCE_SHARE
            # The season track's free Essence, over the season (G28).
            self.s.essence += data.FREE_TRACK_ESSENCE * self._track_share() / data.SEASON_DAYS
            self.s.starlight += haul * (1 - data.HAUL_ESSENCE_SHARE)
            self.s.starlight -= self.entry_fees(rate)
            room = self.capacity()
            self.s.starlight = min(self.s.starlight, room)
            self.s.essence = min(self.s.essence, room)
        else:
            self.s.essence += produced["essence"]
            self.s.starlight += haul

        before = self.s.starlight_spent
        self.spend()
        spent_today = self.s.starlight_spent - before
        n = self.arch.heists_per_day
        if self.v34:
            successes = n * rate                  # expected, not rounded
            self._strays(successes)
            self.spend_essence()
            self._mark_buildings()
            self._mark_realm_levels()
        else:
            successes = round(n * rate)
        failures = n - successes
        if self.cfg.decided_income and self.s.day == 1:
            # §16's two tutorial ruins, a successful heist's experience each
            # and no haul (F37).
            successes += data.TUTORIAL_RUINS
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
            "heist_income": haul,
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
