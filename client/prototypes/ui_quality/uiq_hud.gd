class_name UiqHud
extends Control
## T14's proof (docs/art/ui-quality/report.md): the heist HUD of §21.8 rebuilt
## on authored art (UiqArt) instead of code-drawn boxes, to show the ceiling of
## that pipeline. Same information as HeistHud and the crew row: the laws here,
## the clock, the alarm's six bells, the loot panel, the crew's portraits with
## their pips, health and names, Cast and Get out. Laid out in the phone's
## pixels at 1080 wide. A prototype: tests/shots/uiq_heist_hud.gd lays it over
## the real heist screen; no screen of the game uses it.

const W := 1080.0
const TOP := 150.0
const CREW_Y := 1850.0
const MEDAL := 168.0
const BELLS := 6
const RED_SECONDS := 30

var _clock_box: Control
var _alarm_box: Control
var _bells: Array[TextureRect] = []
var _room_box: Control
var _left_box: Control
var _fill: NinePatchRect
var _tick: TextureRect
var _load: Label
var _laws_box: VBoxContainer
var _crew_box: Control
var _crew_key := ""
var _sage: UiqMedal


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_laws()
	_build_clock()
	_build_loot()
	_crew_box = Control.new()
	_crew_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crew_box)
	_build_hand()


## The state of a heist, as HeistHud.show_state takes it, and the crew row's
## portraits (the screen's, for their pictures, names and health).
func show_state(r: RulebornReplay, crew: Array[FxPortrait], estimate: int, load_target: int) -> void:
	var tps := RulebornReplay.ticks_per_second()
	var left := maxi(0, (r.ticks() - r.tick()) / tps)
	var red := r.ticks() > 0 and left <= RED_SECONDS
	_set_digits(_clock_box, "%d:%02d" % [left / 60, left % 60], "timer_red" if red else "timer", 112.0)
	for i in BELLS:
		_bells[i].texture = UiqArt.tex("bell_off" if i >= r.alarm() else ("bell_red" if r.alarm() >= 4 else "bell_amber"))
	_set_digits(_alarm_box, "%d/%d" % [r.alarm(), BELLS], "white", 54.0)
	var carried := 0
	var carry := 0
	for m: Dictionary in r.crew():
		carried += int(m["carried"])
		carry += int(m["carry"])
	var v := r.vault()
	var open := bool(v.get("open", false))
	_set_digits(_room_box, ShopPresenter.grouped(carry - carried), "gold", 66.0)
	var left_words := ShopPresenter.grouped(int(v.get("exposed", 0))) if open \
		else ("~" + ShopPresenter.grouped(estimate) if estimate >= 0 else "")
	_set_digits(_left_box, left_words, "gold", 66.0)
	var bags := float(carried) / maxf(1.0, float(carry))
	_fill.size.x = maxf(34.0, 270.0 * bags)
	_fill.visible = bags > 0.0
	_tick.visible = load_target >= 0
	_tick.position.x = 30.0 + 270.0 * float(maxi(load_target, 0)) / 100.0 - 13.0
	_load.text = Strings.t("HUD_LOAD_TO", load_target) if load_target >= 0 else ""
	_show_laws(r)
	_show_crew(r, crew)


func _set_digits(box: Control, text: String, style: String, h: float) -> void:
	for c in box.get_children():
		c.free()
	var d := UiqArt.digits(text, style, h)
	box.add_child(d)
	d.reset_size()
	# Right-aligned when the box asks, else centred.
	if box.get_meta("right", false):
		d.position = Vector2(-d.size.x, -h / 2.0)
	else:
		d.position = -d.size / 2.0


func _anchor(at: Vector2, right := false) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = at
	c.set_meta("right", right)
	return c


func _frame(name: String, at: Vector2, side: Vector2) -> NinePatchRect:
	var n := UiqArt.nine(name)
	n.position = at
	n.size = side
	add_child(n)
	return n


func _build_clock() -> void:
	_frame("frame_plaque", Vector2(W / 2.0 - 172.0, TOP - 24.0), Vector2(344, 178))
	_clock_box = _anchor(Vector2(W / 2.0, TOP + 52.0))
	add_child(_clock_box)
	var alarm := _frame("frame_panel", Vector2(W / 2.0 - 180.0, TOP + 138.0), Vector2(360, 168))
	var word := UiqArt.words(Strings.t("HUD_ALARM_WORD"), 46.0, Color("#FFE3A0"))
	word.position = Vector2(34, 20)
	alarm.add_child(word)
	_alarm_box = _anchor(Vector2(282, 52), false)
	alarm.add_child(_alarm_box)
	for i in BELLS:
		var b := UiqArt.sprite("bell_off", Vector2(58.0 + 49.0 * i, 112.0), Vector2(56, 56))
		alarm.add_child(b)
		_bells.append(b)


func _build_loot() -> void:
	var p := _frame("frame_panel", Vector2(W - 380.0, TOP - 24.0), Vector2(370, 316))
	p.add_child(UiqArt.sprite("icon_bag", Vector2(28, 26), Vector2(92, 92)))
	var room := UiqArt.words(Strings.t("HUD_ROOM"), 46.0, Color("#E9DAFF"))
	room.position = Vector2(56, 30)
	p.add_child(room)
	_room_box = _anchor(Vector2(334, 62), true)
	p.add_child(_room_box)
	var left := UiqArt.words(Strings.t("HUD_LEFT"), 46.0, Color("#E9DAFF"))
	left.position = Vector2(56, 98)
	p.add_child(left)
	_left_box = _anchor(Vector2(334, 130), true)
	p.add_child(_left_box)
	var track := UiqArt.nine("bar_track")
	track.position = Vector2(30, 178)
	track.size = Vector2(290, 36)
	p.add_child(track)
	_fill = UiqArt.nine("bar_gold")
	_fill.position = Vector2(34, 181)
	_fill.size = Vector2(34, 30)
	p.add_child(_fill)
	_tick = UiqArt.sprite("tick", Vector2(0, 196), Vector2(26, 58))
	p.add_child(_tick)
	_load = UiqArt.words("", 40.0, Color("#FFE3A0"))
	_load.position = Vector2(30, 216)
	p.add_child(_load)


func _build_laws() -> void:
	var here := UiqArt.words(Strings.t("HUD_LAWS_HERE"), 46.0, Color("#FFC94A"))
	here.position = Vector2(26, TOP - 44.0)
	add_child(here)
	_laws_box = VBoxContainer.new()
	_laws_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_laws_box.position = Vector2(14, TOP + 18.0)
	_laws_box.add_theme_constant_override("separation", -6)
	add_child(_laws_box)


func _show_laws(r: RulebornReplay) -> void:
	if _laws_box.get_child_count() > 0:
		return
	for p: Dictionary in r.pylons():
		if not p.get("standing", false):
			continue
		var chip := UiqArt.nine("frame_chip")
		chip.custom_minimum_size = Vector2(326, 112)
		var icon := "res://ui/icons/png/laws/%s.png" % str(p.get("law", "")).replace("_", "")
		if ResourceLoader.exists(icon):
			var t := UiqArt.sprite("pip", Vector2(60, 50), Vector2(82, 82))
			t.texture = load(icon) as Texture2D
			chip.add_child(t)
		var words := UiqArt.words(Strings.term("LAW", str(p.get("law", ""))), 48.0)
		words.position = Vector2(108, 20)
		chip.add_child(words)
		_laws_box.add_child(chip)


func _build_hand() -> void:
	_button("btn_violet", "icon_cast", Strings.t("HEIST_CAST"), Vector2(W - 232.0, CREW_Y - 230.0), 220.0)
	_button("btn_red", "icon_getout", Strings.t("HEIST_GET_OUT"), Vector2(W - 238.0, CREW_Y - 30.0), 232.0)


## The Sage's disc over Cast (the hand's), its portrait in the crew's ring.
func set_sage(picture: Texture2D, kind: String) -> void:
	if _sage != null or picture == null:
		return
	var who := FxPortrait.new("", Callable(), kind, " ")
	who.picture = picture
	_sage = UiqMedal.new(who, {}, true)
	_sage.position = Vector2(W - 206.0, CREW_Y - 410.0)
	add_child(_sage)
	who.free()


## A pressable button: its face and its sunk face (§21.8's press, here a
## second picture), its icon and its word over the face.
func _button(look: String, icon: String, said: String, at: Vector2, w: float) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = UiqArt.tex(look)
	b.texture_pressed = UiqArt.tex(look + "_down")
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.position = at
	b.size = Vector2(w, w * 190.0 / 220.0)
	b.accessibility_name = said
	add_child(b)
	b.add_child(UiqArt.sprite(icon, Vector2(w / 2.0, w * 0.3), Vector2(w * 0.46, w * 0.46)))
	var l := UiqArt.words(said, w * 0.2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, w * 0.47)
	l.size = Vector2(w, w * 0.26)
	b.add_child(l)
	return b


func _show_crew(r: RulebornReplay, crew: Array[FxPortrait]) -> void:
	var key := ",".join(crew.map(func(p: FxPortrait) -> String: return "%s%.2f%d%s" % [p.letters, p.health, p.uses,
		p.chosen]))
	if key == _crew_key:
		return
	_crew_key = key
	for c in _crew_box.get_children():
		c.free()
	for i in crew.size():
		var medal := UiqMedal.new(crew[i], r.crew()[i] if i < r.crew().size() else {})
		medal.position = Vector2(10.0 + 164.0 * i, CREW_Y - MEDAL / 2.0)
		_crew_box.add_child(medal)
