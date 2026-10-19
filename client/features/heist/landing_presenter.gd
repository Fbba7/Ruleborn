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


## A realm by its code: the Heart, or outer realm k.
static func realm_name(code: int) -> String:
	return Strings.t("UNIVERSE_HEART") if code == 0 else Strings.t("OBS_OUTER_REALM", code)


## Where a choice across a universe lands (§5.4): its realm and the links on
## its shortest route to the Heart, which its clock counts, or its fault,
## straight through to the Heart.
static func realm_line(m: Dictionary) -> String:
	var name := realm_name(int(m["code"]))
	if m.get("fault", false):
		return Strings.t("LANDING_FAULT", name)
	var links := int(m["links"])
	return Strings.t("LANDING_REALM_ONE", name) if links == 1 else Strings.t("LANDING_REALM_MANY", [name, links])


## The picker: the spot on show, how many there are and how many covered,
## and its three buttons. Across a universe each choice carries its realm,
## its links and its own clock (§23.2: "Every outer realm's edge and each
## fault … the heist clock and depth for each choice"), and a fault is a
## choice of its own.
static func picker(marks: Array, pick: int, side: int, reach: int, seconds: int) -> Dictionary:
	if marks.is_empty():
		return {"open": false}
	var edges := marks.filter(func(m: Dictionary) -> bool: return not m.get("fault", false))
	var covered := edges.filter(func(m: Dictionary) -> bool: return m.get("covered", false)).size()
	var shown: Dictionary = marks[clampi(pick, 0, marks.size() - 1)]
	if not shown.has("code"):
		return {"open": true, "title": Strings.t("LANDING_TITLE"),
			"spot": spot(shown, side, reach), "count": Strings.t("LANDING_COUNT", [marks.size(), covered]),
			"clock": clock(seconds), "at": shown["at"], "covered": shown.get("covered", false)}
	var realms := {}
	for m: Dictionary in edges:
		realms[int(m["code"])] = true
	var fault: bool = shown.get("fault", false)
	return {"open": true, "title": Strings.t("LANDING_TITLE"),
		"spot": realm_line(shown) if fault else spot(shown, int(shown["side"]), reach),
		"realm": realm_line(shown),
		"count": Strings.t("LANDING_COUNT", [edges.size(), covered]),
		"across": Strings.t("LANDING_ACROSS", [realms.size(), marks.size() - edges.size()]),
		"clock": clock(int(shown["ticks"]) / 30), "at": shown["at"], "covered": shown.get("covered", false),
		"fault": fault}
