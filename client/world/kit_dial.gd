class_name KitDial
extends RefCounted
## The Heart's great clock dial round the Keeper's Spire, as the design's
## heist draws it (02-heist; realm-diorama.js :1316–1322): a pale face with
## its rims, ticks, Roman hours and an inner ring of pink and cyan wedges,
## painted by the ground shader (kit_ground.gdshader's `dial`), and here its
## raised parts: a lilac curb round the rim and two dark hands, standing
## still. Ground paint and a low curb, so it decides nothing about the tiles
## it lies over.

## The dial's radius past the Spire's half side, in tiles: the design's dial
## is about three times as wide as the Spire's terrace.
const REACH := 2.0
const CURB := Color("#B89AD0")
const HAND := Color("#4A2A6A")


## The radius of the dial round a Spire `side` tiles a side.
static func radius(side: int) -> float:
	return side / 2.0 + REACH


## The curb (into `fine`, un-inked, so it reads lilac, not as a black line)
## and the hands (into `g`, inked) of a dial of `r` centred on `mid`.
static func build(g: Geo, fine: Geo, mid: Vector3, r: float) -> void:
	g.standing(mid.y)
	fine.standing(mid.y)
	fine.torus(Transform3D(Basis.IDENTITY, mid + Vector3(0, 0.02, 0)), r + 0.04, 0.1, CURB,
		72 if not fine.coarse else 40, 4)
	# The hands, as the design's: the long one toward ten to, the short one
	# toward four, laid flat from the centre (the Spire hides the hub).
	for hand: Array in [[0.74, 0.05, -0.9], [0.52, 0.07, 0.6]]:
		var length: float = hand[0] * r
		var yaw: float = hand[2]
		var dir := Vector3(sin(yaw), 0, cos(yaw))
		g.box(Geo.place(mid + dir * length / 2.0 + Vector3(0, 0.025, 0), yaw),
			Vector3(float(hand[1]) * r * 0.6, 0.05, length), HAND)
