class_name Palette
## §21.2 and §21.8's colours, by name. The values are ui/tokens.json's, where
## each is cited, so a change of look is one edit to that file.

# §21.2: "Neutrals: island stone #D8CFC2, soil #8A6A4E, wood #B07A4F,
# ink #221C3A, paper #FCFBFF."
static var STONE: Color = Tokens.color("stone")
static var SOIL: Color = Tokens.color("soil")
static var WOOD: Color = Tokens.color("wood")
static var INK: Color = Tokens.color("ink")
static var PAPER: Color = Tokens.color("paper")

# §21.2: "Sky: day #9FB9F0 to #F6D9C8".
static var SKY_TOP: Color = Tokens.color("sky_top")
static var SKY_BOTTOM: Color = Tokens.color("sky_bottom")

# §21.8: "Ink #221C3A on paper panels at 85% opacity over the world; gold for
# main actions, red #E2536B for alarms, green #3FBF7F for success."
static var PANEL: Color = Tokens.color("panel")
static var ALARM: Color = Tokens.color("alarm")
static var SUCCESS: Color = Tokens.color("success")

## Water and gravel under the features. §21.2 names no colour for either, so
## these are the client's: water in Time's blue, lightened; gravel a darker
## stone.
static var WATER: Color = Tokens.color("water")
static var GRAVEL: Color = Tokens.color("gravel")

# §21.2's school colours: main, shadow.
static var MOTION: Color = Tokens.color("motion")
static var MOTION_SHADOW: Color = Tokens.color("motion_shadow")
static var MATTER: Color = Tokens.color("matter")
static var TIME: Color = Tokens.color("time")
static var ENERGY: Color = Tokens.color("energy")
static var LIFE: Color = Tokens.color("life")
static var SPIRIT: Color = Tokens.color("spirit")

## Each crew role in a school colour, so the five read apart; a role has no
## colour of its own in §21, so this pairing is the client's.
static var ROLE: Dictionary = {
	"Scout": MOTION, "Breaker": ENERGY, "Carrier": LIFE,
	"Warden": MATTER, "Mender": SPIRIT,
}

## A guard's state, as the ring around it. §12.17's six states; the alarm red
## for Alerted, as §21.8 reserves red for alarms.
static var GUARD_STATE: Dictionary = {
	"Unaware": INK, "Returning": INK,
	"Suspicious": MOTION, "Investigating": MOTION, "Searching": MOTION,
	"Alerted": ALARM,
}


## Each ward in its school's colour, by content/wards.json's schools (§10.3).
static var WARD: Dictionary = {
	"GravityWell": MOTION, "CrystalWall": MATTER, "TimeSnare": TIME,
	"StaticCoil": ENERGY, "ThornHedge": LIFE, "LanternGlare": SPIRIT,
}
