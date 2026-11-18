class_name HeistHud
extends VBoxContainer
## §21.8's heist layout, top row: "Clock and alarm meter at the top centre;
## loot at the top right as two numbers, what the bags can still take and what
## is left to load (12.19), beside the Vault's progress; the law banner at the
## top left". Built from the kit alone (docs/art/ui-quality/kit-spec.md 6.3):
## the clock is KitHud.clock_large with KitNumerals' baked timer figures
## (KitHud.clock while the numerals are switched off), counting down and turning to the alarm's red plate in its last 30
## seconds; the alarm is KitHud.alarm_fit, six bells with "N / 6" written
## beside them so the level never rests on colour (§20.8); the loot is
## KitHud.loot_fit, its two numbers over the bags' fill, with how far the
## Vault is cracked as a third while it is shut; each law running in the
## realm is the kit's KitCards.law_chip_fit. A piece whose numbers change is
## set in place (KitHud.set_clock, set_alarm, set_loot), and built again only
## when its shape does. Three columns, left, centre and right; with §20.8's
## large text the loot stands under the laws.

## §21.8: the clock turns red in its last 30 seconds.
const RED_SECONDS := 30
const BELLS := 6
## How many coins fly to the loot at most, and how long each takes (seconds).
const COINS := 6
const FLIGHT := 0.6
## The heist's HUD layer (AD-R55): the screen's HUD columns stand here, above
## every layer of the world under them. The kit stacks the world's markers
## and marks (FxAnchors, full-screen over the world's picture) one overlay
## above the picture (kit-spec.md section 5), so the HUD stands one overlay
## above those, and no marker draws over a panel's words at any text size.
const HUD_Z := 2 * UI.OVERLAY_Z

var clock_label: Label
var alarm_label: Label
var loot_panel: PanelContainer
## §12.5's load target the screen gives, and the target card's rough loot
## estimate (12.4), -1 when the heist has none: "Left" says it until the
## Vault opens, and "?" without one. No load target (a replay) shows no
## "Load to" and no tick.
var load_target := -1
var estimate := -1
## Across a universe, the realm the crew is in and how many it has yet to
## cross to the Heart (§5.4).
var realm_label: Label
var laws_box: VBoxContainer
var clock_panel: PanelContainer
var alarm_panel: PanelContainer

var _alarm := 0
var _open := false
var _vault_full := -1
var _laws_key := ""
var _loot_key := ""
var _red := false
var _time := 0.0
## The loot's bar: the bags' fill.
var _load: KitBar
## Coins on their way to the loot panel: {from: Vector2 (global), t: float,
## coin: Control}.
var _flights: Array[Dictionary] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	# Three columns; with §20.8's large text the loot stands under the law
	# banner, rather than outgrow the phone.
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var large := Settings.text_scale > 130
	# With large text the columns stand closer, so a law's two words keep one
	# line beside the alarm.
	top.add_theme_constant_override("separation", UI.px(1 if large else 4))
	add_child(top)
	# The law banner, top left: "Laws here" over a chip for each law.
	var left := _side(top)
	var laws := VBoxContainer.new()
	laws.name = "Laws"
	laws.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laws.add_theme_constant_override("separation", UI.px(4))
	# The chips share the column's width, as the designs': a name lies on one
	# line wherever the column has room for it.
	laws.size_flags_horizontal = Control.SIZE_FILL
	# AD-R18: gold words outlined in ink were lost on the night sky (ink and
	# sky a few L* apart), so the header is seated on the kit's tag plate:
	# dark capitals on gold inside the ink line, which part from any sky.
	var here := KitStatus.tag(Strings.t("HUD_LAWS_HERE"))
	here.name = "Here"
	if not large:
		# The plate's capitals set the laws column's width at normal text:
		# German's "GESETZE HIER" on one line pushed the top row past the
		# frame (§21.1), so a header wider than 80 points (in the bold face,
		# before the kicker's spacing; "LAWS HERE" is about 73) breaks
		# between its words. Large text already stacks the row.
		var plate := here.get_child(0) as Label
		var wide := UI.bold_font().get_string_size(plate.text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1,
			plate.get_theme_font_size("font_size")).x
		if wide > UI.px(80):
			plate.text = plate.text.replace(" ", "\n")
	if Tokens.high_contrast:
		# High contrast thickens the plate's ink line until it crowds the
		# capitals; a ring of the plate's own fill (high contrast's paper)
		# round each letter keeps them off the line (§21.8 counts an outline
		# of 1.5 points or more).
		var words := here.get_child(0) as Label
		words.add_theme_color_override("font_outline_color", Tokens.color("paper"))
		words.add_theme_constant_override("outline_size", UI.px(2))
	laws.add_child(here)
	laws_box = VBoxContainer.new()
	laws_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laws_box.add_theme_constant_override("separation", UI.px(5))
	laws.add_child(laws_box)
	laws.visible = false
	left.add_child(laws)
	# The clock on its plate, the alarm's bells beneath.
	var centre := VBoxContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_theme_constant_override("separation", UI.px(3))
	centre.alignment = BoxContainer.ALIGNMENT_BEGIN
	centre.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(centre)
	clock_panel = PanelContainer.new()
	centre.add_child(clock_panel)
	_build_clock("0:00")
	alarm_panel = PanelContainer.new()
	centre.add_child(alarm_panel)
	_build_alarm()
	# The loot, top right; with large text the whole width under the law
	# banner and the alarm instead, so each of its lines keeps one line and
	# the column stays above the hand's controls.
	loot_panel = PanelContainer.new()
	if large:
		loot_panel.size_flags_horizontal = Control.SIZE_FILL
		add_child(loot_panel)
	else:
		loot_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
		_side(top).add_child(loot_panel)
	_build_loot(_loot_rows("", "?"), 0.0, "", [])
	var realm_panel := KitStatus.hint("")
	realm_panel.name = "Realm"
	realm_panel.visible = false
	realm_label = realm_panel.get_node("Words")
	realm_label.visible = false
	add_child(realm_panel)


## With §20.8's large text a panel's leather is thinner (3 points top and
## bottom, and 5 at the sides where `sides`), so the HUD's column keeps clear
## of the hand's tray and a law's two words keep one line beside the alarm.
static func _tight(p: PanelContainer, sides := true, side := 5.0) -> void:
	if Settings.text_scale <= 130:
		return
	var box := p.get_theme_stylebox("panel").duplicate() as StyleBox
	if sides:
		box.content_margin_left = UI.px(side)
		box.content_margin_right = UI.px(side)
	box.content_margin_top = UI.px(3)
	box.content_margin_bottom = UI.px(3)
	p.add_theme_stylebox_override("panel", box)


## With §20.8's large text a law's name keeps one line: where the column
## is too narrow for it whole (pt_BR's wider "Alarme" beside it), its size
## steps down, to 80% at most, rather than the name breaking in two and the
## banner standing a line taller, which pushed the loot into the tray (M26).
static func _one_line(l: Label) -> void:
	if l == null or Settings.text_scale <= 130:
		return
	# Measured afresh at each width the column gives it, so a narrow pass
	# mid-layout leaves no name smaller than it needs; its face and full size
	# read in the tree, where its theme is.
	l.resized.connect(func() -> void:
		if not l.has_meta("full_px"):
			l.set_meta("full_px", l.get_theme_font_size("font_size"))
		var full: int = l.get_meta("full_px")
		var face := l.get_theme_font("font")
		var wide := face.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, full).x
		var room := (l.size.x - l.get_theme_stylebox("normal").get_minimum_size().x) * 0.97
		var px := full
		if wide > room and room > 0.0:
			px = maxi(int(full * 0.8), int(floorf(full * room / wide)))
		if px != l.get_theme_font_size("font_size"):
			l.add_theme_font_size_override("font_size", px))


## The alarm panel's count (KitHud.alarm_fit names it "Count").
static func alarm_label_of(piece: PanelContainer) -> Label:
	return piece.find_child("Count", true, false) as Label


## A figure in the kit's baked numerals (KitNumerals), the display finish
## the clock wears (a stroke and a hard drop baked in), in place of its flat
## live words: only with §20.8's large text, where the gate reads the
## figures at display size, and while the numerals' skin is on. The kit's
## label stays the figure's source (set_loot and set_alarm write to it),
## hidden inside a box (marked "baked") that holds the baked row; `_sync` redraws the row
## when the words change. A mark the numerals do not bake (the estimate's
## "~") stays live text before them. Baked glyphs batch with the atlas, so
## the figures cost few draws of their own (an outline and a drop on the
## live words cost 11 at 200%).
static func _bake(l: Label, finish: String) -> void:
	if l == null or Settings.text_scale <= 130 or not KitSkin.is_on("numerals"):
		return
	var box := HBoxContainer.new()
	box.name = "Baked"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_END if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT \
		else BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", 0)
	box.custom_minimum_size.y = l.custom_minimum_size.y
	box.size_flags_horizontal = l.size_flags_horizontal
	box.size_flags_vertical = l.size_flags_vertical
	box.set_meta("finish", finish)
	box.set_meta("baked", true)
	var parent := l.get_parent()
	var at := l.get_index()
	parent.remove_child(l)
	parent.add_child(box)
	parent.move_child(box, at)
	box.add_child(l)
	l.visible = false
	_sync(l)


## A baked figure's row (`_bake`) drawn again for its label's words and the
## finish asked, when either changed; nothing for a label not baked.
static func _sync(l: Label, finish := "") -> void:
	if l == null or l.get_parent() == null or not l.get_parent().has_meta("baked"):
		return
	var box := l.get_parent() as HBoxContainer
	if finish == "":
		finish = str(box.get_meta("finish"))
	var shown := "%s|%s" % [l.text, finish]
	if str(box.get_meta("shown", "")) == shown:
		return
	box.set_meta("shown", shown)
	box.set_meta("finish", finish)
	for c: Node in box.get_children():
		if c != l:
			box.remove_child(c)
			c.queue_free()
	var text := l.text
	if text.begins_with("~"):
		var mark := Label.new()
		mark.text = "~"
		mark.add_theme_font_size_override("font_size", l.get_theme_font_size("font_size"))
		mark.add_theme_color_override("font_color", l.get_theme_color("font_color"))
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(mark)
		text = text.substr(1)
	# "4 / 6" closes up to "4/6": the baked glyphs' own sidebearings space
	# them, and the alarm's column keeps a law's two words on one line.
	var row := KitNumerals.make(text.replace(" ", ""), finish, "number", l.text)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A figure tinted (the loot's cream in high contrast, AD-R62): the white
	# glyphs take it, their ink line stays dark.
	if l.has_meta("tint"):
		if row is Label:
			row.add_theme_color_override("font_color", l.get_meta("tint"))
		else:
			row.modulate = l.get_meta("tint")
	box.add_child(row)
	_through(box)


## The alarm count's finish: white, and the timer's red from past half the
## bells, as KitHud colours the live count (§20.8).
func _alarm_finish() -> String:
	return "num_timer_red" if _alarm >= BELLS / 2 + 1 else "num_white"


## A side column of the top row: it takes what room there is.
func _side(top: HBoxContainer) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_child(v)
	return v


## Puts a kit piece built afresh where `old` stood, keeping its place, how it
## sits in its column and its spoken name. The HUD lies over the world, so
## no part of it takes a touch.
func _swap(old: Control, piece: Control) -> void:
	var parent := old.get_parent()
	var at := old.get_index()
	piece.size_flags_horizontal = old.size_flags_horizontal
	piece.accessibility_name = old.accessibility_name
	parent.remove_child(old)
	old.queue_free()
	parent.add_child(piece)
	parent.move_child(piece, at)
	_through(piece)


## The chip's icon as a rendered badge in its school's shape (FxLawBadge,
## §21.8), at its painted size, in place of the kit's small glyph or disc.
static func _badge(chip: PanelContainer, icon: String, law: String) -> void:
	if not Icons.has(icon) or chip.get_child_count() == 0:
		return
	var row := chip.get_child(0) as HBoxContainer
	if row == null or row.get_child_count() < 2:
		return
	var old := row.get_child(0) as Control
	var links: Array = LawFxLinks.LAWS.get(law, [""])
	# 22 points at 100% text keeps the laws column inside §21.1's frame width.
	var large := Settings.text_scale > 130
	var badge := FxLawBadge.make(icon, str(links[0]), 26.0 if large else 22.0)
	badge.name = "Badge"
	row.add_child(badge)
	row.move_child(badge, 0)
	row.remove_child(old)
	old.queue_free()
	row.add_theme_constant_override("separation", UI.px(4 if large else 1))


static func _through(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in node.get_children():
		_through(c)


func _build_clock(text: String) -> void:
	# The large plate is the baked figures' (board 1's objection A). While the
	# numerals are switched off, its live words would be inked, outlined and
	# shadowed at display size, three passes over the frame's budget at 200%
	# text, so the clock keeps the kit's plain plate until then.
	var piece := KitHud.clock_large(text, _red) if KitSkin.is_on("numerals") else KitHud.clock(text, _red)
	piece.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tight(piece)
	clock_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_swap(clock_panel, piece)
	clock_panel = piece
	clock_label = piece.get_node("Time")
	_figures(text)


## The clock's time: KitHud.set_clock's words and plate, and with the kit's
## numerals switched on (kit_families.json) its baked figures instead of
## the live words, which then only name it for a screen reader.
func _set_clock(text: String) -> void:
	KitHud.set_clock(clock_panel, text, _red)
	_figures(text)


func _figures(text: String) -> void:
	if not KitSkin.is_on("numerals"):
		return
	var old := clock_panel.get_node_or_null("Figures")
	var shown := "%s|%s" % [text, _red]
	if old != null and str(old.get_meta("shown", "")) == shown:
		return
	if old != null:
		clock_panel.remove_child(old)
		old.queue_free()
	var row := KitNumerals.make(text, "num_timer_red" if _red else "num_timer", "display", text)
	row.name = "Figures"
	row.set_meta("shown", shown)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clock_panel.add_child(row)
	# The figures take the words' place: the row sizes the plate and the
	# screen reader says its name, so the words are hidden and cost no draws.
	clock_label.visible = false
	_through(row)


func _build_alarm() -> void:
	var piece := KitHud.alarm_fit(_alarm, BELLS, Strings.t("HUD_ALARM_WORD"))
	# The leather's frame is thick: with large text its words keep 8 points
	# off it, so "Alarm" and the count stand inside the plate (gate, display
	# type: the words ran into the frame at 5).
	_tight(piece, true, 8.0)
	_bake(alarm_label_of(piece), _alarm_finish())
	_swap(alarm_panel, piece)
	alarm_panel = piece
	alarm_label = piece.find_child("Count", true, false)
	# _swap carries the old panel's name over; the kit names the level.
	alarm_panel.accessibility_name = Strings.t("HUD_ALARM", alarm_label.text)


## The loot's rows: what the bags can still take and what is left to load.
static func _loot_rows(room: String, left: String) -> Array:
	return [[Strings.t("HUD_ROOM"), room], [Strings.t("HUD_LEFT"), left]]


## The loot panel (KitHud.loot_fit): its two numbers, the bags' fill with a
## tick at the load target and "Load to N%" under it; while the Vault is
## shut how far it is cracked, a third row or with §20.8's large text a thin
## bar beside its icon, so its progress is always on screen (§12.19).
func _build_loot(rows: Array, bags: float, load_words: String, vault: Array) -> void:
	var aim := load_target / 100.0 if load_target >= 0 else -1.0
	# With large text the panel has the row's whole width (a 360-point phone
	# inside §21.1's sides, less its own rim): loot_fit gives a large panel
	# 2.3 times the width it is told.
	var width := 90.0
	if Settings.text_scale > 130:
		width = (360.0 - 2.0 * Tokens.number("size", "safe_side_points") - 28.0) / 2.3
	var piece := KitHud.loot_fit(rows, bags, aim, load_words, vault, width)
	_load = piece.find_child("Load", true, false)
	# _swap carries the old panel's spoken name over; the kit's names every
	# number.
	var spoken := piece.accessibility_name
	# As the alarm: the figures keep clear of the leather's frame, and are
	# the kit's baked gold numerals, so 946 and ~2,600 read as display
	# figures rather than flat gold words on the plate.
	# In high contrast the figures are information, not an order: cream, as
	# the clock's, never the kit's gold, which says "act here" (AD-R62);
	# baked, with §20.8's large text, in the numerals' white tinted cream.
	_tight(piece, true, 10.0)
	for n: Variant in piece.get_meta("numbers", []):
		if Tokens.high_contrast:
			(n as Label).add_theme_color_override("font_color", Tokens.color("cream"))
			(n as Label).set_meta("tint", Tokens.color("cream"))
		_bake(n as Label, "num_white" if Tokens.high_contrast else "num_gold")
	_swap(loot_panel, piece)
	loot_panel = piece
	loot_panel.accessibility_name = spoken


func show_state(r: RulebornReplay) -> void:
	var tps := RulebornReplay.ticks_per_second()
	var left := maxi(0, (r.ticks() - r.tick()) / tps)
	var time := "%d:%02d" % [left / 60, left % 60]
	var red := r.ticks() > 0 and left <= RED_SECONDS
	_red = red
	_set_clock(time)
	if r.alarm() != _alarm:
		var rose := r.alarm() > _alarm and r.tick() > 0
		_alarm = r.alarm()
		KitHud.set_alarm(alarm_panel, _alarm)
		_sync(alarm_label, _alarm_finish())
		if rose and is_inside_tree():
			Motion.pop(alarm_panel)
	var carried := 0
	var carry := 0
	for m: Dictionary in r.crew():
		carried += int(m["carried"])
		carry += int(m["carry"])
	var v := r.vault()
	_open = bool(v.get("open", false))
	var room := ShopPresenter.grouped(carry - carried)
	var to_load := ShopPresenter.grouped(int(v.get("exposed", 0))) if _open \
		else ("~" + ShopPresenter.grouped(estimate) if estimate >= 0 else "?")
	var load_words := Strings.t("HUD_LOAD_TO", load_target) if load_target >= 0 else ""
	var bags := float(carried) / maxf(1.0, float(carry))
	var health := int(v.get("health", 0))
	if _vault_full < 0 or health > _vault_full:
		_vault_full = health
	var crack := 1.0 - float(health) / maxf(1.0, float(_vault_full))
	var vault := [] if _open else [Strings.t("REHEARSE_LEGEND_VAULT"), "%d%%" % int(100.0 * crack), crack]
	var rows := _loot_rows(room, to_load)
	# Built again only when its shape changes (the Vault opening, a load
	# target or none); its numbers are set in place, and the wording of a
	# row is measured again when its length does.
	var key := "%s|%d|%d|%d" % [load_words, vault.size(), room.length(), to_load.length()]
	if key != _loot_key:
		_loot_key = key
		_build_loot(rows, bags, load_words, vault)
	else:
		var aim := load_target / 100.0 if load_target >= 0 else -1.0
		KitHud.set_loot(loot_panel, rows, bags, aim, load_words, vault)
		for n: Variant in loot_panel.get_meta("numbers", []):
			_sync(n as Label)
	realm_label.text = realm(r.realm_code(), r.realms_to_go())
	realm_label.visible = realm_label.text != ""
	(realm_label.get_parent() as Control).visible = realm_label.visible
	_show_laws(r)


## The laws running in the realm: one chip a standing pylon's law, its icon
## beside its name (§21.8's law banner; §15.3).
func _show_laws(r: RulebornReplay) -> void:
	var laws: Array[String] = []
	for p: Dictionary in r.pylons():
		if p.get("standing", false):
			laws.append(str(p.get("law", "")))
	var key := ",".join(laws)
	if key == _laws_key:
		return
	_laws_key = key
	for c in laws_box.get_children():
		laws_box.remove_child(c)
		c.queue_free()
	for law in laws:
		var icon := "laws/" + law.replace("_", "")
		var chip := KitCards.law_chip_fit(icon if Icons.has(icon) else "", Strings.term("LAW", law))
		_badge(chip, icon, law)
		_tight(chip)
		_one_line(chip.find_child("Words", true, false) as Label)
		laws_box.add_child(chip)
		_through(chip)
	(laws_box.get_parent() as Control).visible = not laws.is_empty()


## §21.8: "rewards fly into their counter": coins from a point on the screen
## (where a crew member grabbed loot) into the loot panel.
func fly_coins(from: Vector2, count: int) -> void:
	if Settings.reduced_motion:
		return
	for k in clampi(count, 1, COINS):
		var coin := Icons.view("heiststatus/lootbag", 14.0)
		coin.top_level = true
		# At the top of the HUD's layer, over its panels and their words, as it
		# flies into the loot.
		coin.z_index = HUD_Z + UI.OVERLAY_Z - 1
		coin.visible = false
		add_child(coin)
		_flights.append({"from": from + Vector2(k * 9.0 - 20.0, -k * 6.0), "t": -k * 0.08, "coin": coin})


func _process(delta: float) -> void:
	_time += delta
	if _red and not Settings.reduced_motion:
		# The last 30 seconds pulse once a second (within §20.8's three
		# flashes a second).
		clock_panel.pivot_offset = clock_panel.size / 2.0
		clock_panel.scale = Vector2.ONE * (1.0 + 0.05 * maxf(0.0, sin(_time * TAU)))
	elif clock_panel.scale != Vector2.ONE:
		clock_panel.scale = Vector2.ONE
	if _flights.is_empty():
		return
	var to := _load.get_global_rect().position
	for f in _flights:
		var t := float(f["t"]) + delta / FLIGHT
		f["t"] = t
		var coin: Control = f["coin"]
		if t >= 1.0:
			coin.queue_free()
		elif t >= 0.0:
			var from: Vector2 = f["from"]
			var e := 1.0 - pow(1.0 - t, 3.0)
			coin.visible = true
			coin.global_position = from.lerp(to, e) + Vector2(0, -sin(t * PI) * 120.0) - coin.size / 2.0
			coin.scale = Vector2.ONE * (1.0 - 0.3 * t)
	_flights = _flights.filter(func(f: Dictionary) -> bool: return float(f["t"]) < 1.0)


## The designs' gold rim on a kit surface (the result's haul tile).
static func _gold_rim(p: Control) -> void:
	var box := RbBox.of(p)
	if box != null and box.material is ShaderMaterial:
		(box.material as ShaderMaterial).set_shader_parameter("rim_color", FxSkin.GOLD)
		(box.material as ShaderMaterial).set_shader_parameter("rim_w", UI.px(3.5))


## The realm the crew is in across a universe, in words; "" for a heist of
## one island or before the crew has landed.
static func realm(code: int, to_go: int) -> String:
	if code < 0:
		return ""
	if code == 0:
		return Strings.t("HEIST_IN_HEART")
	return Strings.t("HEIST_IN_REALM", [LandingPresenter.realm_name(code), to_go])
