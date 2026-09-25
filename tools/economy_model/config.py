"""Model configuration: the choices the design document leaves open or contradicts.

Every field here is either a documented assumption the model has to make, or one
half of a contradiction recorded in docs/analysis/03-contradiction-register.md.
Changing one and re-running is how those contradictions get resolved with numbers
rather than argument.
"""

from dataclasses import dataclass, replace

from . import data


@dataclass
class Config:
    # -- Contested: which raid-payout model is in force (C2) ----------------
    #
    # "share"   §9.4 until v3.3: a successful heist yields ~20% of a day's
    #           production. What the earlier tables were generated with; v3.3
    #           deleted the target ("No balance target", 9.4).
    # "minted"  §9.6: Haul = B(V) x grade x difficulty x richness x fatigue x
    #           fill. What §14.1 now generates the tables with;
    #           `Config.document()` mints it from the document's base and band.
    # "pegged"  The proposal in docs/design/spec/economy.md: the same formula with
    #           B(L) replaced by the raider's OWN daily production times a share.
    #           §9.6's objection to a percentage was to pegging against what a
    #           DEFENDER hoards; pegging against the raider's production is the
    #           quantity the designer controls and the progression curve rests on.
    faucet: str = "share"

    #: The proposed coefficient: a clean heist is worth this much of a day's
    #: production. §9.4's own figure, and under "pegged" it is the single dial.
    peg_share: float = 0.20

    # -- v3.0: the fill term §9.6 added and did not re-derive against ------
    #
    # "Fill: the share of the crew's bags actually loaded. What you carry is what
    # you bank (12.19)." It multiplies the haul, and §9.6's 0.46 average per
    # attempt — the figure it calls the number the progression curve is built on
    # — still assumes a full crew. Setting this True applies the measured value
    # instead, which is how the cost of that omission gets a number.
    apply_fill: bool = False

    # -- Contested: what L is in B(L) (C4) ---------------------------------
    #
    # §9.6 quotes haul figures for levels 2, 6 and 10, but §5.2 caps outer realms
    # at level 5. "vault" reads L as the Vault's level, which does run 1-10 and
    # does carry the 40%->71.5% sealed share §9.6 attributes to it.
    haul_level_source: str = "vault"      # "vault" | "realm" | "keeper_div_4" | "target"
    #
    # "target" is §9.6 as v3.3 settled it: V is the *target's* Vault level.
    # The model has no population of targets, so it takes the target at the
    # raider's own Vault level, difficulty 1.0 and richness 1.0 — the "clean
    # same-level haul" §9.6's own table and raid-worth check are indexed by.
    # That is the same arithmetic as "vault", and it is §9.6's convention, not
    # something §12.22 gives: §12.22 matches on Renown, Keeper level, rating
    # and depth, and its guarantee is a success band, not a level.

    # -- §9.6's base, and what an attempt is worth against it ------------------
    #
    # v3.2 minted from 100; v3.3's raid-worth check raised it to 2,400 (D58).
    haul_base: int = data.V32_HAUL_BASE
    #: What an attempt pays as a fraction of a clean same-level haul. None keeps
    #: v3.2's expected grade (0.46, times the measured fill under `apply_fill`);
    #: a number is §9.6's band, grade and fill already in it.
    attempt_value: float | None = None

    # -- v3.4's economy: ladders from content/, births, keep, pages -----------
    #
    # §14.1: "Pages and Insight arrive as described in 7.6 and 11.7; births
    # and levels are bought whenever Essence allows, after upkeep and the
    # roster's keep (9.5)." False keeps the model the findings were measured
    # on — every home filled for free, Essence never spent, a flat page rate.
    v34_economy: bool = False
    #: Which Codex the run restores: §7.10's launch 24 or §7.9's full 48.
    codex: str = "full"                   # "full" | "launch"
    #: §9.5's birth price growth. None is the shipped rate; `rerun.tune_birth_rate`
    #: finds the one §9.5's rule sets.
    birth_growth: float | None = None

    # -- v3.4's rules the first re-run left out (the review, T2.6) -------------
    #
    # Each is the document's reading where the document is explicit; the ones
    # it leaves to the player are named choices, and rerun.py prints what each
    # alternative moves.
    #: §9.1: Starlight and Essence are held in the "Vault and Storehouses".
    storage_caps: bool = False
    #: §9.4: "Entry fee: 2% of the raider's Starlight, from 100 to 25,000,
    #: returned in full after a clean heist."
    entry_fee: bool = False
    #: §11.5's heist strays (one heist in eight) and §18.2's season stray.
    heist_stray_chance: float = 0.0
    season_strays: bool = False
    #: The owner's answer to F38: a found stray waits and joins only at the
    #: next birth's price, so it is a birth like any other.
    priced_strays: bool = False
    #: The owner's answers to F37 and G28: a non-raider's daily goals, the
    #: tutorial's two ruins on day 1, and the season track's free rewards.
    decided_income: bool = False
    #: §14.1: "Players save for the next Spire level first". True reserves the
    #: next Spire level's cost once its Keeper gate is open; False buys it only
    #: when a day's stock covers it, which the first re-run did.
    spire_reserve: bool = False
    #: §16's first week opens the first outer realm on day 1: opening a realm
    #: is bought with the producers, ahead of everything else.
    realm_open_first: bool = False
    #: §9.3's bonuses to "a matching school" only: the realm's own resource
    #: gets ×1.1 and +10% per realm law, a crown law +5% to its school's
    #: resource everywhere. False gives every producer in an outer realm both,
    #: as the first re-run did.
    school_bonuses: bool = False
    #: Which resource each outer realm boosts, in the order they open. §5.2
    #: leaves the choice to the player: "the player picks each one's type".
    #: The default is the order at the median of all 90 (rerun.py prints the
    #: spread): Keeper 40 and "everything built" land mid-range with it.
    realm_order: tuple = ("aether", "starlight", "essence", "aether", "starlight", "essence")
    #: The school of the Heart's two realm laws and of the crown laws, by the
    #: resource they boost. The player's choice; Starlight is the scarce one.
    heart_law_resource: str = "starlight"
    crown_law_resource: str = "starlight"
    #: Which empty slot a new worker fills. §9.2: "choosing which producer goes
    #: short is the decision", and no order is stated. "heart_first" fills
    #: the Heart, then each realm in turn, Well, Spring, Garden; "even" gives
    #: each producer one worker in turn.
    staffing_order: str = "heart_first"
    #: One ruleborn at every Guardian Post built (§10.2), withheld from work.
    #: §13.2: posts "hold stability only while staffed", so it is a choice.
    staff_posts: bool = False

    # -- Assumption: producers in the Heart --------------------------------
    #
    # §10.2 says Star Wells, Aether Springs and Gardens are built in "every
    # realm", and §5.2 allows a second of each from realm level 3. The Heart has
    # no realm level, so the model keys it to the Spire instead. Documented
    # because it materially affects early production.
    heart_second_producer_at_spire: int = 5

    # -- Contested since v3.0: how partial staffing pays -------------------
    #
    # §9.2:  "Staffing sets 60%, 85% or 100% output."
    # §5.9:  "A producer runs at the share of its worker slots that are filled,
    #         so a half-staffed Well earns half."
    #
    # Those are different rules, and they diverge most where the roster binds:
    # two of three slots is 85% under §9.2 and 67% under §5.9. v3.0 added §5.9
    # and left §9.2 standing, which is C27.
    #
    # "table" reproduces the document as published; "pro_rata" is §5.9's rule.
    staffing_rule: str = "table"

    # §9.2's factors do not say how they map onto buildings with one or two
    # slots. Under "table" the model treats a fully staffed building as 100%
    # whatever its slot count.
    full_staffing_is_always_100: bool = True

    # -- Contested since v3.0: what raiding costs --------------------------
    #
    # §11.6 has a raider away for the heist's three minutes plus rest, which
    # works out at about 2% of the roster — finding F3.
    # §5.8 replaces it: "A crew on a heist is assigned to it, like a guard at a
    # post, and does not work while assigned. Five of thirty-eight is a real
    # choice."
    #
    # False keeps the published behaviour; True is §5.8's rule.
    crew_assigned_not_timed: bool = False

    # -- Assumption: law configuration --------------------------------------
    #
    # §5.5 and §9.3 describe "typical realm matches and harmonies" without
    # defining them. The model assumes a player weaves laws matching each realm's
    # own school, so every producer gets its realm-match bonus and one realm-law
    # bonus per law slot in its realm.
    laws_match_realm_school: bool = True

    # -- Assumption: purchase policy (§14.1) --------------------------------
    #
    # "Players save for the next Spire level first, then buy the cheapest
    # available upgrade; producers come before everything else."
    producers_first: bool = True

    # -- Assumption: which buildings the model buys at all -------------------
    #
    # Defensive and social buildings cost Starlight but return nothing the model
    # tracks, so including them slows growth. The document's own tables include
    # them (they quote build days for Observatory, Beacon and the Dock), so the
    # model does too.
    buy_non_producers: bool = True

    # -- Test switch: how many producers per realm? --------------------------
    #
    # §5.2 allows a second Star Well, Aether Spring and Garden per realm from
    # realm level 3. Setting this to 1 holds every realm to one of each, which
    # is what §9.3's published production figures appear to assume.
    producers_per_realm_override: int | None = None

    # -- Test switch: does the roster cap bind? ------------------------------
    #
    # The published tables in §9.3 may or may not have been generated with the
    # roster cap in §11.5 applied. Setting this False staffs every building
    # regardless of how many ruleborn the player can actually house, which is
    # how the question gets answered with numbers.
    enforce_worker_cap: bool = True

    # -- Simulation ----------------------------------------------------------
    days: int = 400
    archetype: str = "engaged"

    @classmethod
    def document(cls, edge: str = "low", **overrides) -> "Config":
        """The model as §14.1 and §14.2 say the document's tables are generated.

        §5.8's three rules — one producer of each kind per realm, pro-rata
        staffing, the crew assigned rather than timed — and §9.6's haul at one
        edge of its band: "low" for the crew that stops at a fixed 70% fill,
        "high" for the one that reads the guards. The full re-run publishes
        every milestone at both (14.2).
        """
        base = cls(producers_per_realm_override=1, staffing_rule="pro_rata",
                   crew_assigned_not_timed=True, faucet="minted",
                   haul_level_source="target", haul_base=data.HAUL_BASE,
                   v34_economy=True, storage_caps=True, entry_fee=True,
                   heist_stray_chance=data.HEIST_STRAY_CHANCE, season_strays=True,
                   priced_strays=True, decided_income=True,
                   spire_reserve=True, realm_open_first=True, school_bonuses=True,
                   attempt_value=data.ATTEMPT_BAND[{"low": 0, "high": 1}[edge]])
        return replace(base, **overrides)

    def haul_level(self, vault_level: int, realm_level: int, keeper_level: int) -> int:
        if self.haul_level_source in ("vault", "target"):
            return max(1, vault_level)
        if self.haul_level_source == "realm":
            return max(1, realm_level)
        return max(1, keeper_level // 4)
