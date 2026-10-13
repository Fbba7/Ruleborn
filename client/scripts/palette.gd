class_name Palette
## §21.2 and §21.8's colours, by name. The values are ui/tokens.json's, where
## each is cited, so a change of look is one edit to that file. `reload` reads
## them again, as §20.8's high-contrast mode switches (Settings.apply).

# §21.2: "Neutrals: island stone #D8CFC2, soil #8A6A4E, wood #B07A4F,
# ink #221C3A, paper #FCFBFF."
static var STONE: Color
static var SOIL: Color
static var WOOD: Color
static var INK: Color
static var PAPER: Color

# §21.2: "Sky: day #9FB9F0 to #F6D9C8".
static var SKY_TOP: Color
static var SKY_BOTTOM: Color

# §21.8: "Ink #221C3A on paper panels at 85% opacity over the world; gold for
# main actions, red #E2536B for alarms, green #3FBF7F for success."
static var PANEL: Color
static var ALARM: Color
static var SUCCESS: Color
## Behind text that is an alarm: §21.8's red is too light for text on it at
## 4.5:1 in either ink or paper (D72), so text sits on this, in ON_ALARM.
static var ALARM_FILL: Color
static var ON_ALARM: Color
## Alarm and success as words on a panel: §21.8's red and green, deepened to
## read at 4.5:1 (D72). A word in either also carries a glyph (UI.status).
static var ALARM_TEXT: Color
static var SUCCESS_TEXT: Color

## Water and gravel under the features. §21.2 names no colour for either, so
## these are the client's: water in Time's blue, lightened; gravel a darker
## stone.
static var WATER: Color
static var GRAVEL: Color

# §21.2's school colours: main, shadow.
static var MOTION: Color
static var MOTION_SHADOW: Color
static var MATTER: Color
static var TIME: Color
static var ENERGY: Color
static var LIFE: Color
static var SPIRIT: Color

## Each school by its name, for its colour beside its shape (§21.2).
static var SCHOOL: Dictionary = {}

## Each crew role in a school colour, so the five read apart; a role has no
## colour of its own in §21, so this pairing is the client's. Its letter is
## drawn on it too, so the role never rests on colour (§20.8).
static var ROLE: Dictionary = {}

## A guard's state, as the ring around it. §12.17's six states; the alarm red
## for Alerted, as §21.8 reserves red for alarms. RealmView marks each state
## too, so a ring's colour is never the only sign (§20.8).
static var GUARD_STATE: Dictionary = {}

## A character's state on the Roster, as the swatch beside its mark and
## word (§23.2: "a symbol and a word as well as a colour"). §21 names no
## colour for any state, so these are the client's: success's green for
## work, Matter's for a guard, Time's for rest, stone for one with nothing to
## do.
static var ROSTER_STATE: Dictionary = {}

## Each ward in its school's colour and shape, by content/wards.json's
## schools (§10.3).
static var WARD_SCHOOL: Dictionary = {
	"GravityWell": "motion", "CrystalWall": "matter", "TimeSnare": "time",
	"StaticCoil": "energy", "ThornHedge": "life", "LanternGlare": "spirit",
}
static var WARD: Dictionary = {}

static var _loaded := _load()


static func _load() -> bool:
	reload()
	return true


## Every colour read again from the tokens: at start, and when high contrast
## is switched.
static func reload() -> void:
	STONE = Tokens.color("stone")
	SOIL = Tokens.color("soil")
	WOOD = Tokens.color("wood")
	INK = Tokens.color("ink")
	PAPER = Tokens.color("paper")
	SKY_TOP = Tokens.color("sky_top")
	SKY_BOTTOM = Tokens.color("sky_bottom")
	PANEL = Tokens.color("panel")
	ALARM = Tokens.color("alarm")
	SUCCESS = Tokens.color("success")
	ALARM_FILL = Tokens.color("alarm_fill")
	ON_ALARM = Tokens.color("on_alarm")
	ALARM_TEXT = Tokens.color("alarm_text")
	SUCCESS_TEXT = Tokens.color("success_text")
	WATER = Tokens.color("water")
	GRAVEL = Tokens.color("gravel")
	MOTION = Tokens.color("motion")
	MOTION_SHADOW = Tokens.color("motion_shadow")
	MATTER = Tokens.color("matter")
	TIME = Tokens.color("time")
	ENERGY = Tokens.color("energy")
	LIFE = Tokens.color("life")
	SPIRIT = Tokens.color("spirit")
	SCHOOL = {"motion": MOTION, "matter": MATTER, "time": TIME, "energy": ENERGY, "life": LIFE, "spirit": SPIRIT}
	ROLE = {"Scout": MOTION, "Breaker": ENERGY, "Carrier": LIFE, "Warden": MATTER, "Mender": SPIRIT}
	GUARD_STATE = {
		"Unaware": INK, "Returning": INK,
		"Suspicious": MOTION, "Investigating": MOTION, "Searching": MOTION,
		"Alerted": ALARM,
	}
	ROSTER_STATE = {"working": SUCCESS, "guarding": MATTER, "resting": TIME, "idle": STONE}
	WARD = {}
	for kind: String in WARD_SCHOOL:
		WARD[kind] = SCHOOL[WARD_SCHOOL[kind]]
