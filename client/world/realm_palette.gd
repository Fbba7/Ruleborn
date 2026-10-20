class_name RealmPalette
extends RefCounted
## §21.4's realms in colour: "Ground and palette" for each type, its plants
## and its light. The document names the materials ("cream flagstones, gold
## trims", "rust rock, black basalt"); the values are the client's reading
## of them, kept here as the one table the world draws from.

const TYPES := {
	"heart": {"ground": "#E4D3AE", "grass": "#B9C98A", "stone": "#D8CFC2", "rock": "#9C8A7A", "soil": "#8A6A4E",
		"trim": "#F2B43C", "plant": "#5CC46A", "accent": "#F6D27A", "light": "#FFF1DA"},
	"skyfield": {"ground": "#E9DB9A", "grass": "#D9C86A", "stone": "#F4F0E6", "rock": "#B9AE9F", "soil": "#9A7F5C",
		"trim": "#F2B43C", "plant": "#E8D27A", "accent": "#FFFFFF", "light": "#FFF4D8"},
	"crystalline": {"ground": "#CDBDE6", "grass": "#B8C9E8", "stone": "#BFAEDB", "rock": "#7E6AA8", "soil": "#5E4A86",
		"trim": "#8C6CF0", "plant": "#A9D8E8", "accent": "#C9B6FF", "light": "#EDE6FF"},
	"tidehold": {"ground": "#E6D6AE", "grass": "#8FCFA8", "stone": "#9FB0B8", "rock": "#6E8290", "soil": "#7C6A55",
		"trim": "#3CC6D8", "plant": "#5CB88A", "accent": "#9ADFE8", "light": "#EAF6FF"},
	"emberreach": {"ground": "#B5674A", "grass": "#C98A4A", "stone": "#5A4A4E", "rock": "#3A2E34", "soil": "#6A3A2A",
		"trim": "#F07A3C", "plant": "#E0A04A", "accent": "#FFB070", "light": "#FFD9B8"},
	"verdant": {"ground": "#8FCF6A", "grass": "#6CC45A", "stone": "#C9C2A8", "rock": "#7F7462", "soil": "#7A5A3E",
		"trim": "#5CC46A", "plant": "#3E9A48", "accent": "#F2E07A", "light": "#FFF6DA"},
	"lanternvale": {"ground": "#5A5A9A", "grass": "#4E6E8E", "stone": "#7A72A8", "rock": "#3E3868", "soil": "#2E2A4E",
		"trim": "#E05CB4", "plant": "#7AD8C8", "accent": "#FFD27A", "light": "#C8C0FF"},
}

## §21.2's skies by the hour: day, dusk and night, top then horizon.
const SKIES := {
	"day": ["#9FB9F0", "#F6D9C8"], "dusk": ["#6A4FC9", "#F29C7B"], "night": ["#1A1433", "#3A2B6B"],
}


## The light by the hour, with the sky: the sun's colour and strength, and
## the ambient light the shade takes (violet, never black; §21.3).
static func light_at(hour: int) -> Array:
	if hour < 6 or hour >= 20:
		return [Color("#A8B4FF"), 0.5, Color("#4A4396"), 0.55]
	if hour < 8 or hour >= 18:
		return [Color("#FFB98A"), 0.72, Color("#7A5FC0"), 0.45]
	return [Color("#FFF1DA"), 0.82, Color("#8E86C8"), 0.42]


static func of(type: String) -> Dictionary:
	var t: Dictionary = TYPES.get(type, TYPES["heart"])
	var out := {}
	for k: String in t:
		out[k] = Color(t[k])
	return out


## The sky for an hour of the player's day (§21.2: "The sky follows the
## player's local time"): night until 6, dusk at 6 and 18 to 20, day between.
static func sky_at(hour: int) -> Array[Color]:
	var key := "day"
	if hour < 6 or hour >= 20:
		key = "night"
	elif hour < 8 or hour >= 18:
		key = "dusk"
	return [Color(SKIES[key][0]), Color(SKIES[key][1])]
