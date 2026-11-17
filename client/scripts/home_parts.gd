class_name HomeParts
extends RefCounted
## Parts of the home screen (`Home`): the raid notice, and how the purse's
## strain and Full take large text. A helper of its own so home.gd stays within
## gdlint's file length (S2-R23).

## Full's words on its plate with large text, in points before the scale: the
## key frame at 200% draws them as the band's name, under the amount.
const FULL_LARGE_POINTS := 11.0
## The least share of their size the goal's words take with large text, to
## break after the dot on two lines (break_goal).
const GOAL_LEAST := 0.85
## How far Full hangs above its pill's edge at 100%, beyond half its plate:
## clear of the baked figures' tops, which stand on the amount's cap height.
const FULL_LIFT := 8.0
## Home's figures: the kit's gold baked numerals in the small display
## role's slot (kit-spec.md section 2.2, T3), and its words' T2 drawn half
## again as heavy as the role's theme (`inked`). Gold, not white: the white
## finish's pale gradient and thinner stroke read as a flat light fill on the
## dark plates at the still's scale (P2-S2-home-6), where the gold's cream to
## amber reads as the gradient it is, as the pass anchor's counts do.
const FIGURE_FINISH := "num_gold"
const FIGURE_ROLE := "display_s"
const INK_HEAVIER := 1.5
## The live words' outline, at least this share of their size (the rubric's
## 12%, with a little to spare for rounding).
const OUTLINE_SHARE := 0.13
## The leather rim round the ink of words over the starfield, in points.
const RIM := 2.5
## The baked figures' share of the role's line: their cells hold the glyph's
## stroke and drop round its body, so at the full line the figures stand
## taller and higher than the live words beside them (the "k") and meet the
## Full tag over the pill; at this share, foot to the line's foot, their
## bodies match the live face's and sit on its baseline.
const FIGURE_LINE := 0.9


## Large text (§20.8): strain in the purse's fourth place in the two lines the
## key frame at 200% draws in every language (S2-R20's fourth objection), the
## share in the amounts' figures over the band's name, rather than one line.
static func large_strain(pill: PanelContainer, pct: int, named: String) -> void:
	var words := pill.find_child("Words", true, false) as Label
	words.visible = false
	var row := words.get_parent() as HBoxContainer
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	var lines := VBoxContainer.new()
	lines.name = "Lines"
	lines.add_theme_constant_override("separation", 0)
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var share := UI.label("%d%%" % pct, 18)
	share.name = "Share"
	share.set_meta("bold", true)
	lines.add_child(share)
	# In its place first: `figures` sets the baked row beside the label.
	Home.home_figure(share, 18)
	# The band's name tucked under the share's figures, not a whole line below.
	lines.add_theme_constant_override("separation", -int(below(share)))
	var band := UI.label(named, 14)
	band.name = "Band"
	band.theme_type_variation = "LabelText"
	band.set_meta("bold", true)
	band.set_meta("px", band.get_theme_font_size("font_size"))
	lines.add_child(band)
	row.add_child(lines)


## A pill's Full as the key frames draw it, on a red tag: at 100% a tab on
## the pill's top edge at its right, which takes no room from the amount; with
## large text (§20.8) a plate under the amount, at the right, over the bar.
## It shows only while that resource is nearly full (_fit_purse).
static func hang_full(pill: PanelContainer) -> void:
	var tag := UI.panel("red")
	tag.name = "FullTag"
	tag.add_theme_stylebox_override("panel", UI.clear_box(6, 1 if Settings.text_scale < 150 else 0))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.visible = false
	var words := UI.label(Strings.t("KIT_FULL"), 13.0 if Settings.text_scale < 150 else FULL_LARGE_POINTS)
	words.add_theme_font_override("font", UI.bold_font())
	words.set_meta("bold", true)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(words)
	if Settings.text_scale >= 150:
		# Under the amount, its top tucked into the room the figures leave
		# under their line, so the tag adds only its own words' height.
		var under := Control.new()
		under.name = "FullHold"
		under.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var column := pill.get_child(0) as VBoxContainer
		column.add_child(under)
		column.move_child(under, 1)
		under.add_child(tag)
		var amount := pill.find_child("Amount", true, false) as Label
		var tuck := func() -> void:
			var lift := below(amount)
			tag.size = tag.get_combined_minimum_size()
			tag.position = Vector2(under.size.x - tag.size.x, -lift)
			var tall := tag.size.y - lift if tag.visible else 0.0
			if not is_equal_approx(under.custom_minimum_size.y, tall):
				under.custom_minimum_size.y = tall
		under.resized.connect(tuck)
		tag.minimum_size_changed.connect(tuck)
		tag.visibility_changed.connect(tuck)
		amount.minimum_size_changed.connect(tuck)
		return
	# A plain holder the pill fits to its inside, so the tab takes no room in
	# it and hangs half over the pill's edge.
	var hold := Control.new()
	hold.name = "FullHold"
	hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(hold)
	hold.add_child(tag)
	var hang := func() -> void:
		tag.size = tag.get_combined_minimum_size()
		tag.position = Vector2(hold.size.x - tag.size.x, -hold.position.y - tag.size.y * 0.5 - UI.px(FULL_LIFT))
	hold.resized.connect(hang)
	tag.minimum_size_changed.connect(hang)
	tag.visibility_changed.connect(hang)


## The room a label's line leaves under its letters' foot, less a small gap:
## where the line under it may tuck in.
static func below(l: Label) -> float:
	var font := l.get_theme_font("font")
	return maxf(0.0, font.get_descent(l.get_theme_font_size("font_size")) - UI.px(2))


## The goal card's words (Home._show_goal marks them).
static func goal_words(card: Control) -> Label:
	for c: Label in card.find_children("*", "Label", true, false):
		if c.visible and c.has_meta("goal_words"):
			return c
	return null


## What the goal card takes across besides its words: its padding, its picture
## and the words' own box.
static func goal_beside(card: Control, l: Label) -> float:
	var pad := (card as PanelContainer).get_theme_stylebox("panel").get_minimum_size().x
	var row := l.get_parent().get_parent() as BoxContainer
	var beside := 0.0
	for c: Control in row.get_children():
		if c != l.get_parent() and c.visible:
			beside += c.get_combined_minimum_size().x + row.get_theme_constant("separation")
	return pad + beside + l.get_theme_stylebox("normal").get_minimum_size().x


## The goal's words, where they take more than a line in a card `wide` across,
## broken after the dot as the key frame breaks them ("1,240 experience to go ·
## / Keeper 25", AD's objection (d) on S2-R22), where both halves fit a line;
## else left to the label's wrap. With large text the words may be a little
## smaller for it, never under GOAL_LEAST of their size, as the key frame at
## 200% sets them a little under the kit's.
static func break_goal(card: Control, text: String, wide: float) -> void:
	var l := goal_words(card)
	if l == null:
		return
	var want := text
	var px: int = l.get_meta("px", l.get_theme_font_size("font_size"))
	var points := px
	var dot := text.find(" · ")
	if dot > 0:
		var font := l.get_theme_font("font")
		var room := wide - goal_beside(card, l) - 1.0
		var first := text.substr(0, dot + 2)
		var second := text.substr(dot + 3)
		var size := func(t: String, at: int) -> float: return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1,
			at).x
		if size.call(text, px) > room:
			if Settings.text_scale >= 150:
				while points > ceili(px * GOAL_LEAST) and size.call(first, points) > room:
					points -= 1
			if size.call(first, points) <= room and size.call(second, points) <= room:
				want = first + "\n" + second
			else:
				points = px
	if l.get_theme_font_size("font_size") != points:
		l.add_theme_font_size_override("font_size", points)
	if l.text != want:
		l.text = want


## Where `c` and everything shown inside it reach on the screen: a side
## button's badge stands past the button's own rect.
static func reach(c: Control) -> Rect2:
	var r := c.get_global_rect()
	for d: Node in c.find_children("*", "Control", true, false):
		var k := d as Control
		if k.is_visible_in_tree() and k.size.x > 0.0 and k.size.y > 0.0:
			r = r.merge(k.get_global_rect())
	return r


## The raid notice and what it says: the panel home lays in its column.
class Raids:
	extends RefCounted
	var panel: PanelContainer
	var headline: Label
	## The notice's headline in full and its count, for the one-line notice.
	var title := ""
	var count := 0
	## The room the screen gives across, read as the notice lays out.
	var across: Callable

	func _init(room: Callable, dismiss: Callable) -> void:
		across = room
		panel = _build(dismiss)

	## The raid notice, from the kit's alarm banner: the heist's mark on a red
	## disc, a headline over a line saying where to see the defence, See and a
	## close cross on the kit's plate. §21.8: it stays until dismissed. With large
	## text (§20.8) it is one line, so Collect and the goal keep their room (board
	## 3's objection A); the line under the headline is still said with it.
	func _build(dismiss: Callable) -> PanelContainer:
		var p := UI.panel("banner_alarm")
		p.name = "RaidNotice"
		# A dark card edged in the alarm's colour (tokens.json): the skin has no
		# banner shape yet, and its red face fails 4.5:1 (S2-R6 asks K1 for one).
		RbBox.of(p).tint(Tokens.color("card_top"), Tokens.color("card_bottom"))
		var large := Settings.text_scale >= 150
		if large:
			# One line, as tight as its controls at large text, so the realms'
			# chips keep their room above it (board 3's objections A and C).
			p.add_theme_stylebox_override("panel", UI.clear_box(10, 2))
		var row := HBoxContainer.new()
		row.name = "Row"
		row.add_theme_constant_override("separation", UI.px(8))
		p.add_child(row)
		var disc := PanelContainer.new()
		disc.add_theme_stylebox_override("panel", UI.clear_box(4, 4))
		UI.dress(disc, "badge")
		disc.add_child(Icons.view("alerts/raided", 26))
		disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(disc)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.alignment = BoxContainer.ALIGNMENT_CENTER
		text.add_theme_constant_override("separation", 0)
		row.add_child(text)
		headline = UI.status("alarm", "", false)
		headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		headline.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		headline.accessibility_live = AccessibilityServer.LIVE_ASSERTIVE
		text.add_child(headline)
		var line := UI.label(Strings.t("HOME_RAID_LINE"), 13, true)
		line.theme_type_variation = "Secondary"
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		line.visible = not large
		text.add_child(line)
		if not large:
			text.resized.connect(balance.bind(line, text))
		# The kit's secondary look: gold is the screen's one main action, Collect
		# (and the Heist tab), and the red card already draws the eye (§21.8).
		var see := UI.action(Strings.t("HOME_RAIDED_SEE"), func() -> void: App.services.router.go(&"defences"), "ghost")
		see.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(see)
		# The cross on the kit's round plate, its whole 48 points a target.
		var close := KitControls.icon_button("generalui/close", Strings.t("HOME_RAIDED_CLOSE"), dismiss, "leather", 48.0,
			-1.0, 36.0)
		close.name = "Close"
		row.add_child(close)
		# Its tag one line at every size (S2-R20's second objection): two would
		# take the world's height.
		row.pre_sort_children.connect(fit.bind(row, text))
		p.set_meta("line", line)
		return p

	## The line under the headline, where it takes two lines, broken where both
	## halves come out nearest alike, so no word stands alone on the second
	## (S2-R20's second objection).
	static func balance(line: Label, text: Control) -> void:
		var words := Strings.t("HOME_RAID_LINE")
		var font := line.get_theme_font("font")
		var points := line.get_theme_font_size("font_size")
		var room := text.size.x - line.get_theme_stylebox("normal").get_minimum_size().x
		var want := words
		if room > 0.0 and font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x > room:
			var parts := words.split(" ", false)
			var best := INF
			for i in range(1, parts.size()):
				var first := " ".join(parts.slice(0, i))
				var a := font.get_string_size(first, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
				var b := font.get_string_size(" ".join(parts.slice(i)), HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
				if a <= room and b <= room and maxf(a, b) < best:
					best = maxf(a, b)
					want = first + "\n" + " ".join(parts.slice(i))
		if line.text != want:
			line.text = want

	## The headline's tag on one line beside See and the cross: its
	## words where they fit, else the count alone; where even that leaves no room
	## (German's See at 200%), the disc gives way to the tag's alarm glyph.
	func fit(row: HBoxContainer, text: Control) -> void:
		if title == "":
			return
		var disc := row.get_child(0) as Control
		var gap := row.get_theme_constant("separation")
		var room: float = across.call() - panel.get_theme_stylebox("panel").get_minimum_size().x
		for c: Control in row.get_children():
			if c.visible and c != text and c != disc:
				room -= c.get_combined_minimum_size().x + gap
		var font := headline.get_theme_font("font")
		var points := headline.get_theme_font_size("font_size")
		var pad := headline.get_theme_stylebox("normal").get_minimum_size().x + font.get_string_size(
			UI.GLYPH["alarm"] + " ", HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
		var with_disc := room - disc.get_combined_minimum_size().x - gap
		var whole := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x + pad <= with_disc
		var want := title if whole else str(count)
		var keep := whole or font.get_string_size(want, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x + pad <= with_disc
		if disc.visible != keep:
			disc.visible = keep
		if headline.text != "%s %s" % [UI.GLYPH["alarm"], want]:
			UI.set_status(headline, "alarm", want)

	## The raids not yet seen; none hides the notice. It arrives as the kit's
	## banners do (§21.8: easing out, no overshoot); under reduced motion it only
	## fades.
	func show_raids(unseen: int) -> void:
		var was := panel.visible
		panel.visible = unseen > 0
		if panel.visible and not was and panel.is_inside_tree():
			Motion.pop(panel)
		var said := Strings.t("HOME_RAID_TITLE_ONE") if unseen == 1 else Strings.t("HOME_RAID_TITLE", unseen)
		title = said
		count = unseen
		# Through the kit, so the words take the alarm's fill and glyph once they
		# say something (UI.set_status).
		UI.set_status(headline, "alarm", said)
		panel.accessibility_name = "%s. %s" % [said, Strings.t("HOME_RAID_LINE")]
		(panel.get_node("Row") as Control).queue_sort()


## T2 on `l` where the role's theme draws it too lightly to see: the role's
## outline is 2 points and its drop 1.5 with no outline of its own, so the
## stroke covers the drop (P2-S2-home-5: the purse's counts read flat cream).
## The outline here is half again as thick, and never under OUTLINE_SHARE of
## the words' size, so it holds at large text too. On a plate (`over_art`
## false) the drop is the glyph's own shadow set down by the outline and the
## role's drop, so it shows below the stroke, as the baked figures beside it
## have theirs: the shadow is as wide as the stroke, so it is the stroked
## words' drop, not a ghost of their bodies (AD-R45 (a)). Over the starfield (`over_art`) the ink alone merges into the
## night behind it (P2-S2-home-6: "Keeper 24" read as dropped, not outlined),
## so the shadow is a band of the plates' leather rim round the stroke, set
## down by a third of its width (never less than the rim itself would show
## above the letters): the ink then stands out all round against the rim,
## and the rim's heavier foot is the drop. That shadow's outline costs
## one more call, for the one name over the art.
static func inked(l: Label, over_art := false) -> void:
	var t := Tokens.type_role(FIGURE_ROLE)
	var px := l.get_theme_font_size("font_size")
	var outline := maxi(UI.px(float(t["outline"]) * INK_HEAVIER), ceili(px * OUTLINE_SHARE))
	var drop := maxi(1, UI.px(float(t["drop"]) * INK_HEAVIER))
	l.add_theme_color_override("font_color", Tokens.color("cream"))
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_constant_override("shadow_offset_x", 0)
	if over_art:
		var rim := maxi(3, UI.px(RIM))
		l.add_theme_color_override("font_shadow_color", Tokens.color("leather_rim"))
		l.add_theme_constant_override("shadow_offset_y", maxi(1, rim / 3))
		l.add_theme_constant_override("shadow_outline_size", outline + rim)
		return
	l.add_theme_color_override("font_shadow_color", Tokens.color("drop"))
	l.add_theme_constant_override("shadow_offset_y", drop)
	l.add_theme_constant_override("shadow_outline_size", outline)


## `text` cut where the baked numerals end: [the figures, the words after
## them] ("142.0k" is ["142.0", "k"], "142,0 mil" is ["142,0", " mil"]).
## No figures where the text does not start with one ("–", "Keeper 24").
static func figures_cut(text: String) -> PackedStringArray:
	var cut := 0
	while cut < text.length() and KitNumerals.GLYPHS.has(text[cut]):
		cut += 1
	var digits := text.substr(0, cut)
	var gap := ""
	while digits != "" and KitNumerals.GLYPHS[digits[digits.length() - 1]] == "space":
		digits = digits.substr(0, digits.length() - 1)
		gap = " "
	if digits.strip_edges() == "":
		return PackedStringArray(["", text])
	var rest := text.substr(cut)
	return PackedStringArray([digits, gap + rest if rest != "" else ""])


## `l`'s figures in the kit's baked numerals (T3: a gradient fill, a thick
## ink stroke and a hard drop), in a row that takes the label's place beside
## it, the words after them ("k", " mil") in live gold T2 type at the label's
## size. Called again when the label's words or size change; while the
## numerals' skin is off, or a figure has no glyph, the label shows itself.
## The hidden label keeps its words, so a screen reader and `Home._fit_amounts`
## still read them.
static func figures(l: Label) -> void:
	var px := l.get_theme_font_size("font_size")
	var shown := "%s|%d|%s" % [l.text, px, l.get_meta("live", false)]
	var old: Control = l.get_meta("figures") if l.has_meta("figures") else null
	if old != null and is_instance_valid(old):
		if str(old.get_meta("shown", "")) == shown and old.get_parent() == l.get_parent():
			return
		if old.get_parent() != null:
			old.get_parent().remove_child(old)
		old.queue_free()
	l.remove_meta("figures")
	l.visible = true
	var cut := figures_cut(l.text)
	if cut[0] == "" or l.get_parent() == null or l.get_meta("live", false):
		return
	var made := KitNumerals.make(cut[0], FIGURE_FINISH, FIGURE_ROLE, l.text)
	if not made is KitNumerals.Row:
		made.free()
		return
	var digits := InkedRow.of(made as KitNumerals.Row)
	var line := RbTheme.role_font(FIGURE_ROLE).get_height(px)
	(digits as KitNumerals.Row).height = floorf(line * FIGURE_LINE)
	digits.size_flags_vertical = Control.SIZE_SHRINK_END
	# One layer above the words: every baked row then draws in one call from
	# the numerals' atlas page, not splitting the art's or the words' batches.
	digits.z_index = UI.WORDS_Z + 1
	digits.update_minimum_size()
	var box := HBoxContainer.new()
	box.name = String(l.name) + "Figures"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	box.size_flags_horizontal = l.size_flags_horizontal
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.alignment = BoxContainer.ALIGNMENT_END if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT \
			else BoxContainer.ALIGNMENT_CENTER if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER \
			else BoxContainer.ALIGNMENT_BEGIN
	box.accessibility_name = l.text
	box.custom_minimum_size.y = ceilf(line)
	box.add_child(digits)
	if cut[1] != "":
		var after := UI.label(cut[1], float(l.get_meta("points", 18.0)))
		after.name = "After"
		after.theme_type_variation = "Display"
		after.add_theme_font_size_override("font_size", px)
		after.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inked(after)
		after.add_theme_color_override("font_color", Tokens.color("gold"))
		box.add_child(after)
	box.set_meta("shown", shown)
	l.add_sibling(box)
	l.visible = false
	l.set_meta("figures", box)


## What `l` shows: its baked figures' row where it has one, else itself.
static func shown_as(l: Label) -> Control:
	var box: Control = l.get_meta("figures") if l.has_meta("figures") else null
	return box if box != null and is_instance_valid(box) and box.get_parent() != null else l


## How wide `text` is drawn as `figures` draws it at `px`: the baked
## figures' fixed advances and the words after them in the display face; the
## live face's width where the figures cannot be baked.
static func figures_width(l: Label, text: String, px: int) -> float:
	var cut := figures_cut(text)
	var face := l.get_theme_font("font")
	var cells: Array[Dictionary] = []
	for ch: String in cut[0]:
		var p := KitSkin.numeral("%s_%s" % [FIGURE_FINISH, KitNumerals.GLYPHS[ch]])
		if p.is_empty():
			cells.clear()
			break
		cells.append(p)
	if cells.is_empty():
		return face.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var tallest := 1.0
	var across := 0.0
	for p: Dictionary in cells:
		tallest = maxf(tallest, float(p["h"]))
		across += float(p.get("advance", p["w"]))
	var w := ceilf(across * floorf(RbTheme.role_font(FIGURE_ROLE).get_height(px) * FIGURE_LINE) / tallest)
	if cut[1] != "":
		w += face.get_string_size(cut[1], HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	return w


## The row's amounts at full size against `room`, the purse's width less its
## gaps, read from the face and the baked figures (`baked`) or the live face,
## not from the labels as they are now: x, the amounts' widths; y, how far
## the row's pills run over `room`.
static func amounts_over(amounts: Array, held: Array[Control], room: float, baked: bool) -> Vector2:
	var words := 0.0
	var rest := 0.0
	for i in amounts.size():
		var l := amounts[i] as Label
		var full := UI.text_px(float(l.get_meta("points")))
		words += figures_width(l, l.text, full) if baked \
				else l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, full).x
		rest += held[i].get_combined_minimum_size().x - shown_as(l).get_combined_minimum_size().x
	return Vector2(words, words + rest - room)


## The share of their full size the row's amounts take against `room`, and
## whether they are baked (x, y): baked, a little smaller where the row does
## not fit at full size, never under `least_baked`, so every headline count
## keeps the one baked treatment (P2-S2-home-6); live only where even that
## does not fit, then a little smaller too, never under `least_live`.
static func amounts_fit(amounts: Array, held: Array[Control], room: float, least_baked: float,
		least_live: float) -> Vector2:
	for baked: bool in [true, false]:
		var fit := amounts_over(amounts, held, room, baked)
		if fit.y <= 0.5:
			return Vector2(1.0, 1.0 if baked else 0.0)
		var shrunk := (fit.x - fit.y - 1.0) / maxf(fit.x, 1.0)
		if shrunk >= (least_baked if baked else least_live):
			return Vector2(shrunk, 1.0 if baked else 0.0)
	return Vector2(1.0, 0.0)


## The figures' row with T3's treatment held at every text size
## (P2-S2-home-6, the gate at e674b614: "flat gold fills, with no ink
## outline, no hard drop and no gradient" at 100%). The kit's glyphs are
## 210 pixels tall and draw here 18 to 40 high, from a page without
## mipmaps, so their own thin stroke and drop thin out to nothing and their
## gradient to a flat gold. From the same glyphs, in the same call, this row
## draws a hard drop in the drop colour, then an ink stroke all round, both
## from the glyphs' outlines and sized in screen pixels, then each glyph in
## bands shaded from its cream top to a deeper amber foot.
class InkedRow:
	extends KitNumerals.Row

	## The stroke's width, the rule's 12% of the figures' size or more.
	const STROKE_SHARE := 0.08
	## The drop below the stroke, as a share of the figures' size.
	const DROP_SHARE := 0.1
	## The tint at the glyphs' foot; their top keeps the art's own cream.
	const FOOT := Color(0.93, 0.74, 0.5)
	## The bands a glyph is shaded in, at most.
	const BANDS := 16

	## `row` as an inked row: its glyphs, slot and what a screen reader says.
	static func of(row: KitNumerals.Row) -> InkedRow:
		var out := InkedRow.new()
		out.cells = row.cells
		out.height = row.height
		out.accessibility_name = row.accessibility_name
		for key: StringName in row.get_meta_list():
			out.set_meta(key, row.get_meta(key))
		row.free()
		return out

	func _draw() -> void:
		var s := glyph_scale()
		var x := (size.x - get_minimum_size().x) * 0.5
		var bottom := (size.y + height) * 0.5
		var glyphs: Array[Array] = []
		for p: Dictionary in cells:
			var w := float(p["w"]) * s
			var h := float(p["h"]) * s
			var advance := float(p.get("advance", p["w"])) * s
			var at := Rect2(x + (advance - w) * 0.5, bottom - h, w, h)
			glyphs.append([KitSkin.texture(p), at, Rect2(p["x"], p["y"], p["w"], p["h"])])
			x += advance
		var stroke := maxf(1.0, height * STROKE_SHARE)
		var drop := Vector2(0.0, maxf(1.0, height * DROP_SHARE))
		var ring: Array[Vector2] = []
		for i in 8:
			ring.append(Vector2.from_angle(TAU * i / 8.0) * stroke)
		for under: Array in [[Tokens.color("drop"), drop], [Tokens.color("ink_line"), Vector2.ZERO]]:
			for g: Array in glyphs:
				for off: Vector2 in ring:
					draw_texture_rect_region(g[0], Rect2(g[1].position + off + under[1], g[1].size), g[2], under[0])
		for g: Array in glyphs:
			var at: Rect2 = g[1]
			var from: Rect2 = g[2]
			var bands := clampi(ceili(at.size.y), 1, BANDS)
			for i in bands:
				var tint := Color.WHITE.lerp(FOOT, (i + 0.5) / bands)
				draw_texture_rect_region(g[0],
						Rect2(at.position.x, at.position.y + at.size.y * i / bands, at.size.x, at.size.y / bands),
						Rect2(from.position.x, from.position.y + from.size.y * i / bands, from.size.x,
								from.size.y / bands), tint)
