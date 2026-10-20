class_name HeistHud
extends HFlowContainer
## §21.8's heist layout, top row: "Clock and alarm meter at the top centre;
## loot at the top right as two numbers, what the bags can still take and what
## is left to load (12.19), beside the Vault's progress; the law banner at the
## top left". Drawn as the Screens v3 heist draws it: dark glass pills over
## the world with ink outlines, the clock in Lilita One counting down and
## turning red in its last 30 seconds, the alarm as six bells, amber to three
## and red from four, with "N / 6" beside them so the level never rests on
## colour (§20.8); the loot as its two numbers with the bags' fill and the
## Vault's cracking as bars; each law running in the realm as a chip with its
## school's shape. With §20.8's large text the pills stack rather than
## outgrow the phone.

## §21.8: the clock turns red in its last 30 seconds.
const RED_SECONDS := 30
const BELLS := 6

var clock_label: Label
var alarm_label: Label
var loot_label: Label
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


func _init() -> void:
	alignment = FlowContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gap := UI.px(Tokens.number("size", "gap_points"))
	add_theme_constant_override("h_separation", gap)
	add_theme_constant_override("v_separation", gap)
	# The law banner, top left.
	var laws := FxSkin.panel("glass", 14.0, 6.0)
	laws.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	laws_box = VBoxContainer.new()
	laws_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	laws_box.add_theme_constant_override("separation", UI.px(3))
	laws.add_child(laws_box)
	laws.name = "Laws"
	laws.visible = false
	add_child(laws)
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
	meter = FxDraw.new(_draw_meter, Vector2(UI.px(15) * BELLS, UI.px(17)))
	alarm_box.add_child(meter)
	alarm.add_child(alarm_box)
	centre.add_child(alarm)
	add_child(centre)
	# The loot, top right: two numbers and the bars beside them.
	var right := FxSkin.panel("glass", 14.0, 8.0)
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var right_box := VBoxContainer.new()
	right_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_box.add_theme_constant_override("separation", UI.px(2))
	loot_label = FxSkin.label("", 13.0)
	loot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_box.add_child(loot_label)
	loot_bars = FxDraw.new(_draw_bars, Vector2(UI.px(80), UI.px(18)))
	right_box.add_child(loot_bars)
	right.add_child(right_box)
	add_child(right)
	realm_label = FxSkin.label("", 14.0)
	realm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	realm_label.visible = false
	var realm_panel := FxSkin.panel("glass", 12.0, 6.0)
	realm_panel.add_child(realm_label)
	realm_panel.name = "Realm"
	realm_panel.visible = false
	add_child(realm_panel)


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
	_alarm = r.alarm()
	alarm_label.text = Strings.t("HUD_ALARM", "%d / %d" % [_alarm, BELLS])
	alarm_label.add_theme_color_override("font_color", FxSkin.ALARM_ON_DARK if _alarm >= 4 else FxSkin.ON_DARK)
	meter.queue_redraw()
	var carried := 0
	var carry := 0
	for m: Dictionary in r.crew():
		carried += int(m["carried"])
		carry += int(m["carry"])
	var v := r.vault()
	loot_label.text = Strings.t("HUD_LOOT", [carry - carried, int(v.get("exposed", 0))])
	_bags = float(carried) / maxf(1.0, float(carry))
	var health := int(v.get("health", 0))
	if _vault_full < 0 or health > _vault_full:
		_vault_full = health
	_open = bool(v.get("open", false))
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
		chip.add_child(FxDraw.new(func(ci: Control) -> void:
			FxIcons.school(ci, ci.size / 2.0, minf(ci.size.x, ci.size.y), school), Vector2(UI.px(20), UI.px(20))))
		chip.add_child(FxSkin.label(Strings.term("LAW", str(p.get("law", ""))), 13.0))
		laws_box.add_child(chip)
	(laws_box.get_parent() as Control).visible = not laws.is_empty()


func _draw_meter(ci: Control) -> void:
	var s := ci.size.y
	var step := ci.size.x / BELLS
	for i in BELLS:
		var c := Vector2(step * (i + 0.5), s * 0.5)
		var fill := FxSkin.ALARM if i >= 3 else FxSkin.GOLD
		FxIcons.bell(ci, c, s * 0.9, fill, i < _alarm)


func _draw_bars(ci: Control) -> void:
	var h := ci.size.y * 0.36
	var w := ci.size.x
	FxIcons.bar(ci, Rect2(Vector2(0, 0), Vector2(w, h)), _bags, FxSkin.GOLD)
	FxIcons.bar(ci, Rect2(Vector2(0, ci.size.y - h), Vector2(w, h)), _cracked,
		FxSkin.SUCCESS if _open else Color("#9B8CF0"))


## The realm the crew is in across a universe, in words; "" for a heist of
## one island or before the crew has landed.
static func realm(code: int, to_go: int) -> String:
	if code < 0:
		return ""
	if code == 0:
		return Strings.t("HEIST_IN_HEART")
	return Strings.t("HEIST_IN_REALM", [LandingPresenter.realm_name(code), to_go])
