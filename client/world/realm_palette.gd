class_name RealmPalette
extends RefCounted
## §21.4's realms in colour: "Ground and palette" for each type, its plants
## and its light. The document names the materials ("cream flagstones, gold
## trims", "rust rock, black basalt"); the values are the client's reading
## of them, and of the Screens v3 diorama's own table (`REALMS`,
## realm-diorama.js:60–67, and `lights`, :1056), kept here as the one table
## the world draws from.
##
## Keys: `ground` the flagstones, `stone` and `rock` the kit's stone, `soil`
## the earth; `grass` the island's meadow, `dirt` its rim, `cliff` and
## `cliff_deep` the rock beneath; `plant`, `accent` and `trim` the realm's
## plants and its colour; `sky_top`, `sky_mid`, `sky_low` its sky from the
## top of the screen down; `light` its sun.

const TYPES := {
	"heart": {"ground": "#E4D3AE", "grass": "#7FA462", "stone": "#D8CFC2", "rock": "#9C8A7A", "soil": "#8A6A4E",
		"dirt": "#9A6B4F", "cliff": "#6A5C8C", "cliff_deep": "#4B3F6E", "trim": "#F2B43C", "plant": "#5CC46A",
		"accent": "#E05CB4", "bloom": "#F7A6DA", "light": "#FFD8E8",
		"sky_top": "#1B1250", "sky_mid": "#4A2A8E", "sky_low": "#C86FB0"},
	"skyfield": {"ground": "#E2D59E", "grass": "#9EB862", "stone": "#F4F0E6", "rock": "#B9AE9F", "soil": "#9A7F5C",
		"dirt": "#B9875C", "cliff": "#9C8FB4", "cliff_deep": "#746A92", "trim": "#F2B43C", "plant": "#E8D27A",
		"accent": "#F2B43C", "bloom": "#FFFFFF", "light": "#FFF2D0",
		"sky_top": "#3B6FD0", "sky_mid": "#7FB5EE", "sky_low": "#FFE3B0"},
	"crystalline": {"ground": "#CDBDE6", "grass": "#ABA9D8", "stone": "#BFAEDB", "rock": "#7E6AA8", "soil": "#5E4A86",
		"dirt": "#8C86B0", "cliff": "#4F4C86", "cliff_deep": "#37346A", "trim": "#8C6CF0", "plant": "#A9D8E8",
		"accent": "#8C6CF0", "bloom": "#BFAEFF", "light": "#E0E8FF",
		"sky_top": "#15123F", "sky_mid": "#34307D", "sky_low": "#8F7FE0"},
	"tidehold": {"ground": "#E6D6AE", "grass": "#40806A", "stone": "#9FB0B8", "rock": "#6E8290", "soil": "#7C6A55",
		"dirt": "#7C6A58", "cliff": "#4E6D86", "cliff_deep": "#375068", "trim": "#3CC6D8", "plant": "#5CB88A",
		"accent": "#3CC6D8", "bloom": "#F3E6C0", "light": "#E8FFFF",
		"sky_top": "#0E2F4F", "sky_mid": "#2A6D8E", "sky_low": "#A7E6EA"},
	"emberreach": {"ground": "#9C5A44", "grass": "#7A5446", "stone": "#5A4A4E", "rock": "#3A2E34", "soil": "#6A3A2A",
		"dirt": "#5A3B34", "cliff": "#3F2A30", "cliff_deep": "#2B1C22", "trim": "#F07A3C", "plant": "#E0A04A",
		"accent": "#F07A3C", "bloom": "#FF8A3C", "light": "#FFB070",
		"sky_top": "#22091A", "sky_mid": "#5E1F2E", "sky_low": "#F08A4C"},
	"verdant": {"ground": "#86B866", "grass": "#468A48", "stone": "#C9C2A8", "rock": "#7F7462", "soil": "#7A5A3E",
		"dirt": "#7A5A40", "cliff": "#6B5846", "cliff_deep": "#4F4034", "trim": "#5CC46A", "plant": "#3E9A48",
		"accent": "#F2E07A", "bloom": "#F7A6DA", "light": "#FFF0B8",
		"sky_top": "#17402F", "sky_mid": "#3B8657", "sky_low": "#DCF1A8"},
	"lanternvale": {"ground": "#4C4A80", "grass": "#355E52", "stone": "#7A72A8", "rock": "#3E3868", "soil": "#2E2A4E",
		"dirt": "#4E3F4A", "cliff": "#363160", "cliff_deep": "#26224A", "trim": "#E05CB4", "plant": "#7AD8C8",
		"accent": "#F2B43C", "bloom": "#C8FF96", "light": "#8FA0FF",
		"sky_top": "#08071F", "sky_mid": "#171447", "sky_low": "#3E2D6C"},
}

## Each realm's light, after the diorama's `lights` (:1056): the sun's
## strength, the sky's and the ground's ambient (its hemisphere light), the
## sun's place (x, height, z) and how much of the hour's sky the realm takes
## (Lantern Vale keeps its twilight at noon, §21.4).
const LIGHTS := {
	"heart": {"sun": 0.53, "sky": "#FFC8F0", "under": "#4B2F6E", "at": Vector3(12, 20, 8), "hour": 0.3},
	"skyfield": {"sun": 0.59, "sky": "#CFE8FF", "under": "#6A5A40", "at": Vector3(14, 24, 6), "hour": 0.45},
	"crystalline": {"sun": 0.57, "sky": "#C8C0FF", "under": "#2A2660", "at": Vector3(8, 22, 12), "hour": 0.25},
	"tidehold": {"sun": 0.42, "sky": "#B8F0F0", "under": "#284860", "at": Vector3(10, 20, 14), "hour": 0.3},
	"emberreach": {"sun": 0.53, "sky": "#FF9A70", "under": "#2A1018", "at": Vector3(16, 14, 4), "hour": 0.2},
	"verdant": {"sun": 0.50, "sky": "#D8FFC0", "under": "#3A4A20", "at": Vector3(12, 22, 10), "hour": 0.4},
	"lanternvale": {"sun": 0.33, "sky": "#6060B0", "under": "#100820", "at": Vector3(8, 20, 10), "hour": 0.12},
}

## §21.2's skies by the hour: day, dusk and night, top then horizon.
const SKIES := {
	"day": ["#9FB9F0", "#F6D9C8"], "dusk": ["#6A4FC9", "#F29C7B"], "night": ["#1A1433", "#3A2B6B"],
}
## The hour's own light: the sun's tint and strength, and the ambient's tint.
const HOUR_LIGHT := {
	"day": ["#FFFFFF", 1.0, "#FFFFFF"], "dusk": ["#FFD2A8", 0.92, "#C4B0EE"], "night": ["#A2AEFF", 0.5, "#7E76C4"],
}


## The time of day an hour falls in (§21.2: "The sky follows the player's
## local time"): night until 6 and from 20, dusk at 6 and 18 to 20, day
## between.
static func hour_key(hour: int) -> String:
	if hour < 6 or hour >= 20:
		return "night"
	if hour < 8 or hour >= 18:
		return "dusk"
	return "day"


## The light by the hour, with the sky: the sun's colour and strength, and
## the ambient light the shade takes (violet, never black; §21.3).
static func light_at(hour: int, type := "heart") -> Array:
	var l: Dictionary = LIGHTS.get(type, LIGHTS["heart"])
	var h: Array = HOUR_LIGHT[hour_key(hour)]
	var tint := Color(h[0])
	# The realm's light keeps its hue but not all its strength of colour, so
	# the ground's own colours read under it (§21.10).
	# The hour's tint is blended in rather than multiplied, so a green meadow
	# under a low amber sun stays green and glows, not olive.
	var sun := Color(TYPES.get(type, TYPES["heart"])["light"]).lerp(Color.WHITE, 0.35).lerp(tint, 0.45)
	var ambient := Color(l["sky"]).lerp(Color(l["under"]), 0.45).lerp(Color("#B8B0E0"), 0.3) * Color(h[2])
	return [sun, float(l["sun"]) * float(h[1]), ambient, 0.24 if hour_key(hour) != "night" else 0.3]


## The realm's ambient as a hemisphere: what the sky gives a face turned up
## and the ground one turned down, by the hour.
static func hemisphere_at(hour: int, type := "heart") -> Array[Color]:
	var l: Dictionary = LIGHTS.get(type, LIGHTS["heart"])
	var tint := Color(HOUR_LIGHT[hour_key(hour)][2])
	var above := Color(l["sky"]) * tint
	var below := Color(l["under"]) * tint
	if hour_key(hour) == "night":
		# Moonlight: a cool blue from above keeps the ground's hue instead of
		# greying it.
		above = above.lerp(Color("#5868C8"), 0.55)
		below = below.lerp(Color("#1A1840"), 0.3)
	return [above, below]


## Where the sun stands for a realm, as a direction from the island to it;
## lower in the evening and at night.
static func sun_from(hour: int, type := "heart") -> Vector3:
	var at: Vector3 = LIGHTS.get(type, LIGHTS["heart"])["at"]
	match hour_key(hour):
		"dusk":
			at.y *= 0.55
		"night":
			at.y *= 0.8
			at.x = -at.x
	return at.normalized()


static func of(type: String) -> Dictionary:
	var t: Dictionary = TYPES.get(type, TYPES["heart"])
	var out := {}
	for k: String in t:
		out[k] = Color(t[k])
	return out


## The sky for an hour of the player's day (§21.2), top then horizon.
static func sky_at(hour: int) -> Array[Color]:
	var key := hour_key(hour)
	return [Color(SKIES[key][0]), Color(SKIES[key][1])]


## A realm's sky at an hour, top to bottom of the screen: the realm's own
## three colours (§21.4: each realm "owns a distinct value range, hue
## territory", §21.10) crossed with the hour's (§21.2), and the glow
## behind the island.
static func realm_sky_at(hour: int, type := "heart") -> Array[Color]:
	var r := of(type)
	var hour_pair := sky_at(hour)
	var w: float = LIGHTS.get(type, LIGHTS["heart"])["hour"]
	# The realm keeps its own sky by day; at dusk and at night the hour's
	# takes over more, so no horizon stays bright after dark.
	match hour_key(hour):
		"dusk":
			w = maxf(w, 0.45)
		"night":
			w = maxf(w, 0.7)
	var top: Color = (r["sky_top"] as Color).lerp(hour_pair[0], w)
	var mid: Color = (r["sky_mid"] as Color).lerp(hour_pair[0].lerp(hour_pair[1], 0.5), w)
	var low: Color = (r["sky_low"] as Color).lerp(hour_pair[1], w * 0.8)
	return [top, mid, low, low.lerp(Color.WHITE, 0.25)]
