class_name HeistHud
extends VBoxContainer
## §21.8's heist layout, top row: "Clock and alarm meter at the top centre;
## loot at the top right as two numbers, what the bags can still take and what
## is left to load (12.19), beside the Vault's progress; the law banner at the
## top left". Drawn as the Screens v3 heist draws it: dark glass pills over
## the world with ink outlines, the clock in Lilita One counting down and
## turning red in its last 30 seconds, the alarm as six bells, amber to three
## and red from four, with "N / 6" beside them so the level never rests on
## colour (§20.8); the loot as its two numbers with the bags' fill and the
## Vault's cracking as bars; each law running in the realm as a chip with its
## school's shape. Three columns, left, centre and right; with §20.8's large
## text their words wrap rather than outgrow the phone.

## §21.8: the clock turns red in its last 30 seconds.
const RED_SECONDS := 30
const BELLS := 6

var clock_label: Label
var alarm_label: Label
## The loot panel's two numbers (§21.8, 12.19): what the bags can still
## take, and what is left to load ("?" until the Vault opens, 12.6).
var room_label: Label
var left_label: Label
var loot_panel: PanelContainer
## Across a universe, the realm the crew is in and how many it has yet to
## cross to the Heart (§5.4).
var realm_label: Label
var laws_box: VBoxContainer
var clock_panel: PanelContainer
var meter: FxDraw
var loot_bars: FxDraw

var _alarm := 0
var _bags := 0.0
var _cracked := 0.0
var _open := false
var _vault_full := -1
var _laws_key := ""
var _red := false
## Seconds left of the bells' shake after the alarm rose.
var _ring := 0.0
var _time := 0.0
## Coins on their way to the loot panel: {from: Vector2 (global), t: float}.
var _flights: Array[Dictionary] = []
var _coins: FxDraw


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", UI.px(4))
	add_child(top)
	# The law banner, top left.
	var left := _side(top, BoxContainer.ALIGNMENT_BEGIN)
	var laws := FxSkin.panel("glass", 12.0, 5.0)
	laws.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	laws_box = VBoxContainer.new()
	laws_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laws_box.add_theme_constant_override("separation", UI.px(3))
	laws.add_child(laws_box)
	laws.name = "Laws"
	laws.visible = false
	left.add_child(laws)
	# The clock in its pill, the alarm's bells beneath.
	var centre := VBoxContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_theme_constant_override("separation", UI.px(3))
	centre.alignment = BoxContainer.ALIGNMENT_BEGIN
	centre.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	clock_panel = FxSkin.panel("glass", 20.0, 6.0)
	clock_label = FxSkin.label("", 24.0, "glass", true)
	clock_panel.add_child(clock_label)
	centre.add_child(clock_panel)
	var alarm := FxSkin.panel("glass", 12.0, 6.0)
	var alarm_box := VBoxContainer.new()
	alarm_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alarm_box.add_theme_constant_override("separation", 0)
	alarm_label = FxSkin.label("", 13.0)
	alarm_box.add_child(alarm_label)
	meter = FxDraw.new(_draw_meter, Vector2(UI.px(13) * BELLS, UI.px(17)))
	alarm_box.add_child(meter)
	alarm.add_child(alarm_box)
	centre.add_child(alarm)
	top.add_child(centre)
	# The loot, top right: two numbers and the bars beside them.
	var right_side := _side(top, BoxContainer.ALIGNMENT_END)
	var right := FxSkin.panel("glass", 12.0, 7.0)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	loot_panel = right
	var right_box := VBoxContainer.new()
	right_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_box.add_theme_constant_override("separation", UI.px(3))
	# Side by side; with §20.8's large text, one under the other.
	var stats := HFlowContainer.new()
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.alignment = FlowContainer.ALIGNMENT_END
	stats.add_theme_constant_override("h_separation", UI.px(10))
	stats.custom_minimum_size.x = UI.px(84)
	room_label = _stat(stats, Strings.t("HUD_ROOM"))
	left_label = _stat(stats, Strings.t("HUD_LEFT"))
	right_box.add_child(stats)
	# The bags' fill and the Vault's cracking as bars, each beside the
	# designs' icon for it.
	var bars := HBoxContainer.new()
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.add_theme_constant_override("separation", UI.px(3))
	var icons := VBoxContainer.new()
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icons.add_theme_constant_override("separation", 0)
	icons.add_child(Icons.view("heiststatus/lootbag", 13.0))
	icons.add_child(Icons.view("heiststatus/vaultprogress", 13.0))
	bars.add_child(icons)
	loot_bars = FxDraw.new(_draw_bars, Vector2(UI.px(64), UI.px(26)))
	loot_bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_child(loot_bars)
	right_box.add_child(bars)
	right.add_child(right_box)
	right_side.add_child(right)
	realm_label = FxSkin.label("", 14.0)
	realm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	realm_label.visible = false
	var realm_panel := FxSkin.panel("glass", 12.0, 6.0)
	realm_panel.add_child(realm_label)
	realm_panel.name = "Realm"
	realm_panel.visible = false
	add_child(realm_panel)


## One of the loot panel's numbers: its name small above it, the number
## large in tabular figures; returns the number's label.
func _stat(row: HFlowContainer, title: String) -> Label:
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	var name_label := FxSkin.label(title, 13.0)
	name_label.add_theme_color_override("font_color", FxSkin.ON_DARK_SOFT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(name_label)
	var number := FxSkin.label("", 20.0)
	number.add_theme_font_override("font", FxSkin.figures())
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(number)
	row.add_child(col)
	return number


## Words that wrap between words: as narrow as their longest word, so a long
## law's name wraps the line rather than breaking a word; with §20.8's large
## text a word too long for its column breaks rather than outgrow the phone.
static func _wrap_by_words(l: Label) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font := l.get_theme_font("font")
	var px := l.get_theme_font_size("font_size")
	var widest := 0.0
	for w: String in l.text.replace("\n", " ").split(" ", false):
		widest = maxf(widest, font.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
	l.custom_minimum_size.x = minf(ceilf(widest) + 2.0, UI.px(84))


## A side column of the top row: it takes what room there is and holds its
## panel to its edge.
func _side(top: HBoxContainer, edge: BoxContainer.AlignmentMode) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.set_meta("edge", edge)
	top.add_child(v)
	return v


func show_state(r: RulebornReplay) -> void:
	var tps := RulebornReplay.ticks_per_second()
	var left := maxi(0, (r.ticks() - r.tick()) / tps)
	clock_label.text = "%d:%02d" % [left / 60, left % 60]
	var red := r.ticks() > 0 and left <= RED_SECONDS
	if red != _red:
		_red = red
		var box := FxSkin.glass(20.0, 6.0)
		if red:
			# Paper on §21.8's alarm fill: the one red that carries words.
			box.bg_color = FxSkin.ALARM_DEEP
		clock_panel.add_theme_stylebox_override("panel", box)
	if r.alarm() > _alarm and r.tick() > 0:
		_ring = 1.0
	_alarm = r.alarm()
	alarm_label.text = Strings.t("HUD_ALARM", "%d / %d" % [_alarm, BELLS])
	_wrap_by_words(alarm_label)
	alarm_label.add_theme_color_override("font_color", FxSkin.ALARM_ON_DARK if _alarm >= 4 else FxSkin.ON_DARK)
	meter.queue_redraw()
	var carried := 0
	var carry := 0
	for m: Dictionary in r.crew():
		carried += int(m["carried"])
		carry += int(m["carry"])
	var v := r.vault()
	_open = bool(v.get("open", false))
	room_label.text = str(carry - carried)
	left_label.text = str(int(v.get("exposed", 0))) if _open else "?"
	loot_panel.accessibility_name = "%s %s, %s %s" % [Strings.t("HUD_ROOM"), room_label.text, Strings.t("HUD_LEFT"),
		left_label.text]
	_bags = float(carried) / maxf(1.0, float(carry))
	var health := int(v.get("health", 0))
	if _vault_full < 0 or health > _vault_full:
		_vault_full = health
	_cracked = 1.0 if _open else 1.0 - float(health) / maxf(1.0, float(_vault_full))
	loot_bars.queue_redraw()
	realm_label.text = realm(r.realm_code(), r.realms_to_go())
	realm_label.visible = realm_label.text != ""
	(realm_label.get_parent() as Control).visible = realm_label.visible
	_show_laws(r)


## The laws running in the realm: one chip a standing pylon's law, with its
## school's shape (§21.8's law banner; §15.3).
func _show_laws(r: RulebornReplay) -> void:
	var laws: Array[Dictionary] = []
	for p: Dictionary in r.pylons():
		if p.get("standing", false):
			laws.append(p)
	var key := ",".join(laws.map(func(p: Dictionary) -> String: return str(p.get("law", ""))))
	if key == _laws_key:
		return
	_laws_key = key
	for c in laws_box.get_children():
		c.queue_free()
	for p in laws:
		var chip := HBoxContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_constant_override("separation", UI.px(3))
		var school := str(p.get("school", ""))
		var icon := "laws/" + str(p.get("law", "")).replace("_", "")
		if Icons.has(icon):
			# The law's own icon from the designs.
			# On a light disc: a dark law's icon (Glowing dark) reads on the glass.
			var disc := PanelContainer.new()
			disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ring := StyleBoxFlat.new()
			ring.bg_color = FxSkin.PARCH_TOP
			ring.border_color = FxSkin.INK_LINE
			ring.set_border_width_all(maxi(2, UI.px(1.5)))
			ring.set_corner_radius_all(UI.px(14))
			ring.set_content_margin_all(UI.px(2))
			disc.add_theme_stylebox_override("panel", ring)
			disc.add_child(Icons.view(icon, 22.0))
			chip.add_child(disc)
		else:
			chip.add_child(FxDraw.new(func(ci: Control) -> void:
				FxIcons.school(ci, ci.size / 2.0, minf(ci.size.x, ci.size.y), school), Vector2(UI.px(20), UI.px(20))))
		var words := FxSkin.label(Strings.term("LAW", str(p.get("law", ""))), 13.0)
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_wrap_by_words(words)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_child(words)
		laws_box.add_child(chip)
	(laws_box.get_parent() as Control).visible = not laws.is_empty()


## §21.8: "rewards fly into their counter": coins from a point on the screen
## (where a crew member grabbed loot) into the loot panel.
func fly_coins(from: Vector2, count: int) -> void:
	if Settings.reduced_motion:
		return
	for k in clampi(count, 1, 6):
		_flights.append({"from": from + Vector2(k * 9.0 - 20.0, -k * 6.0), "t": -k * 0.08})


func _process(delta: float) -> void:
	_time += delta
	_ring = maxf(0.0, _ring - delta)
	if _ring > 0.0:
		meter.queue_redraw()
	if _red and not Settings.reduced_motion:
		# The last 30 seconds pulse once a second (within §20.8's three
		# flashes a second).
		clock_panel.pivot_offset = clock_panel.size / 2.0
		clock_panel.scale = Vector2.ONE * (1.0 + 0.05 * maxf(0.0, sin(_time * TAU)))
	elif clock_panel.scale != Vector2.ONE:
		clock_panel.scale = Vector2.ONE
	if not _flights.is_empty():
		for f in _flights:
			f["t"] = float(f["t"]) + delta * 1.6
		_flights = _flights.filter(func(f: Dictionary) -> bool: return float(f["t"]) < 1.0)
		if _coins == null:
			_coins = FxDraw.new(_draw_flights)
			_coins.top_level = true
			_coins.z_index = 10
			add_child(_coins)
		_coins.position = Vector2.ZERO
		_coins.size = get_viewport_rect().size
		_coins.queue_redraw()


func _draw_flights(ci: Control) -> void:
	var to := loot_bars.get_global_rect().position + Vector2(UI.px(8), UI.px(4))
	for f in _flights:
		var t := float(f["t"])
		if t < 0.0:
			continue
		var from: Vector2 = f["from"]
		var e := 1.0 - pow(1.0 - t, 3.0)
		var p := from.lerp(to, e) + Vector2(0, -sin(t * PI) * 120.0)
		FxIcons.coin(ci, p, UI.px(6) * (1.0 - 0.3 * t))


func _draw_meter(ci: Control) -> void:
	var s := ci.size.y
	var step := ci.size.x / BELLS
	for i in BELLS:
		var c := Vector2(step * (i + 0.5), s * 0.5)
		if _ring > 0.0 and i < _alarm and not Settings.reduced_motion:
			c.x += sin(_time * 40.0 + i) * s * 0.12 * _ring
		var fill := FxSkin.ALARM if i >= 3 else FxSkin.GOLD
		FxIcons.bell(ci, c, s * 0.9, fill, i < _alarm)


## The bags' fill and the Vault's cracking: the bars say which binds first
## without a word (§12.19).
func _draw_bars(ci: Control) -> void:
	var h := ci.size.y * 0.36
	var gap := (ci.size.y * 0.5 - h) * 0.5
	FxIcons.bar(ci, Rect2(Vector2(0, gap), Vector2(ci.size.x, h)), _bags, FxSkin.GOLD)
	FxIcons.bar(ci, Rect2(Vector2(0, ci.size.y * 0.5 + gap), Vector2(ci.size.x, h)), _cracked,
		FxSkin.SUCCESS if _open else Color("#9B8CF0"))


## The realm the crew is in across a universe, in words; "" for a heist of
## one island or before the crew has landed.
static func realm(code: int, to_go: int) -> String:
	if code < 0:
		return ""
	if code == 0:
		return Strings.t("HEIST_IN_HEART")
	return Strings.t("HEIST_IN_REALM", [LandingPresenter.realm_name(code), to_go])
