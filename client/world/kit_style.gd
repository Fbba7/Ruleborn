class_name KitStyle
extends RefCounted
## The kit's materials by realm, from the design's own table (Screens v3,
## realm-diorama.js `REALMS`: wall, roof, stone, accent per realm), beside
## RealmPalette's ground colours: what a house's plaster, its roof and its
## dressed stone are in each of §21.4's realms, and how its trees grow.

const REALMS := {
	"heart": {"wall": "#F6DDE6", "roof": "#9C3380", "stone": "#E6DCCB", "stone2": "#B9AE9C", "accent": "#E05CB4",
		"tree": "round"},
	"skyfield": {"wall": "#FFFFFF", "roof": "#C0502E", "stone": "#E6DCCB", "stone2": "#B9AE9C", "accent": "#F2B43C",
		"tree": "birch"},
	"crystalline": {"wall": "#D8D4F6", "roof": "#5A3FB0", "stone": "#DCD8F0", "stone2": "#A9A3CC",
		"accent": "#8C6CF0", "tree": "pine"},
	"tidehold": {"wall": "#E4F4F2", "roof": "#1F7F95", "stone": "#E6DCCB", "stone2": "#9FB0B8", "accent": "#3CC6D8",
		"tree": "round"},
	"emberreach": {"wall": "#5A4448", "roof": "#8A2F22", "stone": "#A8928A", "stone2": "#7A625C",
		"accent": "#F07A3C", "tree": "pine"},
	"verdant": {"wall": "#E8D2A8", "roof": "#B5533C", "stone": "#E6DCCB", "stone2": "#B9AE9C", "accent": "#5CC46A",
		"tree": "round"},
	"lanternvale": {"wall": "#6A5A78", "roof": "#4B3C8A", "stone": "#C4BCD8", "stone2": "#8E86A8",
		"accent": "#F2B43C", "tree": "willow"},
}
## The timber, iron, gold and window light every realm shares (the
## diorama's WD, WD2, IRON, GOLD and GL).
const WOOD := Color("#6A4028")
const WOOD_DARK := Color("#4A2A1A")
const IRON := Color("#3A3440")
const GOLD := Color("#E9B65C")
const WINDOW := Color("#FFC870")
const THATCH := Color("#D9B26A")


## The realm a palette is (`RealmPalette.of`'s), found by its ground.
static func realm_of(palette: Dictionary) -> String:
	for key: String in RealmPalette.TYPES:
		if Color(RealmPalette.TYPES[key]["ground"]).is_equal_approx(palette.get("ground", Color.BLACK)):
			return key
	return "heart"


static func of(realm: String) -> Dictionary:
	var t: Dictionary = REALMS.get(realm, REALMS["heart"])
	var out := {}
	for k: String in t:
		out[k] = Color(t[k]) if str(t[k]).begins_with("#") else t[k]
	return out


## A window's light: its colour with the glow flag (alpha under 1).
static func lit(c: Color, strength := 0.4) -> Color:
	return Color(c, 1.0 - strength)
