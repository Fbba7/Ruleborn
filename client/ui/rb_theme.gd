class_name RbTheme
## §21.8's type as a Godot Theme: Manrope for labels, body text and numbers
## (tabular figures on numbers), Lilita One for large still numbers,
## Marcellus for titles, with the designs' hard text shadows and ink outlines,
## in each of the two families of surface: "dark" (the night backdrop,
## cards, glass and leather, with light words) and "light" (parchment and
## gold, with brown ink). A control takes its family's theme from the box
## around it, so the same label reads on either. Type variations, one per
## tokens.json `type` role, are named as the role in capitals ("Kicker",
## "Title", "Number"; "LabelText" and "ButtonText" for the roles named as
## engine classes), plus "Secondary" and the statuses ("StatusAlarm",
## "StatusSuccess", "StatusInfo").

const STATUSES := ["alarm", "success", "info", "confirming"]

static var _themes: Dictionary = {}
static var _knob: ImageTexture = null


## The theme for a family of surface, made once per contrast mode.
static func of(family: String) -> Theme:
	var key := "%s:%s" % [family, Tokens.high_contrast]
	if not _themes.has(key):
		_themes[key] = _build(family)
	return _themes[key]


## The theme for words inside a material: its family's, with the
## material's own colour for words and secondary words, its ink outline
## round every word, and bold words where it says (`bold_words`), so a
## label a screen puts on the red, the green or the gold reads as the kit
## measured it.
static func of_material(name: String) -> Theme:
	var key := "%s:%s" % [name, Tokens.high_contrast]
	if not _themes.has(key):
		var spec := Tokens.material(name)
		var th := _build(str(spec["family"]))
		_words(th, spec)
		_themes[key] = th
	return _themes[key]


## Whether a font draws bold words, as §21.8's contrast levels mean it: Manrope
## at 700 or heavier, or the heavy display face.
static func is_bold(f: Font) -> bool:
	if not f is FontVariation:
		return false
	var v := f as FontVariation
	if v.base_font == (Tokens.font("display") as FontVariation).base_font:
		return true
	var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	return int(v.variation_opentype.get(tag, 400)) >= 700


## A type role's variation name: "number_m" is "NumberM", and a role named
## as an engine class takes "Text" after it ("label" is "LabelText").
static func variation(role: String) -> String:
	var v := role.to_pascal_case()
	return v + "Text" if ClassDB.class_exists(v) else v


## The font a role draws in.
static func role_font(role: String) -> Font:
	var t := Tokens.type_role(role)
	var spacing := roundi(float(t.get("tracking", 0.0)) * float(t["points"]) * UI.PX_PER_POINT)
	return Tokens.font(str(t["family"]), int(t.get("weight", 400)), bool(t.get("tnum", false)), spacing)


## What words of `status` are drawn in on a family of surface (§21.8): on
## parchment #9A1B32 and #155A38, on dark #FF9AAA and #3FBF7F.
static func status_colour(status: String, family: String) -> Color:
	match status:
		"alarm":
			return Tokens.color("alarm_text" if family == "light" else "on_alarm")
		"success":
			return Tokens.color("success_text" if family == "light" else "success_text_on_night")
	return Tokens.color("parchment_ink" if family == "light" else "text_on_night")


## The fill a status's words are carried on, or none (alpha 0). On a dark
## family alarm words are paper on alarm_fill: #FF9AAA misses Lc 60 on
## glass, on the bare backdrop and on leather (kit-spec.md section 2.1).
## Success words keep their own colour and glyph, on no fill (AIA-R8).
static func status_fill(status: String, family: String) -> Color:
	if status == "alarm" and family != "light":
		return Tokens.color("alarm_fill")
	return Color(0, 0, 0, 0)


## Gives a label the light family's theme when it lands on someone else's
## light panel (a StyleBoxFlat drawn by a screen's own code), so its words
## stay ink there; the kit's own boxes set their family themselves.
static func adapt(label: Control) -> void:
	# Words drawn bold are marked so, for §21.8's levels (the contrast check
	# reads the mark): the theme may have made them bold on a gold surface.
	if not label.has_meta("bold") and is_bold(label.get_theme_font("font")):
		label.set_meta("bold", true)
	var n: Node = label.get_parent()
	while n is Control:
		var c := n as Control
		if c.has_meta("rb_family"):
			return
		var box: StyleBox = null
		if c is PanelContainer:
			box = c.get_theme_stylebox("panel")
		elif c is Button:
			box = c.get_theme_stylebox("normal")
		if box is StyleBoxFlat and (box as StyleBoxFlat).bg_color.a > 0.5:
			if ColourCheck.luminance((box as StyleBoxFlat).bg_color) > 0.35:
				label.theme = of("light")
			return
		n = n.get_parent()


static func _words(th: Theme, spec: Dictionary) -> void:
	var light := str(spec["family"]) == "light"
	var plain := Tokens.color("parchment_ink" if light else "text_on_night")
	var words: Color = spec["text"]
	var outline: Array = spec.get("text_outline", [])
	var kinds: Array[String] = ["Label"]
	for role: String in Tokens.type_roles():
		kinds.append(variation(role))
	for kind: String in kinds:
		if words != plain:
			th.set_color("font_color", kind, words)
		if not outline.is_empty():
			th.set_color("font_outline_color", kind, outline[0])
			th.set_constant("outline_size", kind, UI.px(float(outline[1])))
	if spec["text_2"] != Tokens.color("parchment_text_2" if light else "text_on_night_2"):
		th.set_color("font_color", "Secondary", spec["text_2"])
	if bool(spec["bold_words"]):
		th.default_font = role_font("body_bold")
		th.set_font("font", "Label", role_font("body_bold"))
		th.set_font("font", "Secondary", role_font("body_bold"))


static func _build(family: String) -> Theme:
	var th := Theme.new()
	var light := family == "light"
	var text := Tokens.color("parchment_ink" if light else "text_on_night")
	var soft := Tokens.color("parchment_text_2" if light else "text_on_night_2")
	var drop := Tokens.color("ink_line" if light else "drop")
	th.default_font = role_font("body")
	th.default_font_size = UI.px(Tokens.number("size", "body_points"))
	th.set_color("font_color", "Label", text)
	th.set_constant("line_spacing", "Label", UI.px(1))
	# Stated as none, so a label never takes the outline of a material
	# further out (a theme lacking an item hands the lookup to its parent's).
	for kind: String in ["Label", "Button"]:
		th.set_constant("outline_size", kind, 0)
		th.set_color("font_outline_color", kind, drop)
	for role: String in Tokens.type_roles():
		var t := Tokens.type_role(role)
		var v := variation(role)
		th.set_type_variation(v, "Label")
		th.set_font("font", v, role_font(role))
		th.set_font_size("font_size", v, UI.px(float(t["points"])))
		th.set_color("font_color", v, text)
		if t.has("drop") and not light:
			th.set_color("font_shadow_color", v, drop)
			th.set_constant("shadow_offset_x", v, 0)
			th.set_constant("shadow_offset_y", v, maxi(1, UI.px(float(t["drop"]))))
			th.set_constant("shadow_outline_size", v, 0)
		# Light words on a dark surface are stroked in ink; ink words on a
		# light one are not (the designs' figures on parchment are plain
		# ink, and an ink stroke round ink only fattens it).
		if t.has("outline") and not light:
			th.set_color("font_outline_color", v, Tokens.color("ink_line"))
			th.set_constant("outline_size", v, UI.px(float(t["outline"])))
			th.set_color("font_color", v, Tokens.color("cream"))
	# A title stands over the designs' gold rule (UI.title draws it in this
	# margin).
	var under := StyleBoxEmpty.new()
	under.content_margin_bottom = UI.px(14)
	th.set_stylebox("normal", "Title", under)
	th.set_type_variation("Secondary", "Label")
	th.set_color("font_color", "Secondary", soft)
	for s: String in STATUSES:
		var v := "Status" + s.capitalize()
		th.set_type_variation(v, "Label")
		th.set_color("font_color", v, status_colour(s, family))
		th.set_font("font", v, role_font("body_bold"))
		var fill := status_fill(s, family)
		if fill.a > 0.0:
			var box := StyleBoxFlat.new()
			box.bg_color = fill
			box.set_corner_radius_all(UI.px(Tokens.number("size", "radius_s")))
			box.content_margin_left = UI.px(10)
			box.content_margin_right = UI.px(10)
			box.content_margin_top = UI.px(4)
			box.content_margin_bottom = UI.px(4)
			th.set_stylebox("normal", v, box)
		else:
			# Said outright, so a family on no fill never takes the fill of
			# a dark family's theme round it.
			th.set_stylebox("normal", v, StyleBoxEmpty.new())
	_controls(th, text, light)
	return th


## The rest of what a screen's own controls draw: fields, scroll bars and
## the tooltips, in the family's colours.
static func _controls(th: Theme, text: Color, _light: bool) -> void:
	th.set_color("font_color", "LineEdit", Tokens.color("parchment_ink"))
	th.set_color("font_placeholder_color", "LineEdit", Tokens.color("parchment_text_2"))
	th.set_color("caret_color", "LineEdit", Tokens.color("parchment_ink"))
	th.set_color("font_color", "RichTextLabel", text)
	th.set_color("default_color", "RichTextLabel", text)
	# No scroll bar drawn, as the designs' lists (`scrollbar-width:none`):
	# a list shows it goes on by the row cut at its foot.
	var grab := StyleBoxEmpty.new()
	var track := StyleBoxEmpty.new()
	track.content_margin_left = UI.px(1.5)
	track.content_margin_right = UI.px(1.5)
	for part: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		th.set_stylebox(part, "VScrollBar", grab)
	th.set_stylebox("scroll", "VScrollBar", track)
	# Sliders: an ink-edged dark track, filled in gold up to a gold knob.
	var rail := StyleBoxFlat.new()
	rail.bg_color = Tokens.paint("#140A16")
	rail.border_color = Tokens.color("ink_line")
	rail.set_border_width_all(UI.px(1))
	rail.set_corner_radius_all(UI.px(6))
	rail.content_margin_top = UI.px(5)
	rail.content_margin_bottom = UI.px(5)
	var filled := rail.duplicate() as StyleBoxFlat
	filled.bg_color = Tokens.color("gold")
	for kind: String in ["HSlider", "VSlider"]:
		th.set_stylebox("slider", kind, rail)
		th.set_stylebox("grabber_area", kind, filled)
		th.set_stylebox("grabber_area_highlight", kind, filled)
		for icon: String in ["grabber", "grabber_highlight"]:
			th.set_icon(icon, kind, knob())



## The slider's knob: a gold disc in an ink ring, drawn once, smoothed by
## coverage at its edge.
static func knob() -> ImageTexture:
	if _knob != null:
		return _knob
	var n := UI.px(26)
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n, n) * 0.5
	var r := n * 0.5 - 1.0
	var ink := Tokens.color("ink_line")
	var gold := Tokens.color("gold")
	var top := Tokens.color("gold_top")
	for y: int in n:
		for x: int in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var cover := clampf(r - d + 0.5, 0.0, 1.0)
			var inner := clampf(r - UI.px(1.5) - d + 0.5, 0.0, 1.0)
			var lit := top.lerp(gold, clampf(float(y) / n * 1.4, 0.0, 1.0))
			var col := ink.lerp(lit, inner)
			img.set_pixel(x, y, Color(col, cover))
	_knob = ImageTexture.create_from_image(img)
	return _knob
