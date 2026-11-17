class_name ResultFit
extends RefCounted
## How the result screen (`ResultScreen`) fits large text and long languages
## to the phone: the reward tiles as rows or columns, the multipliers' pill on
## one line, Home as its icon, and the measures the raid bar is fitted by;
## and the crew's faces and the baked totals the screen dresses its rewards in.
## A helper of its own so result_screen.gd stays within gdlint's file length.


## The most lines a label has that the fold keeps together (`part_line`).
const KEEP := 3
## The baked totals' line, of their face's (`Home.FIGURE_LINE`'s).
const BAKED_LINE := 0.9


## The column a page's content has across a phone `width` wide: the width
## less the safe side on each edge.
static func column(width: float) -> float:
	return width - 2.0 * UI.px(Tokens.number("size", "safe_side_points"))


## With large text, one reward tile laid as a row rather than a column, as
## 03-result_text200_pt_BR: its icon, its number and its name side by side
## from the left, so the three stand under the time line. The number is
## still the box's second child and the box the tile's only one
## (`ResultScreen._reward_tile`).
static func tile_row(tile: PanelContainer) -> void:
	if Settings.text_scale <= KitLayout.SIDE_BY_SIDE_UP_TO:
		return
	var col := tile.get_child(0) as VBoxContainer
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(10))
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	for c: Node in col.get_children():
		col.remove_child(c)
		row.add_child(c)
		(c as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon := row.get_child(0) as Control
	icon.custom_minimum_size = Vector2.ONE * UI.px(26)
	var words := row.get_child(2) as Label
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.remove_child(col)
	col.queue_free()
	tile.add_child(row)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size.x = 0
	# A row needs less height than the tile's column: the key frame's rows
	# are a line of the number deep, so the third clears the dock.
	tile.add_theme_stylebox_override("panel", UI.clear_box(10, 3))


## With large text, the reward rows (`labels`, each tile's number, in
## `rows`) while each one's icon, number and name fit across a phone `width`
## wide; when one does not, every tile goes back to the design's column, one
## above another, rather than break a word by its letters. Each row is
## measured as it is drawn: the number at its baked width (`bake_totals` has
## laid it), the name by its longest word too (AD's objection H, German's
## "Sternenlicht" at 200%).
static func reward_rows(rows: BoxContainer, labels: Dictionary, width: float) -> void:
	if Settings.text_scale <= KitLayout.SIDE_BY_SIDE_UP_TO:
		return
	var room := column(width) - 2.0 * UI.px(10) - 2.0
	var fits := true
	for kind: String in labels:
		fits = fits and row_wide(tile_of(labels[kind]).get_child(0) as BoxContainer) <= room
	if fits:
		return
	rows.add_theme_constant_override("separation", UI.px(8))
	for kind: String in labels:
		tile_column(tile_of(labels[kind]))


## A reward row's width as drawn: its icon, its number and its name side by
## side, each word at least its own width; a lead's stack (`lead_stack`) as
## wide as its wider line.
static func row_wide(row: BoxContainer) -> float:
	var stack := row.get_child(1) as VBoxContainer
	var words: Array = stack.get_children() if stack != null else [row.get_child(1), row.get_child(2)]
	var gaps := 1 if stack != null else 2
	var side := 0.0
	var widest := 0.0
	for l: Label in words:
		var w := maxf(l.get_combined_minimum_size().x, l.get_theme_font("font").get_string_size(
			l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x)
		side += w
		widest = maxf(widest, w)
	return (row.get_child(0) as Control).custom_minimum_size.x + gaps * row.get_theme_constant("separation") \
		+ (widest if stack != null else side)


## The reward tile a total (`l`) stands in, a row, a column or a lead's stack.
static func tile_of(l: Control) -> PanelContainer:
	var p := l.get_parent()
	while p != null and not p is PanelContainer:
		p = p.get_parent()
	return p as PanelContainer


## Large text: the leading tile (Starlight's, a row from `tile_row`) with its
## name under its number, beside its icon, so the number leads at its full
## size whatever the name's length (German's "Sternenlicht"): the gate's
## Hierarchy fail at pt_BR 200% (P2-S1-result-6), where a lead beside its
## name had to shrink back to the others' size. The tile stays the number's
## nearest panel (`tile_of`).
static func lead_stack(tile: PanelContainer) -> void:
	if Settings.text_scale <= KitLayout.SIDE_BY_SIDE_UP_TO:
		return
	var row := tile.get_child(0) as HBoxContainer
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 0)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var number := row.get_child(1) as Control
	var words := row.get_child(2) as Control
	number.set_meta(&"lead_flags", number.size_flags_horizontal)
	for c: Control in [number, words]:
		row.remove_child(c)
		stack.add_child(c)
	# The number at its own width from the left; the name as wide as the
	# stack, or a wrapping label would be laid at no width, a letter a line.
	number.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	words.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(stack)


## A lead's stack back to a row: its number and name side by side again.
static func unstack(tile: PanelContainer) -> void:
	var row := tile.get_child(0) as HBoxContainer
	var stack := row.get_child(1) as VBoxContainer
	if stack == null:
		return
	for c: Control in stack.get_children():
		stack.remove_child(c)
		row.add_child(c)
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var number := row.get_child(2) as Control
	number.size_flags_horizontal = number.get_meta(&"lead_flags", Control.SIZE_FILL)
	(row.get_child(3) as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.remove_child(stack)
	stack.queue_free()


## Large text: the leading total (`l`, Starlight's) at its lead size, `top`
## pixels, or the least step down from it (to `base`, the others' size) that
## keeps its row within a phone `width` wide, so the lead never sends every
## tile back to a column (the gate's Hierarchy fail, P2-S1-result-6). Its
## icon follows its size. Measured from the live words, as `reward_rows`.
static func lead_fit(l: Label, top: int, base: int, width: float) -> void:
	if Settings.text_scale <= KitLayout.SIDE_BY_SIDE_UP_TO:
		return
	var row := tile_of(l).get_child(0) as BoxContainer
	var icon := row.get_child(0) as Control
	var room := column(width) - 2.0 * UI.px(10) - 2.0
	var px := top
	while true:
		l.add_theme_font_size_override("font_size", px)
		icon.custom_minimum_size = Vector2.ONE * roundf(UI.px(26) * float(px) / float(base))
		if px <= base or row_wide(row) <= room:
			return
		px = maxi(base, px - maxi(1, roundi(px * 0.04)))


## Large text: the hero's prose (`pairs`, each a label and its points) set
## at those points in a lighter `weight`, under the reward totals (the
## gate's Hierarchy fail at pt_BR 200%, P2-S1-result-6), its points kept for
## `hero_shrink`.
static func prose(pairs: Array, weight: int) -> void:
	for pair: Array in pairs:
		var l := pair[0] as Label
		l.add_theme_font_override("font", Tokens.font("ui", weight))
		l.add_theme_font_size_override("font_size", UI.text_px(float(pair[1])))
		l.set_meta("points", float(pair[1]))
		l.set_meta("bold", false)


## A reward tile back from a row to the design's column: its icon, its
## number and its name centred one above another (KitCards.reward's).
static func tile_column(tile: PanelContainer) -> void:
	unstack(tile)
	var row := tile.get_child(0) as HBoxContainer
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	for c: Node in row.get_children():
		row.remove_child(c)
		col.add_child(c)
		(c as Control).size_flags_vertical = Control.SIZE_FILL
	var icon := col.get_child(0) as Control
	icon.custom_minimum_size = Vector2.ONE * UI.px(34)
	var words := col.get_child(2) as Label
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.size_flags_horizontal = Control.SIZE_FILL
	tile.remove_child(row)
	row.queue_free()
	tile.add_child(col)
	tile.add_theme_stylebox_override("panel", UI.clear_box(10, 8))


## Large text: the multipliers' pill (`chip`, its words `label`) on one line
## while it fits the column of a phone `width` wide (AD's S1-R24): at its own
## size, then with its gaps narrowed (the pill's padding, thin spaces round
## its dots), then one size down. False when none fits (a long language);
## the pill then wraps at its dots.
static func chip_on_one_line(chip: PanelContainer, label: Label, width: float) -> bool:
	var font := RbTheme.role_font("label")
	var room := column(width) - UI.px(4)
	var words := label.text
	var narrow := words.replace(" · ", " · ")
	for step: Array in [[words, 10.0, 14.0], [narrow, 6.0, 14.0], [narrow, 6.0, 12.0]]:
		var size := UI.text_px(float(step[2]))
		var wide := font.get_string_size(str(step[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 2.0
		if wide + 2.0 * UI.px(float(step[1])) <= room:
			chip.add_theme_stylebox_override("panel", UI.clear_box(float(step[1]), 4))
			label.add_theme_font_size_override("font_size", size)
			label.text = str(step[0])
			label.clip_text = false
			label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			label.custom_minimum_size.x = 0
			return true
	return false


## Home as its icon alone, on a square of the control's height, its name
## spoken (the raid bar's large-text form, `ResultScreen._fit_raid`).
static func home_square(home: Button) -> void:
	if home.text == "":
		return
	home.accessibility_name = home.text
	home.tooltip_text = home.text
	home.text = ""
	home.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home.custom_minimum_size = Vector2.ONE * UI.px(UI.CONTROL_POINTS + 8.0)
	home.size_flags_vertical = Control.SIZE_SHRINK_CENTER


## Whether each word of each label in `words` fits `room`.
static func words_fit(words: Array[Node], room: float) -> bool:
	for l: Label in words:
		var font := l.get_theme_font("font")
		var text := l.text.to_upper() if l.uppercase else l.text
		for word: String in text.split(" ", false):
			if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x > room:
				return false
	return true


## Large text: the hero's words (`words`, each a label and its points) a
## size or two down, the least step that lifts the reward rows (`numbers`,
## each tile's number) above the action `bar`, so the whole haul stands on
## the first screen (AD's objection B: German and its long lines). Each
## step's saving is measured from the words' lines.
static func hero_shrink(words: Array, numbers: Array, bar: Control) -> void:
	# Above the page's lower edge, which ends a gap above the bar.
	var over := float(UI.px(6) + bar.get_parent().get_theme_constant("separation")) - bar.get_global_rect().position.y
	var foot := 0.0
	for l: Label in numbers:
		foot = maxf(foot, tile_of(l).get_global_rect().end.y)
	over += foot
	if over <= 0.0:
		return
	var steps: Array[float] = [0.88, 0.78, 0.7]
	for f: float in steps:
		var saved := 0.0
		for pair: Array in words:
			var l := pair[0] as Label
			if not l.is_visible_in_tree():
				continue
			# From the height laid out, not the size set: a second fitting
			# before the next layout then picks the same step.
			var then := UI.text_px(float(pair[1]) * f)
			saved += l.size.y - lines(l, l.size.x, then) \
				* (l.get_theme_font("font").get_height(then) + l.get_theme_constant("line_spacing"))
		if saved >= over or f == steps.back():
			for pair: Array in words:
				(pair[0] as Label).add_theme_font_size_override("font_size", UI.text_px(float(pair[1]) * f))
				ink(pair[0] as Label)
			return


## An ink outline round words on the art with no plate (§21.8: 1.5 points or
## 12% of their size, 3 points in high contrast), from the size the label is
## drawn at, so it grows with the text size and follows the hero's shrink.
## Measured at pt_BR 200%: the edge Godot shows outside the glyph is about a
## quarter of `outline_size` (21 gave 5 px on an 84 px face), so four times.
static func ink(l: Label) -> void:
	var font_px := float(l.get_theme_font_size("font_size"))
	var scale := Settings.text_scale / 100.0
	var edge := maxf((3.0 if Settings.high_contrast else 1.5) * UI.PX_PER_POINT * scale, 0.12 * font_px)
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	l.add_theme_constant_override("outline_size", int(ceil(4.0 * edge)))


## How many lines `l`'s words take wrapped between words within `room`, at
## its own size or at `font_px`.
static func lines(l: Label, room: float, font_px := 0) -> int:
	var font := l.get_theme_font("font")
	if font_px <= 0:
		font_px = l.get_theme_font_size("font_size")
	var text := l.text.to_upper() if l.uppercase else l.text
	var n := 1
	var line := ""
	for word: String in text.split(" ", false):
		var next := word if line == "" else line + " " + word
		if line != "" and font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x > room:
			n += 1
			line = word
		else:
			line = next
	return n


## `b` fitted to its words (`UI.fit`), and when one word alone is wider than
## the widest a button may be (German's "Veröffentlichen" at large text),
## its words the least sizes down that keep that word whole, rather than
## broken between its letters.
static func fit_whole(b: Button) -> void:
	UI.fit(b)
	var font := b.get_theme_font("font")
	var font_px := b.get_theme_font_size("font_size")
	var room := b.custom_minimum_size.x - b.get_theme_stylebox("normal").get_minimum_size().x
	var floor_px := UI.text_px(11.0)
	for word: String in b.text.split(" ", false):
		while font_px > floor_px and font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x > room:
			font_px -= 1
	if font_px != b.get_theme_font_size("font_size"):
		b.add_theme_font_size_override("font_size", font_px)
		UI.fit(b)


## Whether each word on `b` fits the room its padding and icon leave.
static func word_fits(b: Button) -> bool:
	var room := b.size.x - b.get_theme_stylebox("normal").get_minimum_size().x
	if b.icon != null:
		room -= UI.px(24) + b.get_theme_constant("h_separation")
	var font := b.get_theme_font("font")
	var font_px := b.get_theme_font_size("font_size")
	for word: String in b.text.split(" ", false):
		if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x > room:
			return false
	return true


## The page's foot over the action bar on a whole line (AD's objection F, in
## S1-R29): with the bar under the page that scrolls, the corner's clearance
## under the bar (`corner`) grows by the cut, lifting the bar and the scroll's
## lower edge off any line it would cut, so the first screen never ends on
## the tops of a line's letters (at 200% in English, "Re-simulated by the
## server" as a row of ticks and dashes), nor on a card's sliver. It cuts
## rather than fades: a fade is a draw call more. Fitted again as the page
## or the scroll changes size; each fitting measures from the edge without
## the cut, so they settle on one.
static func fold(scroll: ScrollContainer, bar: Control, corner: Control) -> void:
	if not scroll.is_inside_tree() or bar.get_parent() != scroll.get_parent():
		return
	if not corner.has_meta("clearance"):
		corner.set_meta("clearance", corner.custom_minimum_size.y)
		# The page's words change, or the bar grows (its words wrapped).
		var again := func() -> void: fold.call_deferred(scroll, bar, corner)
		(scroll.get_child(0) as Control).resized.connect(again)
		scroll.resized.connect(again)
	var tree := scroll.get_tree()
	await tree.process_frame
	await tree.process_frame
	if not scroll.is_inside_tree():
		return
	var clearance := float(corner.get_meta("clearance"))
	# The corner as laid, not as asked: a fitting queued before the last one
	# set its height measures before the layout has taken it, and would read
	# the old edge with the new cut, and undo it.
	var bottom := scroll.get_global_rect().end.y + corner.size.y - clearance
	var cut := 0.0
	for i in 4:
		var part := part_line(scroll, bottom - cut)
		if part <= 0.0:
			break
		cut += part
	corner.custom_minimum_size.y = clearance + cut


## How far above `bottom` the line or card it cuts starts, in the page that
## `scroll` holds: a label's line shown above its baseline only, or a card
## shown by less than a line of body text, or by a face's ring cut; a label
## of up to KEEP lines shown by its first lines only counts whole. Zero when
## `bottom` falls between lines, or under a line's baseline.
static func part_line(scroll: ScrollContainer, bottom: float) -> float:
	var page := scroll.get_child(0) as Control
	var sliver := float(UI.text_px(UI.TEXT_POINTS))
	var part := 0.0
	for c: Node in page.find_children("*", "Control", true, false):
		var n := c as Control
		if not n.is_visible_in_tree():
			continue
		var r := n.get_global_rect()
		if r.position.y >= bottom or r.end.y <= bottom:
			continue
		var shown := bottom - r.position.y
		if n is Label:
			var l := n as Label
			var px := l.get_theme_font_size("font_size")
			var step := l.get_theme_font("font").get_height(px) + l.get_theme_constant("line_spacing")
			var top := l.get_theme_stylebox("normal").get_margin(SIDE_TOP)
			if l.vertical_alignment == VERTICAL_ALIGNMENT_CENTER:
				top = (r.size.y - (step * l.get_line_count() - l.get_theme_constant("line_spacing"))) / 2.0
			shown -= top
			if shown <= 0.0:
				continue
			# A line is shown in part when its baseline is below the edge:
			# only its letters' tops show. A clipped descent leaves it whole.
			var p := fposmod(shown, step)
			if p > 1.0 and p < l.get_theme_font("font").get_ascent(px) and shown < step * l.get_line_count():
				part = maxf(part, p + (top if shown < step else 0.0))
			# A short label's lines kept together: one of up to KEEP lines
			# shown by its first lines only goes under the edge whole (AD's
			# note on S1-R30, "Taxa de entrada de" at pt_BR 200%).
			elif l.get_line_count() <= KEEP and shown > 1.0 and shown < step * (l.get_line_count() - 1) + 1.0:
				part = maxf(part, shown + top)
		elif n is PanelContainer and shown < sliver:
			part = maxf(part, shown)
		# A face's ring cut goes under the edge with its card whole, from the
		# top of the card's drawn box, which reaches past its rect (board 4's
		# note on P2-S1-result-6: at 100% the card's rim and the rings' tops
		# showed over the bar).
		elif n is KitRing:
			var card := n.get_parent() as Control
			while card != page and not card is PanelContainer:
				card = card.get_parent() as Control
			var top := minf(r.position.y, card.get_global_rect().position.y)
			var box := RbBox.of(card)
			if box != null:
				top = minf(top, box.get_global_rect().position.y + box.quad().position.y)
			part = maxf(part, ceilf(bottom - top))
	return part


## One crew member's face in the kit's ring, framed as the kit's avatars
## frame theirs (KitSocial's), on the leather band, `points` across.
static func face(picture: Texture2D, points: float) -> KitRing:
	var ring := KitRing.new()
	ring.name = "Face"
	ring.picture = picture
	ring.band = Tokens.color("gold")
	ring.ground = Tokens.paint("#4A3A9A")
	ring.zoom = 1.2
	ring.focus = Vector2(0.5, 0.42)
	ring.custom_minimum_size = Vector2.ONE * UI.px(points)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ring


## The kinds of crew `crew` (as it ended), in order, each with its
## creature's art.
static func crew_kinds(crew: Array) -> Array[String]:
	var kinds: Array[String] = []
	for m: Variant in crew:
		var kind := str((m as Dictionary).get("kind", "")) if m is Dictionary else ""
		# Played by role alone: the role's default kind, as the heist's
		# portraits show it (FxPortrait, Cast.KIND).
		if kind == "" and m is Dictionary and Cast.KIND.has(str((m as Dictionary).get("role", ""))):
			kind = String(Cast.KIND[str((m as Dictionary)["role"])])
		if kind != "" and CreatureModel.manifest().has(kind.replace("_", "")):
			kinds.append(kind)
	return kinds


## At normal text, the crew's lead in the kit's ring on the Starlight tile's
## upper corner, clear of its icon: the haul framed by who carried it. On a
## layer of its own over the tile, so the tile's column keeps its children.
## With large text the tiles are rows, and the crew stays on its card.
static func carrier(tile: PanelContainer, kinds: Array[String], points: float) -> void:
	if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO or kinds.is_empty():
		return
	var layer := Control.new()
	layer.name = "Carrier"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(layer)
	var ring := face(CreatureBust.of(kinds[0], "", Color(0, 0, 0, 0)), points)
	ring.position = Vector2(-UI.px(8), -UI.px(6))
	ring.size = ring.custom_minimum_size
	layer.add_child(ring)


## Each total (a label of `totals`) in its finish of the kit's baked numerals, over
## its label, whose own glyphs are hidden: the label keeps its words, its
## place in the tile and its size, so a screen reader, the fitting and the
## reward's coins still find it. Drawn again when its words or size change;
## while a glyph has no piece, the label shows itself.
static func bake_totals(totals: Dictionary) -> void:
	for l: Label in totals:
		var px := l.get_theme_font_size("font_size")
		var shown := "%s|%d" % [l.text, px]
		if str(l.get_meta("baked", "")) == shown:
			continue
		l.set_meta("baked", shown)
		var old := l.get_node_or_null("Baked")
		if old != null:
			l.remove_child(old)
			old.queue_free()
		l.visible_characters = -1
		l.custom_minimum_size = Vector2.ZERO
		if l.text == "":
			continue
		var digits := KitNumerals.make(l.text, str(totals[l]), "display_s", l.text)
		if not digits is KitNumerals.Row:
			digits.free()
			continue
		var row := digits as KitNumerals.Row
		row.name = "Baked"
		# The line's height, or less where the glyphs would be wider than the
		# live words with their outline: the total keeps the room the
		# fitting measured. With large text, where the tiles are rows, the
		# live words alone (result-4's width), so a name beside the total
		# keeps its room (AD's objection H).
		var font := l.get_theme_font("font")
		row.height = floorf(font.get_height(px) * BAKED_LINE)
		row.update_minimum_size()
		var room := font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		if Settings.text_scale <= KitLayout.SIDE_BY_SIDE_UP_TO:
			room += float(l.get_theme_constant("outline_size"))
		var wide := row.get_combined_minimum_size().x
		if wide > room:
			row.height = floorf(row.height * room / wide)
		# One layer above the words, as the home's figures: every baked row
		# draws in one call from the numerals' page.
		row.z_index = 1
		row.update_minimum_size()
		l.add_child(row)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# At least as wide as its live words, which it keeps for the reader
		# and the fitting.
		var words := font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		l.custom_minimum_size = Vector2(maxf(ceilf(words), row.get_combined_minimum_size().x),
			row.get_combined_minimum_size().y)
		l.visible_characters = 0
