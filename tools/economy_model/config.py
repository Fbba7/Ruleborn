"""Model configuration: the choices the design document leaves open or contradicts.

Every field here is either a documented assumption the model has to make, or one
half of a contradiction recorded in docs/analysis/03-contradiction-register.md.
Changing one and re-running is how those contradictions get resolved with numbers
rather than argument.
"""

from dataclasses import dataclass


@dataclass
class Config:
    # -- Contested: which raid-payout model is in force (C2) ----------------
    #
    # "share"   §9.4: a successful heist yields ~20% of a day's production.
    #           This is what §14.1 says the published tables were generated with.
    # "minted"  §9.6: Haul = B(L) x grade x difficulty x richness x fatigue.
    #           This is the current, better-argued model.
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
    haul_level_source: str = "vault"      # "vault" | "realm" | "keeper_div_4"

    # -- Assumption: producers in the Heart --------------------------------
    #
    # §10.2 says Star Wells, Aether Springs and Gardens are built in "every
    # realm", and §5.2 allows a second of each from realm level 3. The Heart has
    # no realm level, so the model keys it to the Spire instead. Documented
    # because it materially affects early production.
    heart_second_producer_at_spire: int = 5

    # -- Assumption: staffing ----------------------------------------------
    #
    # §9.2 gives staffing factors of 60% / 85% / 100% but does not say how they
    # map onto buildings with one or two slots. The model treats a fully staffed
    # building as 100% whatever its slot count, and applies 60% / 85% to the
    # partial cases of a three-slot building.
    full_staffing_is_always_100: bool = True

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

    def haul_level(self, vault_level: int, realm_level: int, keeper_level: int) -> int:
        if self.haul_level_source == "vault":
            return max(1, vault_level)
        if self.haul_level_source == "realm":
            return max(1, realm_level)
        return max(1, keeper_level // 4)
