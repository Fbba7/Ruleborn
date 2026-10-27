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


## A small dark tag with a dot of `tone` before its words in capitals (the
## designs' RAIDING, ESCAPED, CHALLENGE).
static func tag(words: String, tone := "") -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Tag"
	p.add_theme_stylebox_override("panel", UI.clear_box(5, 0))
	UI.dress(p, "tag_dark", 999)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if tone != "":
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


static func _face(picture: Texture2D, initials: String, points: float, tone: String) -> Control:
	var ring := KitRing.new()
	ring.name = "Face"
	ring.picture = picture
	ring.band = Tokens.color(tone) if tone != "" else Tokens.color("gold")
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
