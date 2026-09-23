class_name Palette
## §21.2 and §21.8's colours, in one place. Every colour the client draws with
## is named here and cited, so a change in the document is one edit.

# §21.2: "Neutrals: island stone #D8CFC2, soil #8A6A4E, wood #B07A4F,
# ink #221C3A, paper #FCFBFF."
const STONE := Color("#D8CFC2")
const SOIL := Color("#8A6A4E")
const WOOD := Color("#B07A4F")
const INK := Color("#221C3A")
const PAPER := Color("#FCFBFF")

# §21.2: "Sky: day #9FB9F0 to #F6D9C8".
const SKY_TOP := Color("#9FB9F0")
const SKY_BOTTOM := Color("#F6D9C8")

# §21.8: "Ink #221C3A on paper panels at 85% opacity over the world; gold for
# main actions, red #E2536B for alarms, green #3FBF7F for success."
const PANEL := Color(0.9882, 0.9843, 1.0, 0.85)
const ALARM := Color("#E2536B")
const SUCCESS := Color("#3FBF7F")

# §21.2's school colours: main, shadow.
const MOTION := Color("#F2B43C")
const MOTION_SHADOW := Color("#B8741E")
const MATTER := Color("#8C6CF0")
const TIME := Color("#3CC6D8")
const ENERGY := Color("#F07A3C")
const LIFE := Color("#5CC46A")
const SPIRIT := Color("#E05CB4")

## Each crew role in a school colour, so the five read apart; a role has no
## colour of its own in §21, so this pairing is the client's.
const ROLE := {
	"Scout": MOTION, "Breaker": ENERGY, "Carrier": LIFE,
	"Warden": MATTER, "Mender": SPIRIT,
}

## A guard's state, as the ring around it. §12.17's six states; the alarm red
## for Alerted, as §21.8 reserves red for alarms.
const GUARD_STATE := {
	"Unaware": INK, "Returning": INK,
	"Suspicious": MOTION, "Investigating": MOTION, "Searching": MOTION,
	"Alerted": ALARM,
}


## Each ward in its school's colour, by content/wards.json's schools (§10.3).
const WARD := {
	"GravityWell": MOTION, "CrystalWall": MATTER, "TimeSnare": TIME,
	"StaticCoil": ENERGY, "ThornHedge": LIFE, "LanternGlare": SPIRIT,
}
