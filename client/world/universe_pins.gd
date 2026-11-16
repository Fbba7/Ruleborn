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

## How far a pin may stand from the point it marks, in its own heights: a
## named pin within `NEAR` of it, so it reads as its island's (S2-R20's first
## objection); a pin shrunk to its level alone within `FAR`, before it hides.
const NEAR := 1.25
const FAR := 3.0

var view: UniverseView
## Each pin: {"node": Control, "at": Vector3 or realm id, "realm": id, "lift": metres, "zooms": [levels]}.
var _pins: Array[Dictionary] = []
## The most each realm's pin may show (see `_shape`): 0 its icon, name and
## level; 1 its icon and level; 2 its level alone, a numbered chip. Each pin
## shows the most that finds a place near its island, down to this; this
## drops for every realm only where one found none at all. Until the room
## changes.
var _mode := 0
var _room := []


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
		# Locked, as the designs' "Opens at Keeper 28" on a dark pill with a
		# lock; open to buy, its name after a plus.
		var plate := _plate(Color("#100A22", 0.94), Color("#C8BEE6", 0.5), false, 1.5, Color(0, 0, 0, 0.45), 3.0)
		var name := UniversePresenter.realm_name(str((open as Dictionary)["types"][0]))
		var needs: Dictionary = (open as Dictionary).get("needs", {})
		match str((open as Dictionary).get("blocked", "")):
			"keeper_level":
				plate.add_child(_with_mark("generalui/lock", _words(Strings.t("HOME_OPENS_KEEPER",
					int(needs.get("keeper", 0))), Palette.PAPER)))
			"spire_level":
				plate.add_child(_with_mark("generalui/lock", _words(Strings.t("UNIVERSE_NEEDS_SPIRE",
					int(needs.get("spire", 0))), Palette.PAPER)))
			_:
				plate.add_child(_words("+ " + name, Palette.PAPER))
		plate.mouse_filter = Control.MOUSE_FILTER_STOP
		plate.gui_input.connect(func(e: InputEvent) -> void:
			if _tapped(e):
				view.next_chosen.emit())
		_pins.append({"node": plate, "realm": "next:0", "rim": true, "zooms": [0], "rank": 1})
	# Each link's kind, at its middle (the design's link icons, :1167).
	# Drawn by the pins in one run (`_draw`): a paper disc each, then the icons.
	for l: Dictionary in view.links:
		var mark := Control.new()
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var d := UI.text_px(POINTS) * 1.35 + UI.px(8)
		mark.custom_minimum_size = Vector2(d, d)
		mark.size = mark.custom_minimum_size
		mark.set_meta("link", load("res://world/universe_icons/link_%s.svg" % str(l["kind"])))
		_pins.append({"node": mark, "at": l["mid"], "zooms": [1, 2], "rank": 3})
	# The most urgent first: a pin that would cover one before it waits.
	_pins.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rank"]) < int(b["rank"]))
	for p: Dictionary in _pins:
		add_child(p["node"])
	follow()


## A realm's pin: its level in a disc of its school's colour, and its name;
## a tap swoops to it. Not a button: the screen's own list carries each realm
## for a screen reader, and the island itself takes the same tap.
func _realm_pin(id: String, title: String, level: int, school: Color, key: String) -> PanelContainer:
	# The design's label: a parchment plate edged in brown ink, the realm's
	# icon, its name in Marcellus in brown ink, its level on a dark disc after
	# it. Only the name is a node that draws; the plate, icon, disc and level
	# are drawn by the pins together (`_draw`), so the seven labels cost the
	# frame a handful of draw calls, not forty (§21.3).
	var plate := PanelContainer.new()
	var box := StyleBoxEmpty.new()
	box.content_margin_left = UI.px(4)
	box.content_margin_right = UI.px(4)
	box.content_margin_top = UI.px(2)
	box.content_margin_bottom = UI.px(2)
	plate.add_theme_stylebox_override("panel", box)
	plate.set_meta("behind", [PARCHMENT])
	plate.set_meta("school", school)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(4))
	var icon := Control.new()
	icon.custom_minimum_size = Vector2.ONE * UI.text_px(POINTS) * 1.35
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_meta("icon", load("res://world/universe_icons/realm_%s.svg" % key))
	row.add_child(icon)
	var name := _words(title, BROWN_INK)
	name.add_theme_font_override("font", Tokens.font("title"))
	name.add_theme_font_size_override("font_size", UI.text_px(POINTS - 1.0))
	row.add_child(name)
	var digits := str(level)
	var badge := Control.new()
	var w := UI.bold_font().get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(POINTS)).x
	badge.custom_minimum_size = Vector2(maxf(w + UI.px(10), UI.text_px(POINTS) * 1.3), UI.text_px(POINTS) * 1.3)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_meta("digits", digits)
	badge.accessibility_name = digits
	row.add_child(badge)
	plate.add_child(row)
	plate.mouse_filter = Control.MOUSE_FILTER_STOP
	plate.set_meta("realm", id)
	plate.gui_input.connect(func(e: InputEvent) -> void:
		if _tapped(e):
			view.choose(id))
	return plate


## The realm labels' plates, discs, icons and levels, each kind drawn in one
## run across every label so the runs batch: one texture per run.
func _draw() -> void:
	var plates: Array[Control] = []
	for p: Dictionary in _pins:
		var node: Control = p["node"]
		if node.visible and node.has_meta("school") and not node.is_queued_for_deletion():
			plates.append(node)
	var ci := get_canvas_item()
	var edge := Color("#6B4420")
	var plate := UniverseHud.baked_box(PARCHMENT, edge, UI.px(2.0), UI.text_px(POINTS) * 0.6,
		Color(0.04, 0.02, 0.03, 0.55), UI.px(3.0))
	for node: Control in plates:
		plate.draw(ci, Rect2(node.position, node.size))
	# The icon at the plate's start, the level's disc at its end, both centred
	# up and down; from the plate's own size, as its row sorts its children a
	# frame late after `_shape` hides some, which would draw the disc over the
	# icon on a plate half empty (AD's objection (f) on S2-R25).
	var parts := func(node: Control, at: int) -> Rect2:
		var c := node.get_child(0).get_child(at) as Control
		var inner := Rect2(node.position + Vector2(UI.px(4), UI.px(2)), node.size - Vector2(UI.px(8), UI.px(4)))
		var s := c.get_combined_minimum_size()
		var x := inner.position.x if at == 0 else inner.end.x - s.x
		return Rect2(Vector2(x, inner.get_center().y - s.y * 0.5), s)
	var disc := UniverseHud.baked_box(BROWN_INK, BROWN_INK, 0.0, UI.text_px(POINTS) * 0.6, Color(0, 0, 0, 0), 0)
	for node: Control in plates:
		disc.draw(ci, parts.call(node, 2))
	for node: Control in plates:
		var icon := node.get_child(0).get_child(0) as Control
		if icon.visible:
			draw_texture_rect(icon.get_meta("icon"), parts.call(node, 0), false)
	_draw_links()
	var font := UI.bold_font()
	var px := UI.text_px(POINTS)
	for node: Control in plates:
		var r: Rect2 = parts.call(node, 2)
		draw_string(font, Vector2(r.position.x, r.get_center().y + font.get_ascent(px) * 0.36),
			str(node.get_child(0).get_child(2).get_meta("digits")), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, px, PARCHMENT)


## Each link's kind at its middle: paper discs in one run, then the icons
## sorted by kind, so the links cost a draw call a kind.
func _draw_links() -> void:
	var marks: Array[Control] = []
	for p: Dictionary in _pins:
		var node: Control = p["node"]
		if node.visible and node.has_meta("link") and not node.is_queued_for_deletion():
			marks.append(node)
	if marks.is_empty():
		return
	marks.sort_custom(func(a: Control, b: Control) -> bool:
		return (a.get_meta("link") as Texture2D).get_rid().get_id() < (b.get_meta("link") as Texture2D).get_rid().get_id())
	for node: Control in marks:
		UniverseHud.ball(self, node.position + node.size * 0.5, node.size.x * 0.5, [Palette.PAPER, Palette.PAPER,
			Palette.PAPER.darkened(0.1)], Color(), true)
	for node: Control in marks:
		var s := node.size.x - UI.px(10)
		draw_texture_rect(node.get_meta("link"), Rect2(node.position + (node.size - Vector2(s, s)) * 0.5,
			Vector2(s, s)), false)


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


## Words led by one of the kit's icons (`Icons`).
static func _with_mark(name: String, words: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(6))
	var t := TextureRect.new()
	t.texture = Icons.texture(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2.ONE * UI.text_px(POINTS)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(t)
	row.add_child(words)
	return row


## Words led by an icon.
static func _with_icon(name: String, words: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(3))
	row.add_child(_icon(name))
	row.add_child(words)
	return row


## A rounded plate in `fill`, edged in `edge`, baked (UniverseHud.baked_box)
## so each costs the frame one draw call; it says what its words sit on.
static func _plate(fill: Color, edge: Color, disc := false, line := 1.5, shade := Color(0, 0, 0, 0.35),
		under := 1.0) -> PanelContainer:
	var p := PanelContainer.new()
	var solid := Color(fill, maxf(fill.a, 0.9)) if fill.a > 0.5 else fill
	var radius := minf(UI.px(20), UI.text_px(POINTS) * 0.6)
	var box := UniverseHud.baked_box(solid, edge, UI.px(line), radius, shade, UI.px(under)).duplicate() \
		as StyleBoxTexture
	box.content_margin_left = UI.px(6 if disc else 8)
	box.content_margin_right = UI.px(6 if disc else 8)
	box.content_margin_top = UI.px(2)
	box.content_margin_bottom = UI.px(2)
	p.add_theme_stylebox_override("panel", box)
	p.set_meta("behind", [solid])
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
## belongs to. Where a realm's pin finds no room near its island for its name,
## every realm's pin shrinks a step together, to its icon and level, then to its
## level alone, a numbered chip, so the realms are marked in one form (AD's
## objection (b) on S2-R22). The names come back when the room changes.
func follow() -> void:
	if view.camera == null or not view.camera.is_inside_tree():
		return
	queue_redraw()
	var room := [view.size, view.inset, view.zoom, view.keep_clear]
	if room != _room:
		_room = room
		_mode = 0
	while not _lay(_mode) and _mode < 2:
		_mode += 1


## The pins laid out once, the realms' in `mode` (see `_mode`); false where a
## realm's pin that belongs on the screen found no room.
func _lay(mode: int) -> bool:
	var every := true
	var toward := view.toward()
	var taken: Array[Rect2] = []
	# Pins keep clear of the screen's own controls (home's side buttons).
	var taken_by_screen: Array[Rect2] = view.keep_clear
	for p: Dictionary in _pins:
		var node: Control = p["node"]
		if p.has("at"):
			node.visible = view.zoom in (p["zooms"] as Array) and _spot(node,
				view.camera.unproject_position(p["at"]), taken, taken_by_screen, view.inset.x, node.size.y * FAR)
			continue
		var id := str(p.get("realm", ""))
		if not view.islands.has(id):
			node.visible = false
			continue
		var isl: UniverseIsland = view.islands[id]
		var shown: bool = view.zoom in (p["zooms"] as Array)
		# Islands small on the screen keep only their realms' pins and alarms.
		var small := isl.radius / maxf(0.01, view.camera.size) * view.size.y < UI.px(28)
		if int(p["rank"]) >= 2 or p.get("back", false):
			shown = shown and not small
		if view.zoom > 0 and id != view.focus_id:
			shown = false
		node.visible = shown
		if not shown:
			continue
		var at := isl.at + Vector3(0, float(p.get("lift", 0.0)), 0)
		if (p.get("front", false) or p.get("rim", false)) and view.zoom == 0:
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
		var s := view.camera.unproject_position(at)
		node.set_meta("anchor", s)
		if not p.get("front", false):
			node.visible = _spot(node, s, taken, taken_by_screen, view.inset.x, node.size.y * FAR)
			continue
		# A realm's pin with its name where a place near its island is free,
		# never over another realm (S2-R20's first objection). Every realm's pin
		# takes the same form (AD's objection (b) on S2-R22): where one finds no
		# room, `follow` lays them all again a step smaller.
		_shape(node, mode)
		var placed := _spot(node, s, taken, taken_by_screen, view.inset.x, node.size.y * (NEAR if mode < 2 else FAR))
		node.visible = placed
		every = every and placed
	return every


## The pin at the free place nearest the point `s` it marks, within `reach`
## pixels of it: clear by `pin_gap()` of the pins already placed (`taken`) and of
## the screen's controls (`screen`: home's side buttons with their badges,
## Collect, the goal, the raid card), inside the screen's edges and never above
## `ceiling`, the controls at the top it would slip under. False, and the pin
## where it was, where no place so near is free. The nearest counts a step
## aside at half a step up or down, as a pin is wider than it is tall: a pin
## slides along its island's rim before it leaves it.
static func _spot(node: Control, s: Vector2, taken: Array[Rect2], screen: Array[Rect2], ceiling: float,
		reach: float) -> bool:
	var parent := node.get_parent() as Control
	var dim := node.size
	var gap := pin_gap()
	var lo := Vector2(UI.px(4), ceiling + UI.px(2))
	var hi := Vector2(parent.size.x - dim.x - UI.px(4), parent.size.y - dim.y)
	if hi.x < lo.x or hi.y < lo.y:
		return false
	var centred := (s - dim / 2.0).round()
	var xs: Array[float] = [centred.x, s.x - dim.x + UI.px(8), s.x - UI.px(8)]
	var ys: Array[float] = [centred.y, s.y - dim.y, s.y]
	for r: Rect2 in taken + screen:
		xs.append(r.end.x + gap)
		xs.append(r.position.x - dim.x - gap)
		ys.append(r.end.y + gap)
		ys.append(r.position.y - dim.y - gap)
	var best := Vector2.INF
	var score := INF
	for y0: float in ys:
		var y := clampf(y0, lo.y, hi.y)
		if absf(y + dim.y / 2.0 - s.y) > reach + dim.y:
			continue
		for x0: float in xs:
			var v := Vector2(clampf(x0, lo.x, hi.x), y)
			var at := Rect2(v, dim)
			if _off(at, s) > reach:
				continue
			var d := at.get_center() - s
			var cost := d.x * d.x * 0.25 + d.y * d.y
			if cost >= score:
				continue
			var box := at.grow(gap - 0.5)
			if taken.any(func(o: Rect2) -> bool: return o.intersects(box)) \
					or screen.any(func(o: Rect2) -> bool: return o.intersects(box)):
				continue
			best = v
			score = cost
	if score == INF:
		return false
	node.position = best
	taken.append(Rect2(best, dim))
	return true


## The space a pin keeps from the others and from the screen's controls, so
## numbered chips at large text never touch (S2-R20's fifth objection).
static func pin_gap() -> float:
	return UI.px(4)


## How far the point `s` lies outside `r`; nothing where `r` holds it.
static func _off(r: Rect2, s: Vector2) -> float:
	var dx := maxf(maxf(r.position.x - s.x, s.x - r.end.x), 0.0)
	var dy := maxf(maxf(r.position.y - s.y, s.y - r.end.y), 0.0)
	return Vector2(dx, dy).length()


## A realm's pin in `form`: 0 its icon, name and level; 1 its icon and level;
## 2 its level alone, a numbered chip.
static func _shape(node: Control, form: int) -> void:
	var row := node.get_child(0)
	var icon := row.get_child(0) as Control
	var words := row.get_child(1) as Control
	if words.visible != (form == 0) or icon.visible != (form < 2):
		words.visible = form == 0
		icon.visible = form < 2
		node.reset_size()


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
