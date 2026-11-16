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
	Home.home_figure(share, 18)
	lines.add_child(share)
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
		tag.position = Vector2(hold.size.x - tag.size.x, -hold.position.y - tag.size.y * 0.5)
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
