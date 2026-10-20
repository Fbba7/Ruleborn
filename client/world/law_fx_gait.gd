class_name LawFxGait
extends RefCounted
## §21.7's movement signatures ("how characters move") as numbers a
## character controller applies over its walk: T1's CreatureModel reads
## `LawFx.gait(law)` for each law woven where a character stands and layers
## them with `blend`. Every key is always present, so a controller never
## guesses a default:
##
## - `bounce`: how high a step lifts the body, in metres at a 1 m character
##   (WorldView's walk lifts 0.07).
## - `squash`: squash-and-stretch on each landing, 0..1 of the body's height.
## - `lean`: forward lean in radians; negative leans back. `lean_to` says
##   toward what: "move" (the way it walks), "wind" (Current's), "heart"
##   (Inward pull's), "downhill" (Tilt's), "stone" (Lodestones').
## - `stride`: step length, times the walk's.
## - `tempo`: steps a second, times the walk's (the simulation's speed is
##   unchanged: a slower tempo takes longer strides to match it).
## - `float`: 0..1, how long a hop hangs in the air and how far cloaks, hair
##   and sacks drift upward (Half gravity's 0.6).
## - `skate`: 0..1, how far feet glide instead of stepping (Frictionless 1).
## - `tiptoe`: 0..1, toes and a careful, raised step.
## - `crouch`: 0..1, knees bent and the body lowered.
## - `sway`: side-to-side rock, in radians.
## - `trail`: 0..1, how strong a trail of copies follows (Afterimage,
##   Haste's motion lines).
## - `shimmer`: 0..1, a shimmering outline (Stillness, Mirror images).
## - `arms`: the arms' pose: "swing", "out" (balancing), "windmill", "high"
##   (a lantern held up), "front" (sleepwalking), "ears" (cupped), "juggle".
## - `rhythm`: the step pattern: "walk", "step-step-hop", "dart" (wait then
##   dash), "skip", "stomp", "shuffle".
## - `who`: whom it applies to: "all", "crew", "guards", "carriers".
## - `extra`: the one thing a pose library adds that the numbers do not say.

const NEUTRAL := {"bounce": 0.07, "squash": 0.05, "lean": 0.0, "lean_to": "move", "stride": 1.0, "tempo": 1.0,
	"float": 0.0, "skate": 0.0, "tiptoe": 0.0, "crouch": 0.0, "sway": 0.0, "trail": 0.0, "shimmer": 0.0,
	"arms": "swing", "rhythm": "walk", "who": "all", "extra": ""}

## §21.7's "How characters move", each law's in numbers. Laws not launched
## are here too, so a later law needs no code.
const LAWS := {
	"bounce": {"bounce": 0.16, "squash": 0.3, "extra": "rebound off walls with a squash and a springy boing"},
	"half_gravity": {"bounce": 0.32, "stride": 1.5, "tempo": 0.62, "float": 0.6, "squash": 0.02,
		"extra": "long slow hops; cloaks and loot sacks drift upward"},
	"tilt": {"lean": 0.28, "lean_to": "downhill", "arms": "windmill",
		"extra": "arms windmill downhill; lean hard going uphill"},
	"current": {"lean": 0.22, "lean_to": "wind", "stride": 1.15, "extra": "hair and cloaks stream downwind"},
	"heavy_ground": {"bounce": 0.02, "squash": 0.16, "stride": 0.8, "tempo": 0.8, "crouch": 0.3, "rhythm": "stomp",
		"extra": "carriers hunch under loot; flyers walk"},
	"leapfrog": {"bounce": 0.2, "rhythm": "step-step-hop", "extra": "each landing puffs dust"},
	"frictionless": {"bounce": 0.0, "squash": 0.0, "skate": 1.0, "lean": 0.12, "arms": "out",
		"extra": "spin-stop against walls"},
	"inward_pull": {"lean": 0.1, "lean_to": "heart", "extra": "feet drag when heading outward"},
	"brittle_stone": {"tiptoe": 0.7, "stride": 0.7, "tempo": 1.2, "sway": 0.06, "extra": "wobble on cracked tiles"},
	"crystal_growth": {"extra": "pause to tap humming crystal walls"},
	"glass": {"crouch": 0.35, "extra": "crouch behind glass walls, in vain"},
	"density": {"extra": "big characters lumber at half tempo; small ones scurry at double tempo"},
	"honeycomb": {"stride": 0.85, "tempo": 0.85, "squash": 0.08, "extra": "sticky steps pull golden strands"},
	"lodestones": {"lean": 0.12, "lean_to": "stone", "who": "carriers", "extra": "sacks strain toward the stones"},
	"shifting_stones": {"rhythm": "dart", "extra": "wait at gaps, then dart through"},
	"transmute": {"arms": "juggle", "who": "carriers", "extra": "sacks flicker between gold and green"},
	"day_and_night": {"tiptoe": 0.3, "arms": "high", "extra": "in the dark phase only: lanterns held high"},
	"slow_rivers": {"tempo": 0.5, "stride": 1.3, "bounce": 0.12, "extra": "in water only: big, lazy splashes"},
	"stillness": {"shimmer": 1.0, "bounce": 0.0, "extra": "standing still, a frozen statue pose"},
	"afterimage": {"trail": 1.0},
	"delay": {"extra": "flinch a beat (0.4 s) late"},
	"haste": {"tempo": 1.5, "stride": 1.1, "trail": 0.4, "rhythm": "skip", "extra": "motion lines"},
	"held_breath": {"extra": "when the crew stops, everything freezes; the crew breathes in deeply"},
	"tidemark": {"extra": "glance at the tide line"},
	"glowing_dark": {"tiptoe": 0.5, "extra": "glowing characters tiptoe; everyone else is a silhouette"},
	"heat_bloom": {"tempo": 1.15, "extra": "near fire: puff up, steam rising"},
	"spark_trails": {"tiptoe": 0.3, "extra": "runners leave crackling sparks"},
	"aurora": {"rhythm": "dart", "extra": "wait at a light band's edge, then dash"},
	"chain_lightning": {"extra": "hair stands on end"},
	"static": {"bounce": 0.09, "extra": "fur frizzes with every step; a zap pose on contact"},
	"overcharge": {"extra": "every third ability animation doubles with an afterflash"},
	"sunburst": {"crouch": 0.2, "extra": "duck into shade at the warning glint"},
	"bloom": {"extra": "push through hedges that close behind"},
	"kinship": {"extra": "allies walk shoulder to shoulder, linked by a green thread"},
	"wild_paths": {"rhythm": "skip", "bounce": 0.12},
	"flock": {"sway": 0.12, "extra": "weave and shush through the flock"},
	"spores": {"tempo": 0.8, "sway": 0.14, "extra": "drowsy yawns, slow blinks, stumbles"},
	"thorns": {"rhythm": "dart", "extra": "flinch from walls, hop round hedges"},
	"regrowth": {"who": "guards", "extra": "wounds glow green and close"},
	"swarm_birth": {"who": "guards", "extra": "a knocked-out guard pops into two tiny ones"},
	"haunting": {"who": "carriers", "extra": "glance back at the glowing trail"},
	"soul_lanterns": {"tempo": 1.2, "extra": "hurry between lantern pools; flicker outside them"},
	"whispers": {"arms": "ears", "who": "guards", "extra": "an alarm travels as a visible wave"},
	"echoes": {"float": 0.2, "extra": "knocked out, rise as a translucent echo"},
	"sleepwalk": {"arms": "front", "tempo": 0.6, "rhythm": "shuffle", "who": "guards",
		"extra": "the crew tiptoes theatrically"},
	"soul_swap": {"extra": "a magenta swirl as two trade places"},
	"borrowed_face": {"rhythm": "stomp", "extra": "a mask; the crew copies the guards' march"},
	"mirror_images": {"shimmer": 0.6, "who": "guards", "extra": "illusions pop into sparkles when touched"},
	# §7.5's paradoxes.
	"reversal": {"sway": 0.18, "float": 0.25, "extra": "an upside-down sway; hair points at the sky"},
	"twin_suns": {"trail": 0.3, "extra": "two shadows; doubled flourishes"},
	"unmaking": {"extra": "stutter as rules blink in and out"},
}


static func of(law: String) -> Dictionary:
	var out := NEUTRAL.duplicate()
	out.merge(LAWS.get(law, {}), true)
	return out


## Several laws at once, as one gait: sizes multiply against the neutral
## walk (two hoppy laws hop higher still), fractions take the strongest,
## and a pose or rhythm comes from the first law that sets one.
static func blend(laws: Array) -> Dictionary:
	var out := NEUTRAL.duplicate()
	for law: String in laws:
		var g := of(law)
		for k: String in ["stride", "tempo"]:
			out[k] = float(out[k]) * float(g[k])
		out["lean"] = float(out["lean"]) + float(g["lean"])
		for k: String in ["bounce", "squash", "float", "skate", "tiptoe", "crouch", "sway", "trail", "shimmer"]:
			if float(g[k]) == float(NEUTRAL[k]):
				continue
			out[k] = g[k] if float(out[k]) == float(NEUTRAL[k]) else maxf(float(out[k]), float(g[k]))
		for k: String in ["arms", "rhythm", "lean_to"]:
			if out[k] == NEUTRAL[k]:
				out[k] = g[k]
	return out
