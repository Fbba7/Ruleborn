class_name KitSocial
extends RefCounted
## The designs' people (27 Friends): a friend as a round portrait in a ring
## with their name and what they are doing, and a feed row on parchment with
## who, a tag, when, what happened, and a picture with its action. Each says
## its state in words; a colour only repeats them (§20.8).


## A friend in a ring: their picture (or their initials, when there is no
## picture), their name under it, and `status` beneath ("Raiding", "3 h
## ago"). A `tone` (a colour token: "alarm", "spirit", "life"...) rings the
## portrait in it and puts the status on a dark tag led by a dot of it;
## without one the status is plain secondary words.
static func avatar(picture: Texture2D, initials: String, name: String, status := "", tone := "",
		pressed := Callable()) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "Friend"
	v.add_theme_constant_override("separation", UI.px(2))
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	var face := _face(picture, initials, 60.0, tone)
	if pressed.is_valid():
		var b := UI.action("", pressed, "seg", name if status == "" else "%s, %s" % [name, status])
		b.custom_minimum_size = Vector2.ONE * UI.px(60)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		RbBox.of(b).visible = false
		face.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(face)
		v.add_child(b)
	else:
		v.add_child(face)
	var n := UI.label(name, 13)
	n.add_theme_font_override("font", UI.bold_font())
	n.set_meta("bold", true)
	v.add_child(n)
	if status != "":
		if tone != "":
			v.add_child(tag(status, tone))
		else:
			v.add_child(_secondary(status))
	return v


## A small tag with its words in capitals (the designs' RAIDING, HELD,
## CHALLENGE): filled for "success", "warn", "violet" and "alarm", otherwise
## dark with a dot of `tone` (a colour token) before its words.
static func tag(words: String, tone := "") -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Tag"
	p.add_theme_stylebox_override("panel", UI.clear_box(5, 0))
	# A tone with a filled tag of its own (HELD, GOT OUT, FRIENDLY) is
	# filled; any other is a dark tag led by a dot of it.
	var filled := Tokens.materials().has("tag_" + tone)
	UI.dress(p, "tag_" + tone if filled else "tag_dark", 999)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if tone != "" and not filled:
		var dot := KitRing.new()
		dot.dot = true
		dot.fraction = 1.0
		dot.tint = Tokens.color(tone)
		dot.custom_minimum_size = Vector2.ONE * UI.px(8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
	# Capitals without the kicker's tracking: a tag is a word, not a heading.
	var l := UI.label(words, 13)
	l.theme_type_variation = "BodyBold"
	l.add_theme_font_size_override("font_size", UI.text_px(13))
	l.uppercase = true
	l.set_meta("bold", true)
	row.add_child(l)
	p.add_child(row)
	return p


## A feed row on parchment: who (picture or initials), their name, a tag,
## when, what happened (wrapping), and at its end a picture over an action
## ("Watch", "Play") when `action` is given.
static func feed_row(picture: Texture2D, initials: String, name: String, tag_words: String, tone: String,
		when: String, words: String, thumb: Texture2D = null, action := "", pressed := Callable()) -> PanelContainer:
	var p := UI.panel("parchment")
	p.name = "FeedRow"
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	var face := _face(picture, initials, 48.0, tone)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(face)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", UI.px(2))
	# Who and the tag on the left, when on the right, as the designs set it.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI.px(6))
	var who := KitLayout.flow(6)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var n := UI.label(name, 16)
	n.theme_type_variation = "BodyBold"
	n.set_meta("bold", true)
	who.add_child(n)
	if tag_words != "":
		who.add_child(tag(tag_words, tone))
	head.add_child(who)
	if when != "":
		var at := _secondary(when)
		at.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		# At large text it flows on after the tag rather than holding the right.
		if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO:
			who.add_child(at)
		else:
			head.add_child(at)
	text.add_child(head)
	var w := UI.label(words, 14, true)
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.add_child(w)
	row.add_child(text)
	if action != "":
		var end := VBoxContainer.new()
		end.add_theme_constant_override("separation", -UI.px(6))
		end.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if thumb != null:
			var frame := PanelContainer.new()
			frame.add_theme_stylebox_override("panel", UI.clear_box(2, 2))
			UI.dress(frame, "card", 10)
			var t := TextureRect.new()
			t.texture = thumb
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			t.custom_minimum_size = Vector2(UI.px(80), UI.px(52))
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.add_child(t)
			end.add_child(frame)
		end.add_child(UI.action(action, pressed, "gold", "%s: %s" % [action, name]))
		# At large text the words keep the width and the action goes beneath.
		if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO:
			end.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			text.add_child(end)
		else:
			row.add_child(end)
	p.add_child(row)
	return p


## A defence log row (16 Defence log): who, a filled tag, when and what
## happened on the left; the result on the right in its tone's words
## ("Denied 3,300", green; "You lost nothing") over a link ("Report ›").
static func log_row(picture: Texture2D, initials: String, name: String, tag_words: String, tone: String,
		line: String, result: String, result_kind: String, link: String, pressed := Callable()) -> PanelContainer:
	var p := feed_row(picture, initials, name, tag_words, tone, "", line)
	p.name = "LogRow"
	var row := p.get_child(0) as HBoxContainer
	var end := VBoxContainer.new()
	# The link's 48-point hit area overlaps the result a little, as the
	# design sets them close.
	end.add_theme_constant_override("separation", -UI.px(10))
	end.alignment = BoxContainer.ALIGNMENT_CENTER
	# Led by its status's glyph, so the outcome never rests on its colour.
	# One line beside the words; wrapping under them at large text.
	var large := Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO
	var r := UI.status(result_kind, result, large)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	end.add_child(r)
	if link != "":
		end.add_child(text_link(link + " ›", pressed, "%s: %s" % [link, name]))
	if large:
		end.size_flags_horizontal = Control.SIZE_FILL
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		(row.get_child(1) as VBoxContainer).add_child(end)
	else:
		row.add_child(end)
	return p


## Words that act, on parchment, as the designs' "Report ›": no box, bold
## words in the parchment's second ink, a 48-point hit area (§21.1).
static func text_link(words: String, pressed: Callable, spoken := "") -> Button:
	var b := UI.action(words, pressed, "parchment", spoken if spoken != "" else words)
	b.name = "Link"
	var box := RbBox.of(b)
	box.visible = false
	b.custom_minimum_size = Vector2.ONE * UI.px(UI.CONTROL_POINTS)
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Tokens.color("parchment_text_2"))
	return b


static func _face(picture: Texture2D, initials: String, points: float, tone: String) -> Control:
	var ring := KitRing.new()
	ring.name = "Face"
	ring.picture = picture
	ring.band = _tone(tone)
	ring.ground = Tokens.paint("#4A3A9A")
	ring.zoom = 1.2
	ring.focus = Vector2(0.5, 0.42)
	ring.custom_minimum_size = Vector2.ONE * UI.px(points)
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if picture == null:
		# The initials sit on the ground's two stops: what the checks read.
		ring.set_meta("text_bg", [ring.ground.darkened(0.25), ring.ground.lightened(0.18)])
		var c := CenterContainer.new()
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := UI.label(initials, points * 0.32)
		l.add_theme_font_override("font", Tokens.font("display"))
		l.add_theme_color_override("font_color", Tokens.color("cream"))
		l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
		l.add_theme_constant_override("outline_size", UI.px(2))
		l.set_meta("bold", true)
		c.add_child(l)
		ring.add_child(c)
	return ring


static func _secondary(words: String) -> Label:
	var s := UI.label(words, 13)
	s.theme_type_variation = "Secondary"
	return s


## A tone's colour: a colour token, or the violet tags' own.
static func _tone(tone: String) -> Color:
	if tone == "":
		return Tokens.color("gold")
	if tone == "violet":
		return Tokens.paint("#6A55D0")
	return Tokens.color(tone)

