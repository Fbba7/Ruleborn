class_name HeistHud
extends VBoxContainer
## §21.8's heist layout, top row: "Clock and alarm meter at the top centre;
## loot at the top right as two numbers, what the bags can still take and what
## is left to load (12.19), beside the Vault's progress; the law banner at the
## top left". Built from the kit alone (docs/art/ui-quality/kit-spec.md 6.3):
## the clock is KitHud.clock, counting down and turning to the alarm's red
## plate in its last 30 seconds; the alarm is KitHud.alarm, six bells with
## "N / 6" written beside them so the level never rests on colour (§20.8);
## the loot is KitHud.loot, its two numbers over the bags' fill, with how far
## the Vault is cracked as a third while it is shut; each law running in the
## realm is a chip of the kit's leather. The kit's pieces are built whole, so a piece
## whose state changes is built again in its place. Three columns, left,
## centre and right; with §20.8's large text the loot stands under the laws.

## §21.8: the clock turns red in its last 30 seconds.
const RED_SECONDS := 30
const BELLS := 6
## How many coins fly to the loot at most, and how long each takes (seconds).
const COINS := 6
const FLIGHT := 0.6

## Each law icon measured dark or not (dark_icon).
static var _dark := {}

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
	var here := UI.label(Strings.t("HUD_LAWS_HERE"), 14)
	here.add_theme_font_override("font", UI.bold_font())
	here.set_meta("bold", true)
	here.add_theme_color_override("font_color", Tokens.color("gold"))
	# An ink outline all round (§21.8): the words lie on the world, and read
	# on any sky.
	here.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	here.add_theme_constant_override("outline_size", UI.px(3))
	here.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	here.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# The loot, top right; with large text under the law banner instead, so
	# the column stays above the hand's controls.
	var right := left if large else _side(top)
	loot_panel = PanelContainer.new()
	loot_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if large else Control.SIZE_SHRINK_END
	right.add_child(loot_panel)
	_build_loot("", "?", "", 0.0, "")
	var realm_panel := KitStatus.hint("")
	realm_panel.name = "Realm"
	realm_panel.visible = false
	realm_label = realm_panel.get_node("Words")
	realm_label.visible = false
	add_child(realm_panel)


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


static func _through(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in node.get_children():
		_through(c)


func _build_clock(text: String) -> void:
	var piece := KitHud.clock(text, _red)
	piece.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clock_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_swap(clock_panel, piece)
	clock_panel = piece
	clock_label = piece.get_node("Time")


func _build_alarm() -> void:
	var piece := KitHud.alarm(_alarm, BELLS, Strings.t("HUD_ALARM_WORD"))
	_swap(alarm_panel, piece)
	alarm_panel = piece
	alarm_label = piece.find_children("*", "Label", true, false)[1]
	if Settings.text_scale > 130:
		# §20.8's large text: the count on its own line under the word, rather
		# than run off the phone's edge (S1-R4 asks the kit for this).
		var head := alarm_label.get_parent()
		head.remove_child(alarm_label)
		head.add_sibling(alarm_label)
		alarm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if _alarm >= BELLS / 2 + 1:
		# Red from four, as its bells; the number says the level either way.
		alarm_label.add_theme_color_override("font_color", Tokens.color("alarm_text_on_night"))
	alarm_panel.accessibility_name = Strings.t("HUD_ALARM", alarm_label.text)


## The loot panel: its two numbers, the bags' fill with a tick at the load
## target and "Load to N%" under it; while the Vault is shut how far it is
## cracked as a third number, so its progress is always on screen (§12.19).
## Written rather than a second bar: the kit's bar, tick and icon are a draw
## call each, where the heist's budget has room for none (S1-R2).
func _build_loot(room: String, left: String, load_words: String, bags: float, cracked: String) -> void:
	var rows := [[Strings.t("HUD_ROOM"), room], [Strings.t("HUD_LEFT"), left]]
	var large := Settings.text_scale > 130
	if cracked != "" and not large:
		rows.append([Strings.t("REHEARSE_LEGEND_VAULT"), cracked])
	var piece := KitHud.loot(rows, bags, load_target / 100.0, load_words)
	_load = piece.find_child("Load", true, false)
	(_load.get_node("Aim") as Control).visible = load_target >= 0
	_columns(piece.get_child(0), rows)
	if load_words != "":
		# "Load to N%" breaks between words where a language's are long, rather
		# than widen the panel past the phone (S1-R2 asks the kit for both).
		var words := piece.get_child(0).get_child(-1) as Label
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.custom_minimum_size.x = minf(_wide(load_words, 14), UI.px(88))
	if cracked != "" and large:
		# §20.8's large text: a third row would stand the panel on the hint
		# below, so the Vault's cracking is a thin bar beside its icon instead.
		var row := HBoxContainer.new()
		row.name = "Vault"
		row.add_theme_constant_override("separation", UI.px(4))
		var icon := Icons.view("heiststatus/vaultprogress", 16.0)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var crack := KitBar.make(cracked.to_float() / 100.0, Color(), 5.0)
		crack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(crack)
		_load.add_sibling(row)
	_swap(loot_panel, piece)
	loot_panel = piece
	var spoken := PackedStringArray()
	for r: Array in rows:
		spoken.append("%s %s" % r)
	if cracked != "" and large:
		spoken.append("%s %s" % [Strings.t("REHEARSE_LEGEND_VAULT"), cracked])
	if load_words != "":
		spoken.append(load_words)
	loot_panel.accessibility_name = ", ".join(spoken)


## Sets the loot's rows as two columns, the words and then the numbers, so
## each face is drawn in one call rather than one a label (the heist's draw
## calls are held to their record; S1-R2). Where a language's words are too
## long for that ("Restam ~2.600"), a long row's number goes under its word
## instead, rather than push the panel off the phone.
static func _columns(v: Control, rows: Array) -> void:
	var word := 0.0
	var number := 0.0
	for r: Array in rows:
		word = maxf(word, _wide(str(r[0]), 14))
		number = maxf(number, _wide(str(r[1]), 16))
	var lines: Array[Node] = []
	for c in v.get_children():
		if c is HBoxContainer:
			lines.append(c)
	# With §20.8's large text the loot stands under the laws, in a column
	# twice as wide.
	var large := Settings.text_scale > 130
	var room := UI.px(90) * (2.3 if large else 1.0)
	if word + number + UI.px(8) > room:
		# A long row first stands its number closer to its word, and only
		# then under it.
		for line in lines:
			var n := line.get_child(1) as Label
			var wide := _wide((line.get_child(0) as Label).text, 14) + _wide(n.text, 16)
			if wide + UI.px(8) <= room:
				continue
			line.add_theme_constant_override("separation", UI.px(2))
			if wide + UI.px(2) > room:
				line.remove_child(n)
				line.add_sibling(n)
				n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		return
	var both := HBoxContainer.new()
	both.add_theme_constant_override("separation", UI.px(8))
	var sides: Array[VBoxContainer] = [VBoxContainer.new(), VBoxContainer.new()]
	sides[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in sides:
		side.add_theme_constant_override("separation", UI.px(2))
		both.add_child(side)
	for line in lines:
		for k in 2:
			var l := line.get_child(0) as Label
			line.remove_child(l)
			# One height for a word and its number, so the columns keep the rows.
			l.custom_minimum_size.y = ceilf(UI.text_px(16) * 1.4)
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if k == 1:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			sides[k].add_child(l)
		v.remove_child(line)
		line.queue_free()
	v.add_child(both)
	v.move_child(both, 0)


## How wide words stand in the kit's bold face at a size in points (the
## pieces are measured before they are in the tree, where no theme reaches).
static func _wide(text: String, points: float) -> float:
	return ceilf(UI.bold_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(points)).x)


func show_state(r: RulebornReplay) -> void:
	var tps := RulebornReplay.ticks_per_second()
	var left := maxi(0, (r.ticks() - r.tick()) / tps)
	var time := "%d:%02d" % [left / 60, left % 60]
	var red := r.ticks() > 0 and left <= RED_SECONDS
	if red != _red:
		_red = red
		_build_clock(time)
	else:
		clock_label.text = time
	if r.alarm() != _alarm:
		var rose := r.alarm() > _alarm and r.tick() > 0
		_alarm = r.alarm()
		_build_alarm()
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
	var cracked := "" if _open else "%d%%" % int(100.0 * (1.0 - float(health) / maxf(1.0, float(_vault_full))))
	var key := "%s|%s|%s|%s" % [room, to_load, load_words, cracked]
	if key != _loot_key:
		_loot_key = key
		_build_loot(room, to_load, load_words, bags, cracked)
	else:
		Motion.fill(_load, bags)
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
		var chip := _law_chip(icon if Icons.has(icon) else "", Strings.term("LAW", law))
		laws_box.add_child(chip)
		_through(chip)
	(laws_box.get_parent() as Control).visible = not laws.is_empty()


## A law's chip as wide as the banner's column: the kit's leather with the
## law's icon and its name, which wraps between words rather than outgrow the
## column (KitCards.law_chip keeps one line and ends a long name in an
## ellipsis; S1-R3 asks the kit for this one). A dark icon (Glowing dark)
## stands on the kit's light disc so it reads on the leather.
static func _law_chip(icon: String, title: String) -> PanelContainer:
	var p := UI.panel("leather")
	p.name = "Law"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(1 if Settings.text_scale > 130 else 4))
	if icon != "" and dark_icon(icon):
		var disc := PanelContainer.new()
		disc.add_theme_stylebox_override("panel", UI.clear_box(1, 1))
		UI.dress(disc, "icon_disc", 999)
		disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Smaller with large text, where the column is at its narrowest.
		disc.add_child(Icons.view(icon, 15.0 if Settings.text_scale > 130 else 19.0))
		row.add_child(disc)
	elif icon != "":
		var bare := Icons.view(icon, 24.0)
		bare.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bare)
	var l := UI.label(title, 14, true)
	l.name = "Words"
	l.theme_type_variation = "LabelText"
	l.set_meta("bold", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# No narrower than its longest word, so a line breaks between words; with
	# §20.8's large text a word too long for the column breaks instead.
	var widest := 0.0
	for w: String in title.split(" ", false):
		widest = maxf(widest, _wide(w, 14))
	l.custom_minimum_size.x = minf(ceilf(widest * 1.08), UI.px(100) * maxf(1.0, Settings.text_scale / 100.0))
	row.add_child(l)
	p.add_child(row)
	return p


## Whether an icon is mostly dark ink, which needs a light disc behind it
## on the leather: its drawn pixels' mean lightness, measured once.
static func dark_icon(icon: String) -> bool:
	if _dark.has(icon):
		return _dark[icon]
	var image := Icons.texture(icon).get_image()
	var light := 0.0
	var drawn := 0.0
	if image != null:
		var small := image.duplicate() as Image
		small.decompress()
		small.resize(16, 16)
		for y in 16:
			for x in 16:
				var c := small.get_pixel(x, y)
				light += c.get_luminance() * c.a
				drawn += c.a
	_dark[icon] = drawn > 0.0 and light / drawn < 0.3
	return _dark[icon]


## §21.8: "rewards fly into their counter": coins from a point on the screen
## (where a crew member grabbed loot) into the loot panel.
func fly_coins(from: Vector2, count: int) -> void:
	if Settings.reduced_motion:
		return
	for k in clampi(count, 1, COINS):
		var coin := Icons.view("heiststatus/lootbag", 14.0)
		coin.top_level = true
		coin.z_index = 10
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
