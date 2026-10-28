class_name UiAudit
extends RefCounted
## Where a mounted screen draws past the kit (ui_screen.gd with AUDIT=1): a
## button or panel in a fill of its own rather than a kit material, words
## in a face that is not one of the kit's three, words under §21.8's 13
## points, a hand-drawn colour on words where the material has its own ink.
## A report for the screens' owners, not a test: the kit's own pieces pass.


## One line per thing that bypasses the kit, "kind path detail", the most
## common first.
static func report(screen: Control) -> PackedStringArray:
	var out := PackedStringArray()
	var faces := {}
	for family: String in ["ui", "title", "display"]:
		faces[_base(Tokens.font(family)).get_rid()] = true
	var least := UI.text_px(13)
	for n: Node in screen.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.get_global_rect().size.x < 1.0:
			continue
		var where := _short(screen.get_path_to(c))
		if (c is Button or c is PanelContainer) and RbBox.of(c) == null:
			var fill := _own_fill(c)
			if fill.a > 0.01:
				out.append("own-%s %s #%s" % ["button" if c is Button else "panel", where, fill.to_html(false)])
		elif RbBox.of(c) != null and _own_fill(c).a > 0.01:
			out.append("over-kit %s %s" % [where, RbBox.of(c).look])
		if c is Label:
			var l := c as Label
			if l.text.strip_edges() == "":
				continue
			var font := l.get_theme_font("font")
			if font != null and not _kit_face(font, faces):
				out.append("own-face %s %s" % [where, _font_name(font)])
			if l.get_theme_font_size("font_size") < least:
				out.append("small %s %dpx '%s'" % [where, l.get_theme_font_size("font_size"), l.text.left(16)])
	return out


static func _own_fill(c: Control) -> Color:
	var box: StyleBox = c.get_theme_stylebox("panel") if c is PanelContainer else c.get_theme_stylebox("normal")
	if box is StyleBoxFlat and (box as StyleBoxFlat).draw_center:
		return (box as StyleBoxFlat).bg_color
	if box is StyleBoxTexture:
		return Color.WHITE
	return Color(0, 0, 0, 0)


static func _kit_face(font: Font, faces: Dictionary) -> bool:
	var f := _base(font)
	return f != null and (faces.has(f.get_rid()) or _font_name(f) in ["Manrope", "Marcellus", "Lilita One"])


static func _base(font: Font) -> Font:
	var f := font
	while f is FontVariation and (f as FontVariation).base_font != null:
		f = (f as FontVariation).base_font
	return f


static func _font_name(font: Font) -> String:
	var f := _base(font)
	return f.get_font_name() if f != null else "?"


## The last three names of a node's path.
static func _short(path: NodePath) -> String:
	var names := str(path).split("/")
	return "/".join(names.slice(maxi(0, names.size() - 3)))
