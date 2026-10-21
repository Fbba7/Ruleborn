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
			return Tokens.color("alarm_text" if family == "light" else "alarm_text_on_night")
		"success":
			return Tokens.color("success_text" if family == "light" else "success_text_on_night")
	return Tokens.color("parchment_ink" if family == "light" else "text_on_night")


## Gives a label the light family's theme when it lands on someone else's
## light panel (a StyleBoxFlat drawn by a screen's own code), so its words
## stay ink there; the kit's own boxes set their family themselves.
static func adapt(label: Control) -> void:
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
		if t.has("outline"):
			th.set_color("font_outline_color", v, Tokens.color("ink_line"))
			th.set_constant("outline_size", v, UI.px(float(t["outline"])))
			th.set_color("font_color", v, Tokens.color("cream") if not light else text)
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
	_controls(th, text, light)
	return th


## The rest of what a screen's own controls draw: fields, scroll bars and
## the tooltips, in the family's colours.
static func _controls(th: Theme, text: Color, light: bool) -> void:
	th.set_color("font_color", "LineEdit", Tokens.color("parchment_ink"))
	th.set_color("font_placeholder_color", "LineEdit", Tokens.color("parchment_text_2"))
	th.set_color("caret_color", "LineEdit", Tokens.color("parchment_ink"))
	th.set_color("font_color", "RichTextLabel", text)
	th.set_color("default_color", "RichTextLabel", text)
	# A quiet scroll bar: a thin rounded grabber, no track, as phones draw it.
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(Tokens.color("text_on_night_2") if not light else Tokens.color("parchment_text_2"), 0.45)
	grab.set_corner_radius_all(UI.px(2))
	grab.content_margin_left = UI.px(1.5)
	grab.content_margin_right = UI.px(1.5)
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
