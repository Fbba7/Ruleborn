class_name OverlaySheet
extends RefCounted
## The panels over a realm, drawn as a game's interface rather than a form's
## (§21.8: parchment surfaces "from #FFFBF0 to #F1E3C4 with brown ink", night
## surfaces "from #261A4C to #1A1134", every panel and control edged in the
## ink outline #1A0C14, a hard drop beneath so it sits on the world like a
## card on a table). A screen builds its panels with `UI` and then dresses
## them here: the words, their sizes and what a screen reader says stay
## `UI`'s, so §21.8's contrast and §20.8's checks hold unchanged.

## §21.8's parchment, its lighter end; and the ink outline.
const PARCHMENT := Color("#FBF1DA")
const PARCHMENT_LIGHT := Color("#FFFBF0")
const OUTLINE := Color("#1A0C14")
## §21.8's night surface, for chrome that carries no words.
const NIGHT := Color("#261A4C")
## A panel's corner and a control's, in points.
const PANEL_CORNER := 16
const CONTROL_CORNER := 14
## A ribbon's title: smaller than a page's, so the world keeps the room.
const RIBBON_POINTS := 22.0


## A parchment card edged in ink, with a drop of ink beneath.
static func paper(corner := PANEL_CORNER, fill := PARCHMENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill if not Settings.high_contrast else Palette.PAPER
	box.border_color = OUTLINE if not Settings.high_contrast else Palette.INK
	box.set_border_width_all(maxi(2, UI.px(0.75)))
	box.set_corner_radius_all(UI.px(corner))
	box.shadow_color = Color(OUTLINE, 0.55)
	box.shadow_size = 0
	box.shadow_offset = Vector2(0, UI.px(1.25))
	box.set_content_margin_all(UI.px(Tokens.number("size", "gap_points")))
	box.anti_aliasing = true
	return box


## The night surface: a frame for the world's chrome, edged the same way.
static func night(corner := PANEL_CORNER) -> StyleBoxFlat:
	var box := paper(corner, NIGHT)
	box.bg_color = NIGHT
	box.border_color = OUTLINE
	return box


## Every panel and control under `root` dressed: panels on parchment, a
## control as a chunky key with an ink edge and a drop beneath, gold for the
## main action as `UI` already fills it.
static func dress(root: Node) -> void:
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "", true, false))
	for n: Node in nodes:
		# T9's kit draws its own materials: a control it dressed keeps them.
		if n is Control and RbBox.of(n as Control) != null:
			continue
		if n is PanelContainer and not n.has_meta("dressed"):
			var p := n as PanelContainer
			var was := p.get_theme_stylebox("panel") as StyleBoxFlat
			if was != null and was.bg_color.a > 0.0:
				var box := paper()
				box.content_margin_left = was.content_margin_left
				box.content_margin_right = was.content_margin_right
				box.content_margin_top = was.content_margin_top
				box.content_margin_bottom = was.content_margin_bottom
				p.add_theme_stylebox_override("panel", box)
				# Drawn by T9's kit (`KitSkin`), its padding kept.
				KitSkin.panel(p, "parchment")
			p.set_meta("dressed", true)
		elif n is Button and not n.has_meta("dressed"):
			key(n as Button)


## A control as a chunky key: its fill kept (gold for the main action,
## parchment for the rest), the ink edge thickened, a drop beneath that
## sinks when pressed.
static func key(b: Button) -> void:
	# Drawn by T9's kit (`KitSkin`): a kit material stays, the rest parchment.
	KitSkin.button(b, str(b.get_meta("rb_material", "parchment")))
	b.set_meta("dressed", true)


## A number or a short name on a pill, as a pin over the realm or a chip in
## a header: bold, edged in ink, on `fill` (parchment unless given).
static func chip(text: String, fill := Color(), points := -1.0) -> PanelContainer:
	var p := PanelContainer.new()
	var box := paper(CONTROL_CORNER, fill if fill != Color() else PARCHMENT_LIGHT)
	box.content_margin_left = UI.px(5)
	box.content_margin_right = UI.px(5)
	box.content_margin_top = UI.px(1)
	box.content_margin_bottom = UI.px(1)
	p.add_theme_stylebox_override("panel", box)
	p.set_meta("dressed", true)
	var l := UI.label(text, points if points > 0 else UI.TEXT_POINTS)
	l.add_theme_font_override("font", UI.bold_font())
	l.set_meta("bold", true)
	l.name = "Words"
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## A title as a ribbon across the top: the screen's name on parchment,
## heavier than a panel, with the screen's header (`under`) as its second
## line where it has one, so the world keeps the room a second plate took.
static func ribbon(title: Label, under: Label = null) -> PanelContainer:
	var p := PanelContainer.new()
	var box := paper(PANEL_CORNER + 4)
	box.set_border_width_all(maxi(3, UI.px(1.0)))
	box.border_width_bottom = maxi(5, UI.px(1.75))
	p.add_theme_stylebox_override("panel", box)
	p.set_meta("dressed", true)
	title.add_theme_font_override("font", UI.bold_font())
	title.add_theme_font_size_override("font_size", UI.text_px(RIBBON_POINTS))
	title.set_meta("points", RIBBON_POINTS)
	title.set_meta("bold", true)
	if under == null:
		p.add_child(title)
		return p
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	lines.add_child(title)
	lines.add_child(under)
	p.add_child(lines)
	return p


## A row of controls on a night tray at the foot of the screen, as a game
## holds its main keys: for a row of buttons only, since words on the night
## surface would need light ink.
static func dock(row: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var box := night(PANEL_CORNER + 6)
	box.bg_color = Color(NIGHT, 0.88)
	# Thin, so the row inside keeps the width §20.8's 200% text needs.
	box.set_content_margin_all(UI.px(2.5))
	p.add_theme_stylebox_override("panel", box)
	p.set_meta("dressed", true)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	return p


## A reason beside a control in a row (`RosterScreen.offer`) wraps at a
## readable width rather than one letter a line, and so moves below the
## control when the row is narrow.
static func unsqueeze(root: Node) -> void:
	for l: Node in root.find_children("*", "Label", true, false):
		var label := l as Label
		if label.get_parent() is HFlowContainer and label.autowrap_mode != TextServer.AUTOWRAP_OFF:
			label.custom_minimum_size.x = UI.px(100)
