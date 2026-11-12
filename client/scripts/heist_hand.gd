class_name HeistHand
extends BoxContainer
## The heist's bottom right as the design draws it (§21.8: "Sage, cast and Get
## out at the bottom right"): the Sage's portrait disc, the Cast square under
## it and the red Get out square at the bottom. §12.7: a tap on the Sage opens
## a small wheel with its three powers, a tap on Cast a wheel with the
## player's one or two casts; a power or a cast chosen is aimed by a tap on
## the world, which the screen turns into the command. Wheels are modal:
## while one is open nothing else can be tapped.
##
## Everything shown is the simulation's (`RulebornReplay.sage()`, `casts()`):
## a heist with no Sage shows no disc, and one that carries no casts shows
## Cast greyed with "No casts" under it, so it is said, never invented.

## A power or a cast chosen from a wheel: `kind` is the command (13 Sage,
## 14 Cast), `index` the power or the cast, `words` what it is called.
signal chosen(kind: int, index: int, words: String)
## A second tap on the Sage or on Cast while its choice waits: put it away.
signal put_away

const SAGE_KIND := 13
const CAST_KIND := 14

var sage_button: Button
var cast_button: Button
var go_button: Button
## Where a wheel opens: the screen, over everything.
var host: Control
## The command a wheel's choice waits to be aimed with (SAGE_KIND, CAST_KIND),
## 0 when none: its button glows until the tap on the world.
var armed := 0
## The wheel while it is open (a full-screen scrim holding the card).
var wheel: Control
var _sage := {}
var _casts: Array = []
var _cooling := 0.0
var _picture: Texture2D
var _picture_ready := false
var _sage_id := ""


func _init(get_out: Callable) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", UI.px(6))
	size_flags_vertical = Control.SIZE_SHRINK_END
	alignment = BoxContainer.ALIGNMENT_END
	# A column, as the design's; with §20.8's large text a row over the
	# portraits, so it stays on the phone and in reach.
	vertical = Settings.text_scale <= 130
	sage_button = Button.new()
	sage_button.accessibility_name = Strings.t("HEIST_SAGE")
	sage_button.pressed.connect(_open_sage)
	sage_button.custom_minimum_size = Vector2.ONE * UI.px(62)
	sage_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var clear := StyleBoxFlat.new()
		clear.bg_color = Color(FxSkin.CARD_BOTTOM, 0.01)
		sage_button.add_theme_stylebox_override(state, clear)
	var disc := FxDraw.new(_draw_sage)
	disc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sage_button.add_child(disc)
	sage_button.visible = false
	add_child(sage_button)
	cast_button = square(Strings.t("HEIST_CAST"), _open_casts, "leather", "heistcontrols/cast")
	add_child(cast_button)
	go_button = square(Strings.t("HEIST_GET_OUT"), get_out, "red", "heistcontrols/getout")
	add_child(go_button)


## What the simulation says of the Sage and the casts now, at `tick`.
func show_state(sage: Dictionary, casts: Array, tick: int) -> void:
	_sage = sage
	_casts = casts
	sage_button.visible = not sage.is_empty()
	if not sage.is_empty() and str(sage["id"]) != _sage_id:
		_sage_id = str(sage["id"])
		var kind := _sage_id.replace("the_", "")
		_picture = Portrait.of(kind) if CreatureModel.manifest().has(kind) else null
		_picture_ready = false
	var cooling := maxi(0, int(sage.get("cooling_until", 0)) - tick)
	_cooling = cooling / float(RulebornReplay.ticks_per_second())
	if not sage.is_empty():
		var name := Strings.term("SAGE", _sage_id)
		sage_button.accessibility_name = Strings.t("HEIST_SAGE_COOLING", [name, ceili(_cooling)]) if cooling > 0 \
			else Strings.t("HEIST_SAGE_NAMED", name)
		sage_button.tooltip_text = sage_button.accessibility_name
	var open := casts.any(func(c: Dictionary) -> bool: return not c.get("used", false))
	var said := Strings.t("HEIST_CAST") if not casts.is_empty() else Strings.t("HEIST_NO_CASTS")
	cast_button.accessibility_name = said
	# A cast waiting for its place is rimmed in white.
	var box := RbBox.of(cast_button)
	if box != null and box.material is ShaderMaterial:
		var mat := box.material as ShaderMaterial
		if not cast_button.has_meta("rim"):
			cast_button.set_meta("rim", mat.get_shader_parameter("rim_color"))
		mat.set_shader_parameter("rim_color", Color.WHITE if armed == CAST_KIND else cast_button.get_meta("rim"))
	cast_button.tooltip_text = said
	if cast_button.has_meta("words"):
		var l := cast_button.get_meta("words") as Label
		# With §20.8's large text the order keeps its short verb and the
		# greyed wand says nothing is left, so Cast keeps its row beside Get
		# out and the tray stays under the loot (AD-R15); a screen reader
		# and the tooltip still say "No casts", and the wheel says why.
		var shown := Strings.t("HEIST_CAST") if Settings.text_scale > 130 else said
		# The screen may stand the words on two lines; the same words stay.
		if l.text.replace("\n", " ") != shown:
			l.text = shown
		# Nothing left to cast greys the wand, never the words (§21.10).
		(cast_button.get_meta("icon") as Control).modulate.a = 1.0 if open else 0.4
	else:
		cast_button.text = said
	FxSkin.redraw(sage_button)


func _process(_delta: float) -> void:
	if _picture != null and not _picture_ready and Engine.get_process_frames() % 10 == 0 \
			and FxPortrait._drawn(_picture):
		_picture_ready = true
		FxSkin.redraw(sage_button)


## The Sage's disc: its portrait on the spirit's deep violet in a gold ring,
## and while it cools down a dark sweep over it with the seconds left.
func _draw_sage(ci: Control) -> void:
	var r := minf(ci.size.x, ci.size.y) * 0.5 - UI.px(2)
	var c := ci.size * 0.5
	FxPen.circle(ci, c + Vector2(0, UI.px(3)), r, Color(0.05, 0.0, 0.1, 0.45))
	FxPen.circle(ci, c, r, FxSkin.INK_LINE)
	FxPen.circle(ci, c, r * 0.93, Color("#8A5A22"))
	FxPen.circle(ci, c, r * 0.86, FxSkin.INK_LINE)
	var inner := r * 0.82
	FxPen.circle(ci, c, inner, Color("#3A2A8A"))
	FxPen.circle(ci, c + Vector2(0, -inner * 0.15), inner * 0.7, Color("#5A48B8"))
	if _picture_ready:
		FxPen.flush(ci)
		ci.draw_colored_polygon(FxPortrait._disc(c, inner), Color.WHITE, FxPortrait._disc_uv(), _picture)
	FxPen.arc(ci, c, r * 0.9, PI * 1.05, PI * 1.45, 10, Color(1, 1, 1, 0.35), UI.px(2))
	if armed == SAGE_KIND:
		FxPen.circle(ci, c, r * 1.02, Color(1, 1, 1, 0.9), false, UI.px(3))
	if _cooling > 0.0:
		var share := clampf(_cooling / 20.0, 0.0, 1.0)
		var pts := PackedVector2Array([c])
		for i in 33:
			pts.append(c + Vector2.from_angle(-PI * 0.5 + TAU * share * i / 32.0) * inner)
		FxPen.polygon(ci, pts, Color(0.05, 0.0, 0.1, 0.6))
		var font := FxSkin.figures()
		var px := UI.text_px(18.0)
		var t := str(ceili(_cooling))
		var wide := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var at := c + Vector2(-wide * 0.5, px * 0.35)
		FxPen.string_outline(ci, font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, px, UI.px(4), FxSkin.INK_LINE)
		FxPen.string(ci, font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, px, FxSkin.ON_DARK)


func _open_sage() -> void:
	if armed != 0:
		put_away.emit()
		return
	if _sage.is_empty():
		return
	var rows: Array[Dictionary] = []
	var powers: Array = _sage.get("powers", [])
	for i in powers.size():
		var p: Dictionary = powers[i]
		var name := Strings.t("SAGE_POWER_%s_%d" % [_sage_id.to_upper(), i + 1])
		var left := int(p.get("uses", 0))
		var why := ""
		if left <= 0:
			why = Strings.t("HEIST_NONE_LEFT")
		elif _cooling > 0.0:
			why = Strings.t("HEIST_COOLING", ceili(_cooling))
		rows.append({"words": name, "detail": Strings.t("HEIST_USES_LEFT", left) if why == "" else why,
			"can": why == "", "kind": SAGE_KIND, "index": i})
	open_wheel(Strings.term("SAGE", _sage_id), rows)


func _open_casts() -> void:
	if armed != 0:
		put_away.emit()
		return
	var rows: Array[Dictionary] = []
	for i in _casts.size():
		var c: Dictionary = _casts[i]
		var used: bool = c.get("used", false)
		rows.append({"words": Strings.term("LAW", str(c["law"])),
			"detail": Strings.t("HEIST_CAST_USED") if used else Strings.t("HEIST_CAST_PLACE"), "can": not used,
			"kind": CAST_KIND, "index": i})
	if rows.is_empty():
		rows.append({"words": Strings.t("HEIST_NO_CASTS"), "detail": Strings.t("HEIST_NO_CASTS_WHY"), "can": false,
			"kind": CAST_KIND, "index": -1})
	open_wheel(Strings.t("HEIST_CAST"), rows)


## §12.7's wheel: a card over a scrim that takes every tap, a row a choice;
## a tap outside closes it.
func open_wheel(title: String, rows: Array[Dictionary]) -> void:
	close_wheel()
	var parent: Control = host if host != null else self
	var scrim := Button.new()
	scrim.accessibility_name = Strings.t("HEIST_WHEEL_CLOSE")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.pressed.connect(close_wheel)
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0.03, 0.0, 0.08, 0.45)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		scrim.add_theme_stylebox_override(state, shade)
	var card := FxSkin.panel("parchment", 18.0, 10.0)
	card.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	card.add_child(box)
	box.add_child(FxSkin.label(title, 18.0, "parchment", true))
	for r: Dictionary in rows:
		var words := "%s · %s" % [r["words"], r["detail"]]
		var pick := func() -> void:
			close_wheel()
			chosen.emit(int(r["kind"]), int(r["index"]), str(r["words"]))
		var b := UI.action(words, pick, "gold" if r["can"] else "leather", words)
		b.disabled = not r["can"]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = UI.px(240)
		box.add_child(b)
	scrim.add_child(card)
	parent.add_child(scrim)
	wheel = scrim
	card.reset_size()
	var w := parent.size
	card.position = Vector2(clampf(w.x - card.size.x - UI.px(12), UI.px(12), w.x), w.y * 0.5 - card.size.y * 0.5)


func close_wheel() -> void:
	if wheel != null and is_instance_valid(wheel):
		wheel.queue_free()
	wheel = null


## `words` broken onto two lines at the space nearest their middle.
static func two_lines(words: String) -> String:
	var best := -1
	for i in words.length():
		if words[i] == " " and (best < 0 or absi(i * 2 - words.length()) < absi(best * 2 - words.length())):
			best = i
	return words if best < 0 else words.substr(0, best) + "\n" + words.substr(best + 1)


## The design's square order (Cast, Get out): a rounded square in the kit's
## `look`, its icon over its word; the icon's box is meta "box", the word's
## label meta "words". A screen reader hears the word.
static func square(words: String, call: Callable, look: String, icon := "") -> Button:
	if Settings.text_scale > 130:
		# With §20.8's large text a plain button of its words, which the
		# screen lays in a row that wraps.
		var plain := UI.action(words, call, look, words)
		UI.fit(plain)
		return plain
	var b := UI.action("", call, look, words)
	b.tooltip_text = words
	b.custom_minimum_size = Vector2(UI.px(62), UI.px(58))
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	UI.dress(b, look, 16.0)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if icon != "":
		var pic := Icons.view(icon, 28.0)
		pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(pic)
		b.set_meta("icon", pic)
	var l := FxSkin.label(words, 14.0)
	l.add_theme_constant_override("outline_size", UI.px(3))
	box.add_child(l)
	b.add_child(box)
	b.set_meta("box", box)
	b.set_meta("words", l)
	# As wide as its word needs with §20.8's large text, never narrower than
	# the design's square.
	var fit := func() -> void:
		b.custom_minimum_size = Vector2(maxf(UI.px(62), l.get_minimum_size().x + UI.px(14)),
			maxf(UI.px(58), l.get_minimum_size().y + UI.px(36)))
	fit.call()
	l.minimum_size_changed.connect(fit)
	return b
