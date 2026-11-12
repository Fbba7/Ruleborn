class_name HeistHud
extends VBoxContainer
## §21.8's heist layout, top row: "Clock and alarm meter at the top centre;
## loot at the top right as two numbers, what the bags can still take and what
## is left to load (12.19), beside the Vault's progress; the law banner at the
## top left". Built from the kit alone (docs/art/ui-quality/kit-spec.md 6.3):
## the clock is KitHud.clock_large, Lilita One figures inked on parchment,
## counting down and turning to the alarm's red plate in its last 30
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
	# Gold words with the kit's ink outline all round (§21.8): they lie on the
	# world, and read on any sky.
	var here := UI.world_words(Strings.t("HUD_LAWS_HERE"), 14, "gold")
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
	_build_loot(_loot_rows("", "?"), 0.0, "", [])
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
	var piece := KitHud.clock_large(text, _red)
	piece.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	clock_label.self_modulate.a = 0.0
	_through(row)


func _build_alarm() -> void:
	var piece := KitHud.alarm_fit(_alarm, BELLS, Strings.t("HUD_ALARM_WORD"))
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
	var piece := KitHud.loot_fit(rows, bags, aim, load_words, vault)
	_load = piece.find_child("Load", true, false)
	# _swap carries the old panel's spoken name over; the kit's names every
	# number.
	var spoken := piece.accessibility_name
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
