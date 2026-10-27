class_name UniversePins
extends Control
## The universe map's pins (§23.2: realms "with their laws, links, strain
## band, faults, alerts, resources"): each realm's name and level, which a
## tap swoops to; what each producer has ready, ringed when it is full; new
## raids on the Heart; a fault on the realm it opens from; and the next realm
## to open. They are interface, not world: placed each frame where the
## camera shows the point they belong to (the design's projected pins, :241).
## Words in ink-dark plates with paper text, so they read over any sky
## (§21.8), and each says in words what its colour says (§20.8).

## Pins' words: a little under body text, and never under §21.8's 13 points.
const POINTS := 14.0
## The realm labels' parchment and brown ink (§21.8's light family).
const PARCHMENT := Color("#FBF1DA")
const BROWN_INK := Color("#2A1A10")
## Each resource's colour and its glyph, so the colour is never alone.
const RESOURCE := {"star_well": ["#F2B43C", "✦"], "aether_spring": ["#3CC6D8", "◆"], "garden": ["#5CC46A", "❦"]}

var view: UniverseView
## Each pin: {"node": Control, "at": Vector3 or realm id, "realm": id, "lift": metres, "zooms": [levels]}.
var _pins: Array[Dictionary] = []


func _init(owner_view: UniverseView) -> void:
	view = owner_view
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The pins for a universe and what other slices add (`UniverseView.show_universe`).
func show_pins(universe: Dictionary, extras: Dictionary) -> void:
	for p: Dictionary in _pins:
		(p["node"] as Control).queue_free()
	_pins.clear()
	for r: Dictionary in universe.get("realms", []):
		var id := str(r.get("realm", ""))
		var title := UniversePresenter.realm_name(str(r.get("type", "Heart")))
		var key := UniverseLayout.type_key(str(r.get("type", "Heart")))
		var school: Color = Palette.SCHOOL.get(UniverseLayout.SCHOOLS[key], Palette.SPIRIT)
		var b := _realm_pin(id, title, int(r.get("level", 1)), school, key)
		_pins.append({"node": b, "realm": id, "front": true, "zooms": [0, 1], "rank": 1})
	var faults: Array = universe.get("faults", [])
	for f: Variant in faults:
		var plate := _plate(Palette.ALARM_FILL, Palette.ALARM_FILL)
		# The fault's mark over its realm, whose name is on the realm's own pin.
		plate.add_child(_with_icon("band_fault", _words("ϟ", Palette.ON_ALARM)))
		_pins.append({"node": plate, "realm": str(f), "lift": 3.5, "zooms": [0, 1, 2], "rank": 0})
	# Home says the raids and what is ready in its own interface (the raid
	# notice, Collect), so over its whole universe only the realms are named,
	# as the designs' home names them.
	var quiet := bool(extras.get("quiet", false))
	var raids := int(extras.get("raids", 0))
	if raids > 0:
		var plate := _plate(Palette.ALARM_FILL, Palette.ALARM_FILL)
		plate.add_child(_with_icon("alert_raided", _words("! %d" % raids, Palette.ON_ALARM)))
		_pins.append({"node": plate, "realm": "heart", "lift": 6.0, "zooms": [1, 2] if quiet else [0, 1, 2],
			"rank": 0})
	for p: Dictionary in extras.get("producers", []):
		var kind := str(p.get("kind", ""))
		var stored := int(p.get("stored", 0))
		if stored <= 0:
			continue
		var look: Array = RESOURCE.get(kind, ["#F2B43C", "✦"])
		var full := stored >= int(p.get("holds", 1))
		var plate := _plate(Palette.INK, Palette.ALARM if full else Color(look[0]))
		var words := _words("%s %s" % [look[1], ShopPresenter.grouped(stored)], Palette.PAPER)
		if full:
			plate.add_child(_with_icon("alert_ready", words))
		else:
			plate.add_child(words)
		# Over the whole universe only a full producer is pinned, as the
		# designs pin a realm's label only once it is nearly full.
		_pins.append({"node": plate, "realm": str(p.get("realm", "")), "building": kind, "lift": 0.0,
			"zooms": [0, 1, 2] if full and not quiet else [1, 2], "rank": 2})
	# A gold arrow over each building the server says can be raised now: a
	# price met and nothing in the way (§10.2's `next`, unblocked).
	for r: Dictionary in universe.get("realms", []):
		for b: Dictionary in r.get("buildings", []):
			var next: Variant = b.get("next")
			if next is Dictionary and (next as Dictionary).get("blocked") == null:
				var arrow := _plate(Palette.MOTION, Palette.INK, true)
				arrow.add_child(_icon("levelup"))
				_pins.append({"node": arrow, "realm": str(r.get("realm", "")), "lift": 1.2,
					"place": "%s:%d" % [str(b.get("kind", "")), int(b.get("n", 1))], "zooms": [2], "rank": 2})
	# §5.5's strain band over the Heart, in words beside the rings' colour.
	if extras.has("strain"):
		var plate := _plate(Palette.INK, Palette.STONE)
		plate.add_child(_with_icon("hud_strain", _words("%s %d%%" % [WeavingPresenter.band_name(int(extras["band"])),
			roundi(float(extras["strain"]) * 100.0)], Palette.PAPER)))
		_pins.append({"node": plate, "realm": "heart", "back": true, "zooms": [0, 1], "rank": 1})
	var open: Variant = universe.get("open")
	if open is Dictionary and not ((open as Dictionary).get("types", []) as Array).is_empty():
		var plate := _plate(Color(Palette.INK, 0.8), Palette.STONE)
		var name := UniversePresenter.realm_name(str((open as Dictionary)["types"][0]))
		plate.add_child(_words("+ " + name, Palette.PAPER))
		plate.mouse_filter = Control.MOUSE_FILTER_STOP
		plate.gui_input.connect(func(e: InputEvent) -> void:
			if _tapped(e):
				view.next_chosen.emit())
		_pins.append({"node": plate, "realm": "next:0", "lift": 1.0, "zooms": [0], "rank": 1})
	# Each link's kind, at its middle (the design's link icons, :1167).
	for l: Dictionary in view.links:
		var plate := _plate(Palette.PAPER, Palette.INK, true)
		plate.add_child(_icon("link_" + str(l["kind"])))
		_pins.append({"node": plate, "at": l["mid"], "zooms": [1, 2], "rank": 3})
	# The most urgent first: a pin that would cover one before it waits.
	_pins.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rank"]) < int(b["rank"]))
	for p: Dictionary in _pins:
		add_child(p["node"])
	follow()


## A realm's pin: its level in a disc of its school's colour, and its name;
## a tap swoops to it. Not a button: the screen's own list carries each realm
## for a screen reader, and the island itself takes the same tap.
func _realm_pin(id: String, title: String, level: int, school: Color, key: String) -> PanelContainer:
	# The design's label: a parchment plate edged in ink, the realm's icon,
	# its name in Marcellus in brown ink, its level on a dark disc after it.
	var plate := _plate(PARCHMENT, Palette.INK)
	var box := plate.get_theme_stylebox("panel") as StyleBoxFlat
	box.set_border_width_all(UI.px(2))
	box.border_color = school.darkened(0.55)
	box.shadow_color = Color(0.04, 0.02, 0.03, 0.55)
	box.shadow_size = 0
	box.shadow_offset = Vector2(0, UI.px(3))
	box.content_margin_left = UI.px(4)
	box.content_margin_right = UI.px(4)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(4))
	row.add_child(_icon("realm_" + key))
	var name := _words(title, BROWN_INK)
	name.add_theme_font_override("font", Tokens.font("title"))
	name.add_theme_font_size_override("font_size", UI.text_px(POINTS - 1.0))
	row.add_child(name)
	var badge := _plate(BROWN_INK, BROWN_INK, true)
	var disc := badge.get_theme_stylebox("panel") as StyleBoxFlat
	disc.content_margin_left = UI.px(5)
	disc.content_margin_right = UI.px(5)
	disc.content_margin_top = 0
	disc.content_margin_bottom = 0
	badge.add_child(_words(str(level), PARCHMENT))
	row.add_child(badge)
	plate.add_child(row)
	plate.mouse_filter = Control.MOUSE_FILTER_STOP
	plate.set_meta("realm", id)
	plate.gui_input.connect(func(e: InputEvent) -> void:
		if _tapped(e):
			view.choose(id))
	return plate


## A finger or the mouse lifted off a pin.
static func _tapped(e: InputEvent) -> bool:
	return (e is InputEventMouseButton and not (e as InputEventMouseButton).pressed
		and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
		or (e is InputEventScreenTouch and not (e as InputEventScreenTouch).pressed)


## One of the design's icons, at the height of a pin's words.
static func _icon(name: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://world/universe_icons/%s.svg" % name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2.ONE * UI.text_px(POINTS) * 1.35
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Words led by an icon.
static func _with_icon(name: String, words: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(3))
	row.add_child(_icon(name))
	row.add_child(words)
	return row


## A rounded plate in `fill`, edged in `edge`.
static func _plate(fill: Color, edge: Color, disc := false) -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill, maxf(fill.a, 0.9)) if fill.a > 0.5 else fill
	box.border_color = edge
	box.set_border_width_all(UI.px(1.5))
	box.set_corner_radius_all(UI.px(20))
	box.content_margin_left = UI.px(6 if disc else 8)
	box.content_margin_right = UI.px(6 if disc else 8)
	box.content_margin_top = UI.px(2)
	box.content_margin_bottom = UI.px(2)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = UI.px(2)
	box.shadow_offset = Vector2(0, UI.px(1))
	p.add_theme_stylebox_override("panel", box)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func _words(text: String, colour: Color) -> Label:
	var l := UI.label(text, POINTS)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_font_override("font", UI.bold_font())
	l.set_meta("bold", true)
	l.set_meta("points", POINTS)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Every pin where the camera now shows its point, shown at the zooms it
## belongs to.
func follow() -> void:
	if view.camera == null or not view.camera.is_inside_tree():
		return
	var toward := view.toward()
	var taken: Array[Rect2] = []
	# Pins keep clear of the screen's own controls (home's side buttons).
	var taken_by_screen: Array[Rect2] = view.keep_clear
	for p: Dictionary in _pins:
		var node: Control = p["node"]
		if p.has("at"):
			node.visible = view.zoom in (p["zooms"] as Array)
			if node.visible:
				_place(node, view.camera.unproject_position(p["at"]), taken, taken_by_screen)
			continue
		var id := str(p.get("realm", ""))
		if not view.islands.has(id):
			node.visible = false
			continue
		var isl: UniverseIsland = view.islands[id]
		var shown: bool = view.zoom in (p["zooms"] as Array)
		# Islands small on the screen keep only their names and alarms, and a
		# name only its realm's icon and level.
		var small := isl.radius / maxf(0.01, view.camera.size) * view.size.y < UI.px(28)
		if int(p["rank"]) >= 2 or p.get("back", false):
			shown = shown and not small
		if p.get("front", false):
			# A small island's pin is its icon and level; a nearer one's its name
			# between them.
			var words := node.get_child(0).get_child(1) as Control
			if words.visible == small:
				words.visible = not small
				node.reset_size()
		if view.zoom > 0 and id != view.focus_id:
			shown = false
		node.visible = shown
		if not shown:
			continue
		var at := isl.at + Vector3(0, float(p.get("lift", 0.0)), 0)
		if p.get("front", false) and view.zoom == 0:
			# Over the whole universe a realm's name floats over its far rim,
			# as the designs label their islands.
			# The Heart's over its spire.
			at = isl.at - toward * isl.radius * 0.7 + Vector3(0, 4.5, 0) if id != "heart" \
				else isl.at - toward * isl.radius * 0.2 + Vector3(0, 22.0, 0)
		elif p.get("front", false):
			at = isl.at + toward * isl.radius * 1.02 + Vector3(0, -1.6, 0)
		elif p.get("back", false):
			at = isl.at - toward * isl.radius * 0.95 + Vector3(0, 1.0, 0)
		elif p.has("building"):
			at = _producer_at(isl, str(p["building"]))
		elif p.has("place"):
			if not isl.places.has(str(p["place"])):
				node.visible = false
				continue
			at = (isl.places[str(p["place"])] as Vector3) + Vector3(0, float(p["lift"]), 0)
		_place(node, view.camera.unproject_position(at), taken, taken_by_screen)


## A pin centred on `s`, kept in the gap between `screen`'s controls on its
## row (home's side buttons), or below them where it is wider than the gap,
## unless it would cover one already placed.
static func _place(node: Control, s: Vector2, taken: Array[Rect2], screen: Array[Rect2]) -> void:
	node.position = (s - node.size / 2.0).round()
	var wide := (node.get_parent() as Control).size.x
	for attempt: int in 4:
		var lo := UI.px(4)
		var hi := wide - UI.px(4)
		var lowest := -1.0
		for r: Rect2 in screen:
			if r.position.y < node.position.y + node.size.y and r.end.y > node.position.y:
				if r.get_center().x < wide * 0.5:
					lo = maxf(lo, r.end.x + UI.px(2))
				else:
					hi = minf(hi, r.position.x - UI.px(2))
				lowest = maxf(lowest, r.end.y)
		if hi - lo >= node.size.x:
			node.position.x = clampf(node.position.x, lo, hi - node.size.x)
			break
		if lowest < 0.0 or attempt == 3:
			# And inside the screen's edges.
			if wide > node.size.x:
				node.position.x = clampf(node.position.x, UI.px(4), wide - node.size.x - UI.px(4))
			break
		node.position.y = lowest + UI.px(2)
	# Where it would cover another, a step down or up, else not at all.
	for step: float in [0.0, 1.0, -1.0]:
		var box := Rect2(node.position + Vector2(0.0, step * (node.size.y + UI.px(2))), node.size).grow(-UI.px(2))
		if not taken.any(func(other: Rect2) -> bool: return other.intersects(box)):
			node.position = box.grow(UI.px(2)).position
			taken.append(box)
			return
	node.visible = false


## Where a producer of `kind` stands on its island, its pin over it.
static func _producer_at(isl: UniverseIsland, kind: String) -> Vector3:
	for k: String in isl.places:
		if k.begins_with(kind + ":"):
			return isl.places[k]
	return isl.at + Vector3(0, 3.0, 0)


## The realm a pin on the screen stands for, by its id: what a test taps.
func realm_pin(id: String) -> Control:
	for p: Dictionary in _pins:
		if p.get("front", false) and str(p["realm"]) == id:
			return p["node"]
	return null
