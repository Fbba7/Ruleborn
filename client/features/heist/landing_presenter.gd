class_name LandingPresenter
extends RefCounted
## §5.4's landing picker in words: each edge spot by its side and place
## along it, covered (fog, tall grass or darkness on it, so no guard hears
## the skiff) or open (heard within the walked tiles a landing reaches), and
## the heist's clock (§23.2: "each spot marked covered or open from the
## terrain alone, whether a landing there would be heard, and the heist clock
## and depth for each choice").


## Which side of a `side`-wide island the edge tile `at` is on, north first
## at the corners, and how far along it, from 1.
static func place(at: Vector2i, side: int) -> Array:
	if at.y == 0:
		return ["NORTH", at.x + 1]
	if at.y == side - 1:
		return ["SOUTH", at.x + 1]
	if at.x == 0:
		return ["WEST", at.y + 1]
	return ["EAST", at.y + 1]


static func spot(m: Dictionary, side: int, reach: int) -> String:
	var p := place(Vector2i(m["at"]), side)
	var how := Strings.t("LANDING_COVERED") if m.get("covered", false) else Strings.t("LANDING_OPEN", reach)
	return Strings.t("LANDING_SPOT", [Strings.t("LANDING_" + str(p[0])), int(p[1]), side, how])


static func clock(seconds: int) -> String:
	return Strings.t("LANDING_CLOCK", "%d:%02d" % [seconds / 60, seconds % 60])


## The picker: the spot on show, how many there are and how many covered,
## and its three buttons.
static func picker(marks: Array, pick: int, side: int, reach: int, seconds: int) -> Dictionary:
	if marks.is_empty():
		return {"open": false}
	var covered := marks.filter(func(m: Dictionary) -> bool: return m.get("covered", false)).size()
	var shown: Dictionary = marks[clampi(pick, 0, marks.size() - 1)]
	return {"open": true, "title": Strings.t("LANDING_TITLE"),
		"spot": spot(shown, side, reach), "count": Strings.t("LANDING_COUNT", [marks.size(), covered]),
		"clock": clock(seconds), "at": shown["at"], "covered": shown.get("covered", false)}
